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
    private Setup timer_setup;
    [GtkChild]
    private unowned Gtk.ListBox timers_list;
    [GtkChild]
    private unowned Gtk.Box no_timer_container;
    [GtkChild]
    private unowned Gtk.Button start_button;
    [GtkChild]
    private unowned Gtk.Button stop_button;
    [GtkChild]
    private unowned Gtk.Stack stack;

    public PanelId panel_id { get; construct set; }
    public ButtonMode button_mode { get; set; default = NONE; }
    public bool is_running { get; set; default = false; }
    // Translators: Tooltip for the + button
    public string? new_label { get; default = _("New Timer"); }

    private ContentStore timers;
    private GLib.Settings settings;
    private Utils.Bell bell;
    private Utils.SoundManager sound_manager;
    private GLib.Notification notification;
    private Item? ringing_timer = null;

    internal signal void ring (Item item);

    construct {
        panel_id = TIMER;
        timer_setup = new Setup ();

        settings = new GLib.Settings ("org.gnome.clocks");
        sound_manager = new Utils.SoundManager ();
        timers = new ContentStore ();

        timers_list.bind_model (timers, (timer) => {
            var row = new Row ((Item) timer);
            row.deleted.connect (() => remove_timer ((Item) timer));
            row.edited.connect (() => save ());
            ((Item)timer).ring.connect (() => ring_handler ());
            ((Item)timer).notify["state"].connect (() => {
                this.is_running = this.get_total_active_timers () != 0;
                // Stop bell only when timer is paused (not when stopped after completion)
                var item = (Item) timer;
                if (item.state == Item.State.PAUSED) {
                    GLib.Idle.add (() => {
                        bell.stop ();
                        return GLib.Source.REMOVE;
                    });
                }
            });
            return row;
        });

        stop_button.set_sensitive (false);
        stop_button.clicked.connect (() => {
            debug ("Stop button clicked, stopping bell.");
            bell.stop ();
        });

        timers.items_changed.connect ((added, removed, position) => {
            if (this.timers.get_n_items () > 0) {
                stack.visible_child_name = "timers";
                this.button_mode = NEW;
            } else {
                stack.visible_child_name = "empty";
                this.button_mode = NONE;
            }
            save ();
            stop_button.set_sensitive (timers.get_n_items () > 0);
        });

        notification = new GLib.Notification (_("Time is up!"));
        notification.set_body (_("Timer countdown finished"));
        notification.set_priority (HIGH);

        var no_timer_container_first_child = no_timer_container.get_first_child ();
        no_timer_container.insert_child_after (timer_setup, no_timer_container_first_child);
        stack.set_visible_child_name ("empty");

        start_button.set_sensitive (false);
        timer_setup.duration_changed.connect ((duration) => {
            start_button.set_sensitive (duration != 0);
        });
        start_button.clicked.connect (() => {
            var timer = this.timer_setup.get_timer ();
            this.timers.add (timer);

            timer.start ();
        });
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

    private void remove_timer (Item item) {
        timers.remove (item);
    }

    public void activate_new () {
        var dialog = new SetupDialog ((Gtk.Window) get_root ());
        dialog.response.connect ((dialog, response) => {
            if (response == Gtk.ResponseType.ACCEPT) {
                var timer = ((SetupDialog) dialog).timer_setup.get_timer ();
                this.timers.add (timer);
                timer.start ();
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

    public void ring_handler () {
        ringing_timer = null;
        
        // Find which timer just rang (before it gets reset)
        timers.foreach ((item) => {
            var t = (Item) item;
            if (t.state == Item.State.RUNNING && ringing_timer == null) {
                ringing_timer = t;
                return;
            }
        });
        
        if (ringing_timer == null) {
            return;
        }
        
        var window = (Clocks.Window) get_root ();
        if (!window.is_active) {
            var app = (Clocks.Application) GLib.Application.get_default ();
            app.send_notification ("timer-is-up", notification);
        }
        
        // Get custom timer sound path and create bell
        var custom_sound_path = sound_manager.get_timer_sound_path ();
        bell = new Utils.Bell ("alarm-clock-elapsed", custom_sound_path);
        bell.ring ();
        
        // Show ringing panel
        ring (ringing_timer);
    }
    
    public void stop_timer_sound () {
        if (bell != null) {
            bell.stop ();
        }
        ringing_timer = null;
    }

    public override bool grab_focus () {
        if (timers.get_n_items () == 0) {
            start_button.grab_focus ();
            return true;
        }

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
