#!/usr/bin/perl -w
# 
# $Id: Number.pm,v 1.3 2003/10/28 17:18:10 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Number;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use Carp;

require WDDX;

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::Number::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Methods
# 

sub new {
    my( $class, $value ) = @_;
    
    croak "You must supply a value when creating a new $class object\n"
        unless defined $value;
    
    $value += 0;
    
    if ( $value > 1.7e308  or $value < -1.7e308 ) {
        die "Number exceeds supported range of +/-1.7e308\n";
    }
    # Is there a better/more accurate way to handle this?
    # Also, does it make sense to only restrict precision to after decimal?
    if ( ($value =~ /^(\+|-)?(\d*)(\.\d+)?(?:E(\+|-)?(\d+))?$/i)
	 and (defined $3)
         and (length $3 > 16) ) {
        warn "Floating point number exceeds supported accuracy; " .
             "trimming to 15 digits.\n";
        $value = ( "$1$2" . substr( $3, 15 ) . "$4$5" ) + 0;
    }
    
    my $self = {
        value   => $value,
    };
    
    bless $self, $class;
    return $self;
}


sub type {
    return "number";
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
    return "$js_var=$self->{value};";
}


#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    my( $self ) = @_;
    my $val = $self->{value} + 0;
    my $output = "<number>$val</number>";
    
    return $output;
}


sub _deserialize {
    my( $self ) = @_;
    return $self->{value};
}


#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::Number::Parser;


sub new {
    return bless { value => "" }, shift;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    
    unless ( $element eq "number" ) {
        die "<$element> not allowed within <number> element\n";
    }
    
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    my $value = $self->{value};
    
    unless ( $element eq "number" ) {
        die "</$element> not allowed within <number> element\n";
    }
    
    unless ( $value =~ /^(?:\+|-)?\d*(\.\d+)?(?:E(?:\+|-)?(\d+))?$/i ) {
        die "Invalid numeric value: '$value'\n";
    }
    if ( (defined $1) && (length $1 > 16) ) {
        die "Floating point number exceeds supported accuracy (15 digits)\n";
    }
    if ( $value > 1.7e308  or $value < -1.7e308 ) {
        die "Number exceeds supported range of +/-1.7e308\n";
    }
    
    $self = new WDDX::Number( $value + 0 );
    
    return $self;
}


# Not sure if it's appropriate to allow this to be called more than once.
# It's a number after all... shouldn't be split by whitespace or other tags.
sub append_data {
    my( $self, $data ) = @_;
    $self->{value} .= $data;
}


sub is_parser {
    return 1;
}

