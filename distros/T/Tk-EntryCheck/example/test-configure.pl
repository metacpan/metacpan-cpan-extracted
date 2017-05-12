#! /usr/bin/perl
use warnings;
use strict;

use Tk ();
use Tk::EntryCheck;


my $mw = MainWindow->new();

my $ec1 = $mw->EntryCheck( -maxlength => 2, -pattern => qr/\d/  )
    ->pack();
$ec1->configure( -pattern => qr/[a-zA-Z]/ );
$ec1->configure( -maxlength => 4 );

&Tk::MainLoop;

