#!/usr/bin/perl

package Test::TAP::Model::Colorful;

use strict;
use warnings;

use Test::TAP::Model;
use Test::TAP::Model::File;

# yucky mixin behavior
BEGIN {
	push @Test::TAP::Model::ISA, __PACKAGE__;
	push @Test::TAP::Model::File::ISA, __PACKAGE__;
}

sub color {
	my $self = shift;

	my $ratio = $self->ratio;

	my $l= 100;
	if ($ratio == 1){
		return "#00ff00";
	} else {
		return sprintf("#ff%02x%02x", $l + ((255 - $l) * $ratio), $l-20);
	}
}

sub color_css {
	my $self = shift;
	return "background-color: " . $self->color;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::Model::Colorful - Creates color from something that
knows it's success ratio.

=head1 SYNOPSIS

	See template

=head1 DESCRIPTION

Provides methods that are used to color the test matrix.

=head1 METHODS

=over 4

=item color

A string in hex format (C<#xxxxxx>) corresponding to an RGB color representing
the ratio or success.

=item color_css

Wraps the color in a C<background-color: %s>.

=back

=cut
