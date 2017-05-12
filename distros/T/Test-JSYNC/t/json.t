#!perl
use strict;
use warnings;
use Test::Tester;
use Test::More tests => 36;
use Test::JSYNC;

my $json = '{"bool":1,"name":"foo","id":1,"description":null}';
my ($name, $invalid, $is, $isnt);

$name = 'Identical JSON should match';
$is   = '{"bool":1,"name":"foo","id":1,"description":null}';
check_test(
    sub { jsync_is $json, $is, $name },
    {
        ok   => 1,
        name => $name,
    },
    $name
);

$name = 'Attribute order should not matter';
$is   = '{"bool":1,"id":1,"name":"foo","description":null}';
check_test(
    sub { jsync_is $json, $is, $name },
    {
        ok   => 1,
        name => $name,
    },
    $name
);

# null is misspelled
$name    = 'Invalid JSON should fail';
$invalid = '{"bool":1,"name":"fo","id":1,"description":nul}';
check_test(
    sub { jsync_is $json, $invalid, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);

# "fo" should be "foo"
$name = 'Different JSON should fail';
$isnt = '{"bool":1,"name":"fo","id":1,"description":null}';
check_test(
    sub { jsync_is $json, $isnt, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);

$name = 'Valid JSON should succeed';
$json = '{"bool":1,"name":"fo","id":1,"description":null}';
check_test(
    sub { jsync_ok $json, $name },
    {
        ok   => 1,
        name => $name,
    },
    $name
);

$name    = 'Invalid JSON should fail';
$invalid = '{"bool":1,"name":"fo","id":1,"description":nul}';
check_test(
    sub { jsync_ok $invalid, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);
