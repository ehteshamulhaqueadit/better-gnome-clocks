/*
 * Copyright (C) 2013  Paolo Borelli <pborelli@gnome.org>
 * Copyright (C) 2020  Bilal Elmoussaoui <bilal.elmoussaoui@gnome.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

namespace Clocks {
namespace Timer {

[GtkTemplate (ui = "/org/gnome/clocks/ui/timer-face.ui")]
public class Face : Adw.Bin, Clocks.Clock {
    [GtkChild]
    private unowned Gtk.ListBox timers_list;
    [GtkChild]
    private unowned Gtk.Stack stack;

    public PanelId panel_id { get; construct set; }
    public ButtonMode button_mode { get; set; default = NONE; }
    public bool is_running { get; set; default = false; }
    // Translators: Tooltip for the + button
    public string? new_label { get; default = _("New Timer"); }

    private ContentStore timers;
    private GLib.Settings settings;
    private Utils.Bell? bell;
    private Utils.SoundManager sound_manager;
    private GLib.Notification notification;
    
    // Queue system for multiple timers
    private GLib.Queue<Item> ringing_queue;              // Timers waiting to ring
    private Item? currently_ringing_timer = null;         // Currently ringing timer
    private GLib.HashTable<Item, bool> processed_timers; // Prevent duplicate processing

    internal signal void ring (Item item);

    construct {
        panel_id = TIMER;

        settings = new GLib.Settings ("org.gnome.clocks");
        sound_manager = new Utils.SoundManager ();
        timers = new ContentStore ();
        ringing_queue = new GLib.Queue<Item> ();
        processed_timers = new GLib.HashTable<Item, bool> (GLib.direct_hash, GLib.direct_equal);

        timers_list.bind_model (timers, (timer) => {
            var item = (Item) timer;
            var row = new Row (item);
            row.deleted.connect (() => remove_timer (item));
            row.edited.connect (() => save ());
            row.edit_clicked.connect (() => edit_timer (item));
            
            // Connect to timer completion signal
            item.ring.connect (() => ring_handler (item));
            
            // Monitor timer state changes
            item.notify["state"].connect (() => {
                update_app_state ();
                
                // Handle manual pause of currently ringing timer
                // Note: Don't handle STOPPED state here as it occurs naturally on completion
                if (item == currently_ringing_timer && item.state == Item.State.PAUSED) {
                    handle_current_timer_dismissed ();
                }
            });
            return row;
        });

        timers.items_changed.connect ((added, removed, position) => {
            if (this.timers.get_n_items () > 0) {
                stack.visible_child_name = "timers";
                this.button_mode = NEW;
            } else {
                stack.visible_child_name = "empty";
                this.button_mode = NEW;
            }
            save ();
        });

        notification = new GLib.Notification (_("Time is up!"));
        notification.set_body (_("Timer countdown finished"));
        notification.set_priority (HIGH);

        load ();
    }

    private int get_total_active_timers () {
        var total_items = 0;
        this.timers.foreach ((timer) => {
            if (((Item)timer).state == Item.State.RUNNING) {
                total_items += 1;
            }
        });
        return total_items;
    }
    
    /**
     * Updates application state based on running timers.
     * Holds the application in background when timers are active,
     * allowing them to continue running when the window is closed.
     */
    private void update_app_state () {
        var active_count = get_total_active_timers ();
        var was_running = this.is_running;
        this.is_running = active_count != 0;
        
        var app = (Clocks.Application) GLib.Application.get_default ();
        
        // Hold application to keep it running in background when timers are active
        if (!was_running && this.is_running) {
            app.hold ();
        }
        // Release application when all timers have stopped
        else if (was_running && !this.is_running) {
            app.release ();
        }
        
        save ();
    }

    private void remove_timer (Item item) {
        // Remove from queue if waiting
        ringing_queue.remove (item);
        
        // Remove from processed list
        processed_timers.remove (item);
        
        // If this was the currently ringing timer, move to next
        if (item == currently_ringing_timer) {
            handle_current_timer_dismissed ();
        }
        
        timers.remove (item);
    }

    public void activate_new () {
        var dialog = new SetupDialog ((Gtk.Window) get_root ());
        dialog.response.connect ((dialog, response) => {
            if (response == Gtk.ResponseType.ACCEPT) {
                var timer = ((SetupDialog) dialog).timer_setup.get_timer ();
                this.timers.add (timer);
            }
            dialog.destroy ();
        });
        dialog.show ();
    }
    
    /**
     * Opens edit dialog for an existing timer.
     * Allows user to modify timer duration and name.
     * Only stopped timers can be edited.
     */
    private void edit_timer (Item timer) {
        // Don't allow editing running or paused timers
        if (timer.state != Item.State.STOPPED) {
            return;
        }
        
        var dialog = new SetupDialog ((Gtk.Window) get_root (), timer);
        dialog.response.connect ((dialog, response) => {
            if (response == Gtk.ResponseType.ACCEPT) {
                var edited = ((SetupDialog) dialog).timer_setup.get_timer ();
                // Update the existing timer's values
                timer.hours = edited.hours;
                timer.minutes = edited.minutes;
                timer.seconds = edited.seconds;
                timer.name = edited.name;
                timer.reset (); // Reset to update display
                save ();
            } else if (response == 2) {  // DELETE_TIMER response
                // Delete the timer
                timers.delete_item (timer);
                save ();
            }
            dialog.destroy ();
        });
        dialog.show ();
    }

    private void load () {
        timers.deserialize (settings.get_value ("timers"), Item.deserialize);
    }

    private void save () {
        settings.set_value ("timers", timers.serialize ());
    }

    /**
     * Handles timer completion events.
     * 
     * Implements a queue system where timers ring one at a time sequentially.
     * If a timer is already ringing, new completions are added to the queue.
     * Prevents duplicate processing through the processed_timers HashTable.
     * 
     * @param completed_timer The timer that just finished counting down
     */
    public void ring_handler (Item completed_timer) {
        // Prevent duplicate processing
        if (processed_timers.contains (completed_timer) || 
            completed_timer == currently_ringing_timer || 
            is_in_queue (completed_timer)) {
            return;
        }
        
        // Mark as processed to prevent re-triggering
        processed_timers.insert (completed_timer, true);
        
        // Start ringing immediately if no other timer is active
        if (currently_ringing_timer == null) {
            start_ringing_timer (completed_timer);
        } else {
            // Queue this timer to ring after current one is stopped
            ringing_queue.push_tail (completed_timer);
        }
    }
    
    /** Checks if a timer is already in the ringing queue */
    private bool is_in_queue (Item timer) {
        for (int i = 0; i < ringing_queue.get_length (); i++) {
            if (ringing_queue.peek_nth (i) == timer) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Starts ringing a completed timer.
     * 
     * - Sends system notification if window is closed/hidden
     * - Plays alarm sound through Utils.Bell
     * - Shows ringing panel UI via ring signal
     * 
     * @param timer The timer to ring
     */
    private void start_ringing_timer (Item timer) {
        currently_ringing_timer = timer;
        
        var window = (Clocks.Window?) get_root ();
        var app = (Clocks.Application) GLib.Application.get_default ();
        
        // Send notification if window is closed or hidden
        // Use window.visible check (not is_active) to detect truly closed windows
        if (window == null || !window.visible) {
            var timer_name = timer.name ?? _("Timer");
            var notif = new GLib.Notification (_("Time is up!"));
            notif.set_body (_("%s countdown finished").printf (timer_name));
            notif.set_priority (HIGH);
            notif.add_button (_("Stop"), "app.stop-timer");
            app.send_notification ("timer-is-up", notif);
        }
        
        // Stop any existing bell before starting new one
        if (bell != null) {
            bell.stop ();
        }
        
        // Create and play the alarm sound
        var custom_sound_path = sound_manager.get_timer_sound_path ();
        bell = new Utils.Bell ("alarm-clock-elapsed", custom_sound_path);
        bell.ring ();
        
        // Emit signal to show ringing panel in window
        ring (timer);
    }
    
    /**
     * Handles dismissal of current timer and processes queue.
     * Called when user manually pauses the ringing timer.
     */
    private void handle_current_timer_dismissed () {
        // Clean up current timer state
        if (currently_ringing_timer != null) {
            processed_timers.remove (currently_ringing_timer);
        }
        currently_ringing_timer = null;
        
        // Stop the alarm sound
        if (bell != null) {
            bell.stop ();
            bell = null;
        }
        
        // Process next timer in queue if available
        if (!ringing_queue.is_empty ()) {
            var next_timer = ringing_queue.pop_head ();
            start_ringing_timer (next_timer);
        }
    }
    
    /**
     * Stops the currently ringing timer sound.
     * Called from notification action or window dismiss.
     * @return true if another timer started ringing, false if queue is empty
     */
    public bool stop_timer_sound () {
        // Stop alarm sound
        if (bell != null) {
            bell.stop ();
            bell = null;
        }
        
        // Clean up current timer
        if (currently_ringing_timer != null) {
            processed_timers.remove (currently_ringing_timer);
        }
        currently_ringing_timer = null;
        
        // Process next queued timer if available
        if (!ringing_queue.is_empty ()) {
            var next_timer = ringing_queue.pop_head ();
            start_ringing_timer (next_timer);
            return true; // Another timer started
        }
        
        return false; // Queue is empty
    }

    public override bool grab_focus () {
        // Focus is handled by the window
        return false;
    }

    public bool escape_pressed () {
        var res = false;
        this.timers.foreach ((item) => {
                var timer = (Item) item;
                if (timer.state == Item.State.RUNNING) {
                    timer.pause ();
                    res = true;
                }
            });
        return res;
    }
}

} // namespace Timer
} // namespace Clocks
