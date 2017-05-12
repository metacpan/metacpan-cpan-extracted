#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 08_DragQueryPoint.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# Test Win32::GUI::DropFiles DragQueryPoint() function

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# We assume that 01_load.t has been run, so we know we have Test::More
# and that Win32::GUI and Win32::GUI::DropFiles will load.

use Test::More;
 
BEGIN {
    eval "use Win32::API 0.41";
    plan skip_all => "Win32::API 0.41 required for testing DragQueryPoint()" if $@;
}

# Load our helpers
use FindBin;
use lib "$FindBin::Bin";
use DropTest;

use Win32::GUI 1.03_02,'';
use Win32::GUI::DropFiles;

my @testdata = (
  { x => 100, y => 120, c => 1 },
  { x => 1,   y => -1,  c => 0 },
);
my $numtests = scalar @testdata;

plan tests => 9 * $numtests;

my $W = Win32::GUI::Window->new(
    -name  => 'win',
    -title => "Win32::GUI DropFiles Test",
    -size  => [400,300],
    -onDropFiles => \&drop,
);

Win32::GUI::DoEvents();

my $testnum;
for (0..$numtests-1) {
    $testnum = $_;
    my $dropobj = DropTest->new(
        x => $testdata[$testnum]->{x},
        y => $testdata[$testnum]->{y},
        client => $testdata[$testnum]->{c},
    );
    $dropobj->PostDropMessage($W);
    Win32::GUI::Dialog();
}
exit(0);

sub drop {
    my ($self, $dropobj) = @_;

    # DragQueryPoint returns a list of x, y, client info
    {
        my ($x, $y, $c) = Win32::GUI::DropFiles::DragQueryPoint($dropobj);
        is($x, $testdata[$testnum]->{x}, "X-pos reported correctly when passed object");
        is($y, $testdata[$testnum]->{y}, "Y-pos reported correctly when passed object");
        is($c, $testdata[$testnum]->{c}, "client pos reported correctly when passed object");
    }
    {
        my ($x, $y, $c) = Win32::GUI::DropFiles::DragQueryPoint($dropobj->{-handle});
        is($x, $testdata[$testnum]->{x}, "X-pos reported correctly when passed handle");
        is($y, $testdata[$testnum]->{y}, "Y-pos reported correctly when passed handle");
        is($c, $testdata[$testnum]->{c}, "client pos reported correctly when passed handle");
    }
    {
        my ($x, $y, $c) = $dropobj->DragQueryPoint();
        is($x, $testdata[$testnum]->{x}, "X-pos reported correctly when called as method");
        is($y, $testdata[$testnum]->{y}, "Y-pos reported correctly when called as method");
        is($c, $testdata[$testnum]->{c}, "client pos reported correctly when called as method");
    }
    
    return -1;
}
