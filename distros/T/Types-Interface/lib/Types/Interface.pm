use 5.008;
use strict;
use warnings;

package Types::Interface;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Carp qw( croak );
use Role::Inspector qw( get_role_info );
use Type::Library -base, -declare => qw( ClassDoesInterface ObjectDoesInterface );
use Types::LoadableClass qw( LoadableClass );
use Types::Standard qw( Object );

my %common = (
	constraint_generator => sub {
		my ($role, %opts) = @_;
		my $info = get_role_info($role)
			or croak("$role does not seem to be a role");
		my @methods = @{$info->{api}};
		@methods = grep(!/\A_/, @methods)
			if exists($opts{private}) && !$opts{private};
		
		return sub {
			$_->DOES($role) or do {
				my $ok = 1;
				for my $method (@methods) {
					$_->can($method) or ($ok=0, next);
				}
				$ok;
			};
		};
	},
	
	inline_generator => sub {
		my ($role, %opts) = @_;
		my $info = get_role_info($role)
			or croak("$role does not seem to be a role");
		my @methods = @{$info->{api}};
		@methods = grep(!/\A_/, @methods)
			if exists($opts{private}) && !$opts{private};
		
		return sub {
			my $var = $_[1];
			return (
				undef,
				sprintf(
					'(%s->DOES(%s) or (%s))',
					$var,
					B::perlstring($role),
					join(
						' and ',
						map(
							sprintf('%s->can(%s)', $var, B::perlstring($_)),
							@methods,
						),
					),
				),
			);
		};
	},
);

__PACKAGE__->meta->add_type({
	name    => ClassDoesInterface,
	parent  => LoadableClass,
	%common,
});

__PACKAGE__->meta->add_type({
	name    => ObjectDoesInterface,
	parent  => Object,
	%common,
});

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Interface - fuzzy role constraints

=head1 SYNOPSIS

   package MyApp::Role::FooBar {
      use Moose::Role;
      
      requires qw( foo bar );
   }
   
   package MyApp::Class::FooBar {
      use Moose;
      
      # Note, the following line is commented out!
      # with qw( MyApp::Role::FooBar );
      
      sub foo { 1 }
      sub bar { 2 }
   }
   
   package MyApp::Class::Main {
      use Moose;
      use Types::Interface qw(ObjectDoesInterface);
      
      has foobar => (
         is   => 'ro',
         isa  => ObjectDoesInterface['MyApp::Role::FooBar'],
      );
   }
   
   # This is ok...
   my $obj = MyApp::Class::Main->new(
      foobar => MyApp::Class::FooBar->new(),
   );

=head1 DESCRIPTION

Types::Interface provides a type constraint library suitable for
L<Moose>, L<Mouse>, and L<Moo> attributes, L<Kavorka> signatures,
and any other place where type constraints might be used.

The type constraints it provides are based on the idea that an
object or class might fulfil all the requirements for a role without
explicitly consuming the role.

=head2 Type Constraints

This module provides the following type constraints:

=over

=item C<< ObjectDoesInterface[$role] >>

This type constraint accepts any object where C<< $object->DOES($role) >>
returns true, B<or> where the object happens to provide all the methods
that form part of the role's API, according to L<Role::Inspector>.

This type constraint is a subtype of C<Object> from L<Types::Standard>.

=item C<< ObjectDoesInterface[$role, private => 0] >>

This type constraint accepts any object where C<< $object->DOES($role) >>
returns true, B<or> where the object happens to provide all the public
methods (i.e. those not starting with an underscore) that form part of
the role's API, according to L<Role::Inspector>.

=item C<< ClassDoesInterface[$role] >>

This type constraint accepts any class name where C<< $class->DOES($role) >>
returns true, B<or> where the class happens to provide all the methods
that form part of the role's API, according to L<Role::Inspector>.

This type constraint is a subtype of C<LoadableClass> from
L<Types::LoadableClass>.

=item C<< ClassDoesInterface[$role, private => 0] >>

This type constraint accepts any class name where C<< $class->DOES($role) >>
returns true, B<or> where the object class to provide all the public
methods (i.e. those not starting with an underscore) that form part of
the role's API, according to L<Role::Inspector>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-Interface>.

=head1 SEE ALSO

L<Type::Tiny::Manual>,
L<Types::LoadableClass>,
L<Types::Standard>,
L<Role::Inspector>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

