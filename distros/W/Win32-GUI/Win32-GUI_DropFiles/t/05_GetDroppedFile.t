#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 05_GetDroppedFile.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# Test Win32::GUI::DropFiles GetDroppedFile() method

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# We assume that 01_load.t has been run, so we know we have Test::More
# and that Win32::GUI and Win32::GUI::DropFiles will load.

use Test::More;
 
BEGIN {
    eval "use Win32::API 0.41";
    plan skip_all => "Win32::API 0.41 required for testing GetDroppedFile()" if $@;
}

plan tests => 10;

# Load our helpers
use FindBin;
use lib "$FindBin::Bin";
use DropTest;

use Win32::GUI 1.03_02,'';
use Win32::GUI::DropFiles;

# Some Useful constants:
sub EINVAL() {22}
sub ERROR_INVALID_INDEX() {1413}

# Cygwin doesn't provide Win32 extended errors, so $^E == $!
my $EXPECTED_E = (lc $^O eq "cygwin") ? EINVAL : ERROR_INVALID_INDEX;

my @files = ( "A", "B", "Longer Name with spaces" );

my $dropobj = DropTest->new(
    files => \@files,
);

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

    # GetDroppedFiles in scalar context returns number of files
    my $count = $dropobj->GetDroppedFiles();

    my @f;
    for (0..$count-1) {
        push @f, $dropobj->GetDroppedFile($_);
    }

    ok(eq_set(\@files,\@f), "Correct set of files found");

    # Test out of range indices
    for my $index (-1, $count, 1000) {
        my($r, $e);

        $!=$^E=0;
        $r = $dropobj->GetDroppedFile($index);
        $e = $^E; # record value of $^E immediately

        is($r, undef , "Out of range index ($index) returns undef");
        SKIP: {
            skip "Can't test error values if no error", 2 if defined $r;

            cmp_ok($!, '==', EINVAL, "errno set to EINVAL");
            cmp_ok($^E, '==', $EXPECTED_E, "GetLastError returns ERROR_INVALID_INDEX");
        }
    }
    
    return -1;
}
