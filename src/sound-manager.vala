/*
 * Copyright (C) 2026 Sound Manager Contributors
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
namespace Utils {

/**
 * SoundManager: Manages custom sound files and preferences
 */
public class SoundManager : Object {
    private GLib.Settings settings;

    public SoundManager () {
        settings = new GLib.Settings ("org.gnome.clocks");
    }

    /**
     * Get list of .ogg files from a folder
     */
    public string[] get_sound_files_from_folder (string folder_path) {
        var sounds = new string[]{};
        
        try {
            var file = GLib.File.new_for_path (folder_path);
            var enumerator = file.enumerate_children (GLib.FileAttribute.STANDARD_NAME,
                                                       GLib.FileQueryInfoFlags.NONE,
                                                       null);
            GLib.FileInfo? info;
            while ((info = enumerator.next_file (null)) != null) {
                string filename = info.get_name ();
                if (filename.down ().has_suffix (".ogg")) {
                    sounds += filename;
                }
            }
        } catch (GLib.Error e) {
            warning ("Error reading sound folder: %s", e.message);
        }

        return sounds;
    }

    /**
     * Get alarm sound folder path
     */
    public string get_alarm_sound_folder () {
        return settings.get_string ("alarm-sound-folder");
    }

    /**
     * Set alarm sound folder path
     */
    public void set_alarm_sound_folder (string folder_path) {
        settings.set_string ("alarm-sound-folder", folder_path);
    }

    /**
     * Get alarm sound file name
     */
    public string get_alarm_sound_file () {
        return settings.get_string ("alarm-sound-file");
    }

    /**
     * Set alarm sound file name
     */
    public void set_alarm_sound_file (string file_name) {
        settings.set_string ("alarm-sound-file", file_name);
    }

    /**
     * Get timer sound folder path
     */
    public string get_timer_sound_folder () {
        return settings.get_string ("timer-sound-folder");
    }

    /**
     * Set timer sound folder path
     */
    public void set_timer_sound_folder (string folder_path) {
        settings.set_string ("timer-sound-folder", folder_path);
    }

    /**
     * Get timer sound file name
     */
    public string get_timer_sound_file () {
        return settings.get_string ("timer-sound-file");
    }

    /**
     * Set timer sound file name
     */
    public void set_timer_sound_file (string file_name) {
        settings.set_string ("timer-sound-file", file_name);
    }

    /**
     * Get full path to alarm sound file
     */
    public string get_alarm_sound_path () {
        var folder = get_alarm_sound_folder ();
        var file = get_alarm_sound_file ();
        
        if (folder.length == 0 || file.length == 0) {
            return "";
        }
        
        return GLib.Path.build_filename (folder, file);
    }

    /**
     * Get full path to timer sound file
     */
    public string get_timer_sound_path () {
        var folder = get_timer_sound_folder ();
        var file = get_timer_sound_file ();
        
        if (folder.length == 0 || file.length == 0) {
            return "";
        }
        
        return GLib.Path.build_filename (folder, file);
    }

    /**
     * Check if custom alarm sound is configured
     */
    public bool has_custom_alarm_sound () {
        return get_alarm_sound_path ().length > 0;
    }

    /**
     * Check if custom timer sound is configured
     */
    public bool has_custom_timer_sound () {
        return get_timer_sound_path ().length > 0;
    }
}

} // namespace Utils
} // namespace Clocks
