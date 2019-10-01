use strict;
use warnings;
use Test::Needs 'Moo';
use Test::More;

use With::Roles;

{
  package My::Moo::Role;
  use Moo::Role;
  sub from_role { 1 }
}

{
  package My::Moo::Role2;
  use Moo::Role;
  sub from_role2 { 1 }
}

{
  package My::Moo::Class;
  use Moo;
}

my $o = My::Moo::Class->with::roles('My::Moo::Role')->new;
ok $o->can('from_role');
ok !My::Moo::Class->can('from_role');

my $o2 = My::Moo::Class->new->with::roles('My::Moo::Role');
ok $o2->can('from_role');
ok !My::Moo::Class->can('from_role');

my $r = My::Moo::Role->with::roles('My::Moo::Role2');
ok $r->can('from_role2');
ok !My::Moo::Role->can('from_role2');

my $o3 = My::Moo::Class->with::roles($r)->new;
ok $o3->can('from_role');
ok $o3->can('from_role2');
ok !My::Moo::Class->can('from_role');
ok !My::Moo::Class->can('from_role2');

done_testing;
