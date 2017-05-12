use 5.008;
use strict;
use warnings;

package Tie::Moose::FallbackHash;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moose::Role;
use namespace::autoclean;
use Carp qw(croak);
use Types::Standard -types;
use Types::TypeTiny qw(HashLike);

my $hashish = Ref['HASH'] | HashLike;

has _fallback_hash => (
	is       => 'ro',
	isa      => $hashish,
	required => 1,
	init_arg => 'fallback',
);

override fallback => sub
{
	my $self = shift;
	my ($operation, $key, $value) = @_;
	my $hash = $self->_fallback_hash;
	
	for ($operation)
	{
		if ($_ eq "FETCH")  { return $hash->{$key} }
		if ($_ eq "STORE")  { return $hash->{$key} = $value }
		if ($_ eq "EXISTS") { return exists $hash->{$key} }
		if ($_ eq "DELETE") { return delete $hash->{$key} }
		
		confess "This should never happen!";
	}
};

1;

__END__

=head1 NAME

Tie::Moose::FallbackHash - provide a fallback hashref for unknown attributes

=head1 SYNOPSIS

	my %data;
	tie(
		my %bob,
		"Tie::Moose"->with_traits("FallbackHash"),
		$bob, fallback => \%data,
	);
	
	$bob{xyz} = 123;   # $bob doesn't have an attribute called "xyz"
	say $data{xyz};    # ... so this gets stored in the fallback hash

=head1 DESCRIPTION

Usually if you try to store data against a hash key which does not have a
corresponding attribute in the underlying Moose object, L<Tie::Moose> will
throw an exception. This module allows you to instead store it into a
fallback hash.

The fallback hash can itself be a tied hash, or an object which overloads
C<< %{} >>, so this allows for some interesting possibilities.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Tie-Moose>.

=head1 SEE ALSO

L<Tie::Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

