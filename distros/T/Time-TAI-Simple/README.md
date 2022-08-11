NAME
        Time::TAI::Simple - High resolution UNIX epoch time without leapseconds

VERSION
        1.16

SYNOPSIS
        use Time::TAI::Simple;  # imports tai, tai10, and tai35

        # simple and fast procedural interface:

        $seconds_since_epoch = tai();
        $since_epoch_minus_ten = tai10();  # Probably what you want!
        $close_to_utc_time_for_now = tai35();

        # You can likely skip the rest of this synopsis.

        # object-oriented interface:

        $tai = Time::TAI::Simple->new();

        $since_epoch_minus_ten = $tai->time();

        # download a more up-to-date leapsecond list, and recalculate time base:

        $tai->download_leapseconds() or die("cannot download leapseconds file");
        $tai->load_leapseconds();
        $tai->calculate_base();
        $since_epoch_minus_ten = $tai->time();

        # .. or simply download the leapsecond list as part of instantiation.
        # There is also an option for specifying where to put/find the list:

        $tai = Time::TAI::Simple->new(
            download_leapseconds => 1,
            leapseconds_pathname => '/etc/leap-seconds.list'
            );
        $since_epoch_minus_ten = $tai->time();

        # use mode parameter for TAI-00 time or TAI-35 time:

        $tai00 = Time::TAI::Simple->new(mode => 'tai');
        $seconds_since_epoch = $tai00->time();

        $tai35 = Time::TAI::Simple->new(mode => 'tai35');
        $close_to_utc_time_for_now = $tai35->time();

        # reduce processing overhead of instantiation, at the expense of
        # some precision, by turning off fine-tuning step:

        $tai = Time::TAI::Simple->new(fine_tune => 0);
        $nowish = $tai->time();  # accurate to a few milliseconds, not microseconds.

DESCRIPTION
    The "Time::TAI::Simple" module provides a very simple way to obtain the
    number of seconds elapsed since the beginning of the UNIX epoch (January
    1st, 1970).

    It differs from "Time::HiRes" in that it returns the actual number of
    elapsed seconds, unmodified by the leap seconds introduced by the IETF
    to make UTC time. These leap seconds can be problematic for automation
    software, as they effectively make the system clock stand still for one
    second every few years.

    D. J. Bernstein describes other problems with leapseconds-adjusted time
    in this short and sweet article: <http://cr.yp.to/proto/utctai.html>

    "Time::TAI::Simple" provides a monotonically increasing count of
    seconds, which means it will never stand still or leap forward or
    backward due to system clock adjustments (such as from NTP), and avoids
    leapseconds-related problems in general.

    This module differs from Time::TAI <https://metacpan.org/pod/Time::TAI>
    and Time::TAI::Now <https://metacpan.org/pod/Time::TAI::Now> in a few
    ways:

        * it is much simpler to use,

        * it uses the same epoch as perl's "time" builtin and "Time::HiRes",
        not the IETF's 1900-based epoch,

        * it is a "best effort" implementation, accurate to a few
        microseconds,

        * it depends on the local POSIX monotonic clock, not an external
        atomic clock.

ABOUT TAI, TAI10, TAI35
    This module provides three *modes* of TAI time:

    tai is, very simply, the actual number of elapsed seconds since the
    epoch.

    tai10 provides TAI-10 seconds, which is how TAI time has traditionally
    been most commonly used, because when leapseconds were introduced in
    1972, UTC was TAI minus 10 seconds.

    It is the type of time provided by Arthur David Olson's popular time
    library, and by the TAI patch currently proposed to the standard
    zoneinfo implementation. When most people use TAI time, it is usually
    TAI-10.

    tai35 provides TAI-35 seconds, which makes it exactly equal to the
    system clock time returned by "Time::HiRes::time()" before July 1 2015.
    As the IETF introduces more leapseconds, tai35 will be one second ahead
    of the system clock time with each introduction.

    This mode is provided for use-cases where compatability with other TAI
    time implementations is not required, and keeping the monotonically
    increasing time relatively close to the system clock time is desirable.

    It was decided to provide three types of TAI time instead of allowing an
    arbitrary seconds offset parameter to make it easier for different
    systems with different users and different initialization times to pick
    compatible time modes.

FURTHER READING
    The following reading is recommended:

    <http://cr.yp.to/proto/utctai.html>

    <http://tycho.usno.navy.mil/leapsec.html>

    <http://leapsecond.com/java/gpsclock.htm>

MODULE-SCOPE VARIABLES
    "Time::TAI::Simple" defines a few externally-accessible variables so
    that users may customize their values to fit their needs, or to use them
    in other programming projects.

  @Time::TAI::Simple::LEAPSECOND_UNIX_PATHNAME_LIST
    This list enumerates the pathnames where methods will look for the file
    listing IETF-defined leapseconds on UNIX systems. The list is traversed
    in order, and the first readable file will be used.

  @Time::TAI::Simple::LEAPSECOND_WINDOWS_PATHNAME_LIST
    This list enumerates the pathnames where methods will look for the file
    listing IETF-defined leapseconds on Windows systems. Like its UNIX
    counterpart, the list is traversed in order, and the first readable file
    will be used.

  @Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST
    If no leapseconds list file can be found, "Time::TAI::Simple" falls back
    on using this hard-coded list of IETF-defined leapseconds.

    This is dangerous because if the module is too old to include recently
    introduced leapseconds, TAI clock objects instantiated after the new
    leapsecond will be one second ahead of the desired TAI time.

    This problem can be avoided by downloading the most recent leapsecond
    list file, either by invoking the "download_leapseconds" method or by
    manually downloading it from
    <https://www.ietf.org/timezones/data/leap-seconds.list> and putting it
    somewhere "Time::TAI::Simple" will find it, such as
    "/etc/leap-seconds.list" or "C:\WINDOWS\leap-seconds.list".

    @Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST is a list of arrayrefs,
    each referenced array consisting of two elements, an IETF timestamp and
    a time delta.

  $Time::TAI::Simple::LEAPSECOND_IETF_DELTA
    The IETF represents TAI time as the number of seconds elapsed since
    1900-01-01, which is 2208960000 seconds greater than the number of
    seconds elapsed since 1971-01-01 (the UNIX epoch). "Time::TAI::Simple"
    keeps this value in $Time::TAI::Simple::LEAPSECOND_IETF_DELTA and uses
    it internally to convert IETF times to UNIX epoch times.

  $Time::TAI::Simple::TAI_OR
  $Time::TAI::Simple::TAI10_OR
  $Time::TAI::Simple::TAI35_OR
    When using "Time::TAI::Simple"'s procedural interface, the first time
    the "tai", "tai10", and "tai35" functions are invoked, they instantiate
    "Time::TAI::Simple" with the appropriate "mode" and assign it to these
    module-scope variables. Subsequent invocations re-use these instants.

    Before the first invocation, these variables are "undef".

PROCEDURAL INTERFACE
  "$seconds = tai()"
  "$seconds = tai10()"
  "$seconds = tai35()"
    These functions return a floating-point number of seconds elapsed since
    the epoch. They are equivalent to instantiating a $tai object with the
    corresponding mode and invoking its "time" method.

    EXAMPLE:

        use Time::TAI::Simple;

        my $start_time = tai();
        do_something();
        my $time_delta = tai() - $start_time;
        print "doing something took $time_delta seconds\n";

OBJECT ORIENTED INTERFACE
  INSTANTIATION
   "$tai = Time::TAI::Simple->new(%options)"
    Instantiates and returns a new "Time::TAI::Simple" object, hereafter
    referred to as $tai. Returns "undef" on irrecoverable error.

    Without options, instantiation will:

        * find and load the local copy of the leapseconds file into
        "$tai->{ls_ar}" (or load from
        @Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST if no local file is
        found),

        * instantiate a "POSIX::RT::Clock" object referencing the POSIX
        monotonic clock and store it in "$tai->{tm_or}",

        * calculate a value for "$tai->{tm_base}", which is the number of
        seconds to add to the POSIX monotonic clock time to derive the
        TAI-10 time, and

        * perform a "fine tuning" of this "tm_base", based on repeatedly
        sampling the system clock and estimating the time difference between
        loading the value of the system clock and loading the value of the
        monotonic clock.

    This behavior can be changed by passing optional parameters:

    "mode => 'tai'"
    "mode => 'tai10'" (default)
    "mode => 'tai35'"
        Adjusts "$tai->{tm_base}" so that "$tai->time()" returns the TAI,
        TAI-10, or TAI-35 time.

    "download_leapseconds => 0" (default)
    "download_leapseconds => 1"
        When set, causes "new" to try to http-download a new leapseconds
        list file before loading the leapseconds file.

        "Time::TAI::Simple" maintains an internal list of URLs from which to
        download this file, and it goes down this list sequentially,
        stopping when the file has been successfully downloaded. This list
        may be amended via the "download_urls" option.

        By default, no attempt is made to download a leapseconds file. This
        avoids the potential for very long http timeouts and clobbering any
        existing administrator-provided leapseconds file.

        "Time::TAI::Simple-"{ua_ar}> is an arrayref to a list of User-Agent
        strings, and one of these will be picked at random for HTTP queries,
        stored in "Time::TAI::Simple-"{ua_str}>.

        User-Agent spoofing behavior is subject to the following options
        which can be passed to "new" (see the documentation for
        "tai-download-leapseconds" for a description of their use):

            agent => <STRING>,
            churn_agent => 1,
            force_edge => 1,

        See "tai-download-leapseconds" also for the download-related
        options:

            retry => <NUMBER>,
            retry_delay => <SECONDS>

    "download_urls => [$url1, $url2, ...]"
        Prepends the provided list of URLs to the list of remove locations
        from which the leapseconds file is downloaded when the
        "download_leapseconds" option is set. Use this if your administrator
        maintains a leapseconds file for organizational use.

    "leapseconds_pathname => '/home/tai/leap-seconds.list'"
        Sets the pathname of the leapseconds list file. This is the pathname
        to which the file will be stored when downloaded via the
        "download_leapseconds" option or "download_leapseconds" method, and
        it is the pathname from which the file will be loaded by the
        "load_leapseconds" method.

        By default, "Time::TAI::Simple" will look for this file in several
        locations, specified in
        @Time::TAI::Simple::LEAPSECOND_UNIX_PATHNAME_LIST and
        @Time::TAI::Simple::LEAPSECOND_WINDOWS_PATHNAME_LIST. The user may
        opt to replace the contents of these list variables as an
        alternative to using the "leapseconds_pathname" option (for
        instance, before invoking the "tai", "tai10", "tai35" functions).

    "do_not_load_leapseconds => 0" (default)
    "do_not_load_leapseconds => 1"
        When set, prevents loading the timestamp list from the timestamp
        list file or @Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST into
        "$tai->{ls_ar}".

        This only makes sense when setting the "base_time" option or when
        populating "$tai->{ls_ar}" manually after instantiation and
        subsequently re-running the "calculate_base" method.

    "base_time => $seconds"
        When set, circumvents the normal process of calculating
        "$tai->{tm_base}" and uses the provided value instead. This should
        be the number of seconds added to the time obtained from the POSIX
        monotonic clock to get the TAI time returned by the "time" method.

    "fine_tune => 0"
    "fine_tune => 1" (default)
        When set (the default), adjusts "tm_base", based on repeatedly
        sampling the system clock and estimating the time difference between
        loading the value of the system clock and loading the value of the
        monotonic clock. This can add measurable overhead to the
        "calculate_base" method -- about 35 microseconds on 2013-era
        hardware, accounting for about 3/4 of instantiation time.

        When false, skips this fine-tuning, diminishing the precision of the
        "time" method from a few microseconds to a few milliseconds.

  OBJECT ATTRIBUTES
    The following attributes of a "Time::TAI::Simple" instance are public.
    Changes to some attributes will do nothing until the "load_leapseconds"
    and/or "calculate_base" methods are re-run.

   "opt_hr" (hash reference)
    Refers to the parameters passed to "new".

   "tm_or" ("POSIX::RT::Clock" object reference)
    Refers to the POSIX standard monotonic clock interface used by "time" to
    calculate the current TAI time (along with "tm_base").

   "ls_ar" (array reference)
    Refers to the IETF leapseconds list. Its elements are arrayrefs to "[UTC
    epoch, seconds]" tuples, and they are ordered by "UTC epoch".

   "ls_tm" (integer)
    Value is the file modification time of the IETF leapseconds list file,
    if "ls_ar" was loaded from a file, or the time "ls_ar" was loaded from
    @Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST, or 0 if never loaded.

   "dl_tm" (floating point)
    Value is the system clock time the "download_leapseconds" method last
    attempted to download the IETF leapseconds list file, or 0.0 if never
    attempted.

   "tm_base" (floating point)
    Value is the difference, in seconds, between the POSIX monotonic clock
    time and the beginning of the epoch. It is used by "time" to calculate
    the current TAI time. It is initialized by the "calculate_base" method,
    and is 0.0 if never initialized.

   "mode" (string)
    Exactly one of "tai", "tai10", "tai35", indicating the "mode" with which
    the object was instantiated, and thus the type of TAI time returned by
    "time". Its default value is "tai10".

  OBJECT METHODS
   "$tai->time()"
    Returns a floating-point number of seconds elapsed since the epoch.

   "$tai->calculate_base(%options)"
    "calculate_base" uses the POSIX monotonic clock, the leapsecond list,
    and the system clock to calculate "$tai->{tm_base}", which is the
    difference between the POSIX monotonic clock and the TAI time. This
    difference is used by "time" to calculate the TAI time from the POSIX
    monotonic clock time.

    This method is normally only called by "new", but can be called
    explicitly to recalculate "$tai->{tm_base}" if one of its dependencies
    is changed.

    It takes some of the same options as "new", and they have the same
    effect:

    "base_time => $seconds"
    "fine_tune => 0 or 1"

    It has no return value.

   "$tai->load_leapseconds(%options)"
    "load_leapseconds" finds the local copy of the IETF leapseconds list
    file, reads it, and populates the object's "ls_ar" attribute. If it
    cannot find any file it uses the values in
    @Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST instead.

    This method, too, is normally only called by "new", but can be called
    explicitly as needed to re-initialize "$tai->{ls_ar}".

    For now it takes only one option, which has the same effect as passing
    it to <new>:

    "leapseconds_pathname => "/home/tai/leap-seconds.list""

    It returns 1 on success, 0 on failure.

   "$tai->download_leapseconds(%options)"
    "download_leapseconds" tries to download the IETF leapseconds file so it
    can be loaded by the "load_leapseconds" method. It iterates through a
    list of URLs (any provided via the "leapseconds_pathname" parameter
    first, and an internal list after) and saves the first file it is able
    to download to either the pathname specified by the
    "leapseconds_pathname" parameter or a sensible location appropriate to
    the operating system type.

    This method can be called by "new", but only when the
    "download_leapseconds" parameter is passed to "new" with a value which
    resolves to "true".

    It takes two options, which have the same effects as passing them to
    "new":

    "download_urls => [$url1, $url2, ...]"
    "leapseconds_pathname => "/home/tai/leap-seconds.list""

    It returns 1 on success, 0 on failure.

EXAMPLES
    Some simple scripts wrapping this module can be found in "bin":

    "tai-download-leapseconds"
        Attempts to download the IETF leapseconds file. Will write the
        pathname of the downloaded file to STDOUT and exit 0, or write an
        error to STDERR and exit 1. Pass it the "-h" option to see its
        options.

        On UNIX hosts, it is recommended that a symlink be made in
        "/etc/cron.monthly" to "/usr/local/bin/tai-download-leapseconds" so
        that it updates the system's leapseconds file as updates become
        available.

    "tai"
        Prints the current time. Shows TAI-10 by default. Pass it the "-h"
        option to see its options.

TODO
    Needs support for negative leapseconds.

    Needs support for Linux's POSIX CLOCK_TAI, when available, now that
    that's properly exposed in recent Linux releases. Currently blocked on
    POSIX::RT::Timer but if an update is too long in the coming I may just
    roll my own.

    Needs more unit tests.

    Does "new" need changes to be made thread-safe?

    Test "_fine_tune" under other versions of perl, find out if the constant
    factor needs to be version-specific.

    Do something smart with "ls_tm" and "dl_tm", like an optional feature
    which tries to refresh the leapsecond list periodically when stale.

THREADS
    Not tested, but its dependencies are purportedly thread-safe, and I
    think the "time" method, and the "tai", "tai10", and "tai35" functions
    should be thread-safe. Not so sure about "new".

BUGS
    Probably. In particular, the Windows compatability code is not tested,
    nor do I have access to a Windows environment in which to test it. I
    doubt that the paths in
    @Time::TAI::Simple::LEAPSECOND_WINDOWS_PATHNAME_LIST are sufficient for
    all environments.

    Also, some corners were cut in "bin/tai", particularly in the "--iso"
    code, which means its output will not be precisely correct for locales
    with timezones whose time offsets are not whole hours.

    Please report relevant bugs to <ttk[at]ciar[dot]org>.

    Bugfix patches are also welcome.

SEE ALSO
    DateTime has a "subtract_datetime_absolute" method which will give the
    actual difference between two times, just like taking the difference
    between two TAI times.

    If you are a scientist, you might want Time::TAI
    <https://metacpan.org/pod/Time::TAI> or Time::TAI::Now
    <https://metacpan.org/pod/Time::TAI::Now>.

    An alternative approach to solving the problem of leapsecond-induced
    bugs is Time::UTC_SLS <https://metacpan.org/pod/Time::UTC_SLS>, "UTC
    with Smoothed Leap Seconds".

AUTHOR
    TTK Ciar, <ttk[at]ciar[dot]org>

COPYRIGHT AND LICENSE
    Copyright 2014-2022 by TTK Ciar

    This library is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

