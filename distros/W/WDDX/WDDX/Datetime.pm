#!/usr/bin/perl -w
# 
# $Id: Datetime.pm,v 1.1.1.1 2003/10/28 16:04:37 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Datetime;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use Carp;
use Time::Local;

require WDDX;

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::Datetime::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Methods
# 

sub new {
    my( $class, $value ) = @_;
    
    croak "You must supply the date in (integer) seconds when creating " .
          "Datetime objects\n" if $value =~ /\D/;
    
    my $self = {
        value   => $value,
        tz_info => 1,
    };
    
    bless $self, $class;
    return $self;
}


sub type {
    return "datetime";
}


sub as_packet {
    my( $self ) = @_;
    my $output = $WDDX::PACKET_HEADER .
                 $self->_serialize .
                 $WDDX::PACKET_FOOTER;
}


sub as_scalar {
    my( $self ) = @_;
    return $self->_deserialize;
}


sub as_javascript {
    my( $self, $js_var ) = @_;
    my $time_in_secs = $self->{value};
    
    my( $sec, $min, $hour, $day, $mon, $year ) = localtime( $time_in_secs );
    return "$js_var=new Date($year,$mon,$day,$hour,$min,$sec);";
}


# Timezone info is included in new packets by default
sub use_timezone_info {
    my( $self, $arg ) = @_;
    $self->{tz_info} = ( $arg ? 1 : 0 ) if defined $arg;
    return $self->{tz_info}
}

#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    my( $self ) = @_;
    my $time_in_secs = $self->{value};
    
    my( $sec, $min, $hour, $day, $mon, $year ) = localtime( $time_in_secs );
    my $output = sprintf "<dateTime>%02d-%02d-%02dT%02d:%02d:%02d",
                    $year + 1900, $mon + 1, $day, $hour, $min, $sec;
    $output .= tz_info() if $self->use_timezone_info;
    $output .= "</dateTime>";
    return $output;
}


sub _deserialize {
    my( $self ) = @_;
    return $self->{value};
}


# This generates the timezone info by looking at the difference between
# gmtime and localtime; uses functions from standard Time::Local module
sub tz_info {
    my $local = timelocal( localtime );
    my $gmt   = timegm   ( localtime );
    
    my $diff = abs( $gmt - $local );
    my $hrs  = int( $diff / ( 60 * 60 ) );
    my $mins = int( $diff / 60 ) - $hrs * 60;
    my $dir  = $gmt - $local >= 0 ? '+' : '-';
    
    return sprintf "$dir%0.2d:%0.2d", $hrs, $mins;
}


#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::Datetime::Parser;

use Time::Local;


sub new {
    my $class = shift;
    
    my $self = {
        value   => "",
        tz_info => undef
    };
    return bless $self, $class;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    
    unless ( $element eq "datetime" ) {
        die "<$element> not allowed within <datetime> element\n";
    }
    
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    my $value = $self->{value};
    my $time_in_secs;
    
    unless ( $element eq "datetime" ) {
        die "</$element> not allowed within <datetime> element\n";
    }
    
    my( $yr, $mon, $day, $hr, $min, $sec, $tz_dir, $tz_hr, $tz_min ) = 
     $value =~ /^(\d{4})-(\d+)-(\d+)T(\d+):(\d+):(\d+)(?:([+-])(\d+):(\d+))?$/i
     or die "Invalid dateTime value: '$value'\n";
    
    # Note: this isn't a Y2K bug; years >= 2000 represented w/ 3 digits
    $yr -= 1900;
    die "DateTime values prior to 1900-01-01 are not supported\n" if $yr < 0;
    $mon--;
    
    eval {
        $time_in_secs = timelocal( $sec, $min, $hr, $day, $mon, $yr );
    };
    if ( $@ ) {
        die "Invalid dateTime value. $@\n";
    }
    if ( $time_in_secs < 0 ) {
        die "DateTime value exceeds the integer limit for this machine\n";
    }
    
    if ( $tz_dir ) {
        # Adjust according to timezone info in packet
        if ( $tz_dir eq '+' ) {
            $time_in_secs += $tz_min * 60;
            $time_in_secs += $tz_hr  * 60 * 60;
        }
        else {
            $time_in_secs -= $tz_min * 60;
            $time_in_secs -= $tz_hr  * 60 * 60;
        }
        
        # Readjust to compensate for our own timezone diff relative to UTC/GMT
        my $tz_info = WDDX::Datetime::tz_info();
        my( $loc_dir, $loc_hr, $loc_min ) = $tz_info =~ /([+-])(\d+):(\d+)/;
        
        if ( $loc_dir eq '-' ) {
            $time_in_secs += $loc_min * 60;
            $time_in_secs += $loc_hr  * 60 * 60;
        }
        else {
            $time_in_secs -= $loc_min * 60;
            $time_in_secs -= $loc_hr  * 60 * 60;
        }
    }
    
    $self = new WDDX::Datetime( $time_in_secs );
    $self->use_timezone_info( 0 ) unless $tz_dir;
    
    return $self;
}


sub append_data {
    my( $self, $data ) = @_;
    $self->{value} .= $data;
}


sub is_parser {
    return 1;
}

