package Zuzu::Util::Number;

use utf8;

our $VERSION = '0.006000';

use Exporter qw( import );

our @EXPORT_OK = qw(
	is_finite_number
);

my $POSITIVE_INFINITY = 9**9**9;
my $NEGATIVE_INFINITY = -$POSITIVE_INFINITY;

sub is_finite_number {
	my ( $number ) = @_;

	$number = 0 + $number;
	return 0 if $number != $number;
	return 0 if $number == $POSITIVE_INFINITY;
	return 0 if $number == $NEGATIVE_INFINITY;
	return 1;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Util::Number >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
