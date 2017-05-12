#!/usr/bin/perl

package Test::TAP::Model::Visual;
use base qw/Test::TAP::Model/;

use strict;
use warnings;

use Test::TAP::Model::Colorful;
use Test::TAP::Model::File::Visual;

sub file_class { "Test::TAP::Model::File::Visual" }

sub get_test_files {
	my $self = shift;
	my $str = $self->desc_string;
	map { $_->desc_string($str); $_ } $self->SUPER::get_test_files(@_);
}

sub desc_string {
	my $self = shift;
	$self->{_desc_string} = shift if @_;
	$self->{_desc_string} ||= "";
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::Model::Visual - A result set that will create ::Visual children, and
knows it's color.

=head1 SYNOPSIS

	See template

=head1 DESCRIPTION

It inherits from L<Test::TAP::Model::Colorful>. That's about it.

=head1 METHODS

=over 4

=item file_class

This is actually the only functionality. This method is overridden to return
L<Test::TAP::Model::File::Visual>. See L<Test::TAP::Model/file_class> for
details.

=item summary

A nice little textual summary about the result of the entire test run.

=item desc_string

A short descriptive string used to distinguish this model from others in the
various consolidated reports.

=item get_test_files

An overridden version of get_test_files which sets C<desc_string> on the files
based on the one from $self.

=back

=cut
