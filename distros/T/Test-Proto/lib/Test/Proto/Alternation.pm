package Test::Proto::Alternation;
use strict;
use warnings;
use Moo;

has 'alternatives',
	is      => 'rw',
	default => sub { [] };

sub BUILDARGS {
	my $class = shift;
	return { alternatives => [@_] };
}

around 'alternatives' => \&Test::Proto::Common::chainable;

=head1 NAME

Test::Proto::Alternation - represent an alternation in array validation

=head1 SYNOPSIS

	pArray->contains_only(pAlternation('a', pSeries('b', 'c'))); 
	# will validate ['a'] and ['b', 'c'] as true

Used in array validation to represent different options. Equivalent to C<|> in a regular expression. There is no limit to the number of alternatives which may be specified, but there must be at least one. This can handle nested L<Test::Proto::Series> and L<Test::Proto::Repeatable> elements, and can be nested within them. 

For single-item alternation consider using C<Test::Proto::Base::any_of>.

=head1 METHODS

=head3 new

Each argument is a different alternative. 

=head3 alternatives

	die unless exists $alternation->alternatives->[0];

A chainable getter/setter method for the different alternatives available to the alternation.

=cut

1;
