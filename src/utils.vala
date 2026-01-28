/*
 * Copyright (C) 2013  Paolo Borelli <pborelli@gnome.org>
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

extern int clocks_cutils_get_week_start ();
extern bool calculate_sunrise_sunset (double lat,
                                      double lon,
                                      int year,
                                      int month,
                                      int day,
                                      double correction,
                                      out int rise_hour,
                                      out int rise_min,
                                      out int set_hour,
                                      out int set_min);

const double RISESET_CORRECTION_NONE = 0.0;
const double RISESET_CORRECTION_CIVIL = 6.0;
const double RISESET_CORRECTION_NAUTICAL = 12.0;
const double RISESET_CORRECTION_ASTRONOMICAL = 18.0;

namespace Clocks {
namespace Utils {

public void time_to_hms (double t, out int h, out int m, out int s, out double remainder) {
    h = (int) t / 3600;
    t = t % 3600;
    m = (int) t / 60;
    t = t % 60;
    s = (int) t;
    remainder = t - s;
}

public string get_time_difference_message (double offset) {
    var diff = (double) offset / (double) TimeSpan.HOUR;
    var diff_string = "%.0f".printf (diff.abs ());

    if (diff != Math.round (diff)) {
        if (diff * 2 != Math.round (diff * 2)) {
            diff_string = "%.2f".printf (diff.abs ());
        } else {
            diff_string = "%.1f".printf (diff.abs ());
        }
    }

    // Translators: The time is the same as the local time
    var message = _("Current timezone");

    if (diff > 0) {
        // Translators: The (possibly fractical) number hours in the past
        // (relative to local) the clock/location is
        message = ngettext ("%s hour earlier",
                            "%s hours earlier",
                            ((int) diff).abs ()).printf (diff_string);
    } else if (diff < 0) {
        // Translators: The (possibly fractical) number hours in the
        // future (relative to local) the clock/location is
        message = ngettext ("%s hour later",
                            "%s hours later",
                            ((int) diff).abs ()).printf (diff_string);
    }
    return message;
}

// TODO: For now we are wrapping Gnome's clock, but we should probably
// implement our own class, maybe using gnome-datetime-source
// Especially if we want to try to use CLOCK_REALTIME_ALARM
// see https://bugzilla.gnome.org/show_bug.cgi?id=686115
public class WallClock : Object {
    public enum Format {
        TWELVE,
        TWENTYFOUR
    }

    private static WallClock? instance;

    public static WallClock get_default () {
        if (instance == null) {
            instance = new WallClock ();
        }
        // If it's still null something has gone horribly wrong
        return (WallClock) instance;
    }

    public GLib.DateTime date_time { get; private set; }
    public GLib.TimeZone timezone { get; private set; }
    public Format format { get; private set; }

    private GLib.Settings settings;
    private Gnome.WallClock wc;

    private WallClock () {
        wc = new Gnome.WallClock ();
        wc.notify["clock"].connect (() => {
            update ();
            tick ();
        });

        // mirror the wallclock's timezone property
        timezone = wc.timezone;
        wc.notify["timezone"].connect (() => {
            timezone = wc.timezone;
        });

        // system-wide settings about clock format
        settings = new GLib.Settings ("org.gnome.desktop.interface");
        settings.changed["clock-format"].connect (() => {
            update_format ();
        });
        update_format ();

        update ();
    }

    public signal void tick ();

    private void update_format () {
        var sys_format = settings.get_string ("clock-format");
        format = sys_format == "12h" ? Format.TWELVE : Format.TWENTYFOUR;
    }

    // provide various types/objects of the same time, to be used directly
    // in AlarmItem and ClockItem, so they don't need to call these
    // functions themselves all the time (they only care about minutes).
    private void update () {
        date_time = new GLib.DateTime.now (timezone);
    }

    public string format_time (GLib.DateTime date_time) {
        string time = date_time.format (format == Format.TWELVE ? "%I:%M %p" : "%H:%M");

        // Replace ":" with ratio, space with thin-space, and prepend LTR marker
        // to force direction. Replacement is done afterward because date_time.format
        // may fail with utf8 chars in some locales
        time = time.replace (":", "\xE2\x80\x8E\xE2\x88\xB6");

        if (format == Format.TWELVE) {
            time = time.replace (" ", "\xE2\x80\x89");
        }

        return time;
    }
}

public class Weekdays {
    private static string[]? abbreviations = null;
    private static string[]? names = null;

    public enum Day {
        MON = 0,
        TUE,
        WED,
        THU,
        FRI,
        SAT,
        SUN;

        private const string[] SYMBOLS = {
            // Translators: This is used in the repeat toggle for Monday
            NC_("Alarm|Repeat-On|Monday", "M"),
            // Translators: This is used in the repeat toggle for Tuesday
            NC_("Alarm|Repeat-On|Tuesday", "T"),
            // Translators: This is used in the repeat toggle for Wednesday
            NC_("Alarm|Repeat-On|Wednesday", "W"),
            // Translators: This is used in the repeat toggle for Thursday
            NC_("Alarm|Repeat-On|Thursday", "T"),
            // Translators: This is used in the repeat toggle for Friday
            NC_("Alarm|Repeat-On|Friday", "F"),
            // Translators: This is used in the repeat toggle for Saturday
            NC_("Alarm|Repeat-On|Saturday", "S"),
            // Translators: This is used in the repeat toggle for Sunday
            NC_("Alarm|Repeat-On|Sunday", "S")
        };

        private const string[] EN_DAYS = {
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "Sunday"
        };

        private const string[] PLURALS = {
            N_("Mondays"),
            N_("Tuesdays"),
            N_("Wednesdays"),
            N_("Thursdays"),
            N_("Fridays"),
            N_("Saturdays"),
            N_("Sundays")
        };

        public string symbol () {
            return dpgettext2 (null, "Alarm|Repeat-On|" + EN_DAYS[this], SYMBOLS[this]);
        }

        public string plural () {
            return _(PLURALS[this]);
        }

        public string abbreviation () {
            // lazy init because we cannot rely on class init being
            // called for us (at least in the current version of vala)
            if (abbreviations == null) {
                abbreviations = {
                     (new GLib.DateTime.utc (1, 1, 1, 0, 0, 0)).format ("%a"),
                     (new GLib.DateTime.utc (1, 1, 2, 0, 0, 0)).format ("%a"),
                     (new GLib.DateTime.utc (1, 1, 3, 0, 0, 0)).format ("%a"),
                     (new GLib.DateTime.utc (1, 1, 4, 0, 0, 0)).format ("%a"),
                     (new GLib.DateTime.utc (1, 1, 5, 0, 0, 0)).format ("%a"),
                     (new GLib.DateTime.utc (1, 1, 6, 0, 0, 0)).format ("%a"),
                     (new GLib.DateTime.utc (1, 1, 7, 0, 0, 0)).format ("%a"),
                };
            }
            return abbreviations[this];
        }

        public string name () {
            // lazy init because we cannot rely on class init being
            // called for us (at least in the current version of vala)
            if (names == null) {
                names = {
                     (new GLib.DateTime.utc (1, 1, 1, 0, 0, 0)).format ("%A"),
                     (new GLib.DateTime.utc (1, 1, 2, 0, 0, 0)).format ("%A"),
                     (new GLib.DateTime.utc (1, 1, 3, 0, 0, 0)).format ("%A"),
                     (new GLib.DateTime.utc (1, 1, 4, 0, 0, 0)).format ("%A"),
                     (new GLib.DateTime.utc (1, 1, 5, 0, 0, 0)).format ("%A"),
                     (new GLib.DateTime.utc (1, 1, 6, 0, 0, 0)).format ("%A"),
                     (new GLib.DateTime.utc (1, 1, 7, 0, 0, 0)).format ("%A"),
                };
            }
            return names[this];
        }

        public static Day get_first_weekday () {
            var d = clocks_cutils_get_week_start ();
            return (Day) ((d + 6) % 7);
        }
    }

    private const bool[] WEEKDAYS = {
        true, true, true, true, true, false, false
    };

    private const bool[] WEEKENDS = {
        false, false, false, false, false, true, true
    };

    const bool[] NONE = {
        false, false, false, false, false, false, false
    };

    const bool[] ALL = {
        true, true, true, true, true, true, true
    };

    private bool[] days = NONE;

    public bool empty {
        get {
            return (days_equal (NONE));
        }
    }

    public bool is_weekdays {
        get {
            return (days_equal (WEEKDAYS));
        }
    }

    public bool is_weekends {
        get {
            return (days_equal (WEEKENDS));
        }
    }

    public bool is_all {
        get {
            return (days_equal (ALL));
        }
    }

    private bool days_equal (bool[] d) {
        assert (d.length == 7);
        return (Memory.cmp (d, days, days.length * sizeof (bool)) == 0);
    }

    public bool get (Day d) {
        assert (d >= 0 && d < 7);
        return days[d];
    }

    public void set (Day d, bool on) {
        assert (d >= 0 && d < 7);
        days[d] = on;
    }

    public string get_label () {
        string? r = null;
        int n = 0;
        int first = -1;
        for (int i = 0; i < 7; i++) {
            if (get ((Day) i)) {
                if (first < 0) {
                    first = i;
                }
                n++;
            }
        }

        if (n == 0) {
            r = "";
        } else if (n == 1) {
            r = ((Day) first).plural ();
        } else if (n == 7) {
            r = _("Every Day");
        } else if (days_equal (WEEKDAYS)) {
            r = _("Weekdays");
        } else if (days_equal (WEEKENDS)) {
            r = _("Weekends");
        } else {
            string?[]? abbrs = {};
            for (int i = 0; i < 7; i++) {
                Day d = (Day.get_first_weekday () + i) % 7;
                if (get (d)) {
                    abbrs += d.abbreviation ();
                }
            }
            r = string.joinv (", ", abbrs);
        }
        return (string) r;
    }

    // Note that we serialze days according to ISO 8601
    // (1 is Monday, 2 is Tuesday... 7 is Sunday)

    public GLib.Variant serialize () {
        var builder = new GLib.VariantBuilder (new VariantType ("ai"));
        int32 i = 1;
        foreach (var d in days) {
            if (d) {
                builder.add ("i", i);
            }
            i++;
        }
        return builder.end ();
    }

    public static Weekdays deserialize (GLib.Variant days_variant) {
        Weekdays d = new Weekdays ();
        foreach (var v in days_variant) {
            var i = (int32) v;
            if (i > 0 && i <= 7) {
                d.set ((Day) (i - 1), true);
            } else {
                warning ("Invalid days %d", i);
            }
        }
        return d;
    }
}

public class Bell : Object {
    private GSound.Context? gsound;
    private GLib.Cancellable cancellable;
    private GLib.Thread<bool>? playback_thread;
    private string soundtheme;
    private string sound;
    private string? custom_sound_path;
    private bool is_playing;

    public Bell (string soundid, string? custom_path = null) {
        try {
            gsound = new GSound.Context ();
        } catch (GLib.Error e) {
            warning ("Sound could not be initialized, error: %s", e.message);
        }

        var settings = new GLib.Settings ("org.gnome.desktop.sound");
        soundtheme = settings.get_string ("theme-name");
        sound = soundid;
        custom_sound_path = custom_path;
        is_playing = false;
        playback_thread = null;
        cancellable = new GLib.Cancellable ();
        debug ("Bell created with sound: %s, custom_path: %s, theme: %s", soundid, custom_path ?? "(none)", soundtheme);
    }

    // Play sound in background thread to prevent UI freeze
    private void play_sound_in_background (bool repeat) {
        // Stop any existing playback before starting new one
        if (is_playing) {
            debug ("Stopping previous playback before starting new one");
            stop ();
        }
        
        is_playing = true;
        playback_thread = new GLib.Thread<bool> ("bell-playback", () => {
            debug ("Background thread: starting play_sound_sync");
            try {
                play_sound_sync (repeat);
            } catch (GLib.Error e) {
                warning ("Error in background thread: %s", e.message);
            }
            is_playing = false;
            debug ("Background thread: finished");
            return true;
        });
    }

    // Synchronous sound playback (runs in background thread)
    private void play_sound_sync (bool repeat) {
        do {
            // Try to play custom sound if available
            if (custom_sound_path != null && custom_sound_path.length > 0) {
                debug ("Attempting to play custom sound: %s", custom_sound_path);
                if (GLib.FileUtils.test (custom_sound_path, GLib.FileTest.EXISTS)) {
                    try {
                        string[] spawn_args = {"paplay", custom_sound_path};
                        int exit_status;
                        GLib.Process.spawn_sync (null, spawn_args, null, GLib.SpawnFlags.SEARCH_PATH, null, null, null, out exit_status);
                        debug ("Custom sound played, exit status: %d", exit_status);
                        
                        // If not repeating or cancelled, exit
                        if (!repeat || cancellable.is_cancelled ()) {
                            return;
                        }
                        // Small delay between repeats
                        GLib.Thread.usleep (500000); // 0.5 second
                        continue;
                    } catch (GLib.Error e) {
                        warning ("Error playing custom sound: %s", e.message);
                    }
                }
            }

            // Fallback to system sound with paplay
            string sound_file = "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga";
            if (GLib.FileUtils.test (sound_file, GLib.FileTest.EXISTS)) {
                try {
                    string[] spawn_args = {"paplay", sound_file};
                    int exit_status;
                    GLib.Process.spawn_sync (null, spawn_args, null, GLib.SpawnFlags.SEARCH_PATH, null, null, null, out exit_status);
                    debug ("System sound played with paplay, exit status: %d", exit_status);
                    
                    // If not repeating or cancelled, exit
                    if (!repeat || cancellable.is_cancelled ()) {
                        return;
                    }
                    // Small delay between repeats
                    GLib.Thread.usleep (500000); // 0.5 second
                    continue;
                } catch (GLib.Error e) {
                    warning ("Error playing system sound: %s", e.message);
                }
            }
            
            // If we get here and repeat is true, break to avoid infinite loop with no sound
            break;
        } while (repeat && !cancellable.is_cancelled ());

        // Final fallback to GSound
        if (gsound != null) {
            try {
                debug ("Playing sound with GSound: %s", sound);
                ((GSound.Context) gsound).play_simple (cancellable,
                                                       GSound.Attribute.EVENT_ID, sound,
                                                       GSound.Attribute.CANBERRA_XDG_THEME_NAME, soundtheme,
                                                       GSound.Attribute.MEDIA_ROLE, "alarm");
            } catch (GLib.Error e) {
                warning ("Error playing with GSound: %s", e.message);
            }
        }
    }

    private async void ring_real (bool repeat) {
        if (gsound == null && (custom_sound_path == null || custom_sound_path.length == 0)) {
            debug ("ring_real called but no sound available");
            return;
        }

        if (cancellable.is_cancelled ()) {
            cancellable.reset ();
        }

        try {
            // Play sound in background thread with repeat option
            debug ("ring_real: starting playback with repeat=%s", repeat.to_string());
            play_sound_in_background (repeat);
        } catch (GLib.Error e) {
            warning ("Error in ring_real: %s", e.message);
        }
    }

    public void ring_once () {
        debug ("ring_once called - starting playback in background thread");
        is_playing = true;
        playback_thread = new GLib.Thread<bool> ("bell-ringonce", () => {
            debug ("Ring thread: playing sound");
            play_sound_sync (false);
            is_playing = false;
            debug ("Ring thread: sound complete");
            return true;
        });
    }
    
    // Play once for preview (stops existing playback)
    public void play_once () {
        debug ("play_once called for preview");
        play_sound_in_background (false);
    }

    public void ring () {
        debug ("ring called with sound: %s", sound);
        ring_real.begin (true);
    }

    public void stop () {
        debug ("Bell.stop() called");
        is_playing = false;
        cancellable.cancel ();
        
        // Try to terminate paplay processes
        try {
            string[] pkill_args = {"pkill", "-f", "paplay"};
            int exit_status;
            GLib.Process.spawn_sync (null, pkill_args, null, GLib.SpawnFlags.SEARCH_PATH, null, null, null, out exit_status);
            debug ("pkill paplay, exit status: %d", exit_status);
        } catch (GLib.Error e) {
            debug ("Error stopping paplay: %s", e.message);
        }
    }
}

} // namespace Utils
} // namespace Clocks
