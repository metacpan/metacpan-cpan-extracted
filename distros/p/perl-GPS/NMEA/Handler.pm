# Copyright (c) 1999-2000 João Pedro Gonçalves <joaop@sl.pt>.
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package GPS::NMEA::Handler;

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use POSIX qw(:termios_h);
use FileHandle;
use Carp;

#$|++;

#$GPRMB,A,0.66,L,003,004,4917.24,N,12309.57,W,001.3,052.5,000.5,V*0B
#

# $GPRMB,<1>,<2>,<3>,<4>,<5>,<6>,<7>,<8>,<9>,<10>,<11>,<12>,<13>*hh
# 1) Data status, A=OK, V=warning
# 2) Cross-track error (nautical miles, 9.9 max)
# 3) L=steer left to correct, R=steer right to correct
# 4) Origin waypoint ID
# 5) Destination waypoint ID
# 6) Destination waypoint latitude
# 7) Destination waypoint latitude hemisphere
# 8) Destination waypoint longitude
# 9) Destination waypoint longitude hemisphere
# 10) Range to destination, nautical miles
# 11) True bearing to destination
# 12) Velocity towards destination, knots
# 13) Arrival alarm, A=Arrived, V=Not arrived

sub GPRMB {
    # RMB - Data when waypoint destination is active
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{data_valid},
     $$d{cross_track_error_naut_miles},
     $$d{steer_L_or_R},
     $$d{origin_waypoint},
     $$d{dest_waypoint},
     $$d{dest_waypoint_lat},
     $$d{dest_lat_NS},
     $$d{dest_waypoint_lon},
     $$d{dest_lon_EW},
     $$d{range_dest},
     $$d{bearing_dest},
     $$d{velocity_dest_knots},
     $$d{arrival_alarm}
    ) = split(',',shift);
    1;
}


#$GPGGA,033850,4748.811,N,12219.564,W,1,04,2.2,202.8,M,-18.3,M,,*7F
#

# GPS-35:
# $GPGGA,<1>,<2>,<3>,<4>,<5>,<6>,<7>,<8>,<9>,M,<10>,M,<11>,<12>*hh
# 1) UTC time of position fix, hhmmss format
# 2) Latitude, ddmm.mmmm format (leading zeroes will be transmitted)
# 3) Latitude hemisphere, N or S
# 4) Longitude, dddmm.mmmm format (leading zeros will be transmitted)
# 5) Longitude hemisphere, E or W
# 6) GPS quality indication, 0=no fix, 1=non-DGPS fix, 2=DGPS fix
# 7) Number of sats in use, 00 to 12
# 8) Horizontal Dilution of Precision 1.0 to 99.9
# 9) Antenna height above/below mean sea level, -9999.9 to 99999.9 meters
# 10) Geoidal height, -999.9 to 9999.9 meters
# 11) DGPS data age, number of seconds since last valid RTCM transmission (null if non-DGPS)
# 12) DGPS reference station ID, 0000 to 1023 (leading zeros will be sent, null if non-DGPS)

sub GPGGA {
    # Global Positioning System Fix Data

    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});

    my $d = $self->{NMEADATA};
    (undef,
     $$d{time_utc},
     $$d{lat_ddmm},
     $$d{lat_NS},
     $$d{lon_ddmm},
     $$d{lon_EW},
     $$d{fixq012},
     $$d{num_sat_tracked},
     $$d{hdop},
     $$d{alt_meters},
     $$d{alt_meters_units},
     $$d{height_above_wgs84},
     $$d{height_units},
     $$d{sec_since_last_dgps_update},
     $$d{dgps_station_id}
    ) = split(',',shift);
    $$d{time_utc} =~ s/(\d\d)(\d\d)(\d\d)/$1:$2:$3/g;
    1;
}

#$GPGSA,A,2,01,,,,23,,,,,,,,2.2,2.2,*1D
#

# GPS-35:
# $GPGSA,<1>,<2>,<3>,<3>,<3>,<3>,<3>,<3>,<3>,<3>,<3>,<3>,<3>,<3>,<4>,<5>,<6>*hh
# 1) Mode, M=Manual, A=Automatic
# 2) Fix type, 1=no fix, 2=2D, 3=3D
# 3) PRN number, 01 to 32, of satellites used in solution (leading zeroes sent)
# 4) Position dilution of precision, 1.0 to 99.9
# 5) Horizontal dilution of precision, 1.0 to 99.9
# 6) Vertical dilution of precision, 1.0 to 99.9

sub GPGSA {
    # GPS DOP and active satellites
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});

    my $d = $self->{NMEADATA};

    (undef,
     $$d{auto_man_D},
     $$d{dimen},
     $$d{prn01a},
     $$d{prn02a},
     $$d{prn03a},
     $$d{prn04a},
     $$d{prn05a},
     $$d{prn06a},
     $$d{prn07a},
     $$d{prn08a},
     $$d{prn09a},
     $$d{prn10a},
     $$d{prn11a},
     $$d{prn12a},
     $$d{pdop},
     $$d{hdop},
     $$d{vdop}
    ) = split(',',shift);
    1;
}

#$GPGSV,2,1,08,01,12,187,41,03,50,285,48,17,50,097,45,21,58,246,48*70
# multiple lines!
#

# GPS-35:
# $GPGSV,<1>,<2>,<3>,<4>,<5>,<6>,<7>,...<4>,<5>,<6>,<7>*hh
# 1) Total number of GSV sentences to be transmitted
# 2) Number of current GSV sentence
# 3) Total number of satellites in view, 00 to 12 (leading zeros sent)
# 4) Satellite PRN number, 01 to 32 (leading zeros sent)
# 5) Satellite elevation, 00 to 90 degrees (leading zeros sent)
# 6) Satellite azimuth, 000 to 359 degrees, true (leading zeros sent)
# 7) Signal to Noise ratio (C/No) 00 to 99 dB, null when not tracking (leading zeros sent)
sub GPGSV {
    # Satellites in view

    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    my @data  = split(',',shift);
    my $sentence = $data[2];

    if ($sentence == 1) {
	(undef,
	 $$d{num_sentences},
	 $$d{sentence},
	 $$d{num_sat_vis},
	 $$d{prn01},
	 $$d{elev_deg1},
	 $$d{az_deg1},
	 $$d{sig_str1},
	 $$d{prn02},
	 $$d{elev_deg2},
	 $$d{az_deg2},
	 $$d{sig_str2},
	 $$d{prn03},
	 $$d{elev_deg3},
	 $$d{az_deg3},
	 $$d{sig_str3},
	 $$d{prn04},
	 $$d{elev_deg4},
	 $$d{az_deg4},
	 $$d{sig_str4}
	) = @data;

    } elsif ($sentence == 2) {
	(undef,
	 $$d{num_sentences},
	 $$d{sentence},
	 $$d{num_sat_vis},
	 $$d{prn05},
	 $$d{elev_deg5},
	 $$d{az_deg5},
	 $$d{sig_str5},
	 $$d{prn06},
	 $$d{elev_deg6},
	 $$d{az_deg6},
	 $$d{sig_str6},
	 $$d{prn07},
	 $$d{elev_deg7},
	 $$d{az_deg7},
	 $$d{sig_str7},
	 $$d{prn08},
	 $$d{elev_deg8},
	 $$d{az_deg8},
	 $$d{sig_str8}
	) = @data;

    } elsif ($sentence == 3) {
	(undef,
	 $$d{num_sentences},
	 $$d{sentence},
	 $$d{num_sat_vis},
	 $$d{prn09},
	 $$d{elev_deg9},
	 $$d{az_deg9},
	 $$d{sig_str9},
	 $$d{prn10},
	 $$d{elev_deg10},
	 $$d{az_deg10},
	 $$d{sig_str10},
	 $$d{prn11},
	 $$d{elev_deg11},
	 $$d{az_deg11},
	 $$d{sig_str11},
	 $$d{prn12},
	 $$d{elev_deg12},
	 $$d{az_deg12},
	 $$d{sig_str12}
	) = @data;
    }
    1;
}


#$PGRME,45.8,M,,M,156.8,M*33
#

# GPS-35:
# $PGRME,<1>,M,<2>,M,<3>,M*hh
# 1) Estimated horizontal position error (HPE), 0.0 to 9999.9 meters
# 2) Estimated vertical position error (VPE), 0.0 to 9999.9 meters
# 3) Estimated position error (EPE), 0.0 to 9999.9 meters
sub PGRME {
    # Estimated horiz, vertical, spherical error in meters
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{hpe},
     $$d{hpe_units},
     $$d{vpe},
     $$d{vpe_units},
     $$d{overall_error},
     $$d{overall_error_units}
    ) = split(",",shift);
    1;
}

#$GPGLL,4748.811,N,12219.564,W,033850,A*3C
#

# $GPGLL,<1>,<2>,<3>,<4>,<5>,
# 1) Latitude, ddmm.mm format
# 2) Latitude hemisphere, N or S
# 3) Longitude, dddmm.mm format
# 4) Longitude hemisphere, E or W
# 5) UTC time of position fix, hhmmss format
# 6) Data valid, A=Valid
sub GPGLL {
    # Geographic position, Latitude and Longitude
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{lat_ddmm_low},
     $$d{lat_NS},
     $$d{lon_ddmm_low},
     $$d{lon_EW},
     $$d{time_utc},
     $$d{data_valid}
    ) = split(",",shift);

    1;
}



#$PGRMZ,665,f,2*1F
#
# $PGRMZ,<1>,f,<2>,M*dd
# 1) Altitude in feet
# 2) Position fix, 2=user altitude, 3=GPS altitude
#
sub PGRMZ {
    # Altitude & units, 2 = user altitude 3 = GPS altitude
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{alt},
     $$d{alt_units},
     $$d{alt_mode}
    ) = split(",",shift);
    1;
}


#$PGRMM,WGS 84*06
#

sub PGRMM {
    # Currently active horizontal datum
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{datum},
    ) = split(",",shift);
    1;
}

#$GPBOD,045.,T,023.,M,DEST,START*47
#

# $GPBOD,<1>,T,<2>,M,<3>,<4>*dd
# 1) Bearing from "start" to "dest", true
# 2) Bearing from "start" to "dest", magnetic
# 3) Destination waypoint ID
# 4) Origin waypoint ID

sub GPBOD {
    # Bearing - origin to destination waypoint
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{bearing_start_to_dest_true},
     $$d{junk31},
     $$d{bearing_start_to_dest_mag},
     $$d{junk32},
     $$d{dest_waypoint},
     $$d{origin_waypoint}
    ) = split(",",shift);

    1;
}


#$GPRTE,2,1,c,0,W3IWI,DRIVWY,32CEDR,32-29,32BKLD,32-I95,32-US1*69
# multiple lines!

# $GPRTE,<1>,<2>,<3>,<4>,<5>,<5>,<5>...<5>*dd
# 1) Number of GPRTE sentences
# 2) Number of this sentence
# 3) c=complete list of waypoints in this route, w=first listed waypoint is start of current leg
# 4) Route identifier (0-?)
# 5) Waypoint identifier
sub GPRTE {
    # Waypoints in active route
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    my @data = split(',',shift);
    my $sentence = $data[2];

    if ($sentence == 1) {
	(undef,
	 $$d{num_sentences},
	 undef,
	 $$d{c_w},
	 $$d{route_num},
	 @{$d->{waypoint1}}
	) = @data;
	undef $d->{waypoint2} if ref($d->{waypoint2});
	undef $d->{waypoint3} if ref($d->{waypoint3});
    } elsif ($sentence == 2) {
	(undef,
	 $$d{num_sentences},
	 undef,
	 $$d{c_w},
	 $$d{route_num},
	 @{$d->{waypoint2}}
	) = @data;
	undef $d->{waypoint3} if ref($d->{waypoint3});
    } elsif ($sentence == 2) {
	(undef,
	 $$d{num_sentences},
	 undef,
	 $$d{c_w},
	 $$d{route_num},
	 @{$d->{waypoint3}}
	) = @data;
    }


    1;
}


#$GPRMC,033850,A,4748.811,N,12219.564,W,000.0,150.3,160596,019.6,E*64
#

# GPS-35:
# $GPRMC,<1>,<2>,<3>,<4>,<5>,<6>,<7>,<8>,<9>,<10>,<11>*hh
# 1) UTC time of position fix, hhmmss format
# 2) Status, A=Valid position, V=NAV receiver warning
# 3) Latitude, ddmm.mmmm format (leading zeros sent)
# 4) Latitude hemisphere, N or S
# 5) Longitude, dddmm.mmmm format (leading zeros sent)
# 6) Longitude hemisphere, E or W
# 7) Speed over ground, 0.0 to 999.9 knots
# 8) Course over ground, 000.0 to 359.9 degrees, true (leading zeros sent)
# 9) UTC date of position fix, ddmmyy format
# 10) Magnetic variation, 000.0 to 180.0 degrees (leading zeros sent)
# 11) Magnetic variation direction, E or W (westerly variation adds to true course)

sub GPRMC {
    # RMC - Recommended minimum specific GPS/Transit data
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{time_utc},
     $$d{data_valid},
     $$d{lat_ddmm},
     $$d{lat_NS},
     $$d{lon_ddmm},
     $$d{lon_EW},
     $$d{speed_over_ground},
     $$d{course_made_good},
     $$d{ddmmyy},
     $$d{mag_var},
     $$d{mag_var_EW}
    ) = split(",",shift);

    $d->{time_utc} =~ s/(\d\d)(\d\d)(\d\d)/$1:$2:$3/g;
    1;
}

1;


__END__
#

=head1 NAME

GPS::NMEA::Handler - Handlers to NMEA data

=head1 SYNOPSIS

  use GPS::NMEA::Handler;


=head1 DESCRIPTION

	Used internally

=over

=head1 AUTHOR

Based on
NMEA Parsing Program
Copyright (C) 1997-2000, Curt Mills and Lane Holdcroft.

=head1 SEE ALSO

=cut
