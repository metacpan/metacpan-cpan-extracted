#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 03_new_callback.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# Test Win32::GUI DropFiles callback after loading Win32::GUI::DropFiles

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
    plan skip_all => "Win32::API 0.41 required for testing New Callback API" if $@;
}

plan tests => 7;

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
    my ($dropobj) = shift;

    ok(defined $dropobj, "OEM callback, dropobj defined");
    isa_ok($dropobj, "Win32::GUI::DropFiles", "OEM dropobj is a Win32::GUI::DropFiles object");
    
    return -1;
}

sub drop {
    my ($self, $dropobj) = @_;

    is($self, $W, "NEM callback gets window object");
    ok(defined $dropobj, "NEM callback, dropobj defined");
    isa_ok($dropobj, "Win32::GUI::DropFiles","NEM dropobj is a Win32::GUI::DropFiles object");
    
    return -1;
}
