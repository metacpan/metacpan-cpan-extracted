#!perl -w
# Win32::GUI::DropFiles test suite
# $Id: 07_DragQueryFile.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# Test Win32::GUI::DropFiles DragQueryFile() function

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# We assume that 01_load.t has been run, so we know we have Test::More
# and that Win32::GUI and Win32::GUI::DropFiles will load.

use Test::More;
 
BEGIN {
    eval "use Win32::API 0.41";
    plan skip_all => "Win32::API 0.41 required for testing DragQueryFile()" if $@;
}

plan tests => 33;

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

    # DragQueryFile with no params returns the number of files
    is(Win32::GUI::DropFiles::DragQueryFile($dropobj), scalar @files, "Correct number of files when passed object");
    is(Win32::GUI::DropFiles::DragQueryFile($dropobj->{-handle}), scalar @files, "Correct number of files when passed handle");
    is($dropobj->DragQueryFile(), scalar @files, "Correct number of files when called as method");

    # DragQueryFile with one param returns file name
    my $count = $dropobj->GetDroppedFiles();
    
    {
        my @f;
        for (0..$count-1) {
            push @f, Win32::GUI::DropFiles::DragQueryFile($dropobj, $_);
        }

        ok(eq_set(\@files,\@f), "Correct set of files found when passed object");

        # Test out of range indices
        for my $index (-1, $count, 1000) {
            my($r, $e);

            $!=$^E=0;
            $r = Win32::GUI::DropFiles::DragQueryFile($dropobj,$index);
            $e = $^E; # record value of $^E immediately

            is($r, undef , "Out of range index ($index) returns undef when passed object");
            SKIP: {
                skip "Can't test error values if no error", 2 if defined $r;

                cmp_ok($!, '==', EINVAL, "errno set to EINVAL");
                cmp_ok($^E, '==', $EXPECTED_E, "GetLastError returns ERROR_INVALID_INDEX");
            }
        }
    }
    {
        my @f;
        for (0..$count-1) {
            push @f, Win32::GUI::DropFiles::DragQueryFile($dropobj->{-handle}, $_);
        }

        ok(eq_set(\@files,\@f), "Correct set of files found when passed handle");

        # Test out of range indices
        for my $index (-1, $count, 1000) {
            my($r, $e);

            $!=$^E=0;
            $r = Win32::GUI::DropFiles::DragQueryFile($dropobj->{-handle},$index);
            $e = $^E; # record value of $^E immediately

            is($r, undef , "Out of range index ($index) returns undef when passed handle");
            SKIP: {
                skip "Can't test error values if no error", 2 if defined $r;

                cmp_ok($!, '==', EINVAL, "errno set to EINVAL");
                cmp_ok($^E, '==', $EXPECTED_E, "GetLastError returns ERROR_INVALID_INDEX");
            }
        }
    }
    {
        my @f;
        for (0..$count-1) {
            push @f, $dropobj->DragQueryFile($_);
        }

        ok(eq_set(\@files,\@f), "Correct set of files found when called as method");

        # Test out of range indices
        for my $index (-1, $count, 1000) {
            my($r, $e);

            $!=$^E=0;
            $r = $dropobj->DragQueryFile($index);
            $e = $^E; # record value of $^E immediately

            is($r, undef , "Out of range index ($index) returns undef when called as method");
            SKIP: {
                skip "Can't test error values if no error", 2 if defined $r;

                cmp_ok($!, '==', EINVAL, "errno set to EINVAL");
                cmp_ok($^E, '==', $EXPECTED_E, "GetLastError returns ERROR_INVALID_INDEX");
            }
        }
    }
    
    return -1;
}
