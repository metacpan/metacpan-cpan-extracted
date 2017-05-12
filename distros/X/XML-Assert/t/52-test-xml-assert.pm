#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";

our $tests_pass;
our $tests_fail;

BEGIN {
    $tests_pass = [
       {
           xpath => '//Error',
           count => 0,
           name  => 'Error in response',
       },
       {
           xpath => '//price',
           count => 3,
           name  => 'Three prices found',
       },
    ];

    $tests_fail = [
       {
           xpath => '//price',
           count => 2,
           name  => 'Three prices, not two',
       },
    ];

    require Test::Builder::Tester;
    Test::Builder::Tester->import(tests => 2);
}

require Test::XML::Assert;
Test::XML::Assert->import;

require 'data.pl';
my $parser = XML::LibXML->new();
my $doc = $parser->parse_string( xml() )->documentElement();

my $t;

# two passing tests
$t = $tests_pass->[0];
test_out('ok 1 - Error in response');
is_xpath_count($doc, {}, $t->{xpath}, $t->{count}, $t->{name});
test_test($t->{name});

$t = $tests_pass->[1];
test_out('ok 1 - Three prices found');
is_xpath_count($doc, {}, $t->{xpath}, $t->{count}, $t->{name});
test_test($t->{name});

# a failing test
$t = $tests_fail->[0];
test_out('not ok 1 - Three prices, not two');
test_fail(1);
is_xpath_count($doc, {}, $t->{xpath}, $t->{count}, $t->{name});
test_test($t->{name});
