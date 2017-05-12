package Tie::Filter::Scalar;

use 5.008;
use strict;
use warnings;

use Tie::Filter;

our $VERSION = '1.02';

=head1 NAME

Tie::Filter::Scalar - Tie a facade around a scalar

=head1 DESCRIPTION

Don't use this package directly. Instead, see L<Tie::Filter>.

=cut

sub TIESCALAR {
	my ($class, $scalar, %args) = @_;
	$args{WRAP} = $scalar;
	return bless \%args, $class;
}

sub FETCH {
	my $self = shift;
	Tie::Filter::_filter($$self{FETCH}, ${$$self{WRAP}});
}

sub STORE {
	my $self = shift;
	my $value = shift;
	${$$self{WRAP}} = Tie::Filter::_filter($$self{STORE}, $value);
}

sub UNTIE { }

sub DESTROY { }

=head1 SEE ALSO

L<perltie>, L<Tie::Filter>

=head1 AUTHOR

  Andrew Sterling Hanenkamp, <sterling@hanenkamp.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2003 Andrew Sterling Hanenkamp. All Rights Reserved. This library is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1

