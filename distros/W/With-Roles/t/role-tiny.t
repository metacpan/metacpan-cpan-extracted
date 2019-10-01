use strict;
use warnings;
use Test::Needs 'Role::Tiny';
use Test::More;

use With::Roles;

{
  package My::Role::Tiny::Role;
  use Role::Tiny;
  sub from_role { 1 }
}

{
  package My::Role::Tiny::Role2;
  use Role::Tiny;
  sub from_role2 { 1 }
}

{
  package My::Role::Tiny::Class::Role::Role;
  use Role::Tiny;
  sub from_role { 1 }
}

{
  package My::Role::Tiny::Class::Role::Role2;
  use Role::Tiny;
  sub from_role2 { 1 }
}

{
  package My::Role::Tiny::Class;
  sub new { bless {}, shift }
}

{
  package My::Role::Tiny::Class2;
  sub ROLE_BASE { 'MyRoles' }
  sub new { bless {}, shift }
}

{
  package MyRoles::Role;
  use Role::Tiny;
  sub from_role { __PACKAGE__ }
}

{
  my $o = My::Role::Tiny::Class->with::roles('My::Role::Tiny::Role')->new;
  ok $o->can('from_role');
  ok !My::Role::Tiny::Class->can('from_role');
}

{
  my $o = My::Role::Tiny::Class->new->with::roles('My::Role::Tiny::Role');
  ok $o->can('from_role');
  ok !My::Role::Tiny::Class->can('from_role');
}

{
  my $r = My::Role::Tiny::Role->with::roles('My::Role::Tiny::Role2');
  ok $r->can('from_role2');
  ok !My::Role::Tiny::Role->can('from_role2');

  my $o = My::Role::Tiny::Class->with::roles($r)->new;
  ok $o->can('from_role');
  ok $o->can('from_role2');
  ok !My::Role::Tiny::Class->can('from_role');
  ok !My::Role::Tiny::Class->can('from_role2');
}

{
  my $c = My::Role::Tiny::Class->with::roles('+Role');
  ok $c->can('from_role');
  my $c2 = $c->with::roles('+Role2');
  ok $c2->can('from_role');
  ok $c2->can('from_role2');
}

{
  my $c = My::Role::Tiny::Class2->with::roles('+Role');
  ok $c->can('from_role');
  is $c->from_role, 'MyRoles::Role';
}

done_testing;
