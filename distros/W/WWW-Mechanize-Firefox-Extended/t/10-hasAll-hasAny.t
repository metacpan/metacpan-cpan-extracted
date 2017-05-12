#!perl -w
use strict;
use Time::HiRes qw/tv_interval gettimeofday/;
use Test::More;

use lib 'lib';
use WWW::Mechanize::Firefox::Extended;

my $o = eval { WWW::Mechanize::Firefox::Extended->new() };

if (! $o) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
    exit;
} else {
    plan tests => 5;
};

isa_ok $o, 'WWW::Mechanize::Firefox::Extended';

my $DEBUG = 0;
my ($got, $exp, $msg, $tmp);
my ($t0, $elapsed, $wait, $found);

#----- Test hasAll()
$o->get_local('10-hasAll-hasAny.html');

$msg = 'hasAll() - Positive test';
$got = $o->hasAll('#form1', '//input[@name="username"]', '.ui');
$exp = '1';
is($got, $exp, $msg);

$msg = 'hasAll() - Negative test';
$got = $o->hasAll('#form1', '//input[@name="username"]', '.uix');
$exp = '0';
is($got, $exp, $msg);

#----- Test hasAny()
$o->get_local('10-hasAll-hasAny.html');

$msg = 'hasAny() - Positive test';
$got = $o->hasAny('#form1', '//input[@name="username"]', 'xxx');
$exp = '1';
is($got, $exp, $msg);

$msg = 'hasAny() - Negative test';
$got = $o->hasAll('#form1xxx', '//input[@name="username"]xxx', '.uix');
$exp = '0';
is($got, $exp, $msg);

