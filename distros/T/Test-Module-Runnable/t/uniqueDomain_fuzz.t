#!/usr/bin/perl
package Tester_uniqueDomain_fuzzTests;
use strict;
use warnings;
use Moose;
extends 'Test::Module::Runnable';

use POSIX qw(EXIT_SUCCESS);
use Readonly;
use Test::Module::Runnable;
use Test::More;

Readonly my $ITERATIONS => 100;

sub setUp {
	my ($self) = @_;

	$self->sut($self);

	return EXIT_SUCCESS;
}

sub testLettersOnly {
	my ($self) = @_;
	plan tests => $ITERATIONS;

	foreach (1 .. $ITERATIONS) {
		my $domain = $self->uniqueDomain({ lettersOnly => 1 });
		unlike($domain, qr/\d/, "$domain does not contain digits");
	}

	return EXIT_SUCCESS;
}

sub testAllowNumbers {
	my ($self) = @_;
	plan tests => 1;

	my $seenNumbers = 0;
	foreach (1 .. $ITERATIONS) {
		my $domain = $self->uniqueDomain();
		$seenNumbers++ if $domain =~ /\d/;
	}

	cmp_ok($seenNumbers, '>', 0, "$seenNumbers domains had a number in them");

	return EXIT_SUCCESS;
}

package main;
use strict;
use warnings;
exit(Tester_uniqueDomain_fuzzTests->new->run);
