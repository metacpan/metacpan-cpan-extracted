use strict;
use warnings;
use Test::Needs 'Moose';
use Test::More;

use With::Roles;

{
  package My::Moose::Role;
  use Moose::Role;
  sub from_role { 1 }
}

{
  package My::Moose::Role2;
  use Moose::Role;
  our $VERSION = '1.002';

  sub from_role2 { 1 }
}

{
  package My::Moose::Class;
  use Moose;
}

my $o = My::Moose::Class->with::roles('My::Moose::Role')->new;
ok $o->can('from_role');
ok !My::Moose::Class->can('from_role');

my $o2 = My::Moose::Class->new->with::roles('My::Moose::Role');
ok $o2->can('from_role');
ok !My::Moose::Class->can('from_role');

my $r = My::Moose::Role->with::roles('My::Moose::Role2');
ok $r->can('from_role2');
ok !My::Moose::Role->can('from_role2');

my $o3 = My::Moose::Class->with::roles($r)->new;
ok $o3->can('from_role');
ok $o3->can('from_role2');
ok !My::Moose::Class->can('from_role');
ok !My::Moose::Class->can('from_role2');

my $o4;
eval {
  $o4 = My::Moose::Class->with::roles('My::Moose::Role2' => { -version => 1 })->new;
};
is $@, '';
ok $o4->can('from_role2');

done_testing;
