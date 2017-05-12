use 5.008;
use strict;
use warnings;

package Tie::Moose::Forgiving;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moose::Role;
use namespace::autoclean;

override fallback => sub
{
	my $self = shift;
	my ($operation, $key, $value) = @_;
	
	for ($operation)
	{
		if ($_ eq "FETCH")  { return; }
		if ($_ eq "STORE")  { super; }
		if ($_ eq "EXISTS") { return; }
		if ($_ eq "DELETE") { return; }
		
		confess "This should never happen!";
	}
};

1;

__END__

=head1 NAME

Tie::Moose::Forgiving - don't die at the mere mention of an unknown key

=head1 SYNOPSIS

	tie my %bob, "Tie::Moose"->with_traits("Forgiving"), $bob;

=head1 DESCRIPTION

L<Tie::Moose> is very happy to throw exceptions.

If, for example, you use a hash key that doesn't correspond to one of the
object's attributes, it will croak. Even if you used C<exists>!

This trait prevents read-only accesses from throwing due to unknown
attributes.

	use v5.14;
	
	package Person {
		use Moose;
		has name => (
			is     => "rw",
			isa    => "Str",
		);
		has age => (
			is     => "rw",
			isa    => "Num",
			reader => "get_age",
			writer => "set_age",
		);
	}
	
	my $bob = Person->new(name => "Robert");
	
	tie my %bob, "Tie::Moose"->with_traits("Forgiving"), $bob;
	
	my $x = $bob{xyz};   # ok ($x is undef)
	$bob{xyz} = $x;      # would croak

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

