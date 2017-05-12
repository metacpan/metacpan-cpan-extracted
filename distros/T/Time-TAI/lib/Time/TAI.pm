=head1 NAME

Time::TAI - International Atomic Time and realisations

=head1 SYNOPSIS

	use Time::TAI qw(tai_instant_to_mjd tai_mjd_to_instant);

	$mjd = tai_instant_to_mjd($instant);
	$instant = tai_mjd_to_instant($mjd);

	use Time::TAI qw(tai_realisation);

	$rln = tai_realisation("npl");
	$instant = $rln->to_tai($npl_instant);

=head1 DESCRIPTION

International Atomic Time (TAI) is a time scale produced by an ensemble
of atomic clocks around Terra.  It attempts to tick at the rate of proper
time on the Terran geoid (i.e., at sea level), and thus is the principal
realisation of Terrestrial Time (TT).  It is the frequency standard
underlying Coordinated Universal Time (UTC), and so is indirectly the
basis for Terran civil timekeeping.

This module represents instants on the TAI time scale as a scalar number
of TAI seconds since an epoch.  This is an appropriate form for all manner
of calculations.  The TAI scale is defined with a well-known point at UT2
instant 1958-01-01T00:00:00.0 as calculated by the United States Naval
Observatory.  That instant is assigned the scalar value zero exactly,
making it the epoch for this linear seconds count.  This matches the
convention used by C<Time::TT> for instants on the TT scale.

There is also a conventional way to represent TAI instants using day-based
notations associated with planetary rotation `time' scales.  The `day'
of TAI is a nominal period of exactly 86400 TAI seconds, which is
slightly shorter than an actual Terran day.  The well-known point at UT2
instant 1958-01-01T00:00:00.0 is assigned the label 1958-01-01T00:00:00.0
(MJD 36204.0).  Because TAI is not connected to Terran rotation, and so
has no inherent concept of a day, it is somewhat misleading to use such
day-based notations.  Conversion between this notation and the linear
count of seconds is supported by this module.  This notation does not
match the similar day-based notation used for TT.

Because TAI is canonically defined only in retrospect, real-time time
signals can only approximate it.  To achieve microsecond accuracy it
is necessary to take account of this process.  This module supports
conversion of times between different realisations of TAI.

=cut

package Time::TAI;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Math::BigRat 0.04;

our $VERSION = "0.003";

use parent "Exporter";
our @EXPORT_OK = qw(tai_instant_to_mjd tai_mjd_to_instant tai_realisation);

=head1 FUNCTIONS

=over

=item tai_instant_to_mjd(INSTANT)

Converts from a count of seconds to a Modified Julian Date in the manner
conventional for TAI.  The MJD can be further converted to other forms of
day-based date using other modules.  The input must be a C<Math::BigRat>
object, and the result is the same type.

=cut

use constant TAI_EPOCH_MJD => Math::BigRat->new(36204);

sub tai_instant_to_mjd($) {
	my($tai) = @_;
	return TAI_EPOCH_MJD + ($tai / 86400);
}

=item tai_mjd_to_instant(MJD)

Converts from a Modified Julian Date, interpreted in the manner
conventional for TAI, to a count of seconds.  The input must be a
C<Math::BigRat> object, and the result is the same type.

=cut

sub tai_mjd_to_instant($) {
	my($mjd) = @_;
	return ($mjd - TAI_EPOCH_MJD) * 86400;
}

=item tai_realisation(NAME)

Looks up and returns an object representing a named realisation of TAI.
The object returned is of the class C<Time::TT::Realisation>; see the
documentation of that class for its interface.

The name, recognised case-insensitively, may be of these forms:

=over

=item "" (the empty string)

TAI itself, as defined retrospectively.

=item B<npl>

TAI(NPL), supplied in real time by the National Physical Laboratory in
the UK.  Other real-time estimates of TAI are named similarly using an
abbreviation of the name of the supplying agency.  The names recognised
are:

    aos   cnm   ftz   inti  lt    nimb  nrc   pknm  smu   tug
    apl   cnmp  glo   ipq   lv    nimt  nrl   pl    snt   ua
    asmw  crl   gps   it    mike  nis   nrlm  psb   so    ume
    aus   csao  gum   jatc  mkeh  nist  ntsc  ptb   sp    usno
    bev   csir  hko   jv    msl   nmc   omh   rc    sta   vmi
    bim   dlr   ien   kim   nao   nmij  onba  roa   su    vsl
    birm  dmdm  ifag  kris  naom  nml   onrj  scl   tao   yuzm
    by    dpt   igma  ksri  naot  nmls  op    sg    tcc   za
    cao   dtag  igna  kz    nict  npl   orb   siq   tl    zipe
    ch    eim   inpl  lds   nim   npli  pel   smd   tp    zmdm

See L<Time::TT::Agencies> for expansions of these abbreviations.

Some pairs of these names refer to the same time scale, due to renaming
of the underlying agency or transfer of responsibility for a time scale.
It is possible that some names that should be aliases are treated
as separate time scales, due to uncertainty of this module's author;
see L</BUGS>.

The relationships between these scales and TAI are defined by isolated
data points, so conversions in general involve interpolation.  The process
is by its nature inexact.

=back

Other names may be recognised in the future, as more TAI(k) time scales
are defined.

=cut

#
# general
#

use constant MJD_1990_01 => 47892;
use constant MJD_1991_01 => 48257;
use constant MJD_1992_01 => 48622;
use constant MJD_1993_01 => 48988;
use constant MJD_1994_01 => 49353;
use constant MJD_1995_01 => 49718;
use constant MJD_1996_01 => 50083;
use constant MJD_1997_01 => 50449;
use constant MJD_1998_01 => 50814;
use constant MJD_1999_01 => 51179;
use constant MJD_2000_01 => 51544;
use constant MJD_2001_01 => 51910;
use constant MJD_2001_07 => 52091;
use constant MJD_2002_01 => 52275;
use constant MJD_2003_01 => 52640;
use constant MJD_2003_04 => 52730;
use constant MJD_2004_01 => 53005;
use constant MJD_2005_01 => 53371;

use constant UTC_1989_07 => Math::BigRat->new( 993945624);
use constant UTC_1990_07 => Math::BigRat->new(1025481625);
use constant UTC_1991_07 => Math::BigRat->new(1057017626);
use constant UTC_1992_07 => Math::BigRat->new(1088640027);
use constant UTC_1993_07 => Math::BigRat->new(1120176028);
use constant UTC_1994_07 => Math::BigRat->new(1151712029);
use constant UTC_1995_07 => Math::BigRat->new(1183248029);
use constant UTC_1996_07 => Math::BigRat->new(1214870430);
use constant UTC_1997_07 => Math::BigRat->new(1246406431);
use constant UTC_1998_07 => Math::BigRat->new(1277942431);
use constant UTC_1999_07 => Math::BigRat->new(1309478432);
use constant UTC_2000_07 => Math::BigRat->new(1341100832);
use constant UTC_2001_07 => Math::BigRat->new(1372636832);
use constant UTC_2002_07 => Math::BigRat->new(1404172832);
use constant UTC_2003_02 => Math::BigRat->new(1422748832);
use constant UTC_2003_07 => Math::BigRat->new(1435708832);
use constant UTC_2004_07 => Math::BigRat->new(1467331232);
use constant UTC_2005_07 => Math::BigRat->new(1498867232);

sub _get_bipm_file($) {
	my($fn) = @_;
	require LWP;
	LWP->VERSION(5.53_94);
	require LWP::UserAgent;
	my $response = LWP::UserAgent->new
				->get("ftp://ftp2.bipm.fr/pub/tai/$fn");
	croak "can't download $fn: ".$response->message
		unless $response->code == 200;
	return $response->content;
}

my $nl_rx = qr/\r?\n(?:\ *\r?\n)*/;

#
# UTC(k) data from utc-* files
#

sub _parse_utck_file($$$) {
	my($content, $min_mjd, $max_mjd) = @_;
	$content =~ /\A\ *MJD\ +\[UTC-UTC\([A-Z]+\ *\)\]\/ns
		     (?:\ [^\n]*)?${nl_rx}
		     (?>\ *[0-9]+\ +(?:-|-?[0-9]+(?:\.[0-9]+)?)
		     (?:\ [^\n]*)?${nl_rx})*
		     \x{1a}?\z/xo
		or die "doesn't look like a UTC-UTC(k) file\n";
	require Time::TT::OffsetKnot;
	Time::TT::OffsetKnot->VERSION(0.004);
	my @data;
	my $last_mjd = 0;
	my $last_nonzero_mjd = 0;
	my $consecutive_zeroes = 0;
	while($content =~ /^\ *([0-9]+)\ +([-+]?[0-9]+(?:\.[0-9]+)?)
				[\ \r\n]/xmg) {
		my($mjd, $offset_ns) = ($1, $2);
		die "data out of order at mjd=$mjd" unless $mjd > $last_mjd;
		$last_mjd = $mjd;
		next unless $mjd >= $min_mjd &&
				(!defined($max_mjd) || $mjd < $max_mjd);
		push @data, Time::TT::OffsetKnot->new($mjd, $offset_ns, 9);
		if($offset_ns =~ /\A-?0+(?:\.0+)?\z/) {
			$consecutive_zeroes++;
		} else {
			$consecutive_zeroes = 0;
			$last_nonzero_mjd = $last_mjd;
		}
	}
	# A couple of files have been seen with lots of bogus zero entries
	# at the end.
	splice @data, -$consecutive_zeroes if $consecutive_zeroes != 0;
	return (\@data, $last_nonzero_mjd);
}

sub _utck_file_source($$$;$);
sub _utck_file_source($$$;$) {
	my($k, $rep_date, $min_mjd, $rpt) = @_;
	my $max_mjd;
	if(!defined($rpt)) {
		$rpt = { last_downloaded => 0, wait_until => 0 };
	} elsif(ref($rpt) eq "") {
		$max_mjd = $rpt;
		$rpt = undef;
	}
	require Math::Interpolator::Source;
	return Math::Interpolator::Source->new(
		sub () {
			if(defined $rpt) {
				my $time = time;
				croak "no more data for TT(TAI(".uc($k).
						")) available"
					unless $time >= $rpt->{wait_until} ||
					       $time < $rpt->{last_downloaded};
				$rpt->{last_downloaded} = $time;
				$rpt->{wait_until} =
					$time + 86400 + rand(86400);
			}
			my($data, $last_mjd) =
				_parse_utck_file(
					_get_bipm_file("publication/utc-$k"),
					$min_mjd, $max_mjd);
			croak "no more data for TT(TAI(".uc($k).")) available"
				unless @$data;
			push @$data, _utck_file_source($k,
					$data->[-1]->x + 1000000,
					$last_mjd + 1, $rpt)
				if defined $rpt;
			return $data;
		},
		$rep_date, $rep_date);
}

#
# UTC(k) data from utc.?? and utc??.ar files
#

sub _parse_utcyr_file($$$) {
	my($content, $min_mjd, $max_mjd) = @_;
	$content =~ /\A\ *Values\ of\ UTC-UTC\(laboratory\)\ for
		     (?>[^\n]+\n)+\n
		     ((?>(?>\ {5}(?:\ {4}[A-Z\ ]{4}){8}\n)+))
		     (?>[0-9]{5}
			(?:[\ \-\+][\ \-\+0-9]{3}\.(?:[0-9]{3}|0\ \ )
			  |\ {8}){8}\n)+
		     \z/x
		or die "doesn't look like a bulk UTC-UTC(k) file\n";
	my @labs = map { [ map { lc } split ] } split(/\n/, $1);
	require Time::TT::OffsetKnot;
	Time::TT::OffsetKnot->VERSION(0.004);
	my %data;
	$content =~ /\n\n/g;
	my $last_mjd = 0;
	while($content =~ /^([0-9]{5})(.{64})\n/msg) {
		my($mjd, $numbers) = ($1, $2);
		die "data out of order at mjd=$mjd" unless $mjd > $last_mjd;
		$last_mjd = $mjd;
		for(my $line = 0; $line != @labs; $line++) {
			unless($line == 0) {
				$content =~ /^([0-9]{5})(.{64})\n/msg
					or die "incomplete data group\n";
				($mjd, $numbers) = ($1, $2);
				die "inconsistent data group\n"
					unless $mjd eq $last_mjd;
			}
			next unless $mjd >= $min_mjd && $mjd < $max_mjd;
			for(my $i = 0; $i != 8; $i++) {
				my $num = substr($numbers, 8*$i, 8);
				my $lab = $labs[$line]->[$i];
				if(!defined($lab)) {
					die "extraneous data\n"
						unless $num eq "        ";
					next;
				}
				next if $num eq "   0.0  ";
				die "malformed number\n"
					unless $num =~ /\A\ *([-+]?[0-9]+
							\.[0-9]+)\z/x;
				push @{$data{$lab}},
					Time::TT::OffsetKnot
						->new($last_mjd, $1, 6);
			}
		}
	}
	return \%data;
}

sub _parse_utcyrar_file($$$) {
	my($content, $min_mjd, $max_mjd) = @_;
	$content =~ /\A[\ \t\n]*[^\n]*\ local\ representations\ of\ utc[\ :].*
		     [\ \t\n]unit\ is\ one\ (micr|nan)osecond\./xsi
		or die "doesn't look like a bulk UTC-UTC(k) file\n";
	my $unit = $1 =~ /\Amicr\z/i ? 6 : 9;
	require Time::TT::OffsetKnot;
	Time::TT::OffsetKnot->VERSION(0.004);
	my %data;
	my @labs;
	while($content =~ /^\ *0h\ UTC((?:\ +[A-Z]{1,4})+)\ *[\r\n]
			  |^\ *[A-Z][a-z]{2}\ +[0-9]+\ +([0-9]+)
			   ((?:\ +(?:-|[-+]?[0-9]+(?:\.[0-9]+)?))+)
			   \ *[\r\n]/xmg) {
		my($labs, $mjd, $offsets) = ($1, $2, $3);
		if(defined $labs) {
			@labs = map { lc } split(" ", $labs);
			foreach my $lab (@labs) {
				next if exists $data{$lab};
				$data{$lab} = {
					last_mjd => 0,
					points => [],
				};
			}
			next;
		}
		die "data without heading\n" unless @labs;
		next unless $mjd >= $min_mjd && $mjd < $max_mjd;
		my @offsets = split(" ", $offsets);
		die "malformed table\n" unless @offsets == @labs;
		for(my $i = @labs; $i--; ) {
			my $lab = $labs[$i];
			unless($mjd > $data{$lab}->{last_mjd}) {
				# there is a repeated table in utc98.ar
				next if $data{$lab}->{last_mjd} == 50994;
				die "data out of order at mjd=$mjd";
			}
			$data{$lab}->{last_mjd} = $mjd;
			my $offset = $offsets[$i];
			push @{$data{$lab}->{points}},
				Time::TT::OffsetKnot->new($mjd, $offset, $unit)
					unless $offset eq "-";
		}
	}
	foreach my $lab (keys %data) {
		$data{$lab} = $data{$lab}->{points};
	}
	return \%data;
}

#
# UTC(GPS) & UTC(GLO) data from utcg(ps|lo)??.ar files
#

sub _parse_gpsyr_file($$$) {
	my($content, $min_mjd, $max_mjd) = @_;
	$content =~ /\A[\ \t\n]*[^\n]*
			\[\ *(?:tai|utc)\ *-\ *(?:gps|glonass)\ time\]/xi
		or die "doesn't look like a GPS file\n";
	my $unit = $content =~ /\(Unit is one microsecond\)/ ? 6 : 9;
	require Time::TT::OffsetKnot;
	Time::TT::OffsetKnot->VERSION(0.004);
	my @data;
	my $last_mjd = 0;
	# in some cases adjacent data lines are separated by a large number
	# of spaces instead of by a newline character
	while($content =~ /(?:^|\ {30})\ *[A-Z][a-z]{2}\ +[0-9]+\ +([0-9]+)
			   \ +([-+]?[0-9]+(?:\.[0-9]+)?)
			   (?:\ +(?:-|[-+]?[0-9]+(?:\.[0-9]+)?)){1,2}
			   (?:\ *[\r\n]|\ {30})/xmg) {
		my($mjd, $offset) = ($1, $2);
		unless($mjd > $last_mjd) {
			# there are two data for one day in utcgps94.ar
			# (they give different C0 values, no idea which is
			# better)
			next if $mjd == 49709;
			die "data out of order at mjd=$mjd";
		}
		$last_mjd = $mjd;
		next unless $mjd >= $min_mjd && $mjd < $max_mjd;
		push @data, Time::TT::OffsetKnot->new($mjd, $offset, $unit);
	}
	return \@data;
}

my %gpsyr_year = (
	"93" => {
		min_mjd => MJD_1993_01, max_mjd => MJD_1994_01,
		rep_date => UTC_1993_07,
	},
	"94" => {
		min_mjd => MJD_1994_01, max_mjd => MJD_1995_01,
		rep_date => UTC_1994_07,
	},
	"95" => {
		min_mjd => MJD_1995_01, max_mjd => MJD_1996_01,
		rep_date => UTC_1995_07,
	},
	"96" => {
		min_mjd => MJD_1996_01, max_mjd => MJD_1997_01,
		rep_date => UTC_1996_07,
	},
	"97" => {
		min_mjd => MJD_1997_01, max_mjd => MJD_1998_01,
		rep_date => UTC_1997_07,
	},
	"98" => {
		min_mjd => MJD_1998_01, max_mjd => MJD_1999_01,
		rep_date => UTC_1998_07,
	},
	"99" => {
		min_mjd => MJD_1999_01, max_mjd => MJD_2000_01,
		rep_date => UTC_1999_07,
	},
	"00" => {
		min_mjd => MJD_2000_01, max_mjd => MJD_2001_01,
		rep_date => UTC_2000_07,
	},
	"01" => {
		min_mjd => MJD_2001_01, max_mjd => MJD_2002_01,
		rep_date => UTC_2001_07,
	},
	"02" => {
		min_mjd => MJD_2002_01, max_mjd => MJD_2003_01,
		rep_date => UTC_2002_07,
	},
	"03" => {
		min_mjd => MJD_2003_01, max_mjd => MJD_2003_04,
		rep_date => UTC_2003_02,
	},
);

sub _gpsyr_file_source($$) {
	my($k, $yr) = @_;
	my $year = $gpsyr_year{$yr};
	die "GPS-style data requested for unknown year `$yr'"
		unless defined $year;
	require Math::Interpolator::Source;
	return Math::Interpolator::Source->new(
		sub () {
			return _parse_gpsyr_file(
					_get_bipm_file("scale/utc$k$yr.ar"),
					$year->{min_mjd}, $year->{max_mjd});
		},
		$year->{rep_date}, $year->{rep_date});
}

#
# UTC(GPS) & UTC(GLO) data from utcgpsglo??.ar files
#

sub _parse_gpsgloyr_file($$$) {
	my($content, $min_mjd, $max_mjd) = @_;
	$content =~ /\A[\ \t\n]*Relations\ of\ UTC\ and\ TAI\ with
		     \ GPS\ time\ and\ GLONASS\ time[\ \t\n]/x
		or die "doesn't look like a GPS/GLONASS file\n";
	require Time::TT::OffsetKnot;
	Time::TT::OffsetKnot->VERSION(0.004);
	my(@gps, @glo);
	my $last_mjd = 0;
	while($content =~ /^\ *[A-Z]{3}\ +[0-9]+\ +([0-9]+)
			   \ +(-|[-+]?[0-9]+(?:\.[0-9]+)?)\ +[0-9]+
			   \ +(-|[-+]?[0-9]+(?:\.[0-9]+)?)\ +[0-9]+
			   \ *[\r\n]/xmg) {
		my($mjd, $gps_offset_ns, $glo_offset_ns) = ($1, $2, $3);
		die "data out of order at mjd=$mjd" unless $mjd > $last_mjd;
		$last_mjd = $mjd;
		next unless $mjd >= $min_mjd && $mjd < $max_mjd;
		push @gps, Time::TT::OffsetKnot->new($mjd, $gps_offset_ns, 9)
			unless $gps_offset_ns eq "-";
		push @glo, Time::TT::OffsetKnot->new($mjd, $glo_offset_ns, 9)
			unless $glo_offset_ns eq "-";
	}
	return { gps => \@gps, glo => \@glo };
}

#
# mechanism for multi-scale files
#

my %multiscale = (
	u90 => {
		filename => "scale/utc.90",
		parser => \&_parse_utcyr_file,
		min_mjd => MJD_1990_01, max_mjd => MJD_1991_01,
		rep_date => UTC_1990_07,
	},
	u91 => {
		filename => "scale/utc.91",
		parser => \&_parse_utcyr_file,
		min_mjd => MJD_1991_01, max_mjd => MJD_1992_01,
		rep_date => UTC_1991_07,
	},
	u92 => {
		filename => "scale/utc.92",
		parser => \&_parse_utcyr_file,
		min_mjd => MJD_1992_01, max_mjd => MJD_1993_01,
		rep_date => UTC_1992_07,
	},
	u93 => {
		filename => "scale/utc93.ar",
		parser => \&_parse_utcyrar_file,
		min_mjd => MJD_1993_01, max_mjd => MJD_1994_01,
		rep_date => UTC_1993_07,
	},
	u94 => {
		filename => "scale/utc94.ar",
		parser => \&_parse_utcyrar_file,
		min_mjd => MJD_1994_01, max_mjd => MJD_1995_01,
		rep_date => UTC_1994_07,
	},
	u95 => {
		filename => "scale/utc95.ar",
		parser => \&_parse_utcyrar_file,
		min_mjd => MJD_1995_01, max_mjd => MJD_1996_01,
		rep_date => UTC_1995_07,
	},
	u96 => {
		filename => "scale/utc96.ar",
		parser => \&_parse_utcyrar_file,
		min_mjd => MJD_1996_01, max_mjd => MJD_1997_01,
		rep_date => UTC_1996_07,
	},
	u97 => {
		filename => "scale/utc97.ar",
		parser => \&_parse_utcyrar_file,
		min_mjd => MJD_1997_01, max_mjd => MJD_1998_01,
		rep_date => UTC_1997_07,
	},
	u98 => {
		filename => "scale/utc98.ar",
		parser => \&_parse_utcyrar_file,
		min_mjd => MJD_1998_01, max_mjd => MJD_1999_01,
		rep_date => UTC_1998_07,
	},
	gg03 => {
		filename => "scale/utcgpsglo03.ar",
		parser => \&_parse_gpsgloyr_file,
		min_mjd => MJD_2003_04, max_mjd => MJD_2004_01,
		rep_date => UTC_2003_07,
	},
	gg04 => {
		filename => "scale/utcgpsglo04.ar",
		parser => \&_parse_gpsgloyr_file,
		min_mjd => MJD_2004_01, max_mjd => MJD_2005_01,
		rep_date => UTC_2004_07,
	},
);

sub _multiscale_source($$) {
	my($k, $source) = @_;
	my $metadata = $multiscale{$source};
	die "multi-scale data requsted from unknown source `$source'\n"
		unless defined $metadata;
	require Math::Interpolator::Source;
	return Math::Interpolator::Source->new(
		sub () {
			my $data = $metadata->{data};
			unless(defined $data) {
				$data = $metadata->{parser}->(
					_get_bipm_file($metadata->{filename}),
					$metadata->{min_mjd},
					$metadata->{max_mjd});
				$metadata->{data} = $data;
			}
			return $data->{$k} || [];
		},
		$metadata->{rep_date}, $metadata->{rep_date});
}

#
# permanently-broken sources to represent missing data
#

sub _bad_start_source($) {
	my($k) = @_;
	$k = uc($k);
	require Math::Interpolator::Source;
	return Math::Interpolator::Source->new(
		sub () {
			croak "earlier data for TT(TAI($k)) is missing";
		},
		UTC_1989_07, UTC_1989_07);
}

sub _bad_end_source($) {
	my($k) = @_;
	$k = uc($k);
	require Math::Interpolator::Source;
	return Math::Interpolator::Source->new(
		sub () {
			croak "later data for TT(TAI($k)) is missing";
		},
		UTC_2005_07, UTC_2005_07);
}

#
# overall structure of realisations
#

#
# These recipes detail where to find data on each time scale.  This is
# necessary because the data are split up between several files, and
# there are redundancies and renamings.  The recipe string contains the
# following items:
#
# "u90".."u98": utc.?? and utc??.ar files, which each contain data on
#               many UTC(k) time scales for a single year
# "u": utc-* files, which each contain data on a single time scale
#      from 1998 onwards
# "u*gum": special case: utc-gum has data only up to 2001-07
# "u*pl": special case: utc-pl has data from 2001-07 onwards
# "g93".."g03": utcg(ps|lo)??.ar files, which each contain data on either
#               GPS or GLONASS for a single year
# "gg03".."gg04": utcgpsglo??.ar files, which each contain GPS and GLONASS
#                 data for a single year
# "<": data missing at start
# ">": data missing at end
# ":dtag": change of name
# "!": following data source has only blanks for this scale
# "?": following data source has only redundant data for this scale
#
# or the recipe may consist entirely of:
#
# "=dtag": alias of referenced scale
# "*tai": special case for TAI itself
#

my %realisation = (
	""   => "*tai",
	# not a real realisation: amc  => "!u",
	aos  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	apl  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	asmw => "< u90 >",
	aus  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	bev  => "< u90 u91 u92 u93 u94 u95 u96 !u97 ?u98 u",
	bim  => "< :nmc u91 u92 u93 !u94 ?u :bim u",
	birm => "u95 u96 u97 ?u98 u",
	by   => "u",
	cao  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	ch   => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	cnm  => "u96 u97 ?u98 u",
	cnmp => "u",
	crl  => "=nict",
	csao => "=ntsc",
	csir => "=za",
	dlr  => "u96 u97 ?u98 u",
	dmdm => "u",
	dpt  => "=za",
	dtag => "< :ftz u90 u91 u92 u93 u94 u95 :dtag u96 u97 ?u98 u",
	eim  => "u",
	ftz  => "=dtag",
	glo  => "< g93 g94 g95 g96 g97 g98 g99 g00 g01 g02 g03 gg03 gg04 >",
	gps  => "< g93 g94 g95 g96 g97 g98 g99 g00 g01 g02 g03 gg03 gg04 >",
	gum  => "=pl",
	hko  => "u",
	ien  => "=it",
	ifag => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	igma => "=igna",
	igna => "< :igma u90 u91 u92 u93 u94 u95 u96 u97 ?u98 :igna u",
	inpl => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	inti => "u",
	ipq  => "u95 u96 u97 ?u98 u",
	it   => "< :ien u90 u91 u92 u93 u94 u95 u96 u97 ?u98 ?u :it u",
	jatc => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	jv   => "u",
	kim  => "u",
	kris => "< :ksri u90 :kris u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	ksri => "=kris",
	kz   => "u",
	lds  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	lt   => "u",
	lv   => "u",
	mike => "u",
	mkeh => "< :omh u90 u91 u92 u93 u94 u95 u96 u97 ?u98 ?u :mkeh u",
	msl  => "< :pel u90 u91 :msl u92 u93 u94 u95 u96 u97 ?u98 u",
	nao  => "< :naom u90 u91 u92 u93 u94 u95 u96 :nao u97 ?u98 u",
	naom => "=nao",
	naot => "< u92 u93 u94 u95 u96 >",
	nict => "< :crl u90 u91 u92 u93 u94 u95 u96 u97 ?u98 ?u :nict u",
	nim  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	nimb => "u",
	nimt => "u",
	nis  => "u",
	nist => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	nmc  => "=bim",
	nmij => "< :nrlm u90 u91 u92 u93 u94 u95 u96 u97 ?u98 ?u :nmij u",
	nml  => "u97 u98",
	nmls => "u",
	npl  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	npli => "< u90 u91 u92 u93 u94 !u95 !u96 ?u98 u",
	nrc  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	nrl  => "u",
	nrlm => "=nmij",
	ntsc => "< :csao u90 u91 u92 u93 u94 u95 u96 u97 ?u98 ?u :ntsc u",
	omh  => "=mkeh",
	onba => "< u92 u93 u94 u95 u96 u97 ?u98 u",
	onrj => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	op   => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	orb  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	pel  => "=msl",
	pknm => "=pl",
	pl   => "< :pknm u90 u91 u92 u93 :gum u94 u95 u96 u97 ?u98 u*gum :pl u*pl",
	psb  => "=sg",
	ptb  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	rc   => "< u90 u91 u92 u93 u94 u95 u96 >",
	roa  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	scl  => "< u92 u93 u94 u95 u96 u97 ?u98 u",
	sg   => ":psb u97 ?u98 ?u :sg u",
	siq  => "u",
	smd  => "u",
	smu  => "?u98 u",
	snt  => "< u91 u92 u93 u94 u95 >",
	so   => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	sp   => "u96 u97 ?u98 u",
	sta  => "< u90 >",
	su   => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	tao  => "< u90 u91 >",
	tcc  => "u",
	tl   => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	tp   => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	tug  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	ua   => "u",
	ume  => "u94 u95 u96 u97 ?u98 u",
	usno => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	vmi  => "u",
	vsl  => "< u90 u91 u92 u93 u94 u95 u96 u97 ?u98 u",
	yuzm => "< u90 u91 !u92 >",
	za   => "< :dpt u90 u91 u92 :csir u93 u94 u95 u96 u97 ?u98 ?u :za u",
	zipe => "< u90 u91 >",
	zmdm => "=dmdm",
);

sub tai_realisation($);
sub tai_realisation($) {
	my($name) = @_;
	$name = lc($name);
	my $r = $realisation{$name};
	croak "no realisation TT(TAI(".uc($name).")) known" unless defined $r;
	if(ref($r) eq "") {
		if($r =~ /\A=([a-z]+)\z/) {
			$r = tai_realisation($1);
		} elsif($r eq "*tai") {
			require Time::TAI::Realisation_TAI;
			$r = Time::TAI::Realisation_TAI->new;
		} else {
			my @parts;
			my $k = $name;
			foreach my $ingredient (split(/ /, $r)) {
				if($ingredient =~ /\A[!?]/) {
					# ignore this data
				} elsif($ingredient =~
						/\A(?:u|gg)[0-9][0-9]\z/) {
					push @parts, _multiscale_source($k,
						$ingredient);
				} elsif($ingredient eq "u") {
					push @parts, _utck_file_source($k,
						UTC_1998_07, MJD_1998_01);
				} elsif($ingredient eq "u*gum") {
					push @parts, _utck_file_source($k,
						UTC_1998_07,
						MJD_1998_01, MJD_2001_07),
				} elsif($ingredient eq "u*pl") {
					push @parts, _utck_file_source($k,
						UTC_2002_07, MJD_2001_07);
				} elsif($ingredient =~ /\Ag([0-9][0-9])\z/) {
					push @parts,
						_gpsyr_file_source($k, $1);
				} elsif($ingredient eq "<") {
					push @parts, _bad_start_source($k);
				} elsif($ingredient eq ">") {
					push @parts, _bad_end_source($k);
				} elsif($ingredient =~ /\A:([a-z]+)\z/) {
					$k = $1;
				} else {
					die "unrecognised ingredient ".
						"`$ingredient'";
				}
			}
			require Math::Interpolator::Robust;
			$r = Math::Interpolator::Robust->new(@parts);
			require Time::TT::InterpolatingRealisation;
			$r = Time::TT::InterpolatingRealisation->new($r);
		}
		$realisation{$name} = $r;
	}
	return $r;
}

=back

=head1 BUGS

For a few of the named realisations of TAI for which there is data, the
author of this module was unable to determine conclusively whether they
were renamed at some point.  This affects particularly the names "naot",
"snt", "sta", "tao".

Time scale data only goes back to the beginning of 1990.  GPS and GLONASS
data only goes back to the beginning of 1993, and forward to the end
of 2004.

If you can supply more information about any of the time scales for
which data is missing then please mail the author.

Time steps and frequency shifts are not noted in the time scale data
available to this module.  The smooth interpolation will therefore produce
inaccurate results in the immediate vicinity of such discontinuities.

=head1 SEE ALSO

L<Date::JD>,
L<Time::GPS>,
L<Time::TAI::Now>,
L<Time::TT>,
L<Time::TT::Agencies>,
L<Time::TT::Realisation>,
L<Time::UTC>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2010 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
