#!perl
use strict;
use warnings;
use Test::Tester;
use Test::More tests => 36;
use Test::JSYNC;

my $jsync = '[{"&":"1","..!":"foo","a":"*1"},["!!perl/array:Foo","*1",null]]';
my ($name, $invalid, $is, $isnt);

$name = 'Identical JSYNC should match';
$is   = '[{"&":"1","..!":"foo","a":"*1"},["!!perl/array:Foo","*1",null]]';
check_test(
    sub { jsync_is $jsync, $is, $name },
    {
        ok   => 1,
        name => $name,
    },
    $name
);

$name = 'Attribute order should not matter';
$is   = '[{"&":"1","a":"*1","..!":"foo"},["!!perl/array:Foo","*1",null]]';
check_test(
    sub { jsync_is $jsync, $is, $name },
    {
        ok   => 1,
        name => $name,
    },
    $name
);

# inalid type: perl/arry
$name    = 'Invalid JSYNC should fail';
$invalid = '[{"&":"1","..!":"foo","a":"*1"},["!!perl/arry:Foo","*1",null]]';
check_test(
    sub { jsync_is $jsync, $invalid, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);

# "*2" should be "*1"
$name = 'Different JSYNC should fail';
$isnt = '[{"&":"1","..!":"foo","a":"*1"},["!!perl/array:Foo","*2",null]]';
check_test(
    sub { jsync_is $jsync, $isnt, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);

$name  = 'Valid JSYNC should succeed';
$jsync = '[{"&":"1","..!":"foo","a":"*1"},["!!perl/array:Foo","*1",null]]';
check_test(
    sub { jsync_ok $jsync, $name },
    {
        ok   => 1,
        name => $name,
    },
    $name
);

$name    = 'Invalid JSYNC should fail';
$invalid = '[{"&":"1","..!":"foo","a":"*1"},["!!perl/arry:Foo","*1",null]]';
check_test(
    sub { jsync_ok $invalid, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);
