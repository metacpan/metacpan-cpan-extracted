#!/usr/bin/perl -w
# 
# $Id: Parser.pm,v 1.1.1.1 2003/10/28 16:04:37 andy Exp $
# 
# This code is copyright 1999-2000 by Scott Guelich <scott@scripted.com>
# and is distributed according to the same conditions as Perl itself
# Please visit http://www.scripted.com/wddx/ for more information
#

package WDDX::Parser;

# Auto-inserted by build scripts
$VERSION = "1.01";

use strict;
use XML::Parser;

require WDDX;

## Necessary??
# die "WDDX.pm Requires XML::Parser 2.x or greater"
#     unless $XML::Parser::VERSION >= 2;

# This creates a tainted empty string (well, unless someone has
# untainted $0) see &taint at bottom
$WDDX::Parser::TAINTED = substr( $0, 0, 0 );

{ my $i_hate_the_w_flag_sometimes = [
        $XML::Parser::VERSION,
        $WDDX::Parser::TAINTED,
        \@WDDX::Data_Types,
        $WDDX::Parser::VERSION
] }

1;


#/-----------------------------------------------------------------------
# Public Constructor
# 

# Takes no parameters
sub new {
    my( $class ) = @_;
    my $self = {
        data      => undef,
        meta_tags => [ qw( <wddxpacket> <header> </header> 
                           <data> </data> </wddxpacket> ) ],
    };
    
    bless $self, $class;
    return $self;
}


# This starts the whole process rolling...
# Takes one parameter containing a WDDX Packet in either a string 
# or open IO::Handle (i.e. file handle or socket)
sub parse {
    my( $self, $arg ) = @_;
    my $p = new XML::Parser( 
        Handlers => {  
            Start   => sub { $self->start_handler( @_ ) },  # closures...
            End     => sub { $self->end_handler  ( @_ ) },  # isn't
            Char    => sub { $self->char_handler ( @_ ) },  # perl
            Final   => sub { $self->final_handler( @_ ) },  # cool?
    } );
    
    $p->parse( $arg );
    
    return $self->root_var;
}


#/-----------------------------------------------------------------------
# Private Handlers for XML::Parser
# 

# Start of XML tag
sub start_handler {
    my( $self, $expat, $element, %attribs ) = @_;
    
    # Force lowercase for element and attrib names
    $element = taint( lc $element );
    %attribs = map { taint( lc $_ ), taint( $attribs{$_} ) } keys %attribs;
    
    eval {
        
        if ( $element eq "wddxpacket" or
             $element eq "header"     or
             $element eq "data"          ) {
            $self->update_status( "<$element>" );
        }
        
        else {
            my $root_var = $self->root_var;
            
            unless ( $root_var ) {
                $root_var = $self->create_var( $element ) or
                    die "Expecting some data type element (e.g., <string>), " .
                        "found: <$element>\n";
                $self->root_var( $root_var );
            }
            $root_var->start_tag( $element, \%attribs );
        }
        
    };
    if ( $@ ) {
        $self->parse_err( $expat, $@ );
    }
}

# End of XML tag
sub end_handler {
    my( $self, $expat, $element ) = @_;
    $element = taint( lc $element );
    
    eval {
        
        if ( $element eq "wddxpacket" or
             $element eq "header"     or
             $element eq "data"          ) {
            $self->update_status( "</$element>" );
        }
        
        else {
            my $root_var = $self->root_var or
                die "Found </$element> before <$element>\n";
            
            $self->root_var( $root_var->end_tag( $element ) );
        }
        
    };
    if ( $@ ) {
        $self->parse_err( $expat, $@ );
    }
}


# Characters within and between tags
sub char_handler {
    my( $self, $expat, $text ) = @_;
    my $root_var = $self->root_var;
    
    $text = taint( $text );
    
    unless ( $root_var && $root_var->is_parser ) {
        return unless $text =~ /\S/;  # ignore whitespace
        die "Illegal text outside of tags\n";
    }
    
    eval {
        $root_var->append_data( $text );
    };
    if ( $@ ) {
        $self->parse_err( $expat, $@ );
    }
}


# Final validation
sub final_handler {
    my( $self, $expat ) = @_;
    
    # This error appears even if other tags are missing too
    unless ( $self->complete ) {
        $self->parse_err( $expat, 
            "Incomplete packet: no </wddxPacket> tag found" );
    }
}


#/-----------------------------------------------------------------------
# Private Helper Subs & Methods
# 

sub parse_err {
    my( $self, $expat, $err_msg ) = @_;
    my $line = $expat->current_line;
    
    die "Error deserializing line $line of WDDX packet,\n$err_msg\n";
}


# Returns the top level var object we're parsing in this packet
# Sets this attribute if it's passed a value
sub root_var {
    my( $self, $var ) = @_;
    
    $self->{data} = $var if $var;
    return $self->{data};
}


# This simplifies the process of creating WDDX::* objects
# Can be called as a class method
sub create_var {
    my( $this, $element ) = @_;
    
    return undef unless grep $_ eq $element, @WDDX::Data_Types;
    my( $untainted_element ) = $element =~ /(\w+)/ or
        die "Invalid data type name!";
    my $new_var = eval "new WDDX::\u${untainted_element}::Parser()";
    die $@ if $@;
    return $new_var;
}


# Checks given tag against next one on the queue of expected meta tags
sub update_status {
    my( $self, $tag ) = @_;
    my $expected_tag = shift @{ $self->{meta_tags} };
    
    unless ( $tag eq $expected_tag ) {
        die "Found $tag before $expected_tag\n";
    }
}


# Checks if anything left on the queue of expected meta tags
sub complete {
    my( $self ) = @_;
    return ( @{ $self->{meta_tags} } ? 0 : 1 );
}


# Ack, XML::Parser untaints data!!! This is a kludge to retaint it...
sub taint {
    return shift() . $WDDX::Parser::TAINTED;
}
