#!perl

# This is the test case for Bug 42903.  This bug was found by Kevin Ryde,
# and he supplied the basics of this test case.

use strict;
use warnings;

use Test::More tests => 3;
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

BEGIN {
    Test::More::use_ok('Test::Weaken');
}

my $result = q{};
{
    my $leak;
    my $test = Test::Weaken::leaks(
        sub {
            my $aref = ['abc'];
            my $obj = { array => $aref };
            $leak = $aref;
            return $obj;
        }
    );
    my $unfreed_proberefs = $test ? $test->unfreed_proberefs() : [];
    for my $ix ( 0 .. $#{$unfreed_proberefs} ) {
        $result .= Data::Dumper->Dump( [ $unfreed_proberefs->[$ix] ],
            ["unfreed_$ix"] );
    }
    $result .= Data::Dumper->Dump( [$leak], ['leak'] );
}
Test::Weaken::Test::is( $result, <<'EOS', 'CPAN Bug ID 42903, example 1' );
$unfreed_0 = [
               'abc'
             ];
$unfreed_1 = \'abc';
$leak = [
          'abc'
        ];
EOS

$result = q{};
{
    my $leak;
    my $test = Test::Weaken::leaks(
        sub {
            my $aref = [ 'def', ['ghi'] ];
            my $obj = { array => $aref };
            $leak = $aref;
            return $obj;
        }
    );
    my $unfreed_proberefs = $test ? $test->unfreed_proberefs() : [];
    for my $ix ( 0 .. $#{$unfreed_proberefs} ) {
        $result .= Data::Dumper->Dump( [ $unfreed_proberefs->[$ix] ],
            ["unfreed_$ix"] );
    }
    $result .= Data::Dumper->Dump( [$leak], ['leak'] );
}
Test::Weaken::Test::is( $result, <<'EOS', 'CPAN Bug ID 42903, example 2' );
$unfreed_0 = [
               'def',
               [
                 'ghi'
               ]
             ];
$unfreed_1 = \'def';
$unfreed_2 = \[
                 'ghi'
               ];
$unfreed_3 = [
               'ghi'
             ];
$unfreed_4 = \'ghi';
$leak = [
          'def',
          [
            'ghi'
          ]
        ];
EOS
