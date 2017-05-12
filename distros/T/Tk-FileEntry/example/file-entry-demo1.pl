#!perl

use strict;
use warnings;
use File::Spec;
use FindBin qw/$Bin/;
use lib File::Spec->catfile($Bin, '..', 'lib');
use Tk;
use Tk::FileEntry;

print "using Tk::FileEntry v" . $Tk::FileEntry::VERSION . "\n";

my $mw = tkinit();

$mw->FileEntry->pack(-expand => 1, -fill => 'x');

$mw->MainLoop();