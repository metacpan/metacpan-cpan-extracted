#!/usr/bin/env perl
use warnings;
use strict;

use Test::Most;
use Test::Directory;

use Test::WriteVariants;

my $testdir = Test::Directory->new(undef);
$testdir->clean;

my $test_writer = Test::WriteVariants->new();

$test_writer->write_test_variants(
    input_tests => {
        'foo' => {},
        'bar' => {},
    },
    variant_providers => [sub { (variant1a => 11, variant1b => 12) }, sub { (variant2a => 21, variant2b => 22) },],
    output_dir        => $testdir->path,
);

for my $provider1 (qw(variant1a variant1b))
{

    $testdir->has_dir($provider1);

    for my $provider2 (qw(variant2a variant2b))
    {

        $testdir->has_dir("$provider1/$provider2");

        for my $testname (qw(foo bar))
        {

            $testdir->has("$provider1/$provider2/$testname.t");

        }
    }
}

$testdir->clean;

done_testing;
