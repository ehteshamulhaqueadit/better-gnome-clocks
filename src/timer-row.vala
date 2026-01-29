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

[GtkTemplate (ui = "/org/gnome/clocks/ui/timer-row.ui")]
public class Row : Gtk.ListBoxRow {
    public Item item {
        get {
            return _item;
        }

        construct set {
            _item = value;

            title.text = _item.name ?? "";
            title.bind_property ("text", _item, "name");
            timer_name.label = _item.name ?? "";
            title.bind_property ("text", timer_name, "label");

            _item.notify["name"].connect (() => {
                // Update title entry when name is changed externally (e.g., from edit dialog)
                // Only update if different to avoid infinite loop
                var new_name = _item.name ?? "";
                if (title.text != new_name) {
                    title.text = new_name;
                }
                edited ();
            });
        }
    }
    private Item _item;
    private Adw.TimedAnimation paused_animation;


    [GtkChild]
    private unowned Gtk.Label countdown_label;

    [GtkChild]
    private unowned Gtk.Label timer_name;

    [GtkChild]
    private unowned Gtk.Stack name_stack;
    [GtkChild]
    private unowned Gtk.Revealer name_revealer;

    [GtkChild]
    private unowned Gtk.Stack start_stack;
    [GtkChild]
    private unowned Gtk.Stack reset_stack;
    [GtkChild]
    private unowned Gtk.Stack delete_stack;

    [GtkChild]
    private unowned Gtk.Button delete_button;
    [GtkChild]
    private unowned Gtk.Entry title;

    public signal void deleted ();
    public signal void edited ();
    public signal void edit_clicked ();

    public Row (Item item) {
        Object (item: item);
        
        // Add click handler for editing
        var click_controller = new Gtk.GestureClick ();
        click_controller.pressed.connect ((n_press, x, y) => {
            if (n_press == 1) {  // Single click
                // Don't trigger edit if clicking on buttons or entry fields
                var widget = this.pick (x, y, Gtk.PickFlags.DEFAULT);
                if (widget != null) {
                    // Check if clicked widget or its parent is a button or entry
                    var parent = widget;
                    while (parent != null && parent != this) {
                        if (parent is Gtk.Button || parent is Gtk.Entry) {
                            return;  // Don't edit when clicking buttons or entry fields
                        }
                        parent = parent.get_parent ();
                    }
                }
                edit_clicked ();
            }
        });
        this.add_controller (click_controller);

        // Force LTR since we do not want to reverse [hh] : [mm] : [ss]
        countdown_label.set_direction (Gtk.TextDirection.LTR);

        item.countdown_updated.connect (this.update_countdown);
        item.ring.connect (() => this.ring ());
        item.start.connect (() => this.start ());
        item.pause.connect (() => this.pause ());
        item.reset.connect (() => this.reset ());
        delete_button.clicked.connect (() => deleted ());

        // Handle Enter key in title entry to remove focus (cursor disappears but stays in edit mode)
        title.activate.connect (() => {
            // Just remove focus from the entry, don't switch to display mode
            this.grab_focus ();
        });

        var target = new Adw.CallbackAnimationTarget (animation_target);
        paused_animation = new Adw.TimedAnimation (this, 0, 2, 2000, target);
        paused_animation.repeat_count = Adw.DURATION_INFINITE;
        paused_animation.easing = Adw.Easing.LINEAR;

        reset ();
    }

    [GtkCallback]
    private void on_start_button_clicked () {
        item.start ();
    }

    [GtkCallback]
    private void on_pause_button_clicked () {
        item.pause ();
    }

    [GtkCallback]
    private void on_reset_button_clicked () {
        item.reset ();
    }

    private void reset () {
        reset_stack.visible_child_name = "empty";
        delete_stack.visible_child_name = "button";

        countdown_label.remove_css_class ("accent");
        countdown_label.add_css_class ("dim-label");

        paused_animation.pause ();

        start_stack.visible_child_name = "start";
        name_revealer.reveal_child = true;  // Always show in reset state for editing
        name_stack.visible_child_name = "edit";

        update_countdown (item.hours, item.minutes, item.seconds);
    }

    private void start () {
        countdown_label.add_css_class ("accent");
        countdown_label.remove_css_class ("dim-label");

        paused_animation.pause ();

        reset_stack.visible_child_name = "empty";
        delete_stack.visible_child_name = "empty";

        start_stack.visible_child_name = "pause";
        // Show name when running if it's not empty
        name_revealer.reveal_child = (timer_name.label != "" && timer_name.label != null);
        name_stack.visible_child_name = "display";
    }

    private void ring () {
        paused_animation.pause ();

        countdown_label.remove_css_class ("accent");
        countdown_label.add_css_class ("dim-label");
    }

    private void pause () {
        paused_animation.play ();

        reset_stack.visible_child_name = "button";
        delete_stack.visible_child_name = "button";
        start_stack.visible_child_name = "start";
        // Show name when paused if it's not empty
        name_revealer.reveal_child = (timer_name.label != "" && timer_name.label != null);
        name_stack.visible_child_name = "display";
    }

    private void update_countdown (int h, int m, int s ) {
        countdown_label.set_text ("%02i ∶ %02i ∶ %02i".printf (h, m, s));
    }

    private void animation_target (double val) {
        if (val < 1.0) {
            countdown_label.add_css_class ("dim-label");
            countdown_label.remove_css_class ("accent");
        } else {
            countdown_label.add_css_class ("accent");
            countdown_label.remove_css_class ("dim-label");
        }
    }
}

} // namespace Timer
} // namespace Clocks
