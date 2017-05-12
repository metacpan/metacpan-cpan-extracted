#!/usr/bin/perl

use strict;
use warnings;

use Test::ManyParams;
use Test::More tests => 3 * 2 * 4;
use Data::Dumper;
$Data::Dumper::Indent = undef;

sub knows_all_arguments {
    my $test_method = shift();
    my @other_params = @{shift()};
    my %exp_numbers = map {$_ => 1} @{shift()};
    my $params   = shift;
    $test_method->( 
        sub { $_ = join "", @_; 
             exists $exp_numbers{$_} and delete $exp_numbers{$_} and 1;
        }, 
        @other_params,
        $params,
        "All params passed to the check routines are known " .
        "and there's no param tuple used twice (" . Dumper($params) . ")"
    );
    ok( (scalar keys %exp_numbers) == 0,
       "All params that should have passed, had been passed" .
       " (" .  Dumper($params) . ")" )
    or diag "These numbers weren't passed: ", sort {$a <=> $b} keys %exp_numbers;
}

my @STANDARD_PARAMS = (
    [ [1 .. 10]                                => [1 .. 10] ],
    [ [[1 .. 10]]                              => [1 .. 10] ],
    [ [[1 .. 9], [1 .. 9]]                     => [grep !/0/, (11 .. 99)] ], 
    [ [[1 .. 9], [1 .. 9], [1 .. 9]]           => [grep !/0/, (111 .. 999)] ]
);

foreach my $p (@STANDARD_PARAMS) {
    knows_all_arguments(\&all_ok,    [],  reverse @$p);
    knows_all_arguments(\&all_are,   [1], reverse @$p);
    knows_all_arguments(\&all_arent, [0], reverse @$p);
}
