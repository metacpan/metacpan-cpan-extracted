#!/usr/bin/perl
package uniqueStrTests;
use strict;
use Moose;
extends 'Test::Module::Runnable';

use POSIX qw(EXIT_SUCCESS);
use Test::Exception;
use Test::Module::Runnable;
use Test::More;

sub setUpBeforeClass {
	my ($self) = @_;

	$ENV{TEST_UNIQUE} = 1; # Tests rely on fixed, determinate nature of unique() or uniqueStr()

	return EXIT_SUCCESS;
}

sub testNotExported {
	plan tests => 1;
	throws_ok { uniqueStr() } qr/^Undefined subroutine &uniqueStrTests::uniqueStr called/, 'not exported by default';
	return EXIT_SUCCESS;
}

sub test {
	my ($self) = @_;

	plan tests => 10;

	is($self->uniqueStr(), 'b', 'single char ok');
	is($self->uniqueStr(), 'c', 'single char returns next in line');
	is($self->uniqueStr(2), 'ad', 'two chars ok');

	$self->uniqueStr() foreach "e".."z";

	is($self->uniqueStr(), 'A', 'uppercase ok');
	$self->uniqueStr() foreach "B".."Z";

	is($self->uniqueStr(), '1', 'digits ok');
	$self->uniqueStr() foreach "2".."9";

	# test wrap around
	is($self->uniqueStr(), 'ba', 'wrap around returns 2 char string');
	is($self->uniqueStr(), 'bb', 'second 2 char string');
	is($self->uniqueStr(), 'bc', 'third 2 char string');

	is($self->uniqueStr(5), 'aaabd', 'length 5');
	is($self->uniqueStr(4), 'aabe', 'length 4');

	return EXIT_SUCCESS;
}

package main;
use strict;
exit(uniqueStrTests->new->run);
