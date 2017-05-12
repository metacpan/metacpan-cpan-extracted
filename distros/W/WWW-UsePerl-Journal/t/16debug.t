#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;
use WWW::UsePerl::Journal;

my $username = "barbie";
my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j, "WWW::UsePerl::Journal");

my $mess = $j->log();
is($j->debug(),0,'... debug off');
is(length($mess),0,'... no debug messages');

is($j->debug(1),1,'... debug on');
$j->log('mess' => 'Test');
$mess = $j->log();
is($j->debug(),1,'... debug on');
is($mess,'Test','... short debug message');

$j->log('clear' => 1);
$mess = $j->log();
is(length($mess),0,'... debug messages cleared');

is($j->debug(0),0,'.. debug off');
