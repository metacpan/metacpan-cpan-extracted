use 5.008;
use strict;
use warnings;

package Type::Libraries;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Type::Library ();
use Type::Utils ();
use Module::Runtime qw(module_notional_filename);

sub import
{
	my ($me, $lib, @args) = @_;
	return unless $lib;
	
	my $shim = $me->_make_class(ref $lib ? @$lib : $lib);
	
	my $import = $shim->can('import');
	@_ = ($shim, @args);
	goto $import;
}

my $ident = 0;
my %cache;

sub _make_class
{
	my ($me, @lib) = @_;
	
	my $id = ( $cache{join '|', sort @lib} ||= ++$ident );
	my $class = sprintf("%s::__SHIMS__::%04d", $me, $id);
	
	unless ($INC{module_notional_filename($class)})
	{
		$INC{module_notional_filename($class)} = __FILE__;
		$me->setup_class($class, @lib);
	}
	
	return $class;
}

sub setup_class
{
	my ($me, $class, @lib) = @_;
	
	eval qq{
		package $class;
		use Type::Library -base;
		Type::Utils::extends( \@lib );
		1;
	} or die($@);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Libraries - bundle up multiple type constraint libraries

=head1 SYNOPSIS

   package Contact {
      use Moo;
      use MooX::late;
      
      use Type::Libraries [qw(
         Types::Standard
         MooseX::Types::Common::Numeric
         MouseX::Types::URI
      )], qw( ArrayRef NegativeInt PositiveInt Uri );
      
      has house_number => (
         is     => 'ro',
         isa    => PositiveInt->plus_coercions(NegativeInt, '-$_'),
         coerce => 1,
      );
      
      has websites => (
         is     => 'ro',
         isa    => ArrayRef[Uri],
         coerce => 1,
      );
   }

=head1 DESCRIPTION

Type::Libraries allows you to import type constraints from multiple
type constraint libraries in a single C<use> statement.

Whatsmore, it wraps type constraints using L<Type::Tiny> to ensure
that the imported type constraint keywords will work in L<Moose>-,
L<Moo>-, and L<Mouse>-based classes and roles. Yes, that's right: you
can use L<MooseX::Types> libraries in L<Moo>; L<MouseX::Types>
libraries in L<Moose> and so on.

=head2 Using Type::Libraries in classes and roles

The example in the L</SYNOPSIS> demonstrates how to use
L<Type::Libraries> in your class or role. (The example uses the
L<MooX::late> extension for L<Moo> to enable C<< coerce => 1 >> to
work. Without this extension, L<Moo> coercions need to be a coderef,
but it by no means necessary to use L<MooX::late> if you're using
Type::Libraries.)

The basic syntax for importing types is:

   use Type::Libraries \@libraries, @types;

For further information, see:

=over

=item *

L<Type::Tiny::Manual::UsingWithMoose>

=item *

L<Type::Tiny::Manual::UsingWithMoo>

=item *

L<Type::Tiny::Manual::UsingWithMouse>

=item *

L<Type::Tiny::Manual::UsingWithOther>

=back

=head2 Using Type::Libraries to create a union type library

You can also use Type::Libraries to create your own type constraint
library which is the union of several pre-existing one:

   package MyTypes {
      use Type::Libraries;
      Type::Libraries->setup_class(
         __PACKAGE__,   # me
         qw(
            Types::Standard
            MooseX::Types::Common::Numeric
            MouseX::Types::URI
         ),
      );
   }

Your union type library can then be imported from:

   use MyTypes qw( ArrayRef NegativeInt PositiveInt Uri );

=begin trustme

=item setup_class

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Libraries>.

=head1 SEE ALSO

L<MooseX::Types::Combine> is similar, but only supports
L<MooseX::Types> libraries.

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

