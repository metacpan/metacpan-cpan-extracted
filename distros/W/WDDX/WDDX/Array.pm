#!/usr/bin/perl -w
# 
# $Id: Array.pm,v 1.2 2003/10/28 17:00:51 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Array;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use Carp;

require WDDX;

{ my $i_hate_the_w_flag_sometimes = [
    $WDDX::PACKET_HEADER,
    $WDDX::PACKET_FOOTER,
    $WDDX::Array::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Methods
# 

sub new {
    my( $class, $arrayref ) = @_;
    
    croak "You must supply an array ref when creating a new $class object\n"
        unless $arrayref;
    
    my $self = {
        value   => $arrayref,
    };
    
    bless $self, $class;
    return $self;
}


sub type {
    return "array";
}


sub as_packet {
    my( $self ) = @_;
    my $output = $WDDX::PACKET_HEADER .
                 $self->_serialize .
                 $WDDX::PACKET_FOOTER;
}


sub as_arrayref {
    my( $self ) = @_;
    return $self->_deserialize;
}


sub as_javascript {
    my( $self, $js_var ) = @_;
    my $arrayref = $self->{value};
    my $output   = "$js_var=new Array();";
    
    for ( my $i = 0; $i < @$arrayref; $i++ ) {
        $output .= $arrayref->[$i]->as_javascript( $js_var . "[$i]" );
    }
    return $output;
}


#/-----------------------------------------------------------------------
# Other Public Methods
# 


sub get_element {
    my( $self, $index ) = @_;
    return $self->{value}[$index];
}


# Method alias
*get = *get = \&get_element;


sub set {
    my( $self, %pairs ) = @_;
    my( $index, $value );
    
    while ( ( $index, $value ) = each %pairs ) {
        croak "The values assigned must be WDDX data objects.\n" 
            unless eval { $value->can( "_serialize" ) };
        $self->{value}[$index] = $value;
    }
}


sub splice {
    my( $self, $offset, $length, @values ) = @_;
    my @result;
    
    if ( @values ) {
        foreach ( @values ) {
            croak "The values assigned must be WDDX data objects.\n" 
                unless eval { $_->can( "_serialize" ) };
        }
        @result = splice @{ $self->{value} }, $offset, $length, @values;
    }
    elsif ( defined $length ) {
        @result = splice @{ $self->{value} }, $offset, $length;
    }
    else {
        @result = splice @{ $self->{value} }, $offset;
    }
    
    if ( wantarray ) {
        return @result;
    }
    else {
        return @result ? pop @result : undef;
    }
}


sub length {
    my( $self ) = @_;
    return scalar @{ $self->{value} };
}


sub push {
    my( $self, @values ) = @_;
    foreach ( @values ) {
        croak "The values assigned must be WDDX data objects.\n" 
            unless eval { $_->can( "_serialize" ) };
    }
    push @{ $self->{value} }, @values;
}


sub pop {
    my( $self ) = @_;
    pop @{ $self->{value} };
}


sub shift {
    my( $self ) = @_;
    shift @{ $self->{value} };
}


sub unshift {
    my( $self , @values ) = @_;
    foreach ( @values ) {
        croak "The values assigned must be WDDX data objects.\n" 
            unless eval { $_->can( "_serialize" ) };
    }
    unshift @{ $self->{value} }, @values;
}


#/-----------------------------------------------------------------------
# Private Methods
# 

sub is_parser {
    return 0;
}


sub _serialize {
    my( $self ) = @_;
    my $value = $self->{value};
    
    my $length = @$value;
    my $output = "<array length='$length'>";
    
    foreach ( @$value ) {
        $output .= $_->_serialize();
    }
    $output .= "</array>";
    return $output;
}


sub _deserialize {
    my( $self ) = @_;
    my @val_array = map $_->_deserialize, @{ $self->{value} };
    
    return \@val_array;
}

#/-----------------------------------------------------------------------
# Parsing Code
# 

package WDDX::Array::Parser;


sub new {
    my $class = shift;
    
    my $self = {
        value       => [],
        'length'    => 0,
        parse_var   => undef,
        seen_arrays => 0,
    };
    return bless $self, $class;
}


sub start_tag {
    my( $self, $element, $attribs ) = @_;
    my $parse_var = $self->parse_var;
    
    if ( $element eq "array" and not $self->{seen_arrays}++ ) {
        unless ( $attribs->{'length'} + 0 ) {
            die "Invalid value for length attribute in <array> tag";
        }
        $self->{'length'} = $attribs->{'length'};
    }
    else {
        unless ( $parse_var ) {
            $parse_var = WDDX::Parser->create_var( $element ) or
                die "Expecting some data element (e.g., <string>), " .
                    "found: <$element>\n";
            $self->push( $parse_var );
        }
        $parse_var->start_tag( $element, $attribs );
    }
    
    return $self;
}


sub end_tag {
    my( $self, $element ) = @_;
    my $parse_var = $self->parse_var;
    
    if ( $element eq "array" and not --$self->{seen_arrays} ) {
        # If fewer elements than declared, pad with null objects??
        while ( $self->num_elements < $self->{'length'} ) {
            $self->push( new WDDX::Null() );
        }
        $self = new WDDX::Array( $self->{value} );
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
        die "No loose character data is allowed within <array> elements\n";
    }
}


sub is_parser {
    return 1;
}


sub parse_var {
    my( $self, $var ) = @_;
    my $last_idx = $self->num_elements - 1;
    
    $self->{value}[ $last_idx ] = $var if defined $var;
    my $curr_var = $self->{value}[ $last_idx ];
    return ( ref $curr_var && $curr_var->is_parser ) ? $curr_var : "";
}


sub push {
    my( $self, $element ) = @_;
    
    die "Number of elements exceeds declared length of <array>\n" if
        $self->num_elements >= $self->{'length'};
    push @{ $self->{value} }, $element;
}


sub num_elements () {
    my( $self ) = @_;
    return scalar @{ $self->{value} };
}
