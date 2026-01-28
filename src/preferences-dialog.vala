/*
 * Copyright (C) 2026 Preferences Dialog Contributors
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

public class PreferencesDialog : Gtk.Window {
    private Utils.SoundManager sound_manager;
    private Utils.Bell preview_bell;

    private Gtk.Entry alarm_folder_entry;
    private Gtk.Button alarm_folder_button;
    private Gtk.ComboBoxText alarm_sound_combo;
    private Gtk.Button alarm_preview_button;

    private Gtk.Entry timer_folder_entry;
    private Gtk.Button timer_folder_button;
    private Gtk.ComboBoxText timer_sound_combo;
    private Gtk.Button timer_preview_button;

    public PreferencesDialog (Gtk.Window parent) {
        Object (transient_for: parent,
                modal: true,
                title: _("Sound Preferences"));

        sound_manager = new Utils.SoundManager ();
        preview_bell = new Utils.Bell ("alarm-clock-elapsed");

        setup_ui ();
        connect_signals ();
        load_settings ();
    }

    private void setup_ui () {
        // Load the UI from resource
        var builder = new Gtk.Builder.from_resource ("/org/gnome/clocks/ui/sound-settings.ui");
        
        alarm_folder_entry = (Gtk.Entry) builder.get_object ("alarm_folder_entry");
        alarm_folder_button = (Gtk.Button) builder.get_object ("alarm_folder_button");
        alarm_sound_combo = (Gtk.ComboBoxText) builder.get_object ("alarm_sound_combo");
        alarm_preview_button = (Gtk.Button) builder.get_object ("alarm_preview_button");

        timer_folder_entry = (Gtk.Entry) builder.get_object ("timer_folder_entry");
        timer_folder_button = (Gtk.Button) builder.get_object ("timer_folder_button");
        timer_sound_combo = (Gtk.ComboBoxText) builder.get_object ("timer_sound_combo");
        timer_preview_button = (Gtk.Button) builder.get_object ("timer_preview_button");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.append ((Gtk.Box) builder.get_object ("alarm_sound_box"));
        main_box.append ((Gtk.Box) builder.get_object ("timer_sound_box"));

        var scrolled = new Gtk.ScrolledWindow ();
        scrolled.set_child (main_box);
        scrolled.hexpand = true;
        scrolled.vexpand = true;
        
        set_child (scrolled);
        set_default_size (500, 600);
    }

    private void connect_signals () {
        alarm_folder_button.clicked.connect (on_alarm_folder_clicked);
        alarm_sound_combo.changed.connect (on_alarm_sound_changed);
        alarm_preview_button.clicked.connect (on_alarm_preview_clicked);

        timer_folder_button.clicked.connect (on_timer_folder_clicked);
        timer_sound_combo.changed.connect (on_timer_sound_changed);
        timer_preview_button.clicked.connect (on_timer_preview_clicked);
        
        // Stop preview sound when dialog closes
        close_request.connect (() => {
            stop_preview ();
            return false;
        });
    }

    private void stop_preview () {
        if (preview_bell != null) {
            preview_bell.stop ();
        }
    }

    private void load_settings () {
        var alarm_folder = sound_manager.get_alarm_sound_folder ();
        if (alarm_folder.length > 0) {
            alarm_folder_entry.text = alarm_folder;
            update_alarm_sounds_combo ();
        }

        var timer_folder = sound_manager.get_timer_sound_folder ();
        if (timer_folder.length > 0) {
            timer_folder_entry.text = timer_folder;
            update_timer_sounds_combo ();
        }
    }

    private void on_alarm_folder_clicked () {
        var dialog = new Gtk.FileChooserDialog (
            _("Select Alarm Sound Folder"),
            this,
            Gtk.FileChooserAction.SELECT_FOLDER,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            _("Select"), Gtk.ResponseType.ACCEPT
        );

        var current_folder = sound_manager.get_alarm_sound_folder ();
        if (current_folder.length > 0) {
            try {
                dialog.set_file (GLib.File.new_for_path (current_folder));
            } catch (GLib.Error e) {
                warning ("Error setting current folder: %s", e.message);
            }
        }

        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.ACCEPT) {
                var file = dialog.get_file ();
                if (file != null) {
                    var path = file.get_path ();
                    if (path != null) {
                        sound_manager.set_alarm_sound_folder (path);
                        alarm_folder_entry.text = path;
                        update_alarm_sounds_combo ();
                    }
                }
            }
            dialog.close ();
        });

        dialog.show ();
    }

    private void update_alarm_sounds_combo () {
        alarm_sound_combo.remove_all ();

        var folder = sound_manager.get_alarm_sound_folder ();
        if (folder.length == 0) {
            return;
        }

        var sounds = sound_manager.get_sound_files_from_folder (folder);
        
        if (sounds.length == 0) {
            alarm_sound_combo.append_text (_("No .ogg files found"));
            alarm_sound_combo.set_active (0);
            alarm_sound_combo.set_sensitive (false);
            return;
        }

        alarm_sound_combo.set_sensitive (true);

        for (int i = 0; i < sounds.length; i++) {
            alarm_sound_combo.append_text (sounds[i]);
        }

        // Select previously selected file if available
        var selected_file = sound_manager.get_alarm_sound_file ();
        for (int i = 0; i < sounds.length; i++) {
            if (sounds[i] == selected_file) {
                alarm_sound_combo.set_active (i);
                return;
            }
        }

        // Default to first file
        alarm_sound_combo.set_active (0);
    }

    private void on_alarm_sound_changed () {
        stop_preview ();
        var selected = alarm_sound_combo.get_active_text ();
        if (selected != null && selected.length > 0) {
            sound_manager.set_alarm_sound_file (selected);
        }
    }

    private void on_alarm_preview_clicked () {
        stop_preview ();
        var sound_path = sound_manager.get_alarm_sound_path ();
        if (sound_path.length > 0) {
            preview_bell = new Utils.Bell ("alarm-clock-elapsed", sound_path);
            preview_bell.ring_once ();
        }
    }

    private void on_timer_folder_clicked () {
        var dialog = new Gtk.FileChooserDialog (
            _("Select Timer Sound Folder"),
            this,
            Gtk.FileChooserAction.SELECT_FOLDER,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            _("Select"), Gtk.ResponseType.ACCEPT
        );

        var current_folder = sound_manager.get_timer_sound_folder ();
        if (current_folder.length > 0) {
            try {
                dialog.set_file (GLib.File.new_for_path (current_folder));
            } catch (GLib.Error e) {
                warning ("Error setting current folder: %s", e.message);
            }
        }

        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.ACCEPT) {
                var file = dialog.get_file ();
                if (file != null) {
                    var path = file.get_path ();
                    if (path != null) {
                        sound_manager.set_timer_sound_folder (path);
                        timer_folder_entry.text = path;
                        update_timer_sounds_combo ();
                    }
                }
            }
            dialog.close ();
        });

        dialog.show ();
    }

    private void update_timer_sounds_combo () {
        timer_sound_combo.remove_all ();

        var folder = sound_manager.get_timer_sound_folder ();
        if (folder.length == 0) {
            return;
        }

        var sounds = sound_manager.get_sound_files_from_folder (folder);

        if (sounds.length == 0) {
            timer_sound_combo.append_text (_("No .ogg files found"));
            timer_sound_combo.set_active (0);
            timer_sound_combo.set_sensitive (false);
            return;
        }

        timer_sound_combo.set_sensitive (true);

        for (int i = 0; i < sounds.length; i++) {
            timer_sound_combo.append_text (sounds[i]);
        }

        // Select previously selected file if available
        var selected_file = sound_manager.get_timer_sound_file ();
        for (int i = 0; i < sounds.length; i++) {
            if (sounds[i] == selected_file) {
                timer_sound_combo.set_active (i);
                return;
            }
        }

        // Default to first file
        timer_sound_combo.set_active (0);
    }

    private void on_timer_sound_changed () {
        stop_preview ();
        var selected = timer_sound_combo.get_active_text ();
        if (selected != null && selected.length > 0) {
            sound_manager.set_timer_sound_file (selected);
        }
    }

    private void on_timer_preview_clicked () {
        stop_preview ();
        var sound_path = sound_manager.get_timer_sound_path ();
        if (sound_path.length > 0) {
            preview_bell = new Utils.Bell ("complete", sound_path);
            preview_bell.ring_once ();
        }
    }
}

} // namespace Clocks
