package Test::Proto::Series;
use strict;
use warnings;
use Moo;

has 'contents',
	is      => 'rw',
	default => sub { [] };

sub BUILDARGS {
	my $class = shift;
	return { contents => [@_] };
}

around 'contents' => \&Test::Proto::Common::chainable;

=head1 NAME

Test::Proto::Series - represent a series in array validation

=head1 SYNOPSIS

	pArray->contains_only(pSeries('a', 'b', 'c')); 
	# will validate ['a', 'b', 'c'] as true

Used in array validation to represent a sequence which must be present in its entirety. Only really useful when used in combination with L<Test::Proto::Repeatable> and L<Test::Proto::Alternation>, which can be nested inside a series, or can contain a series. 

=head1 METHODS

=head3 new

Each argument is another element in the series. 

=head3 contents

	die unless exists $alternation->contents->[0];

A chainable getter/setter method for the contents of the series.

=cut

1;
