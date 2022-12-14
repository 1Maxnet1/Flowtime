/* Timer.vala
 *
 * Copyright 2022 Diego Iván <diegoivan.mae@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Flowtime.Services.Timer : Object {
    public bool running { get; protected set; default = false; }
    public bool already_started { get; protected set; }

    private int _seconds;
    public int seconds {
        get {
            return _seconds;
        }
        set {
            _seconds = value;
            updated ();
        }
    }
    public Mode mode { get; private set; default = WORK; }

    public signal void updated ();
    public signal void done ();

    private const int INTERVAL_MILLISECONDS = 1000;
    private DateTime? last_datetime = null;

    construct {
        seconds = 0;
    }

    public void start () {
        last_datetime = new DateTime.now_utc ();
        running = true;
        Timeout.add (INTERVAL_MILLISECONDS, timeout);
    }

    public void stop () {
        running = false;
    }

    public void resume () {
        running = true;
        last_datetime = null;
        Timeout.add (INTERVAL_MILLISECONDS, timeout);
    }

    public void next_mode () {
        stop ();
        last_datetime = null;

        /*
         * This would mean that we want to change the mode to break. We will obtain the seconds for this
         * mode and change it accordingly
         */
        if (mode == WORK) {
            mode = BREAK;
            seconds /= 5;
            return;
        }

        // Reset timer in case the next mode is work mode
        seconds = 0;
        mode = WORK;
    }

    public void reset () {
        stop ();
        last_datetime = null;
        seconds = 0;
    }

    protected bool timeout () {
        if (!running) {
            return false;
        }

        var current_time = new DateTime.now_utc ();
        // Obtaining the difference between the last and current times, casting it to seconds
        int time_seconds = (int) (current_time.difference (last_datetime) / TimeSpan.SECOND);
        message (time_seconds.to_string ());

        switch (mode) {
            case WORK:
                seconds += time_seconds;
                break;

            case BREAK:
                if (time_seconds >= seconds) {
                    seconds = 0;
                    done ();
                    return false;
                }
                seconds -= time_seconds;
                break;

            default:
                assert_not_reached ();
        }

        last_datetime = current_time;

        return true;
    }
}

public enum Flowtime.Mode {
    WORK,
    BREAK
}
