#! perl -w
use strict;

# $Id$

# Add the test-lines in the '    EOT' here-document
# First char should be 'P' for PASS (we don't want it)
# and 'F' for FAIL (we _do_ want it)
# Second char should be a single space (for readability)
# Rest of the line will be tested!

my @tests;
BEGIN {
    @tests = split /\n/, <<'    EOT';
P op/strict.............ok
F op/strict.............FAILED
F       FAILED 4/10
P t/op/64bitint........................skipping test on this platform
F run/switches...........................FAILED test 7
F        Failed 1/20 tests, 95.00% okay
F Failed 1/736 test scripts, 99.86% okay. 1/70360 subtests failed, 100.00% okay.
F Failed Test    Stat Wstat Total Fail  Failed  List of Failed
F -------------------------------------------------------------------------------
F run/switches.t               20    1   5.00%  7
F 54 tests and 609 subtests skipped.
P C:\usr\local\src\bleadperl\perl\miniperl.exe "-I..\..\lib" "-I..\..\lib" -MExtUtils::Command -e cp bin/piconv blib\script\piconv
P C:\usr\local\src\bleadperl\perl\miniperl.exe "-I..\..\lib" "-I..\..\lib" -MExtUtils::Command -e cp bin/enc2xs blib\script\enc2xs
P Creating library file: libExtTest.dll.a
P not ok 43 # SKIP see perldelta583
P base/cond...................................ok    0.060s
P base/cond...................................ok       60 ms
P cc: warning 983: The -lc library specified on the command line is also added automatically by the compiler driver.  
F t/porting/pending-author ...................................... FAILED at test 1
P t/porting/perlfunc ............................................ ok
P t/lib/cygwin .................................................. skipped
    EOT
}

use Test::More tests => 2 + @tests;

use_ok 'Test::Smoke::Util', 'skip_filter';

for my $test ( @tests ) {
    my( $pf, $line ) = $test =~ /^(.) (.*)$/;

    if ( $pf =~ /[pP]/ ) {
        ok( skip_filter( $line ), "P: $line" );
    } else {
        ok( !skip_filter( $line ), "F: $line" );
    }
}

{
    my $outputfile = 't/logs/5.19.0-make._test.stdout';
    open my $tst, '<', $outputfile or die "Cannot open($outputfile): $!";

    my @nok;
    while (<$tst>) {
        chomp;
        skip_filter($_) and next;
        m/^u=.*tests=/ and next;        
        (my $tname = $_) =~ s/\s*\.+.*/.t/;
        push @nok, $tname;
    }
    close $tst;

    is_deeply(
        \@nok,
        [
            't/porting/pending-author.t',
        ],
        "Grep()ed all failing tests"
    );
}
