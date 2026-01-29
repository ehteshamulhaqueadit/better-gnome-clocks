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

// Response used for the "Delete Timer" button in the edit dialogue
public const int DELETE_TIMER = 2;

public class SetupDialog: Gtk.Dialog {
    public Setup timer_setup;
    private int current_duration = 0;  // Track duration to check validity
    private Gtk.Button delete_button;

    public SetupDialog (Gtk.Window parent, Item? timer_to_edit = null) {
        var is_editing = (timer_to_edit != null);
        
        Object (modal: true, transient_for: parent, use_header_bar: 1);
        
        this.title = is_editing ? _("Edit Timer") : _("New Timer");
        this.set_default_size (480, 420);

        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        var create_button = add_button (is_editing ? _("Save") : _("Add"), Gtk.ResponseType.ACCEPT);
        create_button.add_css_class ("suggested-action");

        timer_setup = new Setup ();
        
        // Pre-fill values if editing
        if (is_editing) {
            timer_setup.set_timer (timer_to_edit);
        }
        
        this.get_content_area ().append (timer_setup);
        
        // Add delete button (only visible when editing)
        if (is_editing) {
            var button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            button_box.margin_top = 12;
            button_box.margin_bottom = 12;
            
            delete_button = new Gtk.Button.with_label (_("R_emove Timer"));
            delete_button.use_underline = true;
            delete_button.halign = Gtk.Align.CENTER;
            delete_button.add_css_class ("destructive-action");
            delete_button.add_css_class ("pill");
            delete_button.clicked.connect (() => {
                response (DELETE_TIMER);
            });
            
            button_box.append (delete_button);
            this.get_content_area ().append (button_box);
        }
        timer_setup.duration_changed.connect ((duration) => {
            current_duration = duration;  // Track the current duration
            this.set_response_sensitive (Gtk.ResponseType.ACCEPT, duration != 0);
        });
        
        // Handle Enter key to accept dialog - use capture phase to get key before spinbuttons
        var key_controller = new Gtk.EventControllerKey ();
        key_controller.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
        key_controller.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Return || keyval == Gdk.Key.KP_Enter) {
                // Check if we can save by attempting to get a timer (will return null if duration is 0)
                var test_timer = timer_setup.get_timer ();
                if (test_timer != null && (state & (Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.ALT_MASK)) == 0) {
                    this.response (Gtk.ResponseType.ACCEPT);
                    return true;
                }
            }
            return false;
        });
        ((Gtk.Widget)this).add_controller (key_controller);
    }
}

} // namespace Timer
} // namespace Clocks
