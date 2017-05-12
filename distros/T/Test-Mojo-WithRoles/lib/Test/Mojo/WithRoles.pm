package Test::Mojo::WithRoles;

use Mojo::Base -strict;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

use Role::Tiny ();
use Test::Mojo;

use Mojo::JSON 'j';

sub import {
  my ($class, @roles) = @_;
  @roles = map { s/^\+// ? $_ : "Test::Mojo::Role::$_" } @roles;
  $^H{'Test::Mojo::WithRoles/enabled'} = j(\@roles);
}

sub unimport {
  my ($class) = @_;
  $^H{'Test::Mojo::WithRoles/enabled'} = '[]';
}

sub new {
  my $class = shift;
  my $hints = (caller(0))[10];
  my $roles = j($hints->{'Test::Mojo::WithRoles/enabled'} || '[]');
  @$roles = 'Test::Mojo::Role::Null' unless @$roles;
  return Role::Tiny->create_class_with_roles('Test::Mojo', @$roles)->new(@_);
}

1;

=head1 NAME

Test::Mojo::WithRoles - Use Test::Mojo roles cleanly and safely

=head1 SYNOPSIS

  package Test::Mojo::Role::MyRole;

  use Role::Tiny;

  sub is_awesome {
    my ($t, ...) = @_;
    # do some test
  }

  ---

  # myapp.t

  use Test::More;
  use Test::Mojo::WithRoles 'MyRole';
  my $t = Test::Mojo::WithRoles->new('MyApp');

  $t->get_ok(...)
    ->is_awesome(...);

  done_testing;

=head1 DESCRIPTION

L<Test::Mojo::WithRoles> builds composite subclasses of L<Test::Mojo> based on a lexically specified set of roles.
This is easy to use and plays nicely with others.

Of course this is all just sugar for the mechanisms provided by L<Role::Tiny>.

=head1 IMPORTING

  {
    use Test::Mojo::WithRoles qw/MyRole +Test::MyRole/;
    my $t = Test::Mojo::WithRoles->new('MyApp');
    $t->does('Test::Mojo::Role::MyRole'); # true
    $t->does('Test::MyRole'); # true
  }

  my $t = Test::Mojo::WithRoles->new;
  $t->does('Test::Mojo::Role::MyRole'); # false

Pass a list of roles when you import L<Test::Mojo::WithRoles>.
Those roles will be used to construct a subclass of L<Test::Mojo> with those roles when C<new> is called within that lexical scope.
After leaving that lexical scope, the roles specified are no longer in effect I<when constructing a new object>.

Roles specified without a leading C<+> sign are assumed to be in the C<Test::Mojo::Role> namespace.
Roles specified with a leading C<+> sign are used literally as the fully qualified package name.

=head1 SEE ALSO

=over

=item L<Test::Mojo>

=item L<Mojolicious>

=item L<Role::Tiny>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Test-Mojo-WithRoles>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

