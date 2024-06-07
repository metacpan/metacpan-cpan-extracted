#!/usr/bin/perl
package uniqueExportTests;
use strict;
use warnings;
use Moose;
extends 'Test::Module::Runnable';

use POSIX qw(EXIT_SUCCESS);
use Test::More 0.96;

use Test::Module::Runnable qw(unique uniqueDomain uniqueStr uniqueStrCI uniqueLetters);

sub setUpBeforeClass {
	my ($self) = @_;

	$ENV{TEST_UNIQUE} = 1; # Tests rely on fixed, determinate nature of unique() or uniqueStr()

	return EXIT_SUCCESS;
}

sub test {
	plan tests => 5;

	is(unique(), 1, 'unique() has been exported');
	is(uniqueStr(), 'c', 'uniqueStr() has been exported');
	is(uniqueStrCI(), 'd', 'uniqueStr() has been exported');
	is(uniqueDomain(), 'aaae.aaf.ag.test', 'uniqueDomain() has been exported');
	is(uniqueLetters(), 'h', 'uniqueLetters() has been exported');

	return EXIT_SUCCESS;
}

package main;
use strict;
use warnings;
exit(uniqueExportTests->new->run);
