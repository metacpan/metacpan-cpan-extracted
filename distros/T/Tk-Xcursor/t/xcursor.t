#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use Tk;
use Tk::Xcursor;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	CORE::exit;
    }
}

my $mw = eval { tkinit };
if (!$mw) {
    plan skip_all => "Cannot create MainWindow: $@";
    CORE::exit;
}

plan tests => 2;

$mw->geometry('+10+10');
diag "This display " . (Tk::Xcursor::SupportsARGB($mw) ? "supports" : "does not support") . " ARGB cursors";
my $zzzfile = "$FindBin::RealBin/zzzcursor";
my $w = $mw->Label(-text => "The cursor is here", -fg => 'red')->pack;
my $xcursor = Tk::Xcursor::LoadCursor($w, $zzzfile);
isa_ok($xcursor, 'Tk::Xcursor', "$zzzfile loaded");
ok($xcursor->Set($w), 'Defined cursor');
$mw->after(2000, sub { $mw->destroy });
MainLoop;

__END__
