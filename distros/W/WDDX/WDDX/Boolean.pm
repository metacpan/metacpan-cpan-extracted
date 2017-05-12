#!/usr/bin/perl -w
# 
# $Id: Boolean.pm,v 1.1.1.1 2003/10/28 16:04:37 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Boolean;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use Carp;

require WDDX;

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::Boolean::VERSION
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
        value   => $value ? 1 : "",
    };
    
    bless $self, $class;
    return $self;
}


sub type {
    return "boolean";
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
    return "$js_var=" . ( $self->{value} ? 'true' : 'false' ) . ";";
}


#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    my( $self ) = @_;    
    my $value = ( $self->{value} ? "true" : "false" );
    my $output = "<boolean value='$value'/>";
    return $output;
}


sub _deserialize {
    my( $self ) = @_;
    return $self->{value};
}


#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::Boolean::Parser;


sub new {
    return bless { value => undef }, shift;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    
    if ( $element eq "boolean" ) {
        if ( $attribs->{value} eq "true" ) {
            $self->{value} = 1;
        }
        elsif ( $attribs->{value} eq "false" ) {
            $self->{value} = "";
        }
        else {
            die "Invalid value for value attribute in <boolean> tag";
        }
    }
    else {
        die "<$element> not allowed within <boolean> element\n";
    }
    
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    
    if ( $element eq "boolean" ) {
        $self = new WDDX::Boolean( $self->{value} );
    }
    else {
        die "</$element> not allowed within <boolean> element\n";
    }
    return $self;
}


sub append_data {
    my( $self, $data ) = @_;
    die "No data is allowed between <boolean> tags\n" if $data =~ /\S/;
}


sub is_parser {
    return 1;
}

