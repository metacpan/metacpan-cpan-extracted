#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 09_DragFinish.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# Test Win32::GUI::DropFiles DragFinish() function

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# We assume that 01_load.t has been run, so we know we have Test::More
# and that Win32::GUI and Win32::GUI::DropFiles will load.

use Test::More;
 
BEGIN {
    eval "use Win32::API 0.41";
    plan skip_all => "Win32::API 0.41 required for testing DragFinish()" if $@;
}

plan tests => 1;

# Load our helpers
use FindBin;
use lib "$FindBin::Bin";
use DropTest;

use Win32::GUI 1.03_02,'';
use Win32::GUI::DropFiles;

my $dropobj = DropTest->new();

my $W = Win32::GUI::Window->new(
    -name  => 'win',
    -title => "Win32::GUI DropFiles Test",
    -size  => [400,300],
    -onDropFiles => \&drop,
);

Win32::GUI::DoEvents();
$dropobj->PostDropMessage($W);
Win32::GUI::Dialog();
exit(0);

sub drop {
    my ($self, $dropobj) = @_;

    #Calling DragFinish should make the HDROP handle invalid
    Win32::GUI::DropFiles::DragFinish($dropobj->{-handle});

    is(DropTest::isValidHandle($dropobj->{-handle}), 0, "handle invalidated");
    
    return -1;
}
