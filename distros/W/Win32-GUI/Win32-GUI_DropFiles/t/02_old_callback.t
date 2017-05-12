#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 02_old_callback.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# Test Win32::GUI DropFiles callback without loading Win32::GUI::DropFiles
# This is really a Win32::GUI test, not a Win32::GUI::Dropfiles test,
# but is here for completeness

# This old callback format is kept for backwards compatibility with
# The GUI Loft's Win32::GUI::DragDrop package.

# - check pre-requsites
# - check both OEM and NEM callbacks
# - check callback parameter types
# - check that DragFinish is called

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# We assume that 01_load.t has been run, so we know we have Test::More
# and that Win32::GUI and Win32::GUI::DropFiles will load.

use Test::More;

BEGIN {
    eval "use Win32::API 0.41";
    plan skip_all => "Win32::API 0.41 required for testing Old Callack API" if $@;
}

plan tests => 7;

# Load our helpers
use FindBin;
use lib "$FindBin::Bin";
use DropTest;

use Win32::GUI 1.03_02,'';

my $dropobj = DropTest->new();

my $W = Win32::GUI::Window->new(
    -name  => 'win',
    -title => "Win32::GUI DropFiles Test",
    -size  => [400,300],
    -onDropFiles => \&drop,
    -eventmodel  => "byname",
);

Win32::GUI::DoEvents();

# Do the OEM tests

$dropobj->PostDropMessage($W);

Win32::GUI::Dialog();

# Check that the receiver freed the handle
ok($dropobj->Free(), "OEM frees the drop object");

# Now do the NEM tests:

$W->Change(-eventmodel => "byref");

$dropobj->PostDropMessage($W);

Win32::GUI::Dialog();
ok($dropobj->Free(), "NEM frees the drop object");

exit(0);

sub win_DropFiles {
    my ($drophandle) = shift;

    ok(defined $drophandle, "OEM callback, drophandle defined");
    is(ref($drophandle), "", "OEM drophandle is a scalar");
    
    return -1;
}

sub drop {
    my ($self, $drophandle) = @_;

    is($self, $W, "NEM callback gets window object");
    ok(defined $drophandle, "NEM callback, drophandle defined");
    is(ref($drophandle), "", "NEM drophandle is a scalar");
    
    return -1;
}
