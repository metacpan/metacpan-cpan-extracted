#!/usr/bin/perl -w
# 
# $Id: Null.pm,v 1.1.1.1 2003/10/28 16:04:37 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Null;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use Carp;

require WDDX;

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::Null::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Methods
# 

sub new {
    return bless { value => undef }, shift;
}


sub type {
    return "null";
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
    return "$js_var=null;";
}


#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    return "<null/>";
}


sub _deserialize {
    return undef;
}


#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::Null::Parser;


sub new {
    return bless { value => undef }, shift;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    
    die "<$element> not allowed within <null> element\n" unless $element eq "null";
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    
    if ( $element eq "null" ) {
        $self = new WDDX::Null();
    }
    else {
        die "</$element> not allowed within <null> element\n";
    }
    return $self;
}


sub append_data {
    my( $self, $data ) = @_;
    die "No data is allowed between <null> tags\n" if $data =~ /\S/;
}


sub is_parser {
    return 1;
}

