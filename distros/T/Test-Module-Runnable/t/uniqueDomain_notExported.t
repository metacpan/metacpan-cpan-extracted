#!/usr/bin/perl
package uniqueDomainTests;
use strict;
use warnings;
use Moose;
extends 'Test::Module::Runnable';

use POSIX qw(EXIT_SUCCESS);
use Test::Exception;
use Test::Module::Runnable;
use Test::More;

sub setUpBeforeClass {
	my ($self) = @_;

	$ENV{TEST_UNIQUE} = 1; # Tests rely on fixed, determinate nature of unique() or uniqueDomain()

	return EXIT_SUCCESS;
}

sub testNotExported {
	plan tests => 1;
	throws_ok { uniqueDomain() } qr/^Undefined subroutine &uniqueDomainTests::uniqueDomain called/, 'not exported by default';
	return EXIT_SUCCESS;
}

package main;
use strict;
use warnings;
exit(uniqueDomainTests->new->run);
