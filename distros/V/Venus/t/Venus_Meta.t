package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Venus::Meta

=cut

$test->for('name');

=tagline

Class Metadata

=cut

$test->for('tagline');

=abstract

Class Metadata for Perl 5

=cut

$test->for('abstract');

=includes

method: attr
method: attrs
method: base
method: bases
method: data
method: new
method: role
method: roles
method: sub
method: subs

=cut

$test->for('includes');

=synopsis

  package Person;

  use Venus::Class;

  attr 'fname';
  attr 'lname';

  package Identity;

  use Venus::Role;

  attr 'id';
  attr 'login';
  attr 'password';

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['id', 'login', 'password']
  }

  package Authenticable;

  use Venus::Role;

  sub authenticate {
    return true;
  }

  sub AUDIT {
    my ($self, $from) = @_;
    # ensure the caller has a login and password when consumed
    die "${from} missing the login attribute" if !$from->can('login');
    die "${from} missing the password attribute" if !$from->can('password');
  }

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['authenticate']
  }

  package User;

  use Venus::Class;

  base 'Person';

  with 'Identity';

  attr 'email';

  test 'Authenticable';

  sub valid {
    my ($self) = @_;
    return $self->login && $self->password ? true : false;
  }

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  # bless({name => 'User'}, 'Venus::Meta')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Meta');
  ok UNIVERSAL::isa($result, 'HASH');

  $result
});

=description

This package provides configuration information for L<Venus> derived classes,
roles, and interfaces.

=cut

$test->for('description');

=method attr

The attr method returns true or false if the package referenced has the
attribute accessor named.

=signature attr

  attr(Str $name) (Bool)

=metadata attr

{
  since => '1.00',
}

=example-1 attr

  # given: synopsis

  package main;

  my $attr = $meta->attr('email');

  # 1

=cut

$test->for('example', 1, 'attr', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 attr

  # given: synopsis

  package main;

  my $attr = $meta->attr('username');

  # 0

=cut

$test->for('example', 2, 'attr', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=method attrs

The attrs method returns all of the attributes composed into the package
referenced.

=signature attrs

  attrs() (ArrayRef)

=metadata attrs

{
  since => '1.00',
}

=example-1 attrs

  # given: synopsis

  package main;

  my $attrs = $meta->attrs;

  # [
  #   'email',
  #   'fname',
  #   'id',
  #   'lname',
  #   'login',
  #   'password',
  # ]

=cut

$test->for('example', 1, 'attrs', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [sort @{$result}], [
    'email',
    'fname',
    'id',
    'lname',
    'login',
    'password',
  ];

  $result
});

=method base

The base method returns true or false if the package referenced has inherited
the package named.

=signature base

  base(Str $name) (Bool)

=metadata base

{
  since => '1.00',
}

=example-1 base

  # given: synopsis

  package main;

  my $base = $meta->base('Person');

  # 1

=cut

$test->for('example', 1, 'base', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 base

  # given: synopsis

  package main;

  my $base = $meta->base('Student');

  # 0

=cut

$test->for('example', 2, 'base', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=method bases

The bases method returns returns all of the packages inherited by the package
referenced.

=signature bases

  bases() (ArrayRef)

=metadata bases

{
  since => '1.00',
}

=example-1 bases

  # given: synopsis

  package main;

  my $bases = $meta->bases;

  # [
  #   'Person',
  #   'Venus::Core::Class',
  #   'Venus::Core',
  # ]

=cut

$test->for('example', 1, 'bases', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [
    'Person',
    'Venus::Core::Class',
    'Venus::Core'
  ];

  $result
});

=method data

The data method returns a data structure representing the shallow configuration
for the package referenced.

=signature data

  data() (HashRef)

=metadata data

{
  since => '1.00',
}

=example-1 data

  # given: synopsis

  package main;

  my $data = $meta->data;

  # {
  #   'ATTR' => {
  #     'email' => [
  #       'email'
  #     ]
  #   },
  #   'BASE' => {
  #     'Person' => [
  #       'Person'
  #     ]
  #   },
  #   'ROLE' => {
  #     'Authenticable' => [
  #       'Authenticable'
  #     ],
  #     'Identity' => [
  #       'Identity'
  #     ]
  #   }
  # }

=cut

$test->for('example', 1, 'data', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok ref $result eq 'HASH';
  ok $result->{ATTR};
  ok $result->{BASE};
  ok $result->{ROLE};

  $result
});

=method new

The new method returns a new instance of this package.

=signature new

  new(Any %args | HashRef $args) (Object)

=metadata new

{
  since => '1.00',
}

=example-1 new

  # given: synopsis

  package main;

  $meta = Venus::Meta->new(name => 'User');

  # bless({name => 'User'}, 'Venus::Meta')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Meta');
  ok $result->{name} eq 'User';

  $result
});

=example-2 new

  # given: synopsis

  package main;

  $meta = Venus::Meta->new({name => 'User'});

  # bless({name => 'User'}, 'Venus::Meta')

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Meta');
  ok $result->{name} eq 'User';

  $result
});

=method role

The role method returns true or false if the package referenced has consumed
the role named.

=signature role

  role(Str $name) (Bool)

=metadata role

{
  since => '1.00',
}

=example-1 role

  # given: synopsis

  package main;

  my $role = $meta->role('Identity');

  # 1

=cut

$test->for('example', 1, 'role', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 role

  # given: synopsis

  package main;

  my $role = $meta->role('Builder');

  # 0

=cut

$test->for('example', 2, 'role', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=method roles

The roles method returns all of the roles composed into the package referenced.

=signature roles

  roles() (ArrayRef)

=metadata roles

{
  since => '1.00',
}

=example-1 roles

  # given: synopsis

  package main;

  my $roles = $meta->roles;

  # [
  #   'Identity',
  #   'Authenticable'
  # ]

=cut

$test->for('example', 1, 'roles', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [sort @{$result}], ['Authenticable', 'Identity'];

  $result
});

=method sub

The sub method returns true or false if the package referenced has the
subroutine named on the package directly, or any of its superclasses.

=signature sub

  sub(Str $name) (Bool)

=metadata sub

{
  since => '1.00',
}

=example-1 sub

  # given: synopsis

  package main;

  my $sub = $meta->sub('authenticate');

  # 1

=cut

$test->for('example', 1, 'sub', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 sub

  # given: synopsis

  package main;

  my $sub = $meta->sub('authorize');

  # 0

=cut

$test->for('example', 2, 'sub', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=method subs

The subs method returns all of the subroutines composed into the package
referenced.

=signature subs

  subs() (ArrayRef)

=metadata subs

{
  since => '1.00',
}

=example-1 subs

  # given: synopsis

  package main;

  my $subs = $meta->subs;

  # [
  #   'attr', ...,
  #   'base',
  #   'email',
  #   'false',
  #   'fname', ...,
  #   'id',
  #   'lname',
  #   'login',
  #   'new', ...,
  #   'role',
  #   'test',
  #   'true',
  #   'with', ...,
  # ]

=cut

$test->for('example', 1, 'subs', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  my %subs = map +($_,$_), @{$result};
  ok $subs{'attr'};
  ok $subs{'authenticate'};
  ok $subs{'base'};
  ok $subs{'email'};
  ok $subs{'false'};
  ok $subs{'fname'};
  ok $subs{'id'};
  ok $subs{'lname'};
  ok $subs{'login'};
  ok $subs{'new'};
  ok $subs{'role'};
  ok $subs{'test'};
  ok $subs{'true'};
  ok $subs{'with'};

  $result
});

# END

$test->render('lib/Venus/Meta.pod') if $ENV{RENDER};

ok 1 and done_testing;
