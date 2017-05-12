#!/usr/bin/perl -w

# $Id$

# Copyright (c) 2000 Mark Summerfield. All Rights Reserved.
# May be used/distributed under the GPL.

use strict ;

#use lib 'blib/lib';
use Test::More tests => 2;

BEGIN { use_ok('Tk::ColourChooser') };

my $tty = -t STDIN;

my $test_dialogue = $tty && $ENV{TEST_DIALOGUE};

SKIP: {
    skip "Set env TEST_DIALOGUE to true if you want to test the gui", 1 unless $test_dialogue;
    my $Win = MainWindow->new;
    my $colour = 'white';
    my $col_dialog = $Win->ColourChooser( 
        -language => 'en',
        -colour   => $colour, 
        -showhex  => 1,
    );
    $colour = $col_dialog->Show;
    #warn __PACKAGE__.':'.__LINE__.": $colour\n";
    ok(defined $colour, "Dialogue");
}


__END__

use vars qw( $Loaded $Count $DEBUG $TRIMWIDTH ) ;

BEGIN { $| = 1 ; print "1..1\n" ; }
END   { print "not ok 1\n" unless $Loaded ; }

use Tk::ColourChooser ;
$Loaded = 1 ;

$DEBUG = 1,  shift if @ARGV and $ARGV[0] eq '-d' ;
$TRIMWIDTH = @ARGV ? shift : 60 ;

report( "loaded module ", 0, '', __LINE__ ) ;



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


