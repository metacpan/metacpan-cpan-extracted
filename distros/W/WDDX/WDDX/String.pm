#!/usr/bin/perl -w
# 
# $Id: String.pm,v 1.1.1.1 2003/10/28 16:04:38 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::String;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use Carp;

require WDDX;

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::String::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Methods
# 

sub new {
    my( $class, $value ) = @_;
    
    croak "You must supply a value when creating a new $class object\n"
        unless defined $value;
    
    croak "WDDX strings may not contain null characters (\\0)\n"
        if $value =~ /\0/;
    
    my $self = {
        value   => $value,
    };
    
    bless $self, $class;
    return $self;
}


sub type {
    return "string";
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
    local $_ = $self->{value};
    
    # Escape for JavaScript... forget anything?
    s/\\/\\\\/g;
    s/\n/\\n/g;
    s/\r/\\r/g;
    s/\t/\\t/g;
    s/"/\\"/g;
    
    return "$js_var=\"$_\";";
}


#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    my( $self ) = @_;
    my $val = $self->xml_encode;
    my $output = "<string>$val</string>";
    
    return $output;
}


sub _deserialize {
    my( $self ) = @_;
    return $self->{value};
}


sub xml_encode {
    my $self = shift;
    local $_ = $self->{value};
    
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/'/&apos;/g;
    s/"/&quot;/g;
    s|([\000-\037])|<char code='@{[ sprintf "%02X", ord($1) ]}'/>|g;
    return $_;
}

#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::String::Parser;


sub new {
    return bless { value => "" }, shift;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    
    if ( $element eq "char" ) {
        $self->append_data( $self->char_decode( $attribs->{code} ) );
    }
    elsif ( $element ne "string" ) {
        die "<$element> not allowed within <string> element\n";
    }
    
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    
    if ( $element eq "string" ) {
        $self = new WDDX::String( $self->{value} );
    }
    elsif ( $element ne "char" ) {
        die "</$element> not allowed within <string> element\n";
    }
    return $self;
}


sub append_data {
    my( $self, $data ) = @_;
    $self->{value} .= $data;
}


sub char_decode {
    my( $self, $code ) = @_;
    
    die "Invalid character code\n" unless $code =~ /^[01][0-9a-f]$/i;
    return chr hex $code;
}


sub is_parser {
    return 1;
}

