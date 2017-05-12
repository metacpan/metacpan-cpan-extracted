#!/usr/bin/perl

package StringHarness;
use base qw/Exporter/;

use strict;
use warnings;

our @EXPORT = qw/strap_this/;

sub strap_this {
	my $s = shift->new;

	while (@_){
		my $name = shift;
		my $output = shift;
		$output = [split /\n/,$output];

		my $r = $s->start_file($name);
		eval { $r->{results} = $s->analyze($name, $output) };
	}

	return $s;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

StringHarness - 

=head1 SYNOPSIS

	use StringHarness;

=head1 DESCRIPTION

=cut


