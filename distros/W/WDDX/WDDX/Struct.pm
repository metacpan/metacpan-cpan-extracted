#!/usr/bin/perl -w
# 
# $Id: Struct.pm,v 1.2 2003/10/28 16:41:12 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Struct;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use Carp;

require WDDX;

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::Struct::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Methods
# 

sub new {
    my( $class, $hashref ) = @_;
    
    croak "You must supply a hash ref when creating a new $class object.\n"
        unless eval { %$hashref || 1 };
    
    foreach ( values %$hashref ) {
        croak "Each element of the supplied hash must be a WDDX data object.\n" 
            unless eval { $_->can( "_serialize" ) };
    }
    
    my $self = {
        value   => $hashref,
    };
    
    bless $self, $class;
    return $self;
}

sub type {
    return "hash";
}

sub as_packet {
    my( $self ) = @_;
    my $output = $WDDX::PACKET_HEADER .
                 $self->_serialize .
                 $WDDX::PACKET_FOOTER;
}


sub as_hashref {
    my( $self ) = @_;
    return $self->_deserialize;
}


sub as_javascript {
    my( $self, $js_var ) = @_;
    my $hashref = $self->{value};
    my $output  = "$js_var=new Object;";
    
    while ( my( $key, $val ) = each %$hashref ) {
        $output .= $val->as_javascript( $js_var . "[\"$key\"]" );
    }
    return $output;
}


#/-----------------------------------------------------------------------
# Other Public Methods
# 


sub get_element {
    my( $self, $key ) = @_;
    return $self->{value}{$key};
}


# Method alias
*get = *get = \&get_element;


sub set {
    my( $self, %pairs ) = @_;
    my( $key, $value );
    while ( ( $key, $value ) = each %pairs ) {
        croak "The value of each pair must be a WDDX data object.\n" 
            unless eval { $value->can( "_serialize" ) };
        $self->{value}{$key} = $value;
    }
}


sub delete {
    my( $self, $key ) = @_;
    delete $self->{value}{$key};
}


sub keys {
    my( $self ) = @_;
    return wantarray ?
        ( keys %{ $self->{value} } ) :
        scalar keys %{ $self->{value} };
}


sub values {
    my( $self ) = @_;
    return wantarray ?
        ( values %{ $self->{value} } ) :
        scalar values %{ $self->{value} };
}


#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    my( $self ) = @_;
    my $hashref = $self->{value};
    my $output = "<struct>";
    
    foreach ( CORE::keys %$hashref ) {
        $output .= "<var name='$_'>";
        $output .= $hashref->{$_}->_serialize;
        $output .= "</var>";
    }
    
    $output .= "</struct>";
    return $output;
}


sub _deserialize {
    my( $self ) = @_;
    my $wddx_hashref = $self->{value};
    my %hash;
    
    foreach ( CORE::keys %$wddx_hashref ) {
        $hash{$_} = $wddx_hashref->{$_}->_deserialize;
    }
    return \%hash;
}

#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::Struct::Parser;


sub new {
    my $class = shift;
    
    my $self = {
        value         => {},
        curr_key      => undef,
        seen_structs  => 0,
    };
    return bless $self, $class;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    my $parse_var = $self->parse_var;
    
    unless ( $element eq "struct" and not $self->{seen_structs}++ ) {
        if ( $element eq "var" and $self->{seen_structs} == 1 ) {
            $self->add( $attribs->{name} );
        }
        else {
            unless ( $parse_var ) {
                $parse_var = WDDX::Parser->create_var( $element ) or
                    die "Expecting some data element (e.g., <string>), " .
                        "found: <$element>\n";
                $self->parse_var( $parse_var );
            }
            $parse_var->start_tag( $element, $attribs );
        }
    }
    
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    my $parse_var = $self->parse_var;
    
    if ( $element eq "struct" and not --$self->{seen_structs} ) {
        # Clean up non-object pairs used for case-insensitive checks
        foreach ( keys %{ $self->{value} } ) {
            delete $self->{value}{$_} unless ref $self->{value}{$_};
        }
        $self = new WDDX::Struct( $self->{value} );
    }
    elsif ( $element eq "var" and $self->{seen_structs} == 1 ) {
        $self->{curr_key} = undef;
    }
    else {
        unless ( $parse_var ) {
            # XML::Parser should actually catch this
            die "Found </$element> before <$element>\n";
        }
        $self->parse_var( $parse_var->end_tag( $element ) );
    }
    
    return $self;
}


sub append_data {
    my( $self, $data ) = @_;
    my $parse_var = $self->parse_var;
    
    if ( $parse_var ) {
        $parse_var->append_data( $data );
    }
    elsif ( $data =~ /\S/ ) {
        die "No data is allowed within <struct> elements outside of " .
            "other elements\n";
    }
}


sub is_parser {
    return 1;
}


sub parse_var {
    my( $self, $var ) = @_;
    my $curr_key = $self->{curr_key};
    
    unless ( defined $curr_key ) {
        return undef;
    }
    
    if ( defined $var ) {
        die "Missing <var> element in <struct>\n" unless defined $curr_key;
        $self->{value}{$curr_key} = $var;
    }
    my $curr_var = $self->{value}{$curr_key};
    return ( ref $curr_var && $curr_var->is_parser ) ? $curr_var : undef;
}


sub add {
    my( $self, $name ) = @_;
    my $hash = $self->{value};
    
    $self->{curr_key} = $name;
    
    # Duplicates should be replaced by later values; case-insensitive
    if ( exists $hash->{lc $name} ) {
        delete $hash->{ $hash->{lc $name} };
    }
    
    $hash->{lc $name} = $name unless $name eq lc $name;
    $hash->{$name} = undef;
}
