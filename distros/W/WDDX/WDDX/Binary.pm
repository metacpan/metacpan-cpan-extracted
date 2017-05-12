#!/usr/bin/perl -w
# 
# $Id: Binary.pm,v 1.1.1.1 2003/10/28 16:04:37 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Binary;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use Carp;
use MIME::Base64;

require WDDX;

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::Binary::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Methods
# 

sub new {
    my( $class, $value ) = @_;
    
    croak "You must supply a value when creating a new $class object\n"
        unless defined $value;
    
    my $self = {
        value   => $value,
    };
    
    bless $self, $class;
    return $self;
}


sub type {
    return "binary";
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
    my $val = $self->_encode;
    return "$js_var=new WddxBinary( \"$val\" );";
}


#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    my( $self ) = @_;
    my $length = length $self->{value};
    my $val = $self->_encode;
    my $output = "<binary length='$length'>$val</binary>";
    
    return $output;
}


sub _deserialize {
    my( $self ) = @_;
    return $self->{value};
}


# This is a separate sub to facilitate adding other encodings in the future
sub _decode {
    my( $self ) = @_;
    return decode_base64( $self->{value} );
}

# This is a separate sub to facilitate adding other encodings in the future
sub _encode {
    my( $self ) = @_;
    return encode_base64( $self->{value} );
}


#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::Binary::Parser;

use MIME::Base64;


sub new {
    return bless { value => "" }, shift;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    
    if ( $element eq "binary" ) {
        $self->{'length'} = 
            defined( $attribs->{'length'} ) ? $attribs->{'length'} : undef;
    }
    else {
        die "<$element> not allowed within <binary> element\n";
    }
    
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    
    if ( $element eq "binary" ) {
        $self = new WDDX::Binary( $self->_decode );
    }
    else {
        die "</$element> not allowed within <binary> element\n";
    }
    return $self;
}


sub append_data {
    my( $self, $data ) = @_;
    $self->{value} .= $data;
}


sub is_parser {
    return 1;
}


# This is a separate sub to facilitate adding other encodings in the future
sub _decode {
    my( $self ) = @_;
    
    my $decoded = decode_base64( $self->{value} );
    
    if ( defined $self->{'length'} ) {
        my $declared = $self->{'length'};
        my $read = length $decoded;
        if ( $declared != $read ) {
            die "Declared length of <binary> element ($declared) does not " .
                "match length read ($read)\n";
        }
    }
    
    return $decoded;
}
