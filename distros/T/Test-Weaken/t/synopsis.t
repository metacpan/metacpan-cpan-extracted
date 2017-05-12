#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use Fatal qw(open close);

BEGIN {
  unless ($] >= 5.008) {
    plan skip_all => 'due to test code no good for 5.006 yet';
  }
  plan tests => 2;
}

use lib 't/lib';
use Test::Weaken::Test;

BEGIN { Test::More::use_ok('Test::Weaken') }

## no critic (InputOutput::RequireBriefOpen)
open my $save_stdout, '>&STDOUT';
## use critic

close STDOUT;
my $code_output;
open STDOUT, q{>}, \$code_output;

## use Marpa::Test::Display synopsis

use Test::Weaken qw(leaks);
use Data::Dumper;
use Math::BigInt;
use Math::BigFloat;
use Carp;
use English qw( -no_match_vars );

my $good_test = sub {
    my $obj1 = Math::BigInt->new('42');
    my $obj2 = Math::BigFloat->new('7.11');
    [ $obj1, $obj2 ];
};

if ( !leaks($good_test) ) {
    print "No leaks in test 1\n"
        or Carp::croak("Cannot print to STDOUT: $ERRNO");
}
else {
    print "There were memory leaks from test 1!\n"
        or Carp::croak("Cannot print to STDOUT: $ERRNO");
}

my $bad_test = sub {
    my $array = [ 42, 711 ];
    push @{$array}, $array;
    $array;
};

my $bad_destructor = sub {'I am useless'};

my $tester = Test::Weaken::leaks(
    {   constructor => $bad_test,
        destructor  => $bad_destructor,
    }
);
if ($tester) {
    my $unfreed_proberefs = $tester->unfreed_proberefs();
    my $unfreed_count     = @{$unfreed_proberefs};
    printf "Test 2: %d of %d original references were not freed\n",
        $tester->unfreed_count(), $tester->probe_count()
        or Carp::croak("Cannot print to STDOUT: $ERRNO");
    print "These are the probe references to the unfreed objects:\n"
        or Carp::croak("Cannot print to STDOUT: $ERRNO");
    for my $ix ( 0 .. $#{$unfreed_proberefs} ) {
        print Data::Dumper->Dump( [ $unfreed_proberefs->[$ix] ],
            ["unfreed_$ix"] )
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
    }
}

## no Marpa::Test::Display

open STDOUT, q{>&}, $save_stdout;

Test::Weaken::Test::is( $code_output, <<'EOS', 'synopsis output' );
No leaks in test 1
Test 2: 4 of 5 original references were not freed
These are the probe references to the unfreed objects:
$unfreed_0 = [
               42,
               711,
               $unfreed_0
             ];
$unfreed_1 = \42;
$unfreed_2 = \711;
$unfreed_3 = \[
                 42,
                 711,
                 ${$unfreed_3}
               ];
EOS
