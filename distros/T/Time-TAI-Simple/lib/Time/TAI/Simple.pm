package Time::TAI::Simple;

# ABSTRACT: Easily obtain current TAI time, using UNIX epoch.

use strict;
use warnings;
require v5.10.0;

use POSIX::RT::Clock;
use Time::HiRes;
use HTTP::Tiny;

use base qw(Exporter);

BEGIN {
    @Time::TAI::Simple::EXPORT = qw(tai tai10 tai35);
    $Time::TAI::Simple::VERSION = '1.15';
}

our @LEAPSECOND_UNIX_PATHNAME_LIST = (
    '/etc/leap-seconds.list',
    ($ENV{'HOME'} // '/root') . "/.leap-seconds.list",
    "/var/tmp/leap-seconds.list",
    "/tmp/leap-seconds.list"
);

our @LEAPSECOND_WINDOWS_PATHNAME_LIST = (
    ($ENV{'WINDIR'} // 'C:\WINDOWS') . '\leap-seconds.list',
    ($ENV{'HOMEDRIVE'} // 'C:') . ($ENV{'HOMEPATH'} // '\Users') . '\.leap-seconds.list',
    ($ENV{'TEMP'} // 'C:\TEMPDIR') . '\leap-seconds.list'
);

our $LEAPSECOND_IETF_DELTA = 2208960000;  # difference between IETF's leapseconds (since 1900-01-01 00:00:00) and equivalent UNIX epoch time.

our @FALLBACK_LEAPSECONDS_LIST = (  # from https://www.ietf.org/timezones/data/leap-seconds.list
    [2272060800, 10],
    [2287785600, 11],
    [2303683200, 12],
    [2335219200, 13],
    [2366755200, 14],
    [2398291200, 15],
    [2429913600, 16],
    [2461449600, 17],
    [2492985600, 18],
    [2524521600, 19],
    [2571782400, 20],
    [2603318400, 21],
    [2634854400, 22],
    [2698012800, 23],
    [2776982400, 24],
    [2840140800, 25],
    [2871676800, 26],
    [2918937600, 27],
    [2950473600, 28],
    [2982009600, 29],
    [3029443200, 30],
    [3076704000, 31],
    [3124137600, 32],
    [3345062400, 33],
    [3439756800, 34],
    [3550089600, 35],
    [3644697600, 36],
    [3692217600, 37]
);

our $TAI_OR   = undef;
our $TAI10_OR = undef;
our $TAI35_OR = undef;

sub new {
    my ($class, %opt_hr) = @_;
    my $success = 0;
    my $timer = undef;
    eval { $timer = POSIX::RT::Clock->new('monotonic'); $success = 1; };
    return undef unless ($success);

    my $self = {
        opt_hr  => \%opt_hr,
        tm_or   => undef,    # POSIX::RT::Clock instance, for monotonic clock access.
        ls_ar   => [],       # list of leap seconds, as tuples of [UTC epoch, $nsec].
        ls_tm   => 0,        # epoch mtime of leap seconds list, so we know when it needs updating.
        dl_tm   => 0,        # epoch time we last tried to download a new leapsecond list.
        tm_base => 0.0,      # add to monotonic clock time to get TAI epoch time.
        mode    => 'tai10',  # one of: "tai", "tai10", or "tai35".
        dl_fr   => undef,
        dl_to   => undef
    };
    bless ($self, $class);
    $self->{http_or} = HTTP::Tiny->new(max_redirect => 15, agent => 'Wget/1.18 (linux-gnu)');
    $self->{mode}    = $self->opt('mode', 'tai10');
    $self->download_leapseconds() if ($self->opt('download_leapseconds', 0));
    $self->load_leapseconds() unless ($self->opt('do_not_load_leapseconds'));
    $self->calculate_base();  # also sets tm_or and potentially ls_next
    return $self;
}

sub time {
    return $_[0]->{tm_or}->get_time() + $_[0]->{tm_base};
}

sub tai {
    $TAI_OR = Time::TAI::Simple->new(mode => 'tai') unless (defined($TAI_OR));
    return $TAI_OR->time();
}

sub tai10 {
    $TAI10_OR = Time::TAI::Simple->new(mode => 'tai10') unless (defined($TAI10_OR));
    return $TAI10_OR->time();
}

sub tai35 {
    $TAI35_OR = Time::TAI::Simple->new(mode => 'tai35') unless (defined($TAI35_OR));
    return $TAI35_OR->time();
}

sub calculate_base {
    my ($self, %opt_h) = @_;
    $self->{tm_or} = POSIX::RT::Clock->new('monotonic') unless (defined($self->{tm_or}));
    if (defined($self->opt('base_time', undef, \%opt_h))) {
        $self->{tm_base} = $self->opt('base_time', undef, \%opt_h);
	return;
    }
    my $tm = Time::HiRes::time();
    my $mo = $self->{tm_or}->get_time();
    my $delta = 0;
    for (my $ix = 0; defined($self->{ls_ar}->[$ix]); $ix++) {
        my ($ls_tm, $ls_delta) = @{$self->{ls_ar}->[$ix]};
	if ($ls_tm > $tm - $delta) {
	    $self->{ls_next} = $ix;
	    last;
	}
	$delta = $ls_delta;
    }
    $delta -= 10 if ($self->{mode} eq 'tai10');
    $delta -= 35 if ($self->{mode} eq 'tai35');
    $delta -= $self->_fine_tune() if ($self->opt('fine_tune', 1));
    $self->{tm_base} = $tm - $mo - $delta;
    return;
}

sub load_leapseconds {
    my ($self, %opt_h) = @_;
    my $filename = $self->_leapseconds_filename(\%opt_h);
    my $fh = undef;
    $self->{ls_ar} = [];
    if (open($fh, '<', $filename)) {
        while(defined(my $x = <$fh>)) {
        next unless ($x =~ /^(\d{10})\s+(\d{2})/);
            my ($iers_tm, $nsec) = ($1, $2);
            my $epoch_tm = $iers_tm - $LEAPSECOND_IETF_DELTA;
            push(@{$self->{ls_ar}}, [$epoch_tm, $nsec]);
            # can't set ls_next here, because base tai time hasn't been computed yet.
        }
        close($fh);
        $self->{ls_tm} = (stat($filename))[9];
    } else {
        foreach my $tup (@FALLBACK_LEAPSECONDS_LIST) {
            my ($iers_tm, $nsec) = @{$tup};
            my $epoch_tm = $iers_tm - $LEAPSECOND_IETF_DELTA;
            push(@{$self->{ls_ar}}, [$epoch_tm, $nsec]);
	}
        $self->{ls_tm} = CORE::time();
    }
    return 1;
}

sub download_leapseconds {
    my ($self, %opt_h) = @_;
    my $response = 0;
    my @url_list = ();
    $self->{dl_tm} = CORE::time();
    if (defined(my $urls = $self->opt('download_urls', undef, \%opt_h))) {
        if (ref($urls) eq 'ARRAY') {
            push(@url_list, @{$urls});
        }
        elsif ($urls =~ /^(http:|ftp:|file:)/i) {
            push(@url_list, $urls);
        }
    }
    push (@url_list, 'http://www.ciar.org/ttk/codecloset/leap-seconds.list');
    push (@url_list, 'https://www.ietf.org/timezones/data/leap-seconds.list');
    eval {
        my $http_or = $self->{http_or};
        my $leapseconds_filename = $self->_leapseconds_filename(\%opt_h);
        foreach my $url (@url_list) {
            my $reply = $http_or->mirror($url, $leapseconds_filename, {});
            next unless (defined($reply) && $reply->{success});
            $response = 1;
            $self->{dl_fr} = $url;
            $self->{dl_to} = $leapseconds_filename;
            last;
        }
    };
    return $response;
}

sub opt {
    my ($self, $name, $default_value, $alt_hr) = @_;
    return $self->{opt_hr}->{$name} if (defined($self->{opt_hr}->{$name}));
    return $alt_hr->{$name} if (defined($alt_hr) && ref($alt_hr) eq 'HASH' && defined($alt_hr->{$name}));
    return $default_value;
}

sub _fine_tune {
    my $self = shift(@_);
    my $sum = 0;
    for (my $i = 0; $i < 100; $i++ ) {
        $sum += 0 - Time::HiRes::time() + Time::HiRes::time();
    }
    my $jitter = $sum * 0.17;  # Correct for v5.18.1, need to test others for skew.
    # printf ('jitter=%0.010f'."\n", $jitter);
    return $jitter;
}

sub _leapseconds_filename {
    my($self, $opt_hr) = @_;
    $opt_hr //= {};
    my $pathname = $self->opt('leapseconds_pathname', undef, $opt_hr);
    return $pathname if (defined($pathname));
    if ($^O eq 'MSWin32') {
        foreach my $f (@LEAPSECOND_WINDOWS_PATHNAME_LIST) {
            $pathname = $f;
            return $f if (-e $f);
        }
    } else {
        foreach my $f (@LEAPSECOND_UNIX_PATHNAME_LIST) {
            $pathname = $f;
            return $f if (-e $f);
        }
    }
    return $pathname;
}

1;

=head1 NAME

    Time::TAI::Simple - High resolution UNIX epoch time without leapseconds

=head1 VERSION

    1.13

=head1 SYNOPSIS

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

=head1 DESCRIPTION

The C<Time::TAI::Simple> module provides a very simple way to obtain the
number of seconds elapsed since the beginning of the UNIX epoch (January
1st, 1970).

It differs from C<Time::HiRes> in that it returns the actual number of
elapsed seconds, unmodified by the leap seconds introduced by the IETF
to make UTC time.  These leap seconds can be problematic for automation
software, as they effectively make the system clock stand still for one
second every few years.

D. J. Bernstein describes other problems with leapseconds-adjusted time
in this short and sweet article: L<http://cr.yp.to/proto/utctai.html>

C<Time::TAI::Simple> provides a monotonically increasing count of seconds,
which means it will never stand still or leap forward or backward due to
system clock adjustments (such as from NTP), and avoids leapseconds-related
problems in general.

This module differs from L<Time::TAI|https://metacpan.org/pod/Time::TAI>
and L<Time::TAI::Now|https://metacpan.org/pod/Time::TAI::Now> in a few
ways:

=over 4

* it is much simpler to use,

* it uses the same epoch as perl's C<time> builtin and C<Time::HiRes>, not the IETF's 1900-based epoch,

* it is a "best effort" implementation, accurate to a few microseconds,

* it depends on the local POSIX monotonic clock, not an external atomic clock.

=back

=head1 ABOUT TAI, TAI10, TAI35

This module provides three I<modes> of TAI time:

B<tai> is, very simply, the actual number of elapsed seconds since the epoch.

B<tai10> provides TAI-10 seconds, which is how TAI time has traditionally been
most commonly used, because when leapseconds were introduced in 1972, UTC was
TAI minus 10 seconds.

It is the type of time provided by Arthur David Olson's popular time library,
and by the TAI patch currently proposed to the standard zoneinfo implementation.
When most people use TAI time, it is usually TAI-10.

B<tai35> provides TAI-35 seconds, which makes it exactly equal to the system
clock time returned by C<Time::HiRes::time()> before July 1 2015.
As the IETF introduces more leapseconds, B<tai35> will be one second ahead
of the system clock time with each introduction.

This mode is provided for use-cases where compatability with other TAI time
implementations is not required, and keeping the monotonically increasing time
relatively close to the system clock time is desirable.

It was decided to provide three types of TAI time instead of allowing an
arbitrary seconds offset parameter to make it easier for different systems
with different users and different initialization times to pick compatible
time modes.

=head1 FURTHER READING

The following reading is recommended:

L<http://cr.yp.to/proto/utctai.html>

L<http://tycho.usno.navy.mil/leapsec.html>

L<http://leapsecond.com/java/gpsclock.htm>

=head1 MODULE-SCOPE VARIABLES

C<Time::TAI::Simple> defines a few externally-accessible variables so that
users may customize their values to fit their needs, or to use them in
other programming projects.

=head2 C<@Time::TAI::Simple::LEAPSECOND_UNIX_PATHNAME_LIST>

This list enumerates the pathnames where methods will look for the file
listing IETF-defined leapseconds on UNIX systems.  The list is traversed
in order, and the first readable file will be used.

=head2 C<@Time::TAI::Simple::LEAPSECOND_WINDOWS_PATHNAME_LIST>

This list enumerates the pathnames where methods will look for the file
listing IETF-defined leapseconds on Windows systems.  Like its UNIX
counterpart, the list is traversed in order, and the first readable file
will be used.

=head2 C<@Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST>

If no leapseconds list file can be found, C<Time::TAI::Simple> falls back on
using this hard-coded list of IETF-defined leapseconds.

This is dangerous because if the module is too old to include recently
introduced leapseconds, TAI clock objects instantiated after the new
leapsecond will be one second ahead of the desired TAI time.

This problem can be avoided by downloading the most recent leapsecond list
file, either by invoking the C<download_leapseconds> method or by manually
downloading it from L<https://www.ietf.org/timezones/data/leap-seconds.list>
and putting it somewhere C<Time::TAI::Simple> will find it, such as
C</etc/leap-seconds.list> or C<C:\WINDOWS\leap-seconds.list>.

C<@Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST> is a list of arrayrefs,
each referenced array consisting of two elements, an IETF timestamp and a
time delta.

=head2 C<$Time::TAI::Simple::LEAPSECOND_IETF_DELTA>

The IETF represents TAI time as the number of seconds elapsed since 1900-01-01,
which is 2208960000 seconds greater than the number of seconds elapsed since
1971-01-01 (the UNIX epoch).  C<Time::TAI::Simple> keeps this value in
C<$Time::TAI::Simple::LEAPSECOND_IETF_DELTA> and uses it internally to convert
IETF times to UNIX epoch times.

=head2 C<$Time::TAI::Simple::TAI_OR>

=head2 C<$Time::TAI::Simple::TAI10_OR>

=head2 C<$Time::TAI::Simple::TAI35_OR>

When using C<Time::TAI::Simple>'s procedural interface, the first time
the C<tai>, C<tai10>, and C<tai35> functions are invoked, they instantiate
C<Time::TAI::Simple> with the appropriate C<mode> and assign it to these
module-scope variables.  Subsequent invocations re-use these instants.

Before the first invocation, these variables are C<undef>.

=head1 PROCEDURAL INTERFACE

=head2 C<$seconds = tai()>

=head2 C<$seconds = tai10()>

=head2 C<$seconds = tai35()>

These functions return a floating-point number of seconds elapsed since the
epoch.  They are equivalent to instantiating a C<$tai> object with the
corresponding mode and invoking its C<time> method.

B<EXAMPLE>:

    use Time::TAI::Simple;

    my $start_time = tai();
    do_something();
    my $time_delta = tai() - $start_time;
    print "doing something took $time_delta seconds\n";

=head1 OBJECT ORIENTED INTERFACE

=head2 INSTANTIATION

=head3 C<$tai = Time::TAI::Simple-E<gt>new(%options)>

Instantiates and returns a new C<Time::TAI::Simple> object, hereafter referred
to as C<$tai>.  Returns C<undef> on irrecoverable error.

Without options, instantiation will:

=over 4

* find and load the local copy of the leapseconds file into C<$tai-E<gt>{ls_ar}>
(or load from C<@Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST> if no local file
is found),

* instantiate a C<POSIX::RT::Clock> object referencing the POSIX monotonic clock
and store it in C<$tai-E<gt>{tm_or}>,

* calculate a value for C<$tai-E<gt>{tm_base}>, which is the number of seconds to
add to the POSIX monotonic clock time to derive the TAI-10 time, and

* perform a "fine tuning" of this C<tm_base>, based on repeatedly sampling the
system clock and estimating the time difference between loading the value of the
system clock and loading the value of the monotonic clock.

=back

This behavior can be changed by passing optional parameters:

=over 4

=item C<mode =E<gt> 'tai'>

=item C<mode =E<gt> 'tai10'> (default)

=item C<mode =E<gt> 'tai35'>

Adjusts C<$tai-E<gt>{tm_base}> so that C<$tai-E<gt>time()> returns the B<TAI>,
B<TAI-10>, or B<TAI-35> time.

=item C<download_leapseconds =E<gt> 0> (default)

=item C<download_leapseconds =E<gt> 1>

When set, causes C<new> to try to http-download a new leapseconds list file
before loading the leapseconds file.

C<Time::TAI::Simple> maintains an internal list of URLs from which to download
this file, and it goes down this list sequentially, stopping when the file has
been successfully downloaded.  This list may be amended via the C<download_urls>
option.

By default, no attempt is made to download a leapseconds file.  This avoids
the potential for very long http timeouts and clobbering any existing
administrator-provided leapseconds file.

=item C<download_urls =E<gt> [$url1, $url2, ...]>

Prepends the provided list of URLs to the list of remove locations from which
the leapseconds file is downloaded when the C<download_leapseconds> option is
set.  Use this if your administrator maintains a leapseconds file for
organizational use.

=item C<leapseconds_pathname =E<gt> '/home/tai/leap-seconds.list'>

Sets the pathname of the leapseconds list file.  This is the pathname to which
the file will be stored when downloaded via the C<download_leapseconds> option
or C<download_leapseconds> method, and it is the pathname from which the file
will be loaded by the C<load_leapseconds> method.

By default, C<Time::TAI::Simple> will look for this file in several locations,
specified in C<@Time::TAI::Simple::LEAPSECOND_UNIX_PATHNAME_LIST> and
C<@Time::TAI::Simple::LEAPSECOND_WINDOWS_PATHNAME_LIST>.  The user may opt
to replace the contents of these list variables as an alternative to using
the C<leapseconds_pathname> option (for instance, before invoking the C<tai>,
C<tai10>, C<tai35> functions).

=item C<do_not_load_leapseconds =E<gt> 0> (default)

=item C<do_not_load_leapseconds =E<gt> 1>

When set, prevents loading the timestamp list from the timestamp list file
or C<@Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST> into C<$tai-E<gt>{ls_ar}>.

This only makes sense when setting the C<base_time> option or when populating
C<$tai-E<gt>{ls_ar}> manually after instantiation and subsequently re-running the
C<calculate_base> method.

=item C<base_time =E<gt> $seconds>

When set, circumvents the normal process of calculating C<$tai-E<gt>{tm_base}>
and uses the provided value instead.  This should be the number of seconds
added to the time obtained from the POSIX monotonic clock to get the TAI
time returned by the C<time> method.

=item C<fine_tune =E<gt> 0>

=item C<fine_tune =E<gt> 1> (default)

When set (the default), adjusts C<tm_base>, based on repeatedly sampling the
system clock and estimating the time difference between loading the value of the
system clock and loading the value of the monotonic clock.  This can add measurable
overhead to the C<calculate_base> method -- about 35 microseconds on 2013-era
hardware, accounting for about 3/4 of instantiation time.

When false, skips this fine-tuning, diminishing the precision of the C<time>
method from a few microseconds to a few milliseconds.

=back

=head2 OBJECT ATTRIBUTES

The following attributes of a C<Time::TAI::Simple> instance are public.  Changes to
some attributes will do nothing until the C<load_leapseconds> and/or C<calculate_base>
methods are re-run.

=head3 C<opt_hr> (hash reference)

Refers to the parameters passed to C<new>.

=head3 C<tm_or> (C<POSIX::RT::Clock> object reference)

Refers to the POSIX standard monotonic clock interface used by C<time> to calculate
the current TAI time (along with C<tm_base>).

=head3 C<ls_ar> (array reference)

Refers to the IETF leapseconds list.  Its elements are arrayrefs to
C<[UTC epoch, seconds]> tuples, and they are ordered by C<UTC epoch>.

=head3 C<ls_tm> (integer)

Value is the file modification time of the IETF leapseconds list file, if C<ls_ar>
was loaded from a file, or the time C<ls_ar> was loaded from
C<@Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST>, or C<0> if never loaded.

=head3 C<dl_tm> (floating point)

Value is the system clock time the C<download_leapseconds> method last attempted to
download the IETF leapseconds list file, or C<0.0> if never attempted.

=head3 C<tm_base> (floating point)

Value is the difference, in seconds, between the POSIX monotonic clock time
and the beginning of the epoch.  It is used by C<time> to calculate the current
TAI time.  It is initialized by the C<calculate_base> method, and is C<0.0> if
never initialized.

=head3 C<mode> (string)

Exactly one of "tai", "tai10", "tai35", indicating the C<mode> with which the
object was instantiated, and thus the type of TAI time returned by C<time>.
Its default value is "tai10".

=head2 OBJECT METHODS

=head3 C<$tai-E<gt>time()>

Returns a floating-point number of seconds elapsed since the epoch.

=head3 C<$tai-E<gt>calculate_base(%options)>

C<calculate_base> uses the POSIX monotonic clock, the leapsecond list, and
the system clock to calculate C<$tai-E<gt>{tm_base}>, which is the difference
between the POSIX monotonic clock and the TAI time.  This difference is used
by C<time> to calculate the TAI time from the POSIX monotonic clock time.

This method is normally only called by C<new>, but can be called explicitly
to recalculate C<$tai-E<gt>{tm_base}> if one of its dependencies is changed.

It takes some of the same options as C<new>, and they have the same effect:

=over 4

=item C<base_time =E<gt> $seconds>

=item C<fine_tune =E<gt> 0 or 1>

=back

It has no return value.

=head3 C<$tai-E<gt>load_leapseconds(%options)>

C<load_leapseconds> finds the local copy of the IETF leapseconds list file,
reads it, and populates the object's C<ls_ar> attribute.  If it cannot find
any file it uses the values in C<@Time::TAI::Simple::FALLBACK_LEAPSECONDS_LIST>
instead.

This method, too, is normally only called by C<new>, but can be called
explicitly as needed to re-initialize C<$tai-E<gt>{ls_ar}>.

For now it takes only one option, which has the same effect as passing it
to <new>:

=over 4

=item C<leapseconds_pathname =E<gt> "/home/tai/leap-seconds.list">

=back

It returns 1 on success, 0 on failure.

=head3 C<$tai-E<gt>download_leapseconds(%options)>

C<download_leapseconds> tries to download the IETF leapseconds file so it
can be loaded by the C<load_leapseconds> method.  It iterates through a
list of URLs (any provided via the C<leapseconds_pathname> parameter first,
and an internal list after) and saves the first file it is able to download
to either the pathname specified by the C<leapseconds_pathname> parameter
or a sensible location appropriate to the operating system type.

This method can be called by C<new>, but only when the C<download_leapseconds>
parameter is passed to C<new> with a value which resolves to C<true>.

It takes two options, which have the same effects as passing them to C<new>:

=over 4

=item C<download_urls =E<gt> [$url1, $url2, ...]>

=item C<leapseconds_pathname =E<gt> "/home/tai/leap-seconds.list">

=back

It returns 1 on success, 0 on failure.

=head1 EXAMPLES

Some simple scripts wrapping this module can be found in C<bin>:

=over 4

=item C<tai-download-leapseconds>

Attempts to download the IETF leapseconds file.  Will write the pathname of
the downloaded file to STDOUT and exit C<0>, or write an error to STDERR and
exit C<1>.  Pass it the C<-h> option to see its options.

On UNIX hosts, it is recommended that a symlink be made in C</etc/cron.monthly>
to C</usr/local/bin/tai-download-leapseconds> so that it updates the system's
leapseconds file as updates become available.

=item C<tai>

Prints the current time.  Shows TAI-10 by default.  Pass it the C<-h> option
to see its options.

=back

=head1 TODO

Needs more unit tests.

Does C<new> need changes to be made thread-safe?

Test C<_fine_tune> under other versions of perl, find out if the constant factor needs
to be version-specific.

Do something smart with C<ls_tm> and C<dl_tm>, like an optional feature which tries to
refresh the leapsecond list periodically when stale.

=head1 THREADS

Not tested, but its dependencies are purportedly thread-safe, and I think the C<time>
method, and the C<tai>, C<tai10>, and C<tai35> functions should be thread-safe.  Not
so sure about C<new>.

=head1 BUGS

Probably.  In particular, the Windows compatability code is not tested, nor do I have
access to a Windows environment in which to test it.  I doubt that the paths in
C<@Time::TAI::Simple::LEAPSECOND_WINDOWS_PATHNAME_LIST> are sufficient for all
environments.

Also, some corners were cut in C<bin/tai>, particularly in the C<--iso> code,
which means its output will not be precisely correct for locales with timezones
whose time offsets are not whole hours.

Please report relevant bugs to <ttk[at]ciar[dot]org>.

Bugfix patches are also welcome.

=head1 SEE ALSO

L<DateTime> has a C<subtract_datetime_absolute> method which will give the actual 
difference between two times, just like taking the difference between two TAI times.

If you are a scientist, you might want
L<Time::TAI|https://metacpan.org/pod/Time::TAI> or
L<Time::TAI::Now|https://metacpan.org/pod/Time::TAI::Now>.

An alternative approach to solving the problem of leapsecond-induced bugs
is L<Time::UTC_SLS|https://metacpan.org/pod/Time::UTC_SLS>, "UTC with Smoothed
Leap Seconds".

=head1 AUTHOR

TTK Ciar, <ttk[at]ciar[dot]org>

=head1 COPYRIGHT AND LICENSE

Copyright 2014-2017 by TTK Ciar

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
