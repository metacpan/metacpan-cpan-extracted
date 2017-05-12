#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: nmea.t,v 1.1 2007/12/31 01:16:01 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Temp;
	1;
    }) {
	print "1..0 # skip: no Test::More and/or File::Temp modules\n";
	exit;
    }
}

plan tests => 5;

use_ok("GPS::NMEA");

my($nmeafh,$nmeafile) = File::Temp::tempfile(UNLINK => 1, SUFFIX => ".nmea");
die if !$nmeafile;
print $nmeafh sample_nmea();
close $nmeafh or die $!;

{
    my $gps = GPS::NMEA->new(Port => "/not/used",
			     Baud => 4800,
			     do_not_init => 1,
			    );
    isa_ok($gps, "GPS::NMEA");
}

{
    package My::GPS::NMEA;
    use vars qw(@ISA);
    @ISA = qw(GPS::NMEA);
    sub connect {
	my $self = shift;
	return $self->serial if $self->serial;
	open NMEAFH, $self->{port} or die $!;
	$self->{serial} = \*NMEAFH;
	$self->{serialtype} = 'FileHandle';
    }
}

my $gps = My::GPS::NMEA->new(Port => $nmeafile);
isa_ok($gps, "GPS::NMEA");
{
    my($ns,$lat,$ew,$lon) = $gps->get_position;
    is("$ns,$lat,$ew,$lon", "N,52.288171,E,13.215627", "first position parse");
}
{
    my($ns,$lat,$ew,$lon) = $gps->get_position;
    is("$ns,$lat,$ew,$lon", "N,52.288321,E,13.215401", "next position parse");
}

sub sample_nmea {
    <<'EOF';
$GPRMC,101542,A,5228.8171,N,01321.5627,E,36.7,317.4,031103,1.8,E,A*27
$GPRMB,A,,,,,,,,,,,,A,A*0B
$GPGGA,101542,5228.8171,N,01321.5627,E,1,00,2.8,41.3,M,43.1,M,,*7E
$GPGSA,A,3,,,,,,,,,,,,,3.0,2.8,1.0*3A
$GPGSV,3,1,10,07,30,123,00,08,18,085,00,09,37,273,00,10,03,195,00*76
$GPGSV,3,2,10,15,02,315,00,18,28,306,00,23,03,341,00,26,76,213,00*7F
$GPGSV,3,3,10,28,53,066,00,29,63,168,00*75
$GPGLL,5228.8171,N,01321.5627,E,101542,A,A*41
$GPBOD,,T,,M,,*47
$PGRME,21.3,M,15.4,M,26.3,M*19
$PGRMZ,135,f,3*1C
$PGRMM,WGS 84*06
$GPRTE,1,1,c,*37
$GPRMC,101544,A,5228.8321,N,01321.5401,E,36.7,317.4,031103,1.8,E,A*20
$GPRMB,A,,,,,,,,,,,,A,A*0B
$GPGGA,101544,5228.8321,N,01321.5401,E,1,00,2.8,41.3,M,43.1,M,,*79
$GPGSA,A,3,,,,,,,,,,,,,3.0,2.8,1.0*3A
$GPGSV,3,1,10,07,30,123,00,08,18,085,00,09,37,273,00,10,03,195,00*76
$GPGSV,3,2,10,15,02,315,00,18,28,305,00,23,03,341,00,26,76,213,00*7C
$GPGSV,3,3,10,28,53,066,00,29,63,168,00*75
$GPGLL,5228.8321,N,01321.5401,E,101544,A,A*46
$GPBOD,,T,,M,,*47
EOF
}

__END__
