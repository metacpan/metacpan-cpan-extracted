#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Test::MockObject;

use ok "Verby::Action";

can_ok("Verby::Action", "confirm");

my $v = 1;
my @args;
{
	package My::Action;
	use Moose;

	with qw/Verby::Action/;

	sub do { die }

	sub verify { push @args, [ @_ ]; $v }
}

my $o = My::Action->new;

my $logger = Test::MockObject->new;
$logger->mock(log_and_die => sub { shift; die "@_" });

my $foo = Test::MockObject->new;
$foo->set_always(logger => $logger);
$foo->set_false("error");
lives_ok { $o->confirm($foo) } "confirm when verified";
is_deeply(\@args, [ [ $o, $foo ] ], "confirm proxied args");

$logger->clear;

$v = 0;
@args = ();
my $bar = Test::MockObject->new;
$bar->set_always(logger => $logger);
$bar->set_false("error");
dies_ok { $o->confirm($bar) } "confirm when verification failed";
is_deeply(\@args, [ [ $o, $bar ] ], "confirm proxied args");

$logger->called_ok("log_and_die");

