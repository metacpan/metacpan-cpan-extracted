#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 10_Unicode.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# Test Win32::GUI::DropFiles Unicode support

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# We assume that 01_load.t has been run, so we know we have Test::More
# and that Win32::GUI and Win32::GUI::DropFiles will load.

use Test::More;

BEGIN {
    #No unicode support before WinNT
    plan skip_all => "No Unicode filename support in Win95/98/ME" if Win32::GetOSVersion() < 2;
    eval "use Win32::API 0.41";
    plan skip_all => "Win32::API 0.41 required for testing Uniocde Support" if $@;
    eval "use Unicode::String";
    plan skip_all => "Unicode::String required for testing Unicode Support" if $@;
}

# Load our helpers
use FindBin;
use lib "$FindBin::Bin";
use DropTest;

use Win32::GUI 1.03_02,'';
use Win32::GUI::DropFiles;

my @tests = (
    # Ascii chars only
    [ "AB", "C", "Longer Name with spaces", ],
    # Simley face
    [ "\x{263A}", ],
    # Hello World - multi-lingual
    [ "Hello world",
      "\x{039A}\x{03B1}\x{03BB}\x{3B7}\x{03BC}\x{1F73}\x{03C1}\x{03B1}",
      "\x{03B1}\x{1F79}\x{03C3}\x{03BC}\x{03B5}, \x{30B3}\x{30F3}\x{30CB}\x{30C1}\x{30CF}",
    ],
    # Thai
    [ "\x{0E4F} \x{0E41}\x{0E1C}\x{0E48}\x{0E19}\x{0E14}\x{0E34}\x{0E19}\x{0E2E}\x{0E31}\x{0E48}\x{0E19}\x{0E40}\x{0E2A}\x{0E37}\x{0E48}\x{0E2D}\x{0E21}\x{0E42}\x{0E17}\x{0E23}\x{0E21}\x{0E41}\x{0E2A}\x{0E19}\x{0E2A}\x{0E31}\x{0E07}\x{0E40}\x{0E27}\x{0E0A}",
"\x{0E1E}\x{0E23}\x{0E30}\x{0E1B}\x{0E01}\x{0E40}\x{0E01}\x{0E28}\x{0E01}\x{0E2D}\x{0E07}\x{0E1A}\x{0E39}\x{0E4A}\x{0E01}\x{0E39}\x{0E49}\x{0E02}\x{0E36}\x{0E49}\x{0E19}\x{0E43}\x{0E2B}\x{0E21}\x{0E48}",
    ],
);

plan tests => 1 * scalar @tests;

my $W = Win32::GUI::Window->new(
    -name  => 'win',
    -title => "Win32::GUI DropFiles Test",
    -size  => [400,300],
    -onDropFiles => \&drop,
);

Win32::GUI::DoEvents();

my $files;
while($files = shift @tests) {
    my $dt = DropTest->new(files => $files, wide => 1);
    $dt->PostDropMessage($W);
    Win32::GUI::Dialog();
}

exit(0);

sub drop {
    my ($self, $dropobj) = @_;

    my @f = $dropobj->GetDroppedFiles();
    ok(eq_set($files,\@f), "Correct set of files found");
    
    return -1;
}
