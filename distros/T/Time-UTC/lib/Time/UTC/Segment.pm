=head1 NAME

Time::UTC::Segment - segments of UTC definition

=head1 SYNOPSIS

	use Time::UTC::Segment;

	$seg = Time::UTC::Segment->start;

	$tai = $seg->start_tai_instant;
	$tai = $seg->end_tai_instant;
	$len = $seg->length_in_tai_seconds;

	$day = $seg->start_utc_day;
	$day = $seg->last_utc_day;
	$day = $seg->end_utc_day;

	$len = $seg->utc_second_length;
	$secs = $seg->leap_utc_seconds;

	$secs = $seg->last_day_utc_seconds;
	$secs = $seg->length_in_utc_seconds;

	$seg = $seg->prev;
	$seg = $seg->next;

	if($seg->complete_p) { ...
	$seg->when_complete(\&do_stuff);

=head1 DESCRIPTION

An object of this class represents a segment of the definition of UTC in
terms of TAI.  Each segment is a period of time over which the relation
between UTC and TAI is stable.  Each point where the relation changes
is a boundary between segments.

Each segment consists of an integral number of consecutive UTC days.
Within each segment, the length of the UTC second is fixed relative
to the TAI second.  Also, every UTC day in the segment except for the
last one contains exactly 86400 UTC seconds.  The last day of a segment
commonly has some other length.

Because UTC is only defined a few months ahead, the description of UTC
that is available at any particular time is necessarily incomplete.
Nevertheless, this API gives the superficial appearance of completeness.
The information-querying methods will C<die> if asked for information
that is not yet available.  There are additional methods to probe the
availability of information.

=cut

package Time::UTC::Segment;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Digest::SHA1 qw(sha1_hex);
use HTTP::Tiny 0.016 ();
use Math::BigRat 0.13;
use Net::FTP 1.21 ();
use Time::Unix 1.02 ();

our $VERSION = "0.008";

@Time::UTC::Segment::Complete::ISA = qw(Time::UTC::Segment);
@Time::UTC::Segment::Incomplete::ISA = qw(Time::UTC::Segment);

=head1 CONSTRUCTOR

Objects of this class are not created by users, but are generated
internally.  New segments appear when updated UTC data is downloaded;
this is done automatically as required.  Segments are accessed from each
other by means of the C<next> and C<prev> methods.

=over

=item Time::UTC::Segment->start

Returns the first segment of the UTC description.

=back

=cut

my $incomplete_segment;

{
	my $start_segment = $incomplete_segment = bless({
		start_utc_day => Math::BigRat->new(1096),
		start_tai_instant =>
			1096*86400 + Math::BigRat->new("1.4228180"),
		utc_second_length => 1 + Math::BigRat->new("0.001296") / 86400,
	}, "Time::UTC::Segment::Incomplete");
	sub start {
		return $start_segment;
	}
}

sub _add_data($$$$$$) {
	my($start_utc_day, $start_tai_instant, $utc_second_length,
		$end_utc_day, $end_tai_instant, $next_utc_second_length) = @_;
	die "backward UTC segment\n" if $end_utc_day <= $start_utc_day;
	my $seg = $incomplete_segment;
	return if $end_utc_day <= $seg->start_utc_day;
	die "unexpected gap in UTC knowledge\n"
		if $start_utc_day > $seg->start_utc_day;
	my $overlap_days = $seg->start_utc_day - $start_utc_day;
	$start_utc_day = $seg->start_utc_day;
	$start_tai_instant += $overlap_days * 86400 * $utc_second_length;
	die "inconsistent UTC knowledge\n"
		unless $start_tai_instant == $seg->start_tai_instant &&
			$utc_second_length == $seg->utc_second_length;
	my $length_in_tai_seconds = $end_tai_instant - $start_tai_instant;
	my $length_in_utc_seconds = $length_in_tai_seconds /
						$utc_second_length;
	my $leap_utc_seconds = $length_in_utc_seconds -
				($end_utc_day - $start_utc_day) * 86400;
	die "UTC leap too large\n"
		if abs($leap_utc_seconds) >= 60;
	$seg->{length_in_tai_seconds} = $length_in_tai_seconds;
	$seg->{length_in_utc_seconds} = $length_in_utc_seconds;
	$seg->{leap_utc_seconds} = $leap_utc_seconds;
	$seg->{last_utc_day} = $end_utc_day - 1;
	$seg->{last_day_utc_seconds} = 86400 + $seg->{leap_utc_seconds};
	$seg->{next} = $incomplete_segment = bless({
		start_utc_day => $end_utc_day,
		start_tai_instant => $end_tai_instant,
		utc_second_length => $next_utc_second_length,
		prev => $seg,
	}, "Time::UTC::Segment::Incomplete");
	bless $seg, "Time::UTC::Segment::Complete";
	foreach my $what (@{$seg->{when_complete}}) {
		eval { local $SIG{__DIE__}; $what->(); };
	}
	delete $seg->{when_complete};
}

use constant _JD_TO_MJD => Math::BigRat->new("2400000.5");

use constant _TAI_EPOCH_MJD => Math::BigRat->new(36204);

sub _add_data_from_tai_utc_dat($$) {
	my($dat, $end_mjd) = @_;
	my $seg;
	while($dat =~ /\G([^\n]*\n)/g) {
		my $line = $1;
		$line =~ /\A[\ \t]*[0-9]+[\ \t]*[A-Z]+[\ \t]*[0-9]+[\ \t]*
				=[\ \t]*
				JD[\ \t]*([0-9]+\.?[0-9]*)[\ \t]*
				TAI[\ \t]*-[\ \t]*UTC[\ \t]*=[\ \t]*
				(-?[0-9]+\.?[0-9]*)[\ \t]*S[\ \t]*
				([\+\-])[\ \t]*
				\([\ \t]*MJD[\ \t]*([\+\-])[\ \t]*
				(-?[0-9]+\.?[0-9]*)[\ \t]*\)[\ \t]*
				X[\ \t]*(-?[0-9]+\.?[0-9]*)[\ \t]*S[\ \t]*
				\n\z/xi
			or die "bad TAI-UTC data\n";
		my($start_jd, $base_difference, $tweak_sign, $base_mjd_sign,
			 $base_mjd, $day_tweak) = ($1, $2, $3, $4, $5, $6);
		my $start_mjd = Math::BigRat->new($start_jd) - _JD_TO_MJD;
		die "bad UTC segment start date" unless $start_mjd->is_int;
		$base_difference = Math::BigRat->new($base_difference);
		$base_mjd = Math::BigRat->new($base_mjd);
		$day_tweak = Math::BigRat->new($day_tweak);
		$base_mjd = -$base_mjd if $base_mjd_sign eq "+";
		$day_tweak = -$day_tweak if $tweak_sign eq "-";
		my $nseg = {
			start_utc_day => $start_mjd - _TAI_EPOCH_MJD,
			utc_second_length => 1 + $day_tweak / 86400,
		};
		$nseg->{start_tai_instant} =
			$nseg->{start_utc_day} * 86400
				+ $base_difference
				+ ($start_mjd - $base_mjd) * $day_tweak;
		if(defined $seg) {
			_add_data($seg->{start_utc_day},
				$seg->{start_tai_instant},
				$seg->{utc_second_length},
				$nseg->{start_utc_day},
				$nseg->{start_tai_instant},
				$nseg->{utc_second_length});
		}
		$seg = $nseg;
	}
	die "no TAI-UTC data\n" unless defined $seg;
	# Final segment: we have a minimal start date for the start of
	# the next real UTC segment ($end_mjd), but don't know what UTC
	# will be from that date onwards.  Consequently we don't know
	# the length of the preceding UTC day, and must knock off a day
	# from the segment that we build here.
	my $end_utc_day = $end_mjd - 1 - _TAI_EPOCH_MJD;
	if($end_utc_day > $seg->{start_utc_day}) {
		_add_data($seg->{start_utc_day},
			$seg->{start_tai_instant},
			$seg->{utc_second_length},
			$end_utc_day,
			$seg->{start_tai_instant} +
				(($end_utc_day - $seg->{start_utc_day}) *
						86400) *
					$seg->{utc_second_length},
			$seg->{utc_second_length});
	}
}

{
	my $init_dat = do { local $/ = undef; <DATA> };
	close(DATA);
	sub _use_builtin_knowledge() {
		$init_dat =~ s/^[\ \t]*[0-9]+[\ \t]*[A-Z]+[\ \t]*[0-9]+[\ \t]*
				=[\ \t]*
				JD[\ \t]*([0-9]+\.?[0-9]*)[\ \t]*
				unknown[\ \t]*\n\z//xim
			or die "broken built-in TAI-UTC data\n";
		my $end_jd = $1;
		_add_data_from_tai_utc_dat($init_dat, $end_jd - _JD_TO_MJD);
		$init_dat = undef;
	}
}

use constant _UNIX_EPOCH_MJD => Math::BigRat->new(40586);

sub _download_tai_utc_dat() {
	# Annoyingly, TAI-UTC data is not published with any
	# indicator of the extent of its future validity.
	# The IERS never says "there will be no leap second
	# until at least 2005-06-30"; the latest TAI-UTC offset
	# is always valid "until further notice".  However,
	# leap seconds are supposed to be announced at least
	# eight weeks in advance, so here we assume validity of
	# the downloaded data seven weeks into the future.
	# For this reason we only do a direct get from USNO;
	# we do not use proxies which might serve old data.
	my $unix_time = Time::Unix::time();
	my $httpresp = HTTP::Tiny->new->get(
			"http://maia.usno.navy.mil/ser7/tai-utc.dat");
	unless($httpresp->{status} == 200) {
		die "failed to download tai-utc.dat: ".
			"@{[$httpresp->{status}]} @{[$httpresp->{reason}]}\n";
	}
	use integer;
	my $now_mjd = $unix_time/86400 + _UNIX_EPOCH_MJD;
	_add_data_from_tai_utc_dat($httpresp->{content}, $now_mjd + 7*7);
}

use constant _NTP_EPOCH_MJD => Math::BigRat->new(15020);

sub _ntp_second_to_tai_day($) {
	my($ntp_sec_str) = @_;
	return Math::BigRat->new($ntp_sec_str) / 86400
		+ _NTP_EPOCH_MJD - _TAI_EPOCH_MJD;
}

use constant _BIGRAT_ONE => Math::BigRat->new(1);

sub _download_leap_seconds_list() {
	my $ftp = Net::FTP->new("utcnist2.colorado.edu")
		or die "failed to download leap-seconds.list: FTP error: $@\n";
	$ftp->login("anonymous","-anonymous\@")
		or die "failed to download leap-seconds.list: FTP error: ".
			$ftp->message;
	$ftp->binary
		or die "failed to download leap-seconds.list: FTP error: ".
			$ftp->message;
	$ftp->cwd("pub")
		or die "failed to download leap-seconds.list: FTP error: ".
			$ftp->message;
	my $ftpd = $ftp->retr("leap-seconds.list")
		or die "failed to download leap-seconds.list: FTP error: ".
			$ftp->message;
	my $list = "";
	while(1) {
		my $n = $ftpd->sysread($list, 4096, length($list));
		defined $n or die "failed to download leap-seconds.list: $!\n";
		last if $n == 0;
	}
	$ftpd->close
		or die "failed to download leap-seconds.list: FTP error: ".
			$ftp->message;
	die "malformed leap-seconds.list" unless $list =~ /\n\z/;
	$list =~ /^\#h([ \t0-9a-fA-F]+)$/m
		or die "no hash in leap-seconds.list";
	(my $hash = $1) =~ tr/A-F \t/a-f/d;
	my $data_to_hash = "";
	while($list =~ /^(?:\#[\$\@])?[ \t]*([0-9][^\#\n]*)[#\n]/mg) {
		$data_to_hash .= $1;
	}
	$data_to_hash =~ tr/0-9//cd;
	die "hash mismatch in leap-seconds.list"
		unless sha1_hex($data_to_hash) eq $hash;
	my($start_utc_day, $start_tai_instant);
	while($list =~ /^([^#\n][^\n]*)$/mg) {
		my $line = $1;
		$line =~ /\A[ \t]*([0-9]+)[ \t]+([0-9]+)[ \t]*(?:\#|\z)/
			or die "malformed data line in leap-seconds.list";
		my($next_start_ntp_sec, $ndiff) = ($1, $2);
		my $next_start_utc_day =
			_ntp_second_to_tai_day($next_start_ntp_sec);
		die "bad transition date in leap-seconds.list"
			unless $next_start_utc_day->is_int;
		my $next_start_tai_instant =
			$next_start_utc_day*86400 + Math::BigRat->new($ndiff);
		if(defined $start_utc_day) {
			_add_data($start_utc_day,
				$start_tai_instant,
				_BIGRAT_ONE,
				$next_start_utc_day,
				$next_start_tai_instant,
				_BIGRAT_ONE);
		}
		$start_utc_day = $next_start_utc_day;
		$start_tai_instant = $next_start_tai_instant;
	}
	$list =~ /^\#\@[ \t]*([0-9]+)[ \t]*$/m
		or die "no expiry date in leap-seconds.list";
	my $expsec = $1;
	my $end_utc_day = _ntp_second_to_tai_day($expsec)->bfloor - 1;
	if(defined $start_utc_day) {
		_add_data($start_utc_day,
			$start_tai_instant,
			_BIGRAT_ONE,
			$end_utc_day,
			$start_tai_instant +
				($end_utc_day - $start_utc_day) * 86400,
			_BIGRAT_ONE);
	}
}

sub _download_latest_data() {
	eval { local $SIG{__DIE__}; _download_leap_seconds_list(); 1 }
		or eval { local $SIG{__DIE__}; _download_tai_utc_dat(); 1 };
}

{
	my $last_download = 0;
	my $wait_until = 0;
	sub _maybe_download_latest_data() {
		my $time = time;
		return unless $time >= $wait_until || $time < $last_download;
		$last_download = $time;
		$wait_until = $last_download + 3600 + rand(3600);
		_download_latest_data() and
			$wait_until = $last_download + 20*86400 + rand(2*86400);
	}
}

my $try_to_extend_knowledge = \&_use_builtin_knowledge;

=head1 METHODS

=head2 Information querying

Most methods merely query the segment data.  The data are strictly
read-only.

The methods will C<die> if information is requested that is not available.
This happens when looking further ahead than UTC has been defined.
UTC is defined only a few months in advance.

All numeric values are returned as C<Math::BigRat> objects.

=over

=cut

sub _data_unavailable {
	my($self, $method) = @_;
	if(defined $try_to_extend_knowledge) {
		eval { local $SIG{__DIE__};
			my $ttek = $try_to_extend_knowledge;
			$try_to_extend_knowledge = undef;
			$ttek->();
		};
		$try_to_extend_knowledge = \&_maybe_download_latest_data;
		if(ref($self) eq "Time::UTC::Segment::Complete") {
			return $self->$method;
		}
	}
	croak "data not available yet";
}

sub _data_unavailable_method($) {
	my($method) = @_;
	return sub { $_[0]->_data_unavailable($method) };
}

=item $seg->start_tai_instant

The instant at which this segment starts, in TAI form: a C<Math::BigRat>
giving the number of TAI seconds since the TAI epoch.

=cut

sub start_tai_instant {
	$_[0]->{start_tai_instant}
}

=item $seg->end_tai_instant

The instant at which this segment ends, in TAI form: a C<Math::BigRat>
giving the number of TAI seconds since the TAI epoch.

=cut

sub Time::UTC::Segment::Complete::end_tai_instant {
	$_[0]->{next}->{start_tai_instant}
}

*Time::UTC::Segment::Incomplete::end_tai_instant =
	_data_unavailable_method("end_tai_instant");

=item $seg->length_in_tai_seconds

The duration of this segment, measured in TAI seconds, as a
C<Math::BigRat>.

=cut

sub Time::UTC::Segment::Complete::length_in_tai_seconds {
	$_[0]->{length_in_tai_seconds}
}

*Time::UTC::Segment::Incomplete::length_in_tai_seconds =
	_data_unavailable_method("length_in_tai_seconds");

=item $seg->start_utc_day

The first UTC day of this segment: a C<Math::BigInt> giving the number
of days since the TAI epoch.

=cut

sub start_utc_day {
	$_[0]->{start_utc_day}
}

=item $seg->last_utc_day

The last UTC day of this segment: a C<Math::BigInt> giving the number
of days since the TAI epoch.

=cut

sub Time::UTC::Segment::Complete::last_utc_day {
	$_[0]->{last_utc_day}
}

*Time::UTC::Segment::Incomplete::last_utc_day =
	_data_unavailable_method("last_utc_day");

=item $seg->end_utc_day

The first UTC day after the end of this segment: a C<Math::BigInt>
giving the number of days since the TAI epoch.

=cut

sub Time::UTC::Segment::Complete::end_utc_day {
	$_[0]->{next}->{start_utc_day}
}

*Time::UTC::Segment::Incomplete::end_utc_day =
	_data_unavailable_method("end_utc_day");

=item $seg->utc_second_length

The length of the UTC second in this segment, measured in TAI seconds,
as a C<Math::BigRat>.

=cut

sub utc_second_length {
	$_[0]->{utc_second_length}
}

=item $seg->leap_utc_seconds

The number of extra UTC seconds inserted at the end of the last day of
this segment, as a C<Math::BigRat>.  May be negative.

=cut

sub Time::UTC::Segment::Complete::leap_utc_seconds {
	$_[0]->{leap_utc_seconds}
}

*Time::UTC::Segment::Incomplete::leap_utc_seconds =
	_data_unavailable_method("leap_utc_seconds");

=item $seg->last_day_utc_seconds

The number of UTC seconds in the last day of this segment, as a
C<Math::BigRat>.

=cut

sub Time::UTC::Segment::Complete::last_day_utc_seconds {
	$_[0]->{last_day_utc_seconds}
}

*Time::UTC::Segment::Incomplete::last_day_utc_seconds =
	_data_unavailable_method("last_day_utc_seconds");

=item $seg->length_in_utc_seconds

The duration of this segment, measured in UTC seconds, as a
C<Math::BigRat>.

=cut

sub Time::UTC::Segment::Complete::length_in_utc_seconds {
	$_[0]->{length_in_utc_seconds}
}

*Time::UTC::Segment::Incomplete::length_in_utc_seconds =
	_data_unavailable_method("length_in_utc_seconds");

=item $seg->prev

The immediately preceding segment.  C<undef> if there is no preceding
segment, because this segment covers the start of UTC service at the
beginning of 1961.

=cut

sub prev {
	$_[0]->{prev}
}

=item $seg->next

The immediately following segment.  In the event that UTC ever becomes
fully defined, either by being defined for the entire future or by being
withdrawn altogether, there will be a final segment for which this will
be C<undef>.

=cut

sub Time::UTC::Segment::Complete::next {
	$_[0]->{next}
}

*Time::UTC::Segment::Incomplete::next = _data_unavailable_method("next");

=back

=head2 Completeness

Segments can be classified as "complete" and "incomplete".  For complete
segments, all information-querying methods give answers.  For incomplete
segments, only a few data are available: the methods C<start_tai_instant>,
C<start_utc_day>, C<utc_second_length>, and C<prev> will give correct
answers, but other methods will C<die>.

An incomplete segment can become complete, as new information becomes
available, when updated UTC data is (automatically) downloaded.  When this
happens, the resulting complete segment cannot be distinguished from
any other complete segment.

Only one incomplete segment exists at a time.

=over

=item $seg->complete_p

Returns a truth value indicating whether the segment is currently complete.

=cut

sub Time::UTC::Segment::Complete::complete_p { 1 }

sub Time::UTC::Segment::Incomplete::complete_p { 0 }

=item $seg->when_complete(WHAT)

I<WHAT> must be a reference to a function which takes no arguments.
When the segment is complete, the function will be called.  If the
segment is already complete then the function is called immediately;
otherwise the function is noted and will be called when the segment
becomes complete due to the availability of new information.

This is a one-shot operation.  To do something similar for all segments,
see C<foreach_utc_segment_when_complete> in C<Time::UTC>.

=cut

sub Time::UTC::Segment::Complete::when_complete {
	my($self, $what) = @_;
	eval { local $SIG{__DIE__}; $what->(); };
}

sub Time::UTC::Segment::Incomplete::when_complete {
	my($self, $what) = @_;
	push @{$self->{when_complete}}, $what;
}

=back

=head1 INVARIANTS

The following relations hold for all segments:

	$seg->length_in_tai_seconds ==
		$seg->end_tai_instant - $seg->start_tai_instant

	$seg->last_utc_day + 1 == $seg->end_utc_day

	$seg->last_day_utc_seconds == 86400 + $seg->leap_utc_seconds

	$seg->length_in_utc_seconds ==
		86400 * ($seg->last_utc_day - $seg->start_utc_day) +
			$seg->last_day_utc_seconds

	$seg->length_in_tai_seconds ==
		$seg->length_in_utc_seconds * $seg->utc_second_length

	$seg->next->prev == $seg

	$seg->end_tai_instant == $seg->next->start_tai_instant

	$seg->end_utc_day == $seg->next->start_utc_day

=head1 SEE ALSO

L<Time::UTC>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2005, 2006, 2007, 2009, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__
1961 JAN  1 =JD 2437300.5  TAI-UTC=   1.4228180 S + (MJD - 37300.) X 0.001296 S
1961 AUG  1 =JD 2437512.5  TAI-UTC=   1.3728180 S + (MJD - 37300.) X 0.001296 S
1962 JAN  1 =JD 2437665.5  TAI-UTC=   1.8458580 S + (MJD - 37665.) X 0.0011232S
1963 NOV  1 =JD 2438334.5  TAI-UTC=   1.9458580 S + (MJD - 37665.) X 0.0011232S
1964 JAN  1 =JD 2438395.5  TAI-UTC=   3.2401300 S + (MJD - 38761.) X 0.001296 S
1964 APR  1 =JD 2438486.5  TAI-UTC=   3.3401300 S + (MJD - 38761.) X 0.001296 S
1964 SEP  1 =JD 2438639.5  TAI-UTC=   3.4401300 S + (MJD - 38761.) X 0.001296 S
1965 JAN  1 =JD 2438761.5  TAI-UTC=   3.5401300 S + (MJD - 38761.) X 0.001296 S
1965 MAR  1 =JD 2438820.5  TAI-UTC=   3.6401300 S + (MJD - 38761.) X 0.001296 S
1965 JUL  1 =JD 2438942.5  TAI-UTC=   3.7401300 S + (MJD - 38761.) X 0.001296 S
1965 SEP  1 =JD 2439004.5  TAI-UTC=   3.8401300 S + (MJD - 38761.) X 0.001296 S
1966 JAN  1 =JD 2439126.5  TAI-UTC=   4.3131700 S + (MJD - 39126.) X 0.002592 S
1968 FEB  1 =JD 2439887.5  TAI-UTC=   4.2131700 S + (MJD - 39126.) X 0.002592 S
1972 JAN  1 =JD 2441317.5  TAI-UTC=  10.0       S + (MJD - 41317.) X 0.0      S
1972 JUL  1 =JD 2441499.5  TAI-UTC=  11.0       S + (MJD - 41317.) X 0.0      S
1973 JAN  1 =JD 2441683.5  TAI-UTC=  12.0       S + (MJD - 41317.) X 0.0      S
1974 JAN  1 =JD 2442048.5  TAI-UTC=  13.0       S + (MJD - 41317.) X 0.0      S
1975 JAN  1 =JD 2442413.5  TAI-UTC=  14.0       S + (MJD - 41317.) X 0.0      S
1976 JAN  1 =JD 2442778.5  TAI-UTC=  15.0       S + (MJD - 41317.) X 0.0      S
1977 JAN  1 =JD 2443144.5  TAI-UTC=  16.0       S + (MJD - 41317.) X 0.0      S
1978 JAN  1 =JD 2443509.5  TAI-UTC=  17.0       S + (MJD - 41317.) X 0.0      S
1979 JAN  1 =JD 2443874.5  TAI-UTC=  18.0       S + (MJD - 41317.) X 0.0      S
1980 JAN  1 =JD 2444239.5  TAI-UTC=  19.0       S + (MJD - 41317.) X 0.0      S
1981 JUL  1 =JD 2444786.5  TAI-UTC=  20.0       S + (MJD - 41317.) X 0.0      S
1982 JUL  1 =JD 2445151.5  TAI-UTC=  21.0       S + (MJD - 41317.) X 0.0      S
1983 JUL  1 =JD 2445516.5  TAI-UTC=  22.0       S + (MJD - 41317.) X 0.0      S
1985 JUL  1 =JD 2446247.5  TAI-UTC=  23.0       S + (MJD - 41317.) X 0.0      S
1988 JAN  1 =JD 2447161.5  TAI-UTC=  24.0       S + (MJD - 41317.) X 0.0      S
1990 JAN  1 =JD 2447892.5  TAI-UTC=  25.0       S + (MJD - 41317.) X 0.0      S
1991 JAN  1 =JD 2448257.5  TAI-UTC=  26.0       S + (MJD - 41317.) X 0.0      S
1992 JUL  1 =JD 2448804.5  TAI-UTC=  27.0       S + (MJD - 41317.) X 0.0      S
1993 JUL  1 =JD 2449169.5  TAI-UTC=  28.0       S + (MJD - 41317.) X 0.0      S
1994 JUL  1 =JD 2449534.5  TAI-UTC=  29.0       S + (MJD - 41317.) X 0.0      S
1996 JAN  1 =JD 2450083.5  TAI-UTC=  30.0       S + (MJD - 41317.) X 0.0      S
1997 JUL  1 =JD 2450630.5  TAI-UTC=  31.0       S + (MJD - 41317.) X 0.0      S
1999 JAN  1 =JD 2451179.5  TAI-UTC=  32.0       S + (MJD - 41317.) X 0.0      S
2006 JAN  1 =JD 2453736.5  TAI-UTC=  33.0       S + (MJD - 41317.) X 0.0      S
2009 JAN  1 =JD 2454832.5  TAI-UTC=  34.0       S + (MJD - 41317.) X 0.0      S
2012 JUL  1 =JD 2456109.5  TAI-UTC=  35.0       S + (MJD - 41317.) X 0.0      S
2013 JAN  1 =JD 2456293.5  unknown
