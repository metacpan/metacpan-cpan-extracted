package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Scalar::Util 'reftype';

# Test Object Construction Hooks

subtest 'ARGS hook' => sub {
  package Venus::Test::__ANON__::Args::List;
  use base 'Venus::Core';

  sub ARGS {
    my ($self, @args) = @_;
    return @args
      ? ((@args == 1 && ref $args[0] eq 'ARRAY') ? @args : [@args])
      : $self->DATA;
  }

  package main;

  my $list = Venus::Test::__ANON__::Args::List->BLESS(1..4);
  is reftype($list), 'ARRAY', 'ARGS returns arrayref for multiple args';
  is_deeply $list, [1..4], 'ARGS converts args to arrayref';
  isa_ok $list, 'Venus::Test::__ANON__::Args::List';
};

subtest 'BLESS hook' => sub {
  package Venus::Test::__ANON__::Bless::User;
  use base 'Venus::Core';

  package main;

  my $user = Venus::Test::__ANON__::Bless::User->BLESS(name => 'Elliot');
  isa_ok $user, 'Venus::Test::__ANON__::Bless::User';
  is reftype($user), 'HASH', 'BLESS creates hashref by default';
  is $user->{name}, 'Elliot', 'BLESS preserves constructor arguments';
};

subtest 'BUILDARGS hook' => sub {
  package Venus::Test::__ANON__::BuildArgs::User;
  use base 'Venus::Core';

  sub BUILDARGS {
    my ($self, @args) = @_;
    my $data = @args == 1 && !ref $args[0] ? {name => $args[0]} : {};
    return $data;
  }

  package main;

  my $user = Venus::Test::__ANON__::BuildArgs::User->BLESS('Elliot');
  is $user->{name}, 'Elliot', 'BUILDARGS converts single string to hashref';

  my $user2 = Venus::Test::__ANON__::BuildArgs::User->BLESS(name => 'Alice', age => 30);
  ok !exists $user2->{name}, 'BUILDARGS can ignore multiple args';
};

subtest 'BUILD hook' => sub {
  package Venus::Test::__ANON__::Build::User;
  use base 'Venus::Core';

  sub BUILD {
    my ($self) = @_;
    $self->{name} = 'Mr. Robot';
    return $self;
  }

  package main;

  my $user = Venus::Test::__ANON__::Build::User->BLESS(name => 'Elliot');
  is $user->{name}, 'Mr. Robot', 'BUILD modifies object after construction';
};

subtest 'BUILD inheritance' => sub {
  package Venus::Test::__ANON__::Build::Parent;
  use base 'Venus::Core';

  sub BUILD {
    my ($self) = @_;
    $self->{parent_built} = 1;
    return $self;
  }

  package Venus::Test::__ANON__::Build::Child;
  use base 'Venus::Test::__ANON__::Build::Parent';

  sub BUILD {
    my ($self, $data) = @_;
    $self->SUPER::BUILD($data);
    $self->{child_built} = 1;
    return $self;
  }

  package main;

  my $child = Venus::Test::__ANON__::Build::Child->BLESS;
  ok $child->{parent_built}, 'Parent BUILD was called';
  ok $child->{child_built}, 'Child BUILD was called';
};

subtest 'CONSTRUCT hook' => sub {
  package Venus::Test::__ANON__::Construct::User;
  use base 'Venus::Core';

  sub CONSTRUCT {
    my ($self) = @_;
    $self->{ready} = 1;
    return $self;
  }

  package main;

  my $user = Venus::Test::__ANON__::Construct::User->BLESS(name => 'Elliot');
  is $user->{name}, 'Elliot', 'CONSTRUCT preserves existing data';
  is $user->{ready}, 1, 'CONSTRUCT adds ready flag';
};

subtest 'DATA hook' => sub {
  package Venus::Test::__ANON__::Data::ArrayExample;
  use base 'Venus::Core';

  sub DATA {
    return [];
  }

  package main;

  my $example = Venus::Test::__ANON__::Data::ArrayExample->BLESS;
  is reftype($example), 'ARRAY', 'DATA returns arrayref';
  is_deeply $example, [], 'DATA returns empty arrayref';
};

subtest 'CLONE hook' => sub {
  package Venus::Test::__ANON__::Clone::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Clone::User->MASK('password');

  sub set_password {
    my ($self, $value) = @_;
    $self->password($value);
  }

  package main;

  my $user = Venus::Test::__ANON__::Clone::User->BLESS(name => 'Elliot');
  $user->set_password('secret');

  my $clone = $user->CLONE;
  is $clone->{name}, 'Elliot', 'CLONE copies public data';
  ok !exists $clone->{password}, 'CLONE does not copy private data (MASK)';
  isnt $user, $clone, 'CLONE creates a new object';
};

# Test Object Destruction Hooks

subtest 'DECONSTRUCT and DESTROY hooks' => sub {
  package Venus::Test::__ANON__::Destruct::User;
  use base 'Venus::Core';

  our $CALLS = 0;
  our $USERS = 0;

  sub CONSTRUCT {
    my ($self) = @_;
    $self->SUPER::CONSTRUCT;
    return $CALLS = $USERS += 1;
  }

  sub DECONSTRUCT {
    my ($self) = @_;
    $self->SUPER::DECONSTRUCT;
    return $USERS--;
  }

  sub DESTROY {
    my ($self) = @_;
    $self->SUPER::DESTROY;
    return $CALLS--;
  }

  package main;
  {
    my $user = Venus::Test::__ANON__::Destruct::User->BLESS;
    is $Venus::Test::__ANON__::Destruct::User::USERS, 1, 'CONSTRUCT incremented USERS';
    is $Venus::Test::__ANON__::Destruct::User::CALLS, 1, 'CONSTRUCT incremented CALLS';
  }

  is $Venus::Test::__ANON__::Destruct::User::USERS, 0, 'DECONSTRUCT decremented USERS';
  is $Venus::Test::__ANON__::Destruct::User::CALLS, 0, 'DESTROY decremented CALLS';
};

# Test Class Building Hooks

subtest 'ATTR hook' => sub {
  package Venus::Test::__ANON__::Attr::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Attr::User->ATTR('name');
  Venus::Test::__ANON__::Attr::User->ATTR('role');

  package main;

  my $user = Venus::Test::__ANON__::Attr::User->BLESS(role => 'Engineer');

  ok $user->can('name'), 'ATTR creates name accessor';
  ok $user->can('role'), 'ATTR creates role accessor';

  is $user->name, undef, 'name defaults to undef';
  is $user->role, 'Engineer', 'role is set from constructor';

  $user->name('Elliot');
  is $user->name, 'Elliot', 'name setter works';

  $user->role('Hacker');
  is $user->role, 'Hacker', 'role setter works';
};

subtest 'BASE hook' => sub {
  package Venus::Test::__ANON__::Base::Entity;

  sub work {
    return 'working';
  }

  package Venus::Test::__ANON__::Base::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Base::User->BASE('Venus::Test::__ANON__::Base::Entity');

  package main;

  my $user = Venus::Test::__ANON__::Base::User->BLESS;
  ok $user->can('work'), 'BASE registers base class methods';
  is $user->work, 'working', 'BASE inherited method works';
  isa_ok $user, 'Venus::Test::__ANON__::Base::Entity';
};

subtest 'MASK hook' => sub {
  package Venus::Test::__ANON__::Mask::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Mask::User->MASK('password');

  sub get_password {
    my ($self) = @_;
    return $self->password;
  }

  sub set_password {
    my ($self, $value) = @_;
    $self->password($value);
  }

  package main;

  my $user = Venus::Test::__ANON__::Mask::User->BLESS(name => 'Elliot');

  # Should work from within class methods
  $user->set_password('secret');
  is $user->get_password, 'secret', 'MASK allows access from within class';

  # Should fail from outside class
  eval { $user->password };
  like $@, qr/private variable/, 'MASK prevents external access';

  # Should also prevent class-level access
  eval { Venus::Test::__ANON__::Mask::User->password };
  like $@, qr/without an instance/, 'MASK prevents class-level access';
};

subtest 'MASK hook with role composition' => sub {
  package Venus::Test::__ANON__::Mask::RoleWithMask;
  use base 'Venus::Core::Role';

  Venus::Test::__ANON__::Mask::RoleWithMask->MASK('role_secret');

  sub set_role_secret {
    my ($self, $value) = @_;
    $self->role_secret($value);
  }

  sub get_role_secret {
    my ($self) = @_;
    return $self->role_secret;
  }

  sub EXPORT {
    return ['role_secret', 'set_role_secret', 'get_role_secret'];
  }

  package Venus::Test::__ANON__::Mask::ClassWithRole;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Mask::ClassWithRole->ROLE('Venus::Test::__ANON__::Mask::RoleWithMask');

  package main;

  my $obj = Venus::Test::__ANON__::Mask::ClassWithRole->BLESS;

  # Should work - role accessing its own mask from role method
  $obj->set_role_secret('secret123');
  is $obj->get_role_secret, 'secret123', 'MASK in role accessible from role methods';

  # Should fail - external access
  eval { $obj->role_secret };
  like $@, qr/private variable/, 'MASK in role prevents external access';
};

subtest 'MASK hook with mixin composition' => sub {
  package Venus::Test::__ANON__::Mask::MixinWithMask;
  use base 'Venus::Core::Mixin';

  Venus::Test::__ANON__::Mask::MixinWithMask->MASK('mixin_cache');

  sub init_cache {
    my ($self) = @_;
    $self->mixin_cache({});
  }

  sub cache_get {
    my ($self, $key) = @_;
    my $cache = $self->mixin_cache || {};
    return $cache->{$key};
  }

  sub cache_set {
    my ($self, $key, $value) = @_;
    my $cache = $self->mixin_cache || {};
    $cache->{$key} = $value;
    $self->mixin_cache($cache);
  }

  sub EXPORT {
    return ['mixin_cache', 'init_cache', 'cache_get', 'cache_set'];
  }

  package Venus::Test::__ANON__::Mask::ClassWithMixin;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Mask::ClassWithMixin->MIXIN('Venus::Test::__ANON__::Mask::MixinWithMask');

  package main;

  my $obj = Venus::Test::__ANON__::Mask::ClassWithMixin->BLESS;

  # Should work - mixin accessing its own mask from mixin method
  $obj->init_cache;
  $obj->cache_set('key1', 'value1');
  is $obj->cache_get('key1'), 'value1', 'MASK in mixin accessible from mixin methods';

  # Should fail - external access
  eval { $obj->mixin_cache };
  like $@, qr/private variable/, 'MASK in mixin prevents external access';
};

subtest 'MASK hook with multiple roles' => sub {
  package Venus::Test::__ANON__::Mask::Role1;
  use base 'Venus::Core::Role';

  Venus::Test::__ANON__::Mask::Role1->MASK('data1');

  sub set_data1 { $_[0]->data1($_[1]) }
  sub get_data1 { $_[0]->data1 }

  sub EXPORT {
    return ['data1', 'set_data1', 'get_data1'];
  }

  package Venus::Test::__ANON__::Mask::Role2;
  use base 'Venus::Core::Role';

  Venus::Test::__ANON__::Mask::Role2->MASK('data2');

  sub set_data2 { $_[0]->data2($_[1]) }
  sub get_data2 { $_[0]->data2 }

  sub EXPORT {
    return ['data2', 'set_data2', 'get_data2'];
  }

  package Venus::Test::__ANON__::Mask::ClassWithMultipleRoles;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Mask::ClassWithMultipleRoles->ROLE('Venus::Test::__ANON__::Mask::Role1');
  Venus::Test::__ANON__::Mask::ClassWithMultipleRoles->ROLE('Venus::Test::__ANON__::Mask::Role2');

  package main;

  my $obj = Venus::Test::__ANON__::Mask::ClassWithMultipleRoles->BLESS;

  # Both roles should be able to access their own masks
  $obj->set_data1('value1');
  $obj->set_data2('value2');

  is $obj->get_data1, 'value1', 'first role can access its mask';
  is $obj->get_data2, 'value2', 'second role can access its mask';

  # External access should still fail
  eval { $obj->data1 };
  like $@, qr/private variable/, 'first role mask prevents external access';

  eval { $obj->data2 };
  like $@, qr/private variable/, 'second role mask prevents external access';
};

# Test Composition Hooks

subtest 'ROLE hook' => sub {
  package Venus::Test::__ANON__::Role::Admin;
  use base 'Venus::Core::Role';

  sub admin_method {
    return 'admin';
  }

  sub EXPORT {
    return ['admin_method'];
  }

  package Venus::Test::__ANON__::Role::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Role::User->ROLE('Venus::Test::__ANON__::Role::Admin');

  package main;

  ok(Venus::Test::__ANON__::Role::User->DOES('Venus::Test::__ANON__::Role::Admin'), 'ROLE registers role consumption');

  my $user = Venus::Test::__ANON__::Role::User->BLESS;
  ok $user->can('admin_method'), 'ROLE imports exported methods';
  is $user->admin_method, 'admin', 'ROLE imported method works';
};

subtest 'ROLE does not override existing methods' => sub {
  package Venus::Test::__ANON__::Role::Provider;
  use base 'Venus::Core::Role';

  sub shared_method {
    return 'from_role';
  }

  sub EXPORT {
    return ['shared_method'];
  }

  package Venus::Test::__ANON__::Role::Consumer;
  use base 'Venus::Core';

  sub shared_method {
    return 'from_consumer';
  }

  Venus::Test::__ANON__::Role::Consumer->ROLE('Venus::Test::__ANON__::Role::Provider');

  package main;

  my $obj = Venus::Test::__ANON__::Role::Consumer->BLESS;
  is $obj->shared_method, 'from_consumer', 'ROLE does not override existing methods';
};

subtest 'MIXIN hook' => sub {
  package Venus::Test::__ANON__::Mixin::Action;
  use base 'Venus::Core::Mixin';

  sub action_method {
    return 'action';
  }

  sub EXPORT {
    return ['action_method'];
  }

  package Venus::Test::__ANON__::Mixin::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Mixin::User->MIXIN('Venus::Test::__ANON__::Mixin::Action');

  package main;

  ok !Venus::Test::__ANON__::Mixin::User->DOES('Venus::Test::__ANON__::Mixin::Action'), 'MIXIN does not register as role';

  my $user = Venus::Test::__ANON__::Mixin::User->BLESS;
  ok $user->can('action_method'), 'MIXIN imports exported methods';
  is $user->action_method, 'action', 'MIXIN imported method works';
};

subtest 'MIXIN overrides existing methods' => sub {
  package Venus::Test::__ANON__::Mixin::Provider;
  use base 'Venus::Core::Mixin';

  sub shared_method {
    return 'from_mixin';
  }

  sub EXPORT {
    return ['shared_method'];
  }

  package Venus::Test::__ANON__::Mixin::Consumer;
  use base 'Venus::Core';

  sub shared_method {
    return 'from_consumer';
  }

  Venus::Test::__ANON__::Mixin::Consumer->MIXIN('Venus::Test::__ANON__::Mixin::Provider');

  package main;

  my $obj = Venus::Test::__ANON__::Mixin::Consumer->BLESS;
  is $obj->shared_method, 'from_mixin', 'MIXIN overrides existing methods';
};

subtest 'TEST hook' => sub {
  package Venus::Test::__ANON__::Venus::Test::__ANON__::Admin;
  use base 'Venus::Core';

  package Venus::Test::__ANON__::Venus::Test::__ANON__::IsAdmin;
  use base 'Venus::Core';

  sub shutdown {
    return 'shutting down';
  }

  sub AUDIT {
    my ($self, $from) = @_;
    die "${from} is not a super-user" if !$from->DOES('Venus::Test::__ANON__::Venus::Test::__ANON__::Admin');
  }

  sub EXPORT {
    return ['shutdown'];
  }

  package Venus::Test::__ANON__::Venus::Test::__ANON__::ValidUser;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Venus::Test::__ANON__::ValidUser->ROLE('Venus::Test::__ANON__::Venus::Test::__ANON__::Admin');
  Venus::Test::__ANON__::Venus::Test::__ANON__::ValidUser->TEST('Venus::Test::__ANON__::Venus::Test::__ANON__::IsAdmin');

  package main;

  my $user = Venus::Test::__ANON__::Venus::Test::__ANON__::ValidUser->BLESS;
  ok $user->can('shutdown'), 'TEST imports methods after AUDIT passes';
  is $user->shutdown, 'shutting down', 'TEST imported method works';
};

subtest 'TEST hook fails AUDIT' => sub {
  package Venus::Test::__ANON__::Venus::Test::__ANON__::InvalidUser;
  use base 'Venus::Core';

  eval {
    Venus::Test::__ANON__::Venus::Test::__ANON__::InvalidUser->TEST('Venus::Test::__ANON__::Venus::Test::__ANON__::IsAdmin');
  };

  package main;

  like $@, qr/not a super-user/, 'TEST triggers AUDIT and fails';
};

subtest 'FROM hook' => sub {
  package Venus::Test::__ANON__::From::Entity;
  use base 'Venus::Core';

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package Venus::Test::__ANON__::From::ValidUser;
  use base 'Venus::Core';

  Venus::Test::__ANON__::From::ValidUser->ATTR('startup');
  Venus::Test::__ANON__::From::ValidUser->ATTR('shutdown');
  Venus::Test::__ANON__::From::ValidUser->FROM('Venus::Test::__ANON__::From::Entity');

  package main;

  my $user = Venus::Test::__ANON__::From::ValidUser->BLESS;
  isa_ok $user, 'Venus::Test::__ANON__::From::Entity';
  ok $user->can('startup'), 'FROM registers inheritance';
  ok $user->can('shutdown'), 'FROM registers inheritance';
};

subtest 'FROM hook fails AUDIT' => sub {
  package Venus::Test::__ANON__::From::InvalidUser;
  use base 'Venus::Core';

  eval {
    Venus::Test::__ANON__::From::InvalidUser->FROM('Venus::Test::__ANON__::From::Entity');
  };

  package main;

  like $@, qr/Missing startup/, 'FROM triggers AUDIT and fails';
};

# Test Interface and Validation Hooks

subtest 'AUDIT hook' => sub {
  package Venus::Test::__ANON__::Audit::HasType;
  use base 'Venus::Core';

  sub AUDIT {
    my ($self, $from) = @_;
    die 'Consumer missing "type" attribute' if !$from->can('type');
  }

  package Venus::Test::__ANON__::Audit::ValidUser;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Audit::ValidUser->ATTR('type');
  Venus::Test::__ANON__::Audit::ValidUser->TEST('Venus::Test::__ANON__::Audit::HasType');

  package Venus::Test::__ANON__::Audit::InvalidUser;
  use base 'Venus::Core';

  package main;

  my $valid = Venus::Test::__ANON__::Audit::ValidUser->BLESS;
  ok($valid, 'AUDIT passes when interface satisfied');

  eval {
    Venus::Test::__ANON__::Audit::InvalidUser->TEST('Venus::Test::__ANON__::Audit::HasType');
  };
  like $@, qr/missing "type" attribute/, 'AUDIT fails when interface not satisfied';
};

# Test Import/Export Hooks

subtest 'EXPORT hook' => sub {
  package Venus::Test::__ANON__::Export::Admin;
  use base 'Venus::Core';

  sub shutdown {
    return 'shutdown';
  }

  sub restart {
    return 'restart';
  }

  sub EXPORT {
    return ['shutdown'];
  }

  package Venus::Test::__ANON__::Export::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Export::User->ROLE('Venus::Test::__ANON__::Export::Admin');

  package main;

  my $user = Venus::Test::__ANON__::Export::User->BLESS;
  ok $user->can('shutdown'), 'EXPORT lists exported method';
  ok !$user->can('restart'), 'EXPORT excludes non-exported method';
};

subtest 'IMPORT hook' => sub {
  package Venus::Test::__ANON__::Import::Admin;
  use base 'Venus::Core';

  our $USES = 0;

  sub shutdown {
    return 'shutdown';
  }

  sub EXPORT {
    return ['shutdown'];
  }

  sub IMPORT {
    my ($self, $into) = @_;
    $self->SUPER::IMPORT($into);
    $USES++;
    return $self;
  }

  package Venus::Test::__ANON__::Import::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Import::User->ROLE('Venus::Test::__ANON__::Import::Admin');

  package main;

  is $Venus::Test::__ANON__::Import::Admin::USES, 1, 'IMPORT hook was called during role composition';
};

subtest 'USE and UNIMPORT hooks' => sub {
  package Venus::Test::__ANON__::UseUnimport::User;
  use base 'Venus::Core';

  package main;

  my $result = Venus::Test::__ANON__::UseUnimport::User->USE;
  is $result, 'Venus::Test::__ANON__::UseUnimport::User', 'USE returns package name';

  my $result2 = Venus::Test::__ANON__::UseUnimport::User->UNIMPORT;
  is $result2, 'Venus::Test::__ANON__::UseUnimport::User', 'UNIMPORT returns package name';
};

# Test Instance Data Hooks

subtest 'GET and SET hooks' => sub {
  package Venus::Test::__ANON__::GetSet::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::GetSet::User->ATTR('name');

  package main;

  my $user = Venus::Test::__ANON__::GetSet::User->BLESS(title => 'Engineer');

  my $value = $user->GET('title');
  is $value, 'Engineer', 'GET retrieves attribute value';

  $user->SET('title', 'Manager');
  is $user->GET('title'), 'Manager', 'SET updates attribute value';
};

subtest 'ITEM hook' => sub {
  package Venus::Test::__ANON__::Item::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Item::User->ATTR('name');

  package main;

  my $user = Venus::Test::__ANON__::Item::User->BLESS;

  my $set_result = $user->ITEM('name', 'unknown');
  is $set_result, 'unknown', 'ITEM sets and returns value';

  my $get_result = $user->ITEM('name');
  is $get_result, 'unknown', 'ITEM gets value';
};

# Test Introspection Hooks

subtest 'META hook' => sub {
  package Venus::Test::__ANON__::Meta::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Meta::User->ATTR('name');
  Venus::Test::__ANON__::Meta::User->ATTR('email');

  package main;

  my $meta = Venus::Test::__ANON__::Meta::User->META;
  isa_ok $meta, 'Venus::Meta';
  is $meta->{name}, 'Venus::Test::__ANON__::Meta::User', 'META contains package name';

  ok $meta->can('attrs'), 'META object has attrs method';
  ok $meta->can('bases'), 'META object has bases method';
  ok $meta->can('roles'), 'META object has roles method';
  ok $meta->can('subs'), 'META object has subs method';
};

subtest 'NAME hook' => sub {
  package Venus::Test::__ANON__::Name::User;
  use base 'Venus::Core';

  package main;

  my $name = Venus::Test::__ANON__::Name::User->NAME;
  is $name, 'Venus::Test::__ANON__::Name::User', 'NAME returns package name';

  my $user = Venus::Test::__ANON__::Name::User->BLESS;
  my $instance_name = $user->NAME;
  is $instance_name, 'Venus::Test::__ANON__::Name::User', 'NAME works on instances';
};

subtest 'DOES hook' => sub {
  package Venus::Test::__ANON__::Does::Admin;
  use base 'Venus::Core';

  package Venus::Test::__ANON__::Does::User;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Does::User->ROLE('Venus::Test::__ANON__::Does::Admin');

  package main;

  ok(Venus::Test::__ANON__::Does::User->DOES('Venus::Test::__ANON__::Does::Admin'), 'DOES returns true for consumed role');
  ok(!Venus::Test::__ANON__::Does::User->DOES('Venus::Test::__ANON__::Does::Owner'), 'DOES returns false for non-consumed role');
};

subtest 'SUBS hook' => sub {
  package Venus::Test::__ANON__::Subs::Example;
  use base 'Venus::Core';

  sub custom_method {
    return;
  }

  sub another_method {
    return;
  }

  package main;

  my $subs = Venus::Test::__ANON__::Subs::Example->SUBS;
  is reftype($subs), 'ARRAY', 'SUBS returns arrayref';
  ok((grep { $_ eq 'custom_method' } @$subs), 'SUBS includes custom_method');
  ok((grep { $_ eq 'another_method' } @$subs), 'SUBS includes another_method');
};

# Test Hook Execution Order

subtest 'Construction phase execution order' => sub {
  package Venus::Test::__ANON__::Order::Tracker;
  use base 'Venus::Core';

  our @ORDER = ();

  sub BUILDARGS {
    my ($self, @args) = @_;
    push @ORDER, 'BUILDARGS';
    return @args;
  }

  sub ARGS {
    my ($self, @args) = @_;
    push @ORDER, 'ARGS';
    return $self->SUPER::ARGS(@args);
  }

  sub BUILD {
    my ($self) = @_;
    push @ORDER, 'BUILD';
    return $self;
  }

  sub CONSTRUCT {
    my ($self) = @_;
    push @ORDER, 'CONSTRUCT';
    return $self;
  }

  package main;

  @Venus::Test::__ANON__::Order::Tracker::ORDER = ();
  my $obj = Venus::Test::__ANON__::Order::Tracker->BLESS(foo => 'bar');

  is_deeply \@Venus::Test::__ANON__::Order::Tracker::ORDER,
    ['BUILDARGS', 'ARGS', 'BUILD', 'CONSTRUCT'],
    'Construction hooks execute in correct order';
};

subtest 'Destruction phase execution order' => sub {
  package Venus::Test::__ANON__::Order::Destructor;
  use base 'Venus::Core';

  our @ORDER = ();

  sub DECONSTRUCT {
    my ($self) = @_;
    $self->SUPER::DECONSTRUCT;
    push @ORDER, 'DECONSTRUCT';
    return $self;
  }

  sub DESTROY {
    my ($self) = @_;
    $self->SUPER::DESTROY;
    push @ORDER, 'DESTROY';
  }

  package main;

  @Venus::Test::__ANON__::Order::Destructor::ORDER = ();
  {
    my $obj = Venus::Test::__ANON__::Order::Destructor->BLESS;
  }

  is_deeply \@Venus::Test::__ANON__::Order::Destructor::ORDER,
    ['DECONSTRUCT', 'DESTROY'],
    'Destruction hooks execute in correct order';
};

# Test Best Practices Examples

subtest 'Best practice: Return $self in BUILD' => sub {
  package Venus::Test::__ANON__::Practice::ReturnSelf;
  use base 'Venus::Core';

  sub BUILD {
    my ($self) = @_;
    $self->{initialized} = 1;
    return $self;
  }

  package main;

  my $obj = Venus::Test::__ANON__::Practice::ReturnSelf->BLESS;
  ok $obj->{initialized}, 'BUILD returns $self and initializes object';
};

subtest 'Best practice: Call SUPER in inherited BUILD' => sub {
  package Venus::Test::__ANON__::Practice::Parent;
  use base 'Venus::Core';

  sub BUILD {
    my ($self) = @_;
    $self->{parent_init} = 1;
    return $self;
  }

  package Venus::Test::__ANON__::Practice::Child;
  use base 'Venus::Test::__ANON__::Practice::Parent';

  sub BUILD {
    my ($self, $data) = @_;
    $self->SUPER::BUILD($data);
    $self->{child_init} = 1;
    return $self;
  }

  package main;

  my $child = Venus::Test::__ANON__::Practice::Child->BLESS;
  ok $child->{parent_init}, 'Parent BUILD called via SUPER';
  ok $child->{child_init}, 'Child BUILD executed';
};

subtest 'Best practice: Explicit EXPORT' => sub {
  package Venus::Test::__ANON__::Practice::Explicit;
  use base 'Venus::Core';

  sub method1 { return 1 }
  sub method2 { return 2 }
  sub internal { return 0 }

  sub EXPORT {
    return ['method1', 'method2'];
  }

  package Venus::Test::__ANON__::Practice::Consumer;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Practice::Consumer->ROLE('Venus::Test::__ANON__::Practice::Explicit');

  package main;

  my $obj = Venus::Test::__ANON__::Practice::Consumer->BLESS;
  ok $obj->can('method1'), 'Explicitly exported method1 available';
  ok $obj->can('method2'), 'Explicitly exported method2 available';
  ok !$obj->can('internal'), 'Non-exported internal method not available';
};

subtest 'Best practice: Use AUDIT for interface enforcement' => sub {
  package Venus::Test::__ANON__::Practice::Interface;
  use base 'Venus::Core';

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing required method 'foo'" if !$from->can('foo');
    die "Missing required method 'bar'" if !$from->can('bar');
  }

  package Venus::Test::__ANON__::Practice::Valid;
  use base 'Venus::Core';

  sub foo { return 'foo' }
  sub bar { return 'bar' }

  Venus::Test::__ANON__::Practice::Valid->TEST('Venus::Test::__ANON__::Practice::Interface');

  package Venus::Test::__ANON__::Practice::Invalid;
  use base 'Venus::Core';

  sub foo { return 'foo' }

  package main;

  ok +Venus::Test::__ANON__::Practice::Valid->BLESS, 'AUDIT passes for valid interface';

  eval {
    Venus::Test::__ANON__::Practice::Invalid->TEST('Venus::Test::__ANON__::Practice::Interface');
  };
  like $@, qr/Missing required method 'bar'/, 'AUDIT enforces interface';
};

subtest 'Best practice: Use MASK for encapsulation' => sub {
  package Venus::Test::__ANON__::Practice::Encapsulated;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Practice::Encapsulated->MASK('internal_cache');

  sub get_cache {
    my ($self) = @_;
    return $self->internal_cache;
  }

  sub set_cache {
    my ($self, $value) = @_;
    $self->internal_cache($value);
  }

  package main;

  my $obj = Venus::Test::__ANON__::Practice::Encapsulated->BLESS;
  $obj->set_cache('cached_data');
  is $obj->get_cache, 'cached_data', 'MASK allows internal access';

  eval { $obj->internal_cache };
  like $@, qr/private variable/, 'MASK prevents external access';
};

subtest 'Best practice: Keep BUILDARGS simple' => sub {
  package Venus::Test::__ANON__::Practice::SimpleBuildArgs;
  use base 'Venus::Core';

  sub BUILDARGS {
    my ($self, @args) = @_;
    # Simple transformation only
    return @args == 1 && !ref $args[0] ? {id => $args[0]} : {@args};
  }

  package main;

  my $obj1 = Venus::Test::__ANON__::Practice::SimpleBuildArgs->BLESS(123);
  is $obj1->{id}, 123, 'BUILDARGS handles single arg';

  my $obj2 = Venus::Test::__ANON__::Practice::SimpleBuildArgs->BLESS(id => 456, name => 'test');
  is $obj2->{id}, 456, 'BUILDARGS handles multiple args';
  is $obj2->{name}, 'test', 'BUILDARGS preserves all args';
};

# Test edge cases and special scenarios

subtest 'CLONE deep cloning' => sub {
  package Venus::Test::__ANON__::Clone::Deep;
  use base 'Venus::Core';

  package main;

  my $obj = Venus::Test::__ANON__::Clone::Deep->BLESS(
    name => 'test',
    nested => { key => 'value' },
    array => [1, 2, 3]
  );

  my $clone = $obj->CLONE;

  # Modify clone's nested structures
  $clone->{nested}{key} = 'modified';
  push @{$clone->{array}}, 4;

  # Original should be unchanged (deep clone)
  is $obj->{nested}{key}, 'value', 'Deep clone: original nested hash unchanged';
  is scalar(@{$obj->{array}}), 3, 'Deep clone: original array unchanged';

  is $clone->{nested}{key}, 'modified', 'Deep clone: clone nested hash modified';
  is scalar(@{$clone->{array}}), 4, 'Deep clone: clone array modified';
};

subtest 'Multiple role composition' => sub {
  package Venus::Test::__ANON__::Multi::Role1;
  use base 'Venus::Core';
  sub method1 { return 'role1' }
  sub EXPORT { return ['method1'] }

  package Venus::Test::__ANON__::Multi::Role2;
  use base 'Venus::Core';
  sub method2 { return 'role2' }
  sub EXPORT { return ['method2'] }

  package Venus::Test::__ANON__::Multi::Consumer;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Multi::Consumer->ROLE('Venus::Test::__ANON__::Multi::Role1');
  Venus::Test::__ANON__::Multi::Consumer->ROLE('Venus::Test::__ANON__::Multi::Role2');

  package main;

  my $obj = Venus::Test::__ANON__::Multi::Consumer->BLESS;
  ok $obj->can('method1'), 'First role method available';
  ok $obj->can('method2'), 'Second role method available';
  is $obj->method1, 'role1', 'First role method works';
  is $obj->method2, 'role2', 'Second role method works';
};


subtest 'CLONE requires instance' => sub {
  package Venus::Test::__ANON__::Clone::ClassLevel;
  use base 'Venus::Core';

  package main;

  eval {
    Venus::Test::__ANON__::Clone::ClassLevel->CLONE;
  };
  like $@, qr/without an instance/i, 'CLONE fails when called on class';
};

subtest 'Empty EXPORT' => sub {
  package Venus::Test::__ANON__::Empty::Role;
  use base 'Venus::Core';

  sub method1 { return 'method1' }
  sub method2 { return 'method2' }

  # No EXPORT defined

  package Venus::Test::__ANON__::Empty::Consumer;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Empty::Consumer->ROLE('Venus::Test::__ANON__::Empty::Role');

  package main;

  my $obj = Venus::Test::__ANON__::Empty::Consumer->BLESS;
  ok !$obj->can('method1'), 'Without EXPORT, methods not imported';
  ok !$obj->can('method2'), 'Without EXPORT, methods not imported';
};

# Test SUPER call requirements

subtest 'SUPER::BUILD - correct pattern' => sub {
  package Venus::Test::__ANON__::Super::Parent;
  use base 'Venus::Core';

  sub BUILD {
    my ($self, $data) = @_;
    $self->{parent_initialized} = 1;
    $self->{init_order} = ['parent'];
    return $self;
  }

  package Venus::Test::__ANON__::Super::Child;
  use base 'Venus::Test::__ANON__::Super::Parent';

  sub BUILD {
    my ($self, $data) = @_;
    # CORRECT: Call parent implementation first
    $self->SUPER::BUILD($data);

    $self->{child_initialized} = 1;
    push @{$self->{init_order}}, 'child';
    return $self;
  }

  package main;

  my $child = Venus::Test::__ANON__::Super::Child->BLESS;
  ok $child->{parent_initialized}, 'Parent BUILD was called via SUPER';
  ok $child->{child_initialized}, 'Child BUILD was called';
  is_deeply $child->{init_order}, ['parent', 'child'], 'Initialization order is correct';
};

subtest 'SUPER::BUILD - missing SUPER breaks framework' => sub {
  package Venus::Test::__ANON__::NoSuper::Parent;
  use base 'Venus::Core';

  sub BUILD {
    my ($self, $data) = @_;
    $self->{parent_initialized} = 1;
    return $self;
  }

  package Venus::Test::__ANON__::NoSuper::Child;
  use base 'Venus::Test::__ANON__::NoSuper::Parent';

  sub BUILD {
    my ($self, $data) = @_;
    # WRONG: Missing SUPER call!
    # $self->SUPER::BUILD($data);

    $self->{child_initialized} = 1;
    return $self;
  }

  package main;

  my $child = Venus::Test::__ANON__::NoSuper::Child->BLESS;
  ok !$child->{parent_initialized}, 'Parent BUILD was NOT called (BROKEN)';
  ok $child->{child_initialized}, 'Only child BUILD was called';
};

subtest 'SUPER::CONSTRUCT - multi-level inheritance' => sub {
  package Venus::Test::__ANON__::Construct::Base;
  use base 'Venus::Core';

  sub CONSTRUCT {
    my ($self) = @_;
    $self->{base_ready} = 1;
    return $self;
  }

  package Venus::Test::__ANON__::Construct::Middle;
  use base 'Venus::Test::__ANON__::Construct::Base';

  sub CONSTRUCT {
    my ($self) = @_;
    $self->SUPER::CONSTRUCT;
    $self->{middle_ready} = 1;
    return $self;
  }

  package Venus::Test::__ANON__::Construct::Leaf;
  use base 'Venus::Test::__ANON__::Construct::Middle';

  sub CONSTRUCT {
    my ($self) = @_;
    $self->SUPER::CONSTRUCT;
    $self->{leaf_ready} = 1;
    return $self;
  }

  package main;

  my $obj = Venus::Test::__ANON__::Construct::Leaf->BLESS;
  ok $obj->{base_ready}, 'Base CONSTRUCT called';
  ok $obj->{middle_ready}, 'Middle CONSTRUCT called';
  ok $obj->{leaf_ready}, 'Leaf CONSTRUCT called';
};

subtest 'SUPER::DECONSTRUCT - cleanup chain' => sub {
  package Venus::Test::__ANON__::Decon::Parent;
  use base 'Venus::Core';

  our $PARENT_CLEANUP = 0;

  sub DECONSTRUCT {
    my ($self) = @_;
    $PARENT_CLEANUP++;
    return $self;
  }

  package Venus::Test::__ANON__::Decon::Child;
  use base 'Venus::Test::__ANON__::Decon::Parent';

  our $CHILD_CLEANUP = 0;

  sub DECONSTRUCT {
    my ($self) = @_;
    $self->SUPER::DECONSTRUCT;
    $CHILD_CLEANUP++;
    return $self;
  }

  package main;

  {
    my $obj = Venus::Test::__ANON__::Decon::Child->BLESS;
  }  # Object goes out of scope here

  ok $Venus::Test::__ANON__::Decon::Parent::PARENT_CLEANUP >= 1, 'Parent DECONSTRUCT called';
  ok $Venus::Test::__ANON__::Decon::Child::CHILD_CLEANUP >= 1, 'Child DECONSTRUCT called';
};

subtest 'SUPER::IMPORT - tracking composition' => sub {
  package Venus::Test::__ANON__::Import::Base;
  use base 'Venus::Core';

  our @IMPORT_CALLS;

  sub method1 { return 'method1' }

  sub EXPORT {
    ['method1']
  }

  sub IMPORT {
    my ($self, $into) = @_;
    push @IMPORT_CALLS, $into;
    $self->SUPER::IMPORT($into);
    return $self;
  }

  package Venus::Test::__ANON__::Import::Extended;
  use base 'Venus::Test::__ANON__::Import::Base';

  sub method2 { return 'method2' }

  sub EXPORT {
    my ($self, $into) = @_;
    return ['method1', 'method2'];
  }

  sub IMPORT {
    my ($self, $into) = @_;
    push @Venus::Test::__ANON__::Import::Base::IMPORT_CALLS, "extended:$into";
    $self->SUPER::IMPORT($into);
    return $self;
  }

  package Venus::Test::__ANON__::Import::Consumer;
  use base 'Venus::Core';

  Venus::Test::__ANON__::Import::Consumer->ROLE('Venus::Test::__ANON__::Import::Extended');

  package main;

  ok scalar(@Venus::Test::__ANON__::Import::Base::IMPORT_CALLS) > 0, 'IMPORT hooks were called';
};

subtest 'SUPER::BUILDARGS - argument preprocessing chain' => sub {
  package Venus::Test::__ANON__::BuildArgs::Base;
  use base 'Venus::Core';

  sub BUILDARGS {
    my ($self, @args) = @_;
    # Base class adds timestamp
    return {timestamp => time, @args};
  }

  package Venus::Test::__ANON__::BuildArgs::Extended;
  use base 'Venus::Test::__ANON__::BuildArgs::Base';

  sub BUILDARGS {
    my ($self, @args) = @_;
    # Get base preprocessing
    my $base_args = $self->SUPER::BUILDARGS(@args);
    # Add version
    return {%$base_args, version => 1};
  }

  package main;

  my $obj = Venus::Test::__ANON__::BuildArgs::Extended->BLESS(name => 'test');
  ok exists $obj->{timestamp}, 'Base BUILDARGS added timestamp';
  ok exists $obj->{version}, 'Extended BUILDARGS added version';
  is $obj->{name}, 'test', 'Original args preserved';
};

subtest 'SUPER::GET/SET - custom accessor logic' => sub {
  package Venus::Test::__ANON__::Accessor::Base;
  use base 'Venus::Core';

  our @GET_LOG;
  our @SET_LOG;

  sub GET {
    my ($self, $name) = @_;
    push @GET_LOG, $name;
    return $self->SUPER::GET($name);
  }

  sub SET {
    my ($self, $name, $value) = @_;
    push @SET_LOG, $name;
    return $self->SUPER::SET($name, $value);
  }

  package Venus::Test::__ANON__::Accessor::Child;
  use base 'Venus::Test::__ANON__::Accessor::Base';

  Venus::Test::__ANON__::Accessor::Child->ATTR('name');

  package main;

  my $obj = Venus::Test::__ANON__::Accessor::Child->BLESS;
  $obj->name('Alice');
  my $name = $obj->name;

  ok scalar(@Venus::Test::__ANON__::Accessor::Base::SET_LOG) > 0, 'SET hook called';
  ok scalar(@Venus::Test::__ANON__::Accessor::Base::GET_LOG) > 0, 'GET hook called';
  is $name, 'Alice', 'Accessor still works correctly';
};

subtest 'SUPER with multiple inheritance levels' => sub {
  # Demonstrates that SUPER must be called at every level of inheritance
  # to ensure all parent initialization runs

  package Venus::Test::__ANON__::MultiSuper::GrandParent;
  use base 'Venus::Core';

  sub BUILD {
    my ($self, $data) = @_;
    $self->{grandparent_built} = 1;
    return $self;
  }

  package Venus::Test::__ANON__::MultiSuper::Parent;
  use base 'Venus::Test::__ANON__::MultiSuper::GrandParent';

  sub BUILD {
    my ($self, $data) = @_;
    $self->SUPER::BUILD($data);
    $self->{parent_built} = 1;
    return $self;
  }

  package Venus::Test::__ANON__::MultiSuper::Child;
  use base 'Venus::Test::__ANON__::MultiSuper::Parent';

  sub BUILD {
    my ($self, $data) = @_;
    $self->SUPER::BUILD($data);
    $self->{child_built} = 1;
    return $self;
  }

  package main;

  my $obj = Venus::Test::__ANON__::MultiSuper::Child->BLESS;
  ok $obj->{grandparent_built}, 'GrandParent BUILD was called through chain';
  ok $obj->{parent_built}, 'Parent BUILD was called';
  ok $obj->{child_built}, 'Child BUILD was called';
};

ok 1 and done_testing;
