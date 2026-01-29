/*
 * Copyright (C) 2013  Paolo Borelli <pborelli@gnome.org>
 * Copyright (C) 2020  Zander Brown <zbrown@gnome.org>
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

[GtkTemplate (ui = "/org/gnome/clocks/ui/timer-ringing-panel.ui")]
private class RingingPanel : Adw.Bin {
    private Item? current_timer;
    
    [GtkChild]
    private unowned Gtk.Label title_label;
    [GtkChild]
    private unowned Gtk.Button stop_button;

    construct {
        stop_button.clicked.connect (() => {
            dismiss_timer ();
        });
    }

    public void set_timer (Item timer) {
        current_timer = timer;
        update_display ();
    }
    
    private void update_display () {
        if (current_timer != null) {
            if (current_timer.name != null && current_timer.name.length > 0) {
                title_label.label = (string) current_timer.name;
            } else {
                title_label.label = _("Timer");
            }
        }
    }

    public virtual signal void dismiss_timer () {
        if (current_timer != null) {
            current_timer.reset ();
            current_timer = null;
        }
    }
}

} // namespace Timer
} // namespace Clocks
