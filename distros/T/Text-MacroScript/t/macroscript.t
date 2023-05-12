#!/usr/bin/perl

# Copyright (c) 2000 Mark Summerfield. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;

use vars qw( $Loaded $Count $DEBUG $TRIMWIDTH ) ;

BEGIN { $| = 1 ; print "1..8\n" ; }
END   { print "not ok 1\n" unless $Loaded ; }

use Text::MacroScript ;
$Loaded = 1 ;

$DEBUG = 1,  shift if @ARGV and $ARGV[0] eq '-d' ;
$TRIMWIDTH = @ARGV ? shift : 60 ;

report( "loaded module ", 0, '', __LINE__ ) ;

my $M ;

eval {
    $M = Text::MacroScript->new ;
} ;
report( 'new', 0, $@, __LINE__ ) ;

eval {
    $M = Text::MacroScript->new( -file => [ 'nosuchfile' ] ) ;
} ;
report( 'new', 1, $@, __LINE__ ) ;

$M = Text::MacroScript->new ;

eval {
    $M->_validate( -fred ) ;
} ;
report( '_validate', 1, $@, __LINE__ ) ;

eval {
    $M->_validate( -name, '[invalid]' ) ;
} ;
report( '_validate', 1, $@, __LINE__ ) ;

eval {
    $M->_validate_array_name( -fred ) ;
} ;
report( '_validate_array_name', 1, $@, __LINE__ ) ;


eval {
    $M->_get_class( -fred ) ;
} ;
report( '_get_class', 1, $@, __LINE__ ) ;

eval {
    $M->_set_class( -fred ) ;
} ;
report( '_set_class', 1, $@, __LINE__ ) ;




sub report {
    my $test = shift ;
    my $flag = shift ;
    my $e    = shift ;
    my $line = shift ;

    ++$Count ;
    printf "[%03d~%04d] $test(): ", $Count, $line if $DEBUG ;

    if( $flag == 0 and not $e ) {
        print "ok $Count\n" ;
    }
    elsif( $flag == 0 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "not ok $Count" ;
        print " \a($e)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and not $e ) {
        print "not ok $Count" ;
        print " \a(error undetected)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "ok $Count" ;
        print " ($e)" if $DEBUG ;
        print "\n" ;
    }
}


