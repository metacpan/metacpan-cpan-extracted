#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 04_GetDroppedFiles.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# Test Win32::GUI::DropFiles GetDroppedFiles() method

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# We assume that 01_load.t has been run, so we know we have Test::More
# and that Win32::GUI and Win32::GUI::DropFiles will load.

use Test::More;
 
BEGIN {
    eval "use Win32::API 0.41";
    plan skip_all => "Win32::API 0.41 required for testing GetDroppedFiles()" if $@;
}


# Load our helpers
use FindBin;
use lib "$FindBin::Bin";
use DropTest;

use Win32::GUI 1.03_02,'';
use Win32::GUI::DropFiles;

my @tests = (
    [ "A", "B", "Longer Name with spaces" ],
    [],   # no files should never happen, but just in case ...
);

plan tests => 2 * scalar @tests;

my $W = Win32::GUI::Window->new(
    -name  => 'win',
    -title => "Win32::GUI DropFiles Test",
    -size  => [400,300],
    -onDropFiles => \&drop,
);

Win32::GUI::DoEvents();

my $files;
while($files = shift @tests) {
    my $dt = DropTest->new(files => $files);
    $dt->PostDropMessage($W);
    Win32::GUI::Dialog();
}

exit(0);

sub drop {
    my ($self, $dropobj) = @_;

    # GetDroppedFiles in scalar context returns number of files
    is(scalar $dropobj->GetDroppedFiles(), scalar @{$files}, "Correct number of files");

    # GetDroppedFiles in list context returns the list of files
    my @f = $dropobj->GetDroppedFiles();
    ok(eq_set($files,\@f), "Correct set of files found");
    
    return -1;
}
