#!/usr/bin/perl -w

use strict ;

use Tk ;
use Tk::ColourChooser ;

print STDERR <<__EOT__ ;
Simple test routine for Tk::ColourChooser.
(Will randomly change languages.)
Select a colour and click OK. The colour's name (or hex number if it has not
got a name) will be output in square brackets after this text. If you click
Transparent the output is [None]. If you click Cancel the program terminates.
__EOT__
#'
my @lang = qw( de en fr ) ;

my $Win = MainWindow->new ;

my $colour = 'white' ;
while( 1 ) {
    my $col_dialog = $Win->ColourChooser( 
                        -language => $lang[int( rand 3 )],
                        -colour   => $colour, 
                        -showhex  => 1,
                        ) ;
    $colour        = $col_dialog->Show ;
    print STDERR "[$colour]\n" ;
    exit unless $colour ;
}

MainLoop ;
