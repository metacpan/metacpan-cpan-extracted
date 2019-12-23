use 5.006001;
use strict;
use warnings;

package Types::DualVar;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Type::Tiny 1.008000;
use Type::Library -base;
use Scalar::Util ();

our @EXPORT = qw(DualVar);

{
	package #hide
		Types::DualVar::_Type;
	our @ISA = 'Type::Tiny';
	require Type::Tiny::ConstrainedObject;
	*stringifies_to = \&Type::Tiny::ConstrainedObject::stringifies_to;
	*numifies_to    = \&Type::Tiny::ConstrainedObject::numifies_to;
}

__PACKAGE__->add_type(
	Types::DualVar::_Type->new(
		name       => 'DualVar',
		constraint => sub { Scalar::Util::isdual($_) },
		inlined    => sub {
			my $var = pop;
			sprintf('Scalar::Util::isdual(%s)', $var);
		},
	),
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::DualVar - type constraint for dualvars

=head1 SYNOPSIS

   package MyClass {
      use Moo;
      use Types::Common::Numeric qw( PositiveInt );
      use Types::DualVar qw( DualVar );
      
      has attr => (
         is        => 'ro',
         isa       => DualVar->numifies_to(PositiveInt),
         required  => 1,
      );
   }
   
   use Scalar::Util qw( dualvar );
   
   # This is okay.
   #
   my $obj1 = MyClass->new(
      attr => dualvar(2, "-1"),
   );
   
   # This is not okay.
   #
   my $obj2 = MyClass->new(
      attr => dualvar(0, "666"),
   );
   
   # This is not okay.
   #
   my $obj3 = MyClass->new(
      attr => 42,
   );

=head1 DESCRIPTION

Types::DualVar is a type library for Moo, Moose, Mouse, or none of the above
which offers just one type: B<< DualVar >>.

B<DualVar> corresponds to the C<< isdual() >> function from L<Scalar::Util>.

The B<DualVar> type is extended with the C<stringifies_to> and
C<numifies_to> methods as documented in L<Type::Tiny::ConstrainedObject>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-DualVar>.

=head1 SEE ALSO

L<Type::Tiny::Manual>, L<Scalar::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

