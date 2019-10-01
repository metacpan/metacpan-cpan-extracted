use strict;
use warnings;
use Test::Needs 'Mouse';
use Test::More;

use With::Roles;

{
  package My::Mouse::Role;
  use Mouse::Role;
  sub from_role { 1 }
}

{
  package My::Mouse::Role2;
  use Mouse::Role;
  sub from_role2 { 1 }
}

{
  package My::Mouse::Class;
  use Mouse;
}

my $o = My::Mouse::Class->with::roles('My::Mouse::Role')->new;
ok $o->can('from_role');
ok !My::Mouse::Class->can('from_role');

my $o2 = My::Mouse::Class->new->with::roles('My::Mouse::Role');
ok $o2->can('from_role');
ok !My::Mouse::Class->can('from_role');

my $r = My::Mouse::Role->with::roles('My::Mouse::Role2');
ok $r->can('from_role2');
ok !My::Mouse::Role->can('from_role2');

my $o3 = My::Mouse::Class->with::roles($r)->new;
ok $o3->can('from_role');
ok $o3->can('from_role2');
ok !My::Mouse::Class->can('from_role');
ok !My::Mouse::Class->can('from_role2');

done_testing;
