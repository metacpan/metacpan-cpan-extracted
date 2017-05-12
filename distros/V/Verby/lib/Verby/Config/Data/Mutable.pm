#!/usr/bin/perl

package Verby::Config::Data::Mutable;
use Moose;

extends qw/Verby::Config::Data/;

our $VERSION = "0.05";

use Carp qw/croak/;

sub set {
	my ( $self, $field, $value ) = @_;

	$self->data->{$field} = $value;
}

sub export {
	my ( $self, $field ) = @_;

	if ($self->exists($field)){
		my $value = $self->extract($field);
		foreach my $parent ($self->parents){
			$parent->set($field, $value);
		}
	} else {
		croak "key $field does not exist in $self";
	}
}

sub export_all {
	my $self = shift;
	foreach my $field (keys %{ $self->data }){
		$self->export($field);
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Data::Mutable - 

=head1 SYNOPSIS

	use Verby::Config::Data::Mutable;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<set>

=item B<export>

=item B<export_all>

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
