package Test::Mojo::Role;

1;

=head1 NAME

Test::Mojo::Role - Roles for Test::Mojo

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

C<Test::Mojo::Role> is not a real module, just documentation.
Roles do not inherit from a base, but if they did, this would be the base class for C<Test::Mojo::Role::>s.

Roles should be built in such a way that they can be applied via L<Role::Tiny>.
Roles may actually be applied using L<Test::Mojo::WithRoles> which provides a nice interface to the test author.
Your role does not need to depend on L<Test::Mojo::WithRoles> but if it does, the test author will get that module during install.


