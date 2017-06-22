#!/usr/bin/env perl
use warnings;
use strict;

use Test::Most;
use Test::Directory;

use Test::WriteVariants;
use FindBin qw();

BEGIN
{
    use Module::Runtime qw(use_module);
    eval { use_module("File::Find::Rule", "0.34") }
      or plan skip_all => 'Need File::Find::Rule for this test';
}

my $testdir = Test::Directory->new(undef);
$testdir->clean;

my $test_writer = Test::WriteVariants->new();
$test_writer->write_test_variants(
    input_tests => $test_writer->find_input_inline_tests(
        search_patterns => ['*.it'],
        search_dirs     => [Cwd::abs_path(File::Spec->catdir($FindBin::RealBin, "inline"))],
    ),
    variant_providers => [sub { (variant1a => 11, variant1b => 12) },],
    output_dir        => $testdir->path,
);

for my $provider1 (qw(variant1a variant1b))
{

    $testdir->has_dir($provider1);

    for my $testname (qw(foo bar))
    {

        $testdir->has("$provider1/$testname.t");

    }
}

$testdir->clean;

done_testing;
