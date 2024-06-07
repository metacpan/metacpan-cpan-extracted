#!/usr/bin/perl
package uniqueDomainTests;
use strict;
use warnings;
use Moose;
extends 'Test::Module::Runnable';

use POSIX qw(EXIT_SUCCESS);
use Test::Module::Runnable;
use Test::More 0.96;

sub setUpBeforeClass {
	my ($self) = @_;

	$ENV{TEST_UNIQUE} = 1; # Tests rely on fixed, determinate nature of unique() or uniqueStr()

	return EXIT_SUCCESS;
}

sub setUp {
	my ($self) = @_;

	$self->sut(Test::Module::Runnable->new());

	return EXIT_SUCCESS;
}

sub test {
	my ($self) = @_;
	plan tests => 7;

	is($self->uniqueDomain, 'aaab.aac.ad.test', 'first domain');
	is($self->uniqueDomain, 'ae.aaaaf.g.aah.test', 'second domain');
	is($self->uniqueDomain, 'aaaai.aj.k.aaal.aam.test', 'third domain');
	is($self->uniqueDomain, 'aan.aaao.test', 'fourth domain');
	is($self->uniqueDomain, 'p.q.aaaar.test', 'fifth domain');
	is($self->uniqueDomain, 'aaas.aat.aaau.v.test', 'sixth domain');

	is($self->uniqueDomain({ length => 8 }), 'aaaaaaaw.aaaax.aaay.az.bc1.test', 'seventh domain, with length specified');

	return EXIT_SUCCESS;
}

package main;
use strict;
use warnings;
exit(uniqueDomainTests->new->run);
