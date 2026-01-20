package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus::Space;
use Venus;

my $test = test(__FILE__);

=name

Venus::Role::Encaseable

=cut

$test->for('name');

=tagline

Encaseable Role

=cut

$test->for('tagline');

=abstract

Encaseable Role for Perl 5

=cut

$test->for('abstract');

=includes

method: clone
method: encase
method: encased
method: recase
method: uncase

=cut

$test->for('includes');

=synopsis

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encase('count', 1);
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, 1;

  $result
});

Venus::Space->new('Example')->purge;

=description

This package modifies the consuming package and provides methods for storing,
retrieving, and removing private instance variables, via the C<private>
(masked) attribute. B<Note:> A pre-existing attribute or routine named
C<private> in the consuming package may cause unexpected issues. This role
differs from L<Venus::Role::Stashable> in that it provides getters and setters
to help obscure the private instance data, whereas Stashable does not.

=cut

$test->for('description');

=method clone

The clone method clones the invocant and returns the result.

=signature clone

  clone() (object)

=metadata clone

{
  since => '4.15',
}

=cut

=example-1 clone

  # given: synopsis

  package main;

  my $clone = $example->clone;

  # bless(..., "Example")

=cut

$test->for('example', 1, 'clone', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa("Example");

  my $c1 = $result->clone;
  my $c2 = $result->clone;

  ok $c1;
  ok $c2;
  ok keys %$c1 == 0;
  ok keys %$c2 == 0;

  require Scalar::Util;
  isnt Scalar::Util::refaddr($c1), Scalar::Util::refaddr($c2);

  is_deeply $c1, $c2;
  is $c1->execute, $c2->execute;

  $result
});

=method encase

The encase method associates and stashes the key and value provided with the
class instance and returns the value provided. If the key is already associated
the value is not overwritten.

=signature encase

  encase(string $key, any $value) (any)

=metadata encase

{
  since => '4.15',
}

=example-1 encase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encase;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=cut

$test->for('example', 1, 'encase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, undef;

  $result
});

Venus::Space->new('Example')->purge;

=example-2 encase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encase('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=cut

$test->for('example', 2, 'encase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, undef;

  $result
});

Venus::Space->new('Example')->purge;

=example-3 encase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encase('count', 1);
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=cut

$test->for('example', 3, 'encase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, 1;

  $result
});

Venus::Space->new('Example')->purge;

=example-4 encase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->encase('count', $count);

    $count = $self->encase('count', $count + 1);

    $count = $self->encase('count', $count + 1);

    return $count;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=cut

$test->for('example', 4, 'encase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, 1;

  $result
});

Venus::Space->new('Example')->purge;

=example-5 encase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->encase('count', $count);

    return $count;
  }

  package main;

  my $execute = Example->execute;

  # Exception! Venus::Fault

=cut

$test->for('example', 5, 'encase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->catch('Venus::Fault')->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Can't encase variable \"count\" without an instance of \"Example\"";

  1
});

Venus::Space->new('Example')->purge;

=example-6 encase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->encase('count', $count);

    return $count;
  }

  package main;

  my $example = Example->new;

  $example->encase('count', 1);

  # Exception! Venus::Fault

=cut

$test->for('example', 6, 'encase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->catch('Venus::Fault')->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Can't encase variable \"count\" outside the class or subclass of \"Example\"";

  1
});

Venus::Space->new('Example')->purge;

=method encased

The encased method retrieves the value associated with the key provided,
associated and stashed with the class instance.

=signature encased

  encased(string $key) (any)

=metadata encased

{
  since => '4.15',
}

=example-1 encased

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encased;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=cut

$test->for('example', 1, 'encased', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, undef;

  $result
});

Venus::Space->new('Example')->purge;

=example-2 encased

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encased('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=cut

$test->for('example', 2, 'encased', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, undef;

  $result
});

Venus::Space->new('Example')->purge;

=example-3 encased

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    $self->encase('count', 1);

    return $self->encased('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=cut

$test->for('example', 3, 'encased', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, 1;

  $result
});

Venus::Space->new('Example')->purge;

=example-4 encased

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->recase('count', $count);

    $count = $self->recase('count', $count + 1);

    $count = $self->recase('count', $count + 1);

    return $self->encased('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 3

=cut

$test->for('example', 4, 'encased', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, 3;

  $result
});

Venus::Space->new('Example')->purge;

=example-5 encased

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encased('count');
  }

  package main;

  my $execute = Example->execute;

  # Exception! Venus::Fault

=cut

$test->for('example', 5, 'encased', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->catch('Venus::Fault')->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Can't retrieve encased variable \"count\" without an instance of \"Example\"";

  1
});

Venus::Space->new('Example')->purge;

=example-6 encased

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encased('count');
  }

  package main;

  my $example = Example->new;

  $example->encased('count');

  # Exception! Venus::Fault

=cut

$test->for('example', 6, 'encased', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->catch('Venus::Fault')->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Can't retrieve encased variable \"count\" outside the class or subclass of \"Example\"";

  1
});

Venus::Space->new('Example')->purge;

=method recase

The recase method associates and stashes the key and value provided with the
class instance and returns the value provided. The value is always overwritten.

=signature recase

  recase(string $key, any $value) (any)

=metadata recase

{
  since => '4.15',
}

=example-1 recase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->recase;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=cut

$test->for('example', 1, 'recase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, undef;

  $result
});

Venus::Space->new('Example')->purge;

=example-2 recase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->encase('count', $count);

    return $self->recase('count', $count + 1);
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 2

=cut

$test->for('example', 2, 'recase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, 2;

  $result
});

Venus::Space->new('Example')->purge;

=example-3 recase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->recase('count', $count);

    $count = $self->recase('count', $count + 1);

    $count = $self->recase('count', $count + 1);

    return $self->recase('count', $count + 1);
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 4

=cut

$test->for('example', 3, 'recase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, 4;

  $result
});

Venus::Space->new('Example')->purge;

=example-5 recase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->recase('count', $count);

    return $count;
  }

  package main;

  my $execute = Example->execute;

  # Exception! Venus::Fault

=cut

$test->for('example', 5, 'recase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->catch('Venus::Fault')->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Can't recase variable \"count\" without an instance of \"Example\"";

  1
});

Venus::Space->new('Example')->purge;

=example-6 recase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->recase('count', $count);

    return $count;
  }

  package main;

  my $example = Example->new;

  $example->recase('count', 1);

  # Exception! Venus::Fault

=cut

$test->for('example', 6, 'recase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->catch('Venus::Fault')->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Can't recase variable \"count\" outside the class or subclass of \"Example\"";

  1
});

Venus::Space->new('Example')->purge;

=method uncase

The uncase method dissociatesthe key and its corresponding value from the class
instance and returns the value.

=signature uncase

  uncase(string $key) (any)

=metadata uncase

{
  since => '4.15',
}

=example-1 uncase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->uncase;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=cut

$test->for('example', 1, 'uncase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, undef;

  $result
});

Venus::Space->new('Example')->purge;

=example-2 uncase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->uncase('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=cut

$test->for('example', 2, 'uncase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, undef;

  $result
});

Venus::Space->new('Example')->purge;

=example-3 uncase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $self->encase('count', $count);

    return $self->uncase('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=cut

$test->for('example', 3, 'uncase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, 1;

  $result
});

Venus::Space->new('Example')->purge;

=example-4 uncase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $self->encase('count', $count);

    $count = $self->uncase('count');

    return $self->uncase('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=cut

$test->for('example', 4, 'uncase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->does('Venus::Role::Encaseable');
  is_deeply $result, {};
  my $returns = $result->execute;
  is_deeply $result, {};
  is $returns, undef;

  $result
});

Venus::Space->new('Example')->purge;

=example-5 uncase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->uncase('count');
  }

  package main;

  my $execute = Example->execute;

  # Exception! Venus::Fault

=cut

$test->for('example', 5, 'uncase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->catch('Venus::Fault')->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Can't uncase variable \"count\" without an instance of \"Example\"";

  1
});

Venus::Space->new('Example')->purge;

=example-6 uncase

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->uncase('count');
  }

  package main;

  my $example = Example->new;

  $example->uncase('count');

  # Exception! Venus::Fault

=cut

$test->for('example', 6, 'uncase', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->catch('Venus::Fault')->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Can't uncase variable \"count\" outside the class or subclass of \"Example\"";

  1
});

Venus::Space->new('Example')->purge;

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Role/Encaseable.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
