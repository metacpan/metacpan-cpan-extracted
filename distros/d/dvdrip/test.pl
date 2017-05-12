# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;

my $loaded;
my $test = 1;
my $max;

BEGIN {
    open( IN, $0 ) or die "can't read $0";
    while (<IN>) {
        ++$max if /^ok/;
    }
    close IN;
    $| = 1;
    print "1..$max\n";
}

END {
    print "not ok 1\n" if not $loaded;
}

BEGIN {
    $Video::DVDRip::PREFERENCE_FILE = "$ENV{HOME}/.dvdriprc";
    $Video::DVDRip::MAKE_TEST       = 1;
}

use Video::DVDRip::GUI::Main;

$loaded = 1;

ok( $loaded, "load dvd::rip" );

sub ok {
    my ( $cond, $comment ) = @_;
    print( $cond ? "ok " : "not ok " );
    print $test++;
    print " - $comment" if $comment;
    print "\n";
    1;
}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

