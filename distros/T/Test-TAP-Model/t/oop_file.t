#!/usr/bin/perl

use strict;
use warnings;

# TODO not very comprehensive

use Test::More tests => 16;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model::File") }

{
	package MockRes;
	sub new {
		my ( $pkg, %fields ) = @_;
		bless \%fields, $pkg;
	}

	sub AUTOLOAD {
		my $self = shift;
		my ( $field ) = ( our $AUTOLOAD =~ /([^:]+)$/ );
		$self->{ $field };
	}
}

isa_ok(my $f = $m->new(my $file = {
	events => [
		my $ok_case = {
			type => "test",
			ok => 1,
		},
		my $nok_case = {
			type => "test",
			ok => 0,
		},
	],
	results => my $r = MockRes->new(
		passing => 0,
		ok => 10,
		todo => 11,
		max => 3,
		seen => 12,
		skip => 13,
	),
}), $m);

ok(!$f->ok, "failed");
$r->{passing} = 1;
ok($f->ok, "passed");
is($f->passed, $f->ok, "alias");
is($f->failed, !$f->ok, "negation");

ok(!$f->skipped, "not all skipped");
$r->{skip_all} = "reason";
ok($f->skipped, "all skipped");

# demonstrates scalar context
is($f->max, 3, "3 planned");
is($f->seen, 12, "but two seen");
is($f->passed_tests, 10, "10 of these passed");
is($f->failed_tests, 12-10, "2 failed");
is($f->todo_tests, 11, "none are todo");
$nok_case->{todo} = 1;
is($f->todo_tests, 11, "none are todo");
$r->{todo} = 2;
is($f->todo_tests, 2, "two todo");
is($f->skipped_tests, 13, "13 skipped");
