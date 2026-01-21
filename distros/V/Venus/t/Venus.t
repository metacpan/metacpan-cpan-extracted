package main;

use 5.018;

use strict;
use warnings;

use Test::More import => ['!is'];
use Venus::Test;
use Venus;

use Config;
use Venus::Process;
use Venus::Path;

my $test = test(__FILE__);
my $fsds = qr/[:\\\/\.]+/;

our $TEST_VENUS_QX_DATA = '';
our $TEST_VENUS_QX_EXIT = 0;
our $TEST_VENUS_QX_CODE = 0;

# _qx
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::_qx"} = sub {
    (
      $TEST_VENUS_QX_DATA,
      $TEST_VENUS_QX_EXIT,
      $TEST_VENUS_QX_CODE
    )
  };
}

our @TEST_VENUS_PROCESS_PIDS;
our $TEST_VENUS_PROCESS_ALARM = 0;
our $TEST_VENUS_PROCESS_CHDIR = 1;
our $TEST_VENUS_PROCESS_EXIT = 0;
our $TEST_VENUS_PROCESS_EXITCODE = 0;
our $TEST_VENUS_PROCESS_FORK = undef;
our $TEST_VENUS_PROCESS_FORKABLE = 1;
our $TEST_VENUS_PROCESS_SERVE = 0;
our $TEST_VENUS_PROCESS_KILL = 0;
our $TEST_VENUS_PROCESS_OPEN = 1;
our $TEST_VENUS_PROCESS_PID = 12345;
our $TEST_VENUS_PROCESS_PPID = undef;
our $TEST_VENUS_PROCESS_PING = 1;
our $TEST_VENUS_PROCESS_SETSID = 1;
our $TEST_VENUS_PROCESS_TIME = 0;
our $TEST_VENUS_PROCESS_WAITPID = undef;

$Venus::Process::PATH = Venus::Path->mktemp_dir;
$Venus::Process::PID = $TEST_VENUS_PROCESS_PID;

# _alarm
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_alarm"} = sub {
    $TEST_VENUS_PROCESS_ALARM = $_[0]
  };
}

# _chdir
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_chdir"} = sub {
    $TEST_VENUS_PROCESS_CHDIR
  };
}

# _exit
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_exit"} = sub {
    $TEST_VENUS_PROCESS_EXIT
  };
}

# _exitcode
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_exitcode"} = sub {
    $TEST_VENUS_PROCESS_EXITCODE
  };
}

# _fork
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_fork"} = sub {
    if (defined $TEST_VENUS_PROCESS_FORK) {
      return $TEST_VENUS_PROCESS_FORK;
    }
    else {
      push @TEST_VENUS_PROCESS_PIDS,
        $TEST_VENUS_PROCESS_PID+@TEST_VENUS_PROCESS_PIDS;
      return $TEST_VENUS_PROCESS_PIDS[-1];
    }
  };
}

# _forkable
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_forkable"} = sub {
    return $TEST_VENUS_PROCESS_FORKABLE;
  };
}

# _serve
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_serve"} = sub {
    return $TEST_VENUS_PROCESS_SERVE;
  };
}

# _kill
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_kill"} = sub {
    $TEST_VENUS_PROCESS_KILL;
  };
}

# _open
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_open"} = sub {
    $TEST_VENUS_PROCESS_OPEN
  };
}

# _ping
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_ping"} = sub {
    $TEST_VENUS_PROCESS_PING
  };
}

# _setsid
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_setsid"} = sub {
    $TEST_VENUS_PROCESS_SETSID
  };
}

# _time
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_time"} = sub {
    $TEST_VENUS_PROCESS_TIME || time
  };
}

# _waitpid
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::_waitpid"} = sub {
    if (defined $TEST_VENUS_PROCESS_WAITPID) {
      return $TEST_VENUS_PROCESS_WAITPID;
    }
    else {
      return pop @TEST_VENUS_PROCESS_PIDS;
    }
  };
}

# default
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Process::default"} = sub {
    $TEST_VENUS_PROCESS_PID
  };
}

=name

Venus

=cut

$test->for('name');

=tagline

Standard Library

=cut

$test->for('tagline');

=abstract

Standard Library for Perl 5

=cut

$test->for('abstract');

=includes

function: after
function: all
function: any
function: args
function: around
function: array
function: arrayref
function: assert
function: async
function: atom
function: await
function: before
function: bool
function: box
function: call
function: cast
function: catch
function: caught
function: chain
function: check
function: clargs
function: cli
function: clone
function: code
function: collect
function: concat
function: config
function: cop
function: data
function: date
function: enum
function: error
function: factory
function: false
function: fault
function: flat
function: float
function: future
function: gather
function: gets
function: handle
function: hash
function: hashref
function: hook
function: in
function: is
function: is_arrayref
function: is_blessed
function: is_boolean
function: is_coderef
function: is_dirhandle
function: is_enum
function: is_error
function: is_false
function: is_fault
function: is_filehandle
function: is_float
function: is_glob
function: is_hashref
function: is_number
function: is_object
function: is_package
function: is_reference
function: is_regexp
function: is_scalarref
function: is_string
function: is_true
function: is_undef
function: is_value
function: is_yesno
function: json
function: kvargs
function: list
function: load
function: log
function: make
function: map
function: match
function: merge
function: merge_flat
function: merge_flat_mutate
function: merge_join
function: merge_join_mutate
function: merge_keep
function: merge_keep_mutate
function: merge_swap
function: merge_swap_mutate
function: merge_take
function: merge_take_mutate
function: meta
function: name
function: number
function: opts
function: pairs
function: path
function: perl
function: process
function: proto
function: puts
function: raise
function: random
function: range
function: read_env
function: read_env_file
function: read_json
function: read_json_file
function: read_perl
function: read_perl_file
function: read_yaml
function: read_yaml_file
function: regexp
function: render
function: replace
function: roll
function: schema
function: search
function: set
function: sets
function: sorts
function: space
function: string
function: syscall
function: template
function: test
function: text_pod
function: text_pod_string
function: text_tag
function: text_tag_string
function: then
function: throw
function: true
function: try
function: tv
function: type
function: unpack
function: vars
function: vns
function: what
function: work
function: wrap
function: write_env
function: write_env_file
function: write_json
function: write_json_file
function: write_perl
function: write_perl_file
function: write_yaml
function: write_yaml_file
function: yaml

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus 'catch', 'error', 'raise';

  # error handling
  my ($error, $result) = catch {
    error;
  };

  # boolean keywords
  if ($result) {
    error;
  }

  # raise exceptions
  if ($result) {
    raise 'MyApp::Error';
  }

  # boolean keywords, and more!
  my $bool = true ne false;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=description

This library provides an object-orientation framework and extendible standard
library for Perl 5 with classes which wrap most native Perl data types. Venus
has a simple modular architecture, robust library of classes, methods, and
roles, supports pure-Perl autoboxing, advanced exception handling, "true" and
"false" functions, package introspection, command-line options parsing, and
more. This package will always automatically exports C<true> and C<false>
keyword functions (unless existing routines of the same name already exist in
the calling package or its parents), otherwise exports keyword functions as
requested at import. This library requires Perl C<5.18+>.

+=head1 CAPABILITIES

The following is a short list of capabilities:

+=over 4

+=item *

Perl 5.18.0+

+=item *

Zero Dependencies

+=item *

Fast Object-Orientation

+=item *

Robust Standard Library

+=item *

Intuitive Value Classes

+=item *

Pure Perl Autoboxing

+=item *

Convenient Utility Classes

+=item *

Simple Package Reflection

+=item *

Flexible Exception Handling

+=item *

Composable Standards

+=item *

Pluggable (no monkeypatching)

+=item *

Proxyable Methods

+=item *

Type Assertions

+=item *

Type Coercions

+=item *

Value Casting

+=item *

Boolean Values

+=item *

Complete Documentation

+=item *

Complete Test Coverage

+=back

=cut

$test->for('description');

=function after

The after function installs a method modifier that executes after the original
method, allowing you to perform actions after a method call. B<Note:> The
return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is always exported unless a routine of the same
name already exists.

=signature after

  after(string $name, coderef $code) (coderef)

=metadata after

{
  since => '4.15',
}

=example-1 after

  package Example;

  use Venus::Class 'after', 'attr';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return 'original';
  }

  after 'test', sub {
    my ($self) = @_;
    push @{$self->calls}, 'after';
    return 'ignored';
  };

  package main;

  my $example = Example->new;
  my $value = $example->test;

  # "original"

=cut

$test->for('example', 1, 'after', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result eq 'original';

  $result
});

=example-2 after

  package Example2;

  use Venus::Class 'after', 'attr';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return $self;
  }

  after 'test', sub {
    my ($self) = @_;
    push @{$self->calls}, 'after';
    return $self;
  };

  package main;

  my $example = Example2->new;
  $example->test;
  my $calls = $example->calls;

  # ['original', 'after']

=cut

$test->for('example', 2, 'after', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['original', 'after'];

  $result
});

=function all

The all function accepts an arrayref, hashref, or
L<"mappable"|Venus::Role::Mappable> and returns true if the rvalue is a
callback and returns true for all items in the collection. If the rvalue
provided is not a coderef that value's type and value will be used as the
criteria.

=signature all

  all(arrayref | hashref | consumes[Venus::Role::Mappable] $lvalue, any $rvalue) (boolean)

=metadata all

{
  since => '4.15',
}

=cut

=example-1 all

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [1, '1'], 1;

  # false

=cut

$test->for('example', 1, 'all', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-2 all

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [1, 1], 1;

  # true

=cut

$test->for('example', 2, 'all', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-3 all

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all {1, 2}, 1;

  # false

=cut

$test->for('example', 3, 'all', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-4 all

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all {1, 1}, 1;

  # true

=cut

$test->for('example', 4, 'all', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-5 all

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [[1], [1]], [1];

  # true

=cut

$test->for('example', 5, 'all', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-6 all

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [1, '1', 2..4], sub{$_ > 0};

  # true

=cut

$test->for('example', 6, 'all', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-7 all

  # given: synopsis

  package main;

  use Venus 'all';

  my $all = all [1, '1', 2..4], sub{$_ > 1};

  # false

=cut

$test->for('example', 7, 'all', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function any

The any function accepts an arrayref, hashref, or
L<"mappable"|Venus::Role::Mappable> and returns true if the rvalue is a
callback and returns true for any items in the collection. If the rvalue
provided is not a coderef that value's type and value will be used as the
criteria.

=signature any

  any(arrayref | hashref | consumes[Venus::Role::Mappable] $lvalue, any $rvalue) (boolean)

=metadata any

{
  since => '4.15',
}

=cut

=example-1 any

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [1, '1'], 1;

  # true

=cut

$test->for('example', 1, 'any', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 any

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [1, 1], 0;

  # false

=cut

$test->for('example', 2, 'any', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-3 any

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any {1, 2}, 1;

  # false

=cut

$test->for('example', 3, 'any', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-4 any

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any {1, 1}, 1;

  # true

=cut

$test->for('example', 4, 'any', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-5 any

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [[0], [1]], [1];

  # true

=cut

$test->for('example', 5, 'any', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-6 any

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [1, '1', 2..4], sub{!defined};

  # false

=cut

$test->for('example', 6, 'any', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-7 any

  # given: synopsis

  package main;

  use Venus 'any';

  my $any = any [1, '1', 2..4, undef], sub{!defined};

  # true

=cut

$test->for('example', 7, 'any', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=function args

The args function builds and returns a L<Venus::Args> object, or dispatches to
the coderef or method provided.

=signature args

  args(arrayref $value, string | coderef $code, any @args) (any)

=metadata args

{
  since => '3.10',
}

=cut

=example-1 args

  package main;

  use Venus 'args';

  my $args = args ['--resource', 'users'];

  # bless({...}, 'Venus::Args')

=cut

$test->for('example', 1, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Args';

  $result
});

=example-2 args

  package main;

  use Venus 'args';

  my $args = args ['--resource', 'users'], 'indexed';

  # {0 => '--resource', 1 => 'users'}

=cut

$test->for('example', 2, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {0 => '--resource', 1 => 'users'};

  $result
});

=function around

The around function installs a method modifier that wraps around the original
method, giving you complete control over its execution. The modifier receives
the original method as its first argument, followed by the method's arguments,
and must explicitly call the original method if desired.

=signature around

  around(string $name, coderef $code) (coderef)

=metadata around

{
  since => '4.15',
}

=example-1 around

  package Example3;

  use Venus::Class 'around', 'attr';

  sub test {
    my ($self, $value) = @_;
    return $value;
  }

  around 'test', sub {
    my ($orig, $self, $value) = @_;
    my $result = $self->$orig($value);
    return $result * 2;
  };

  package main;

  my $result = Example3->new->test(5);

  # 10

=cut

$test->for('example', 1, 'around', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result == 10;

  $result
});

=example-2 around

  package Example4;

  use Venus::Class 'around', 'attr';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return $self;
  }

  around 'test', sub {
    my ($orig, $self) = @_;
    push @{$self->calls}, 'before';
    $self->$orig;
    push @{$self->calls}, 'after';
    return $self;
  };

  package main;

  my $example = Example4->new;
  $example->test;
  my $calls = $example->calls;

  # ['before', 'original', 'after']

=cut

$test->for('example', 2, 'around', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['before', 'original', 'after'];

  $result
});

=function array

The array function builds and returns a L<Venus::Array> object, or dispatches
to the coderef or method provided.

=signature array

  array(arrayref | hashref $value, string | coderef $code, any @args) (any)

=metadata array

{
  since => '2.55',
}

=cut

=example-1 array

  package main;

  use Venus 'array';

  my $array = array [];

  # bless({...}, 'Venus::Array')

=cut

$test->for('example', 1, 'array', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Array';
  is_deeply $result->get, [];

  $result
});

=example-2 array

  package main;

  use Venus 'array';

  my $array = array [1..4], 'push', 5..9;

  # [1..9]

=cut

$test->for('example', 2, 'array', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..9];

  $result
});

=function arrayref

The arrayref function takes a list of arguments and returns a arrayref.

=signature arrayref

  arrayref(any @args) (arrayref)

=metadata arrayref

{
  since => '3.10',
}

=example-1 arrayref

  package main;

  use Venus 'arrayref';

  my $arrayref = arrayref(content => 'example');

  # [content => "example"]

=cut

$test->for('example', 1, 'arrayref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [content => "example"];

  $result
});

=example-2 arrayref

  package main;

  use Venus 'arrayref';

  my $arrayref = arrayref([content => 'example']);

  # [content => "example"]

=cut

$test->for('example', 2, 'arrayref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, [content => "example"];

  $result
});

=example-3 arrayref

  package main;

  use Venus 'arrayref';

  my $arrayref = arrayref('content');

  # ['content']

=cut

$test->for('example', 3, 'arrayref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ['content'];

  $result
});

=function assert

The assert function builds a L<Venus::Assert> object and returns the result of
a L<Venus::Assert/validate> operation.

=signature assert

  assert(any $data, string $expr) (any)

=metadata assert

{
  since => '2.40',
}

=cut

=example-1 assert

  package main;

  use Venus 'assert';

  my $assert = assert(1234567890, 'number');

  # 1234567890

=cut

$test->for('example', 1, 'assert', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1234567890;

  $result
});

=example-2 assert

  package main;

  use Venus 'assert';

  my $assert = assert(1234567890, 'float');

  # Exception! (isa Venus::Check::Error)

=cut

$test->for('example', 2, 'assert', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  ok defined $result;
  isa_ok $result, 'Venus::Check::Error';

  $result
});

=example-3 assert

  package main;

  use Venus 'assert';

  my $assert = assert(1234567890, 'number | float');

  # 1234567890

=cut

$test->for('example', 3, 'assert', sub {
  my ($tryable) = @_;
  my $result = $tryable->error->result;
  ok defined $result;
  is_deeply $result, 1234567890;

  $result
});

=function async

The async function accepts a callback and executes it asynchronously via
L<Venus::Process/future>. This function returns a L<Venus::Future> object which
can be fulfilled via L<Venus::Future/wait>.

=signature async

  async(coderef $code, any @args) (Venus::Future)

=metadata async

{
  since => '3.40',
}

=cut

=example-1 async

  package main;

  use Venus 'async';

  my $async = async sub{
    'done'
  };

  # bless({...}, 'Venus::Future')

=cut

$test->for('example', 1, 'async', sub {
  no warnings 'once';
  if ($Config{d_pseudofork}) {
    plan skip_all => 'Fork emulation not supported';
    return 1;
  }
  my ($tryable) = @_;
  local $TEST_VENUS_PROCESS_FORK = 0;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Future";

  $result
});

=function atom

The atom function builds and returns a L<Venus::Atom> object.

=signature atom

  atom(any $value) (Venus::Atom)

=metadata atom

{
  since => '3.55',
}

=cut

=example-1 atom

  package main;

  use Venus 'atom';

  my $atom = atom 'super-admin';

  # bless({scope => sub{...}}, "Venus::Atom")

  # "$atom"

  # "super-admin"

=cut

$test->for('example', 1, 'atom', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Atom";
  is_deeply $result->get, "super-admin";

  $result
});

=function await

The await function accepts a L<Venus::Future> object and eventually returns a
value (or values) for it. The value(s) returned are the return values or
emissions from the asychronous callback executed with L</async> which produced
the process object.

=signature await

  await(Venus::Future $future, number $timeout) (any)

=metadata await

{
  since => '3.40',
}

=cut

=example-1 await

  package main;

  use Venus 'async', 'await';

  my $process;

  my $async = async sub{
    return 'done';
  };

  my $await = await $async;

  # bless(..., "Venus::Future")

=cut

$test->for('example', 1, 'await', sub {
  no warnings 'once';
  if ($Config{d_pseudofork}) {
    plan skip_all => 'Fork emulation not supported';
    return 1;
  }
  my ($tryable) = @_;
  local $TEST_VENUS_PROCESS_FORK = 0;
  local $TEST_VENUS_PROCESS_PING = 0;
  local $TEST_VENUS_PROCESS_TIME = time + 1;
  local $Venus::Process::PPID = $TEST_VENUS_PROCESS_PPID = undef;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Future";

  $result
});

=function before

The before function installs a method modifier that executes before the
original method, allowing you to perform actions before a method call. B<Note:>
The return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is always exported unless a routine of the same
name already exists.

=signature before

  before(string $name, coderef $code) (coderef)

=metadata before

{
  since => '4.15',
}

=example-1 before

  package Example5;

  use Venus::Class 'attr', 'before';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return $self;
  }

  before 'test', sub {
    my ($self) = @_;
    push @{$self->calls}, 'before';
    return $self;
  };

  package main;

  my $example = Example5->new;
  $example->test;
  my $calls = $example->calls;

  # ['before', 'original']

=cut

$test->for('example', 1, 'before', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['before', 'original'];

  $result
});

=example-2 before

  package Example6;

  use Venus::Class 'attr', 'before';

  attr 'validated';

  sub test {
    my ($self, $value) = @_;
    return $value;
  }

  before 'test', sub {
    my ($self, $value) = @_;
    $self->validated(1) if $value > 0;
    return 'ignored';
  };

  package main;

  my $example = Example6->new;
  my $value = $example->test(5);

  # 5

=cut

$test->for('example', 2, 'before', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result == 5;

  $result
});

=function bool

The bool function builds and returns a L<Venus::Boolean> object.

=signature bool

  bool(any $value) (Venus::Boolean)

=metadata bool

{
  since => '2.55',
}

=cut

=example-1 bool

  package main;

  use Venus 'bool';

  my $bool = bool;

  # bless({value => 0}, 'Venus::Boolean')

=cut

$test->for('example', 1, 'bool', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Boolean';
  is_deeply $result->get, 0;

  !$result
});

=example-2 bool

  package main;

  use Venus 'bool';

  my $bool = bool 1_000;

  # bless({value => 1}, 'Venus::Boolean')

=cut

$test->for('example', 2, 'bool', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Boolean';
  is_deeply $result->get, 1;

  $result
});

=function box

The box function returns a L<Venus::Box> object for the argument provided.

=signature box

  box(any $data) (Venus::Box)

=metadata box

{
  since => '2.32',
}

=example-1 box

  package main;

  use Venus 'box';

  my $box = box({});

  # bless({value => bless({value => {}}, 'Venus::Hash')}, 'Venus::Box')

=cut

$test->for('example', 1, 'box', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Box');
  ok $result->unbox->isa('Venus::Hash');
  is_deeply $result->unbox->value, {};

  $result
});

=example-2 box

  package main;

  use Venus 'box';

  my $box = box([]);

  # bless({value => bless({value => []}, 'Venus::Array')}, 'Venus::Box')

=cut

$test->for('example', 2, 'box', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Box');
  ok $result->unbox->isa('Venus::Array');
  is_deeply $result->unbox->value, [];

  $result
});

=function call

The call function dispatches function and method calls to a package and returns
the result.

=signature call

  call(string | object | coderef $data, any @args) (any)

=metadata call

{
  since => '2.32',
}

=example-1 call

  package main;

  use Venus 'call';

  require Digest::SHA;

  my $result = call(\'Digest::SHA', 'new');

  # bless(do{\(my $o = '...')}, 'digest::sha')

=cut

$test->for('example', 1, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Digest::SHA');

  $result
});

=example-2 call

  package main;

  use Venus 'call';

  require Digest::SHA;

  my $result = call('Digest::SHA', 'sha1_hex');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"

=cut

$test->for('example', 2, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "da39a3ee5e6b4b0d3255bfef95601890afd80709";

  $result
});

=example-3 call

  package main;

  use Venus 'call';

  require Venus::Hash;

  my $result = call(sub{'Venus::Hash'->new(@_)}, {1..4});

  # bless({value => {1..4}}, 'Venus::Hash')

=cut

$test->for('example', 3, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Hash');
  is_deeply $result->value, {1..4};

  $result
});

=example-4 call

  package main;

  use Venus 'call';

  require Venus::Box;

  my $result = call(Venus::Box->new(value => {}), 'merge', {1..4});

  # bless({value => bless({value => {1..4}}, 'Venus::Hash')}, 'Venus::Box')

=cut

$test->for('example', 4, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Box');
  ok $result->unbox->isa('Venus::Hash');
  is_deeply $result->unbox->value, {1..4};

  $result
});

=function cast

The cast function returns the argument provided as an object, promoting native
Perl data types to data type objects. The optional second argument can be the
name of the type for the object to cast to explicitly.

=signature cast

  cast(any $data, string $type) (object)

=metadata cast

{
  since => '1.40',
}

=example-1 cast

  package main;

  use Venus 'cast';

  my $undef = cast;

  # bless({value => undef}, "Venus::Undef")

=cut

$test->for('example', 1, 'cast', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result->isa('Venus::Undef');

  !$result
});

=example-2 cast

  package main;

  use Venus 'cast';

  my @booleans = map cast, true, false;

  # (bless({value => 1}, "Venus::Boolean"), bless({value => 0}, "Venus::Boolean"))

=cut

$test->for('example', 2, 'cast', sub {
  my ($tryable) = @_;
  ok my @result = $tryable->result;
  ok $result[0]->isa('Venus::Boolean');
  is_deeply $result[0]->get, 1;
  ok $result[1]->isa('Venus::Boolean');
  is_deeply $result[1]->get, 0;

  @result
});

=example-3 cast

  package main;

  use Venus 'cast';

  my $example = cast bless({}, "Example");

  # bless({value => 1}, "Example")

=cut

$test->for('example', 3, 'cast', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example');

  $result
});

=example-4 cast

  package main;

  use Venus 'cast';

  my $float = cast 1.23;

  # bless({value => "1.23"}, "Venus::Float")

=cut

$test->for('example', 4, 'cast', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Float');
  is_deeply $result->get, 1.23;

  $result
});

=function catch

The catch function executes the code block trapping errors and returning the
caught exception in scalar context, and also returning the result as a second
argument in list context.

=signature catch

  catch(coderef $block) (Venus::Error, any)

=metadata catch

{
  since => '0.01',
}

=example-1 catch

  package main;

  use Venus 'catch';

  my $error = catch {die};

  $error;

  # "Died at ..."

=cut

$test->for('example', 1, 'catch', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok !ref($result);

  $result
});

=example-2 catch

  package main;

  use Venus 'catch';

  my ($error, $result) = catch {error};

  $error;

  # bless({...}, 'Venus::Error')

=cut

$test->for('example', 2, 'catch', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');

  $result
});

=example-3 catch

  package main;

  use Venus 'catch';

  my ($error, $result) = catch {true};

  $result;

  # 1

=cut

$test->for('example', 3, 'catch', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=function caught

The caught function evaluates the exception object provided and validates its
identity and name (if provided) then executes the code block provided returning
the result of the callback. If no callback is provided this function returns
the exception object on success and C<undef> on failure.

=signature caught

  caught(object $error, string | tuple[string, string] $identity, coderef $block) (any)

=metadata caught

{
  since => '1.95',
}

=example-1 caught

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error };

  my $result = caught $error, 'Venus::Error';

  # bless(..., 'Venus::Error')

=cut

$test->for('example', 1, 'caught', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  ok !$result->name;

  $result
});

=example-2 caught

  package main;

  use Venus 'catch', 'caught', 'raise';

  my $error = catch { raise 'Example::Error' };

  my $result = caught $error, 'Venus::Error';

  # bless(..., 'Venus::Error')

=cut

$test->for('example', 2, 'caught', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example::Error');
  ok $result->isa('Venus::Error');
  ok !$result->name;

  $result
});

=example-3 caught

  package main;

  use Venus 'catch', 'caught', 'raise';

  my $error = catch { raise 'Example::Error' };

  my $result = caught $error, 'Example::Error';

  # bless(..., 'Venus::Error')

=cut

$test->for('example', 3, 'caught', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example::Error');
  ok $result->isa('Venus::Error');
  ok !$result->name;

  $result
});

=example-4 caught

  package main;

  use Venus 'catch', 'caught', 'raise';

  my $error = catch { raise 'Example::Error', { name => 'on.test' } };

  my $result = caught $error, ['Example::Error', 'on.test'];

  # bless(..., 'Venus::Error')

=cut

$test->for('example', 4, 'caught', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Example::Error');
  ok $result->isa('Venus::Error');
  ok $result->name;
  is_deeply $result->name, 'on.test';

  $result
});

=example-5 caught

  package main;

  use Venus 'catch', 'caught', 'raise';

  my $error = catch { raise 'Example::Error', { name => 'on.recv' } };

  my $result = caught $error, ['Example::Error', 'on.send'];

  # undef

=cut

$test->for('example', 5, 'caught', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  !$result
});

=example-6 caught

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error };

  my $result = caught $error, ['Example::Error', 'on.send'];

  # undef

=cut

$test->for('example', 6, 'caught', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  !$result
});

=example-7 caught

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error };

  my $result = caught $error, ['Example::Error'];

  # undef

=cut

$test->for('example', 7, 'caught', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  !$result
});

=example-8 caught

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error };

  my $result = caught $error, 'Example::Error';

  # undef

=cut

$test->for('example', 8, 'caught', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  !$result
});

=example-9 caught

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error { name => 'on.send' } };

  my $result = caught $error, ['Venus::Error', 'on.send'];

  # bless(..., 'Venus::Error')

=cut

$test->for('example', 9, 'caught', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  ok $result->name;
  is_deeply $result->name, 'on.send';

  $result
});

=example-10 caught

  package main;

  use Venus 'catch', 'caught', 'error';

  my $error = catch { error { name => 'on.send.open' } };

  my $result = caught $error, ['Venus::Error', 'on.send'], sub {
    $error->stash('caught', true) if $error->is('on.send.open');
    return $error;
  };

  # bless(..., 'Venus::Error')

=cut

$test->for('example', 10, 'caught', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  ok $result->stash('caught');
  ok $result->name;
  is_deeply $result->name, 'on.send.open';

  $result
});

=function chain

The chain function chains function and method calls to a package (and return
values) and returns the result.

=signature chain

  chain(string | object | coderef $self, string | within[arrayref, string] @args) (any)

=metadata chain

{
  since => '2.32',
}

=example-1 chain

  package main;

  use Venus 'chain';

  my $result = chain('Venus::Path', ['new', 't'], 'exists');

  # 1

=cut

$test->for('example', 1, 'chain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-2 chain

  package main;

  use Venus 'chain';

  my $result = chain('Venus::Path', ['new', 't'], ['test', 'd']);

  # 1

=cut

$test->for('example', 2, 'chain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=function check

The check function builds a L<Venus::Assert> object and returns the result of
a L<Venus::Assert/check> operation.

=signature check

  check(any $data, string $expr) (boolean)

=metadata check

{
  since => '2.40',
}

=cut

=example-1 check

  package main;

  use Venus 'check';

  my $check = check(rand, 'float');

  # true

=cut

$test->for('example', 1, 'check', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-2 check

  package main;

  use Venus 'check';

  my $check = check(rand, 'string');

  # false

=cut

$test->for('example', 2, 'check', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 0;

  !$result
});

=function clargs

The clargs function accepts a single arrayref of L<Getopt::Long> specs, or an
arrayref of arguments followed by an arrayref of L<Getopt::Long> specs, and
returns a three element list of L<Venus::Args>, L<Venus::Opts>, and
L<Venus::Vars> objects. If only a single arrayref is provided, the arguments
will be taken from C<@ARGV>. If this function is called in scalar context only
the L<Venus::Opts> object will be returned.

=signature clargs

  clargs(arrayref $args, arrayref $spec) (Venus::Args, Venus::Opts, Venus::Vars)

=metadata clargs

{
  since => '3.10',
}

=cut

=example-1 clargs

  package main;

  use Venus 'clargs';

  my ($args, $opts, $vars) = clargs;

  # (
  #   bless(..., 'Venus::Args'),
  #   bless(..., 'Venus::Opts'),
  #   bless(..., 'Venus::Vars')
  # )

=cut

$test->for('example', 1, 'clargs', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  isa_ok $result[0], 'Venus::Args';
  is_deeply $result[0]->value, [];
  isa_ok $result[1], 'Venus::Opts';
  is_deeply $result[1]->value, [];
  isa_ok $result[2], 'Venus::Vars';

  @result
});

=example-2 clargs

  package main;

  use Venus 'clargs';

  my ($args, $opts, $vars) = clargs ['resource|r=s', 'help|h'];

  # (
  #   bless(..., 'Venus::Args'),
  #   bless(..., 'Venus::Opts'),
  #   bless(..., 'Venus::Vars')
  # )

=cut

$test->for('example', 2, 'clargs', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  isa_ok $result[0], 'Venus::Args';
  is_deeply $result[0]->value, [];
  isa_ok $result[1], 'Venus::Opts';
  is_deeply $result[1]->value, [];
  is_deeply $result[1]->specs, ['resource|r=s', 'help|h'];
  isa_ok $result[2], 'Venus::Vars';

  @result
});

=example-3 clargs

  package main;

  use Venus 'clargs';

  my ($args, $opts, $vars) = clargs ['--resource', 'help'],
    ['resource|r=s', 'help|h'];

  # (
  #   bless(..., 'Venus::Args'),
  #   bless(..., 'Venus::Opts'),
  #   bless(..., 'Venus::Vars')
  # )

=cut

$test->for('example', 3, 'clargs', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  isa_ok $result[0], 'Venus::Args';
  is_deeply $result[0]->value, [];
  isa_ok $result[1], 'Venus::Opts';
  is_deeply $result[1]->value, ['--resource', 'help'];
  is_deeply $result[1]->specs, ['resource|r=s', 'help|h'];
  isa_ok $result[2], 'Venus::Vars';

  @result
});

=example-4 clargs

  package main;

  use Venus 'clargs';

  my ($args, $opts, $vars) = clargs ['--help', 'how-to'],
    ['resource|r=s', 'help|h'];

  # (
  #   bless(..., 'Venus::Args'),
  #   bless(..., 'Venus::Opts'),
  #   bless(..., 'Venus::Vars')
  # )

=cut

$test->for('example', 4, 'clargs', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  isa_ok $result[0], 'Venus::Args';
  is_deeply $result[0]->value, ['how-to'];
  isa_ok $result[1], 'Venus::Opts';
  is_deeply $result[1]->value, ['--help', 'how-to'];
  is_deeply $result[1]->specs, ['resource|r=s', 'help|h'];
  isa_ok $result[2], 'Venus::Vars';

  @result
});

=example-5 clargs

  package main;

  use Venus 'clargs';

  my $opts = clargs ['--help', 'how-to'], ['resource|r=s', 'help|h'];

  # bless(..., 'Venus::Opts'),

=cut

$test->for('example', 5, 'clargs', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Opts';
  is_deeply $result->value, ['--help', 'how-to'];
  is_deeply $result->specs, ['resource|r=s', 'help|h'];

  $result
});

=function cli

The cli function builds and returns a L<Venus::Cli> object.

=signature cli

  cli(arrayref $args) (Venus::Cli)

=metadata cli

{
  since => '2.55',
}

=cut

=example-1 cli

  package main;

  use Venus 'cli';

  my $cli = cli;

  # bless({...}, 'Venus::Cli')

=cut

$test->for('example', 1, 'cli', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Cli';

  $result
});

=example-2 cli

  package main;

  use Venus 'cli';

  my $cli = cli 'mycli';

  # bless({...}, 'Venus::Cli')

  # $cli->boolean('option', 'help');

  # $cli->parse('--help');

  # $cli->option_value('help');

  # 1

=cut

$test->for('example', 2, 'cli', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Cli';
  $result->boolean('option', 'help');
  $result->parse('--help');
  my $help = $result->option_value('help');
  ok $help == 1;

  $result
});

=function clone

The clone function uses L<Storable/dclone> to perform a deep clone of the
reference provided and returns a copy.

=signature clone

  clone(ref $value) (ref)

=metadata clone

{
  since => '3.55',
}

=cut

=example-1 clone

  package main;

  use Venus 'clone';

  my $orig = {1..4};

  my $clone = clone $orig;

  $orig->{3} = 5;

  my $result = $clone;

  # {1..4}

=cut

$test->for('example', 1, 'clone', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, {1..4};

  $result
});

=example-2 clone

  package main;

  use Venus 'clone';

  my $orig = {1,2,3,{1..4}};

  my $clone = clone $orig;

  $orig->{3}->{3} = 5;

  my $result = $clone;

  # {1,2,3,{1..4}}

=cut

$test->for('example', 2, 'clone', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, {1,2,3,{1..4}};

  $result
});

=function code

The code function builds and returns a L<Venus::Code> object, or dispatches
to the coderef or method provided.

=signature code

  code(coderef $value, string | coderef $code, any @args) (any)

=metadata code

{
  since => '2.55',
}

=cut

=example-1 code

  package main;

  use Venus 'code';

  my $code = code sub {};

  # bless({...}, 'Venus::Code')

=cut

$test->for('example', 1, 'code', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Code';
  ok ref $result->get eq 'CODE';
  ok !defined $result->call;

  $result
});

=example-2 code

  package main;

  use Venus 'code';

  my $code = code sub {[1, @_]}, 'curry', 2,3,4;

  # sub {...}

=cut

$test->for('example', 2, 'code', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'CODE';
  is_deeply $result->(), [1..4];
  is_deeply $result->(5..9), [1..9];

  $result
});

=function concat

The concat function stringifies and L<"joins"|perlfunc/join> multiple values delimited
by a single space and returns the resulting string.

=signature concat

  concat(any @args) (string)

=metadata concat

{
  since => '4.15',
}

=cut

=example-1 concat

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat;

  # ""

=cut

$test->for('example', 1, 'concat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "";

  !$result
});

=example-2 concat

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat 'hello';

  # "hello"

=cut

$test->for('example', 2, 'concat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "hello";

  $result
});

=example-3 concat

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat 'hello', 'world';

  # "hello world"

=cut

$test->for('example', 3, 'concat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "hello world";

  $result
});

=example-4 concat

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat 'value is', [1,2];

  # "value is [1,2]"

=cut

$test->for('example', 4, 'concat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "value is [1,2]";

  $result
});

=example-5 concat

  # given: synopsis

  package main;

  use Venus 'concat';

  my $concat = concat 'value is', [1,2], 'and', [3,4];

  # "value is [1,2] and [3,4]"

=cut

$test->for('example', 5, 'concat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "value is [1,2] and [3,4]";

  $result
});

=function config

The config function builds and returns a L<Venus::Config> object, or dispatches
to the coderef or method provided.

=signature config

  config(hashref $value, string | coderef $code, any @args) (any)

=metadata config

{
  since => '2.55',
}

=cut

=example-1 config

  package main;

  use Venus 'config';

  my $config = config {};

  # bless({...}, 'Venus::Config')

=cut

$test->for('example', 1, 'config', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Config';
  is_deeply $result->get, {};

  $result
});

=example-2 config

  package main;

  use Venus 'config';

  my $config = config {}, 'read_perl', '{"data"=>1}';

  # bless({...}, 'Venus::Config')

=cut

$test->for('example', 2, 'config', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Config';
  is_deeply $result->get, {data => 1};

  $result
});

=function collect

The collect function uses L<Venus::Collect> to iterate over the value and
selectively transform or filter the data. The function supports both list-like
and hash-like data structures, handling key/value iteration when applicable.

=signature collect

  collect(any $value, coderef $code) (any)

=metadata collect

{
  since => '4.15',
}

=cut

=example-1 collect

  package main;

  use Venus 'collect';

  my $collect = collect [];

  # []

=cut

$test->for('example', 1, 'collect', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 collect

  package main;

  use Venus 'collect';

  my $collect = collect [1..4], sub{$_%2==0?(@_):()};

  # [2,4]

=cut

$test->for('example', 2, 'collect', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2,4];

  $result
});

=example-3 collect

  package main;

  use Venus 'collect';

  my $collect = collect {};

  # {}

=cut

$test->for('example', 3, 'collect', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-4 collect

  package main;

  use Venus 'collect';

  my $collect = collect {1..8}, sub{$_%6==0?(@_):()};

  # {5,6}

=cut

$test->for('example', 4, 'collect', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {5,6};

  $result
});

=function cop

The cop function attempts to curry the given subroutine on the object or class
and if successful returns a closure.

=signature cop

  cop(string | object | coderef $self, string $name) (coderef)

=metadata cop

{
  since => '2.32',
}

=example-1 cop

  package main;

  use Venus 'cop';

  my $coderef = cop('Digest::SHA', 'sha1_hex');

  # sub { ... }

=cut

$test->for('example', 1, 'cop', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply ref($result), 'CODE';

  $result
});

=example-2 cop

  package main;

  use Venus 'cop';

  require Digest::SHA;

  my $coderef = cop(Digest::SHA->new, 'digest');

  # sub { ... }

=cut

$test->for('example', 2, 'cop', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply ref($result), 'CODE';

  $result
});

=function data

The data function builds and returns a L<Venus::Data> object, or dispatches to
the coderef or method provided.

=signature data

  data(any $value, string | coderef $code, any @args) (any)

=metadata data

{
  since => '4.15',
}

=cut

=example-1 data

  package main;

  use Venus 'data';

  my $data = data {value => {name => 'Elliot'}};

  # bless({...}, 'Venus::Data')

=cut

$test->for('example', 1, 'data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Data';

  $result
});

=example-2 data

  package main;

  use Venus 'data';

  my $data = data {value => {name => 'Elliot'}}, 'valid';

  # 1

=cut

$test->for('example', 2, 'data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=example-3 data

  package main;

  use Venus 'data';

  my $data = data {value => {name => 'Elliot'}}, 'shorthand', ['name!' => 'string'];

  # bless({...}, 'Venus::Data')

  # $data->valid;

  # 1

=cut

$test->for('example', 3, 'data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Data';
  ok $result->valid;

  $result
});

=example-4 data

  package main;

  use Venus 'data';

  my $data = data {value => {name => undef}}, 'shorthand', ['name!' => 'string'];

  # bless({...}, 'Venus::Data')

  # $data->valid;

  # 0

=cut

$test->for('example', 4, 'data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Data';
  ok !$result->valid;

  $result
});

=function date

The date function builds and returns a L<Venus::Date> object, or dispatches to
the coderef or method provided.

=signature date

  date(number $value, string | coderef $code, any @args) (any)

=metadata date

{
  since => '2.40',
}

=cut

=example-1 date

  package main;

  use Venus 'date';

  my $date = date time, 'string';

  # '0000-00-00T00:00:00Z'

=cut

$test->for('example', 1, 'date', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  like $result, qr/\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d/;

  $result
});

=example-2 date

  package main;

  use Venus 'date';

  my $date = date time, 'reset', 570672000;

  # bless({...}, 'Venus::Date')

  # $date->string;

  # '1988-02-01T00:00:00Z'

=cut

$test->for('example', 2, 'date', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result->string, '1988-02-01T00:00:00Z';

  $result
});

=example-3 date

  package main;

  use Venus 'date';

  my $date = date time;

  # bless({...}, 'Venus::Date')

=cut

$test->for('example', 3, 'date', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Date';

  $result
});

=function enum

The enum function builds and returns a L<Venus::Enum> object.

=signature enum

  enum(arrayref | hashref $value) (Venus::Enum)

=metadata enum

{
  since => '3.55',
}

=cut

=example-1 enum

  package main;

  use Venus 'enum';

  my $themes = enum ['light', 'dark'];

  # bless({scope => sub{...}}, "Venus::Enum")

  # my $result = $themes->get('dark');

  # bless({scope => sub{...}}, "Venus::Enum")

  # "$result"

  # "dark"

=cut

$test->for('example', 1, 'enum', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Enum";
  my $returned = $result->get('dark');
  isa_ok $returned, "Venus::Enum";
  is_deeply "$returned", "dark";

  !$result
});

=example-2 enum

  package main;

  use Venus 'enum';

  my $themes = enum {
    light => 'light_theme',
    dark => 'dark_theme',
  };

  # bless({scope => sub{...}}, "Venus::Enum")

  # my $result = $themes->get('dark');

  # bless({scope => sub{...}}, "Venus::Enum")

  # "$result"

  # "dark_theme"

=cut

$test->for('example', 2, 'enum', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Enum";
  my $returned = $result->get('dark');
  isa_ok $returned, "Venus::Enum";
  is_deeply "$returned", "dark_theme";

  !$result
});

=function error

The error function throws a L<Venus::Error> exception object using the
exception object arguments provided.

=signature error

  error(maybe[hashref] $args) (Venus::Error)

=metadata error

{
  since => '0.01',
}

=example-1 error

  package main;

  use Venus 'error';

  my $error = error;

  # bless({...}, 'Venus::Error')

=cut

$test->for('example', 1, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Exception!';

  $result
});

=example-2 error

  package main;

  use Venus 'error';

  my $error = error {
    message => 'Something failed!',
  };

  # bless({message => 'Something failed!', ...}, 'Venus::Error')

=cut

$test->for('example', 2, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Something failed!';

  $result
});

=function factory

The factory function builds and returns a L<Venus::Factory> object, or
dispatches to the coderef or method provided.

=signature factory

  factory(hashref $value, string | coderef $code, any @args) (any)

=metadata factory

{
  since => '4.15',
}

=cut

=example-1 factory

  package main;

  use Venus 'factory';

  my $factory = factory {};

  # bless(..., 'Venus::Factory')

=cut

$test->for('example', 1, 'factory', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  is_deeply $result, {};

  $result
});

=example-2 factory

  package main;

  use Venus 'factory';

  my $path = factory {name => 'path', value => ['/tmp/log']}, 'class', 'Venus::Path';

  # bless(..., 'Venus::Factory')

  # $path->build;

  # bless({value => '/tmp/log'}, 'Venus::Path')

=cut

$test->for('example', 2, 'factory', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Factory');
  my $returns = $result->build;
  ok $returns->isa('Venus::Path');
  is_deeply $returns->value, '/tmp/log';

  $result
});

=function false

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value.

=signature false

  false() (boolean)

=metadata false

{
  since => '0.01',
}

=example-1 false

  package main;

  use Venus;

  my $false = false;

  # 0

=cut

$test->for('example', 1, 'false', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=example-2 false

  package main;

  use Venus;

  my $true = !false;

  # 1

=cut

$test->for('example', 2, 'false', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=function fault

The fault function throws a L<Venus::Fault> exception object and represents a
system failure, and isn't meant to be caught.

=signature fault

  fault(string $args) (Venus::Fault)

=metadata fault

{
  since => '1.80',
}

=example-1 fault

  package main;

  use Venus 'fault';

  my $fault = fault;

  # bless({message => 'Exception!'}, 'Venus::Fault')

=cut

$test->for('example', 1, 'fault', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('Venus::Fault');
  ok $error->{message} eq 'Exception!';

  $result
});

=example-2 fault

  package main;

  use Venus 'fault';

  my $fault = fault 'Something failed!';

  # bless({message => 'Something failed!'}, 'Venus::Fault')

=cut

$test->for('example', 2, 'fault', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('Venus::Fault');
  ok $error->{message} eq 'Something failed!';

  $result
});

=function flat

The flat function take a list of arguments and flattens them where possible and
returns the list of flattened values. When a hashref is encountered, it will be
flattened into key/value pairs. When an arrayref is encountered, it will be
flattened into a list of items.

=signature flat

  flat(any @args) (any)

=metadata flat

{
  since => '4.15',
}

=cut

=example-1 flat

  package main;

  use Venus 'flat';

  my @flat = flat 1, 2, 3;

  # (1, 2, 3)

=cut

$test->for('example', 1, 'flat', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, [1, 2, 3];

  @result
});

=example-2 flat

  package main;

  use Venus 'flat';

  my @flat = flat 1, 2, 3, [1, 2, 3];

  # (1, 2, 3, 1, 2, 3)

=cut

$test->for('example', 2, 'flat', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, [1, 2, 3, 1, 2, 3];

  @result
});

=example-3 flat

  package main;

  use Venus 'flat';

  my @flat = flat 1, 2, 3, [1, 2, 3], {1, 2};

  # (1, 2, 3, 1, 2, 3, 1, 2)

=cut

$test->for('example', 3, 'flat', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, [1, 2, 3, 1, 2, 3, 1, 2];

  @result
});

=function float

The float function builds and returns a L<Venus::Float> object, or dispatches
to the coderef or method provided.

=signature float

  float(string $value, string | coderef $code, any @args) (any)

=metadata float

{
  since => '2.55',
}

=cut

=example-1 float

  package main;

  use Venus 'float';

  my $float = float 1.23;

  # bless({...}, 'Venus::Float')

=cut

$test->for('example', 1, 'float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Float';
  is_deeply $result->get, 1.23;

  $result
});

=example-2 float

  package main;

  use Venus 'float';

  my $float = float 1.23, 'int';

  # 1

=cut

$test->for('example', 2, 'float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=function future

The future function builds and returns a L<Venus::Future> object.

=signature future

  future(coderef $code) (Venus::Future)

=metadata future

{
  since => '3.55',
}

=cut

=example-1 future

  package main;

  use Venus 'future';

  my $future = future(sub{
    my ($resolve, $reject) = @_;

    return int(rand(2)) ? $resolve->result('pass') : $reject->result('fail');
  });

  # bless(..., "Venus::Future")

  # $future->is_pending;

  # false

=cut

$test->for('example', 1, 'future', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Future";
  ok !$result->is_pending;

  $result
});

=function gather

The gather function builds a L<Venus::Gather> object, passing it and the value
provided to the callback provided, and returns the return value from
L<Venus::Gather/result>.

=signature gather

  gather(any $value, coderef $callback) (any)

=metadata gather

{
  since => '2.50',
}

=cut

=example-1 gather

  package main;

  use Venus 'gather';

  my $gather = gather ['a'..'d'];

  # bless({...}, 'Venus::Gather')

  # $gather->result;

  # undef

=cut

$test->for('example', 1, 'gather', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Gather';

  $result
});

=example-2 gather

  package main;

  use Venus 'gather';

  my $gather = gather ['a'..'d'], sub {{
    a => 1,
    b => 2,
    c => 3,
  }};

  # [1..3]

=cut

$test->for('example', 2, 'gather', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..3];

  $result
});

=example-3 gather

  package main;

  use Venus 'gather';

  my $gather = gather ['e'..'h'], sub {{
    a => 1,
    b => 2,
    c => 3,
  }};

  # []

=cut

$test->for('example', 3, 'gather', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-4 gather

  package main;

  use Venus 'gather';

  my $gather = gather ['a'..'d'], sub {
    my ($case) = @_;

    $case->when(sub{lc($_) eq 'a'})->then('a -> A');
    $case->when(sub{lc($_) eq 'b'})->then('b -> B');
  };

  # ['a -> A', 'b -> B']

=cut

$test->for('example', 4, 'gather', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['a -> A', 'b -> B'];

  $result
});

=example-5 gather

  package main;

  use Venus 'gather';

  my $gather = gather ['a'..'d'], sub {

    $_->when(sub{lc($_) eq 'a'})->then('a -> A');
    $_->when(sub{lc($_) eq 'b'})->then('b -> B');
  };

  # ['a -> A', 'b -> B']

=cut

$test->for('example', 5, 'gather', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['a -> A', 'b -> B'];

  $result
});

=function gets

The gets function select values from within the underlying data structure using
L<Venus::Array/path> or L<Venus::Hash/path>, where each argument is a selector,
returns all the values selected. Returns a list in list context.

=signature gets

  gets(string @args) (arrayref)

=metadata gets

{
  since => '4.15',
}

=cut

=example-1 gets

  package main;

  use Venus 'gets';

  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};

  my $gets = gets $data, 'bar', 'foo.bar';

  # [['baz'], 'baz']

=cut

$test->for('example', 1, 'gets', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['baz'], 'baz'];

  $result
});

=example-2 gets

  package main;

  use Venus 'gets';

  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};

  my ($bar, $foo_bar) = gets $data, 'bar', 'foo.bar';

  # (['baz'], 'baz')

=cut

$test->for('example', 2, 'gets', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, [['baz'], 'baz'];

  @result
});

=example-3 gets

  package main;

  use Venus 'gets';

  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];

  my $gets = gets $data, '3', '1.bar';

  # [['baz'], 'baz']

=cut

$test->for('example', 3, 'gets', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['baz'], 'baz'];

  $result
});

=example-4 gets

  package main;

  use Venus 'gets';

  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];

  my ($baz, $one_bar) = gets $data, '3', '1.bar';

  # (['baz'], 'baz')

=cut

$test->for('example', 4, 'gets', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, [['baz'], 'baz'];

  @result
});

=function handle

The handle function installs a method modifier that wraps a method similar to
L</around>, but is the low-level implementation. The modifier receives the
original method as its first argument (which may be undef if the method doesn't
  exist), followed by the method's arguments. This is the foundation for the
other method modifiers.

=signature handle

  handle(string $name, coderef $code) (coderef)

=metadata handle

{
  since => '4.15',
}

=example-1 handle

  package Example7;

  use Venus::Class 'handle';

  sub test {
    my ($self, $value) = @_;
    return $value;
  }

  handle 'test', sub {
    my ($orig, $self, $value) = @_;
    return $orig ? $self->$orig($value * 2) : 0;
  };

  package main;

  my $result = Example7->new->test(5);

  # 10

=cut

$test->for('example', 1, 'handle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result == 10;

  $result
});

=example-2 handle

  package Example8;

  use Venus::Class 'handle';

  handle 'missing', sub {
    my ($orig, $self) = @_;
    return 'method does not exist';
  };

  package main;

  my $result = Example8->new->missing;

  # "method does not exist"

=cut

$test->for('example', 2, 'handle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result eq 'method does not exist';

  $result
});

=function hash

The hash function builds and returns a L<Venus::Hash> object, or dispatches
to the coderef or method provided.

=signature hash

  hash(hashref $value, string | coderef $code, any @args) (any)

=metadata hash

{
  since => '2.55',
}

=cut

=example-1 hash

  package main;

  use Venus 'hash';

  my $hash = hash {1..4};

  # bless({...}, 'Venus::Hash')

=cut

$test->for('example', 1, 'hash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Hash';
  is_deeply $result->get, {1..4};

  $result
});

=example-2 hash

  package main;

  use Venus 'hash';

  my $hash = hash {1..8}, 'pairs';

  # [[1, 2], [3, 4], [5, 6], [7, 8]]

=cut

$test->for('example', 2, 'hash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [[1, 2], [3, 4], [5, 6], [7, 8]];

  $result
});

=function hashref

The hashref function takes a list of arguments and returns a hashref.

=signature hashref

  hashref(any @args) (hashref)

=metadata hashref

{
  since => '3.10',
}

=example-1 hashref

  package main;

  use Venus 'hashref';

  my $hashref = hashref(content => 'example');

  # {content => "example"}

=cut

$test->for('example', 1, 'hashref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {content => "example"};

  $result
});

=example-2 hashref

  package main;

  use Venus 'hashref';

  my $hashref = hashref({content => 'example'});

  # {content => "example"}

=cut

$test->for('example', 2, 'hashref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {content => "example"};

  $result
});

=example-3 hashref

  package main;

  use Venus 'hashref';

  my $hashref = hashref('content');

  # {content => undef}

=cut

$test->for('example', 3, 'hashref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {content => undef};

  $result
});

=example-4 hashref

  package main;

  use Venus 'hashref';

  my $hashref = hashref('content', 'example', 'algorithm');

  # {content => "example", algorithm => undef}

=cut

$test->for('example', 4, 'hashref', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {content => "example", algorithm => undef};

  $result
});

=function hook

The hook function is a specialized method modifier helper that applies a
modifier (after, around, before, or handle) to a lifecycle hook method. It
automatically uppercases the hook name, making it convenient for modifying
Venus lifecycle hooks like BUILD, BLESS, BUILDARGS, and AUDIT.

=signature hook

  hook(string $type, string $name, coderef $code) (coderef)

=metadata hook

{
  since => '4.15',
}

=example-1 hook

  package Example9;

  use Venus::Class 'attr', 'hook';

  attr 'startup';

  sub BUILD {
    my ($self, $args) = @_;
    $self->startup('original');
  }

  hook 'after', 'build', sub {
    my ($self) = @_;
    $self->startup('modified');
  };

  package main;

  my $result = Example9->new->startup;

  # "modified"

=cut

$test->for('example', 1, 'hook', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result eq 'modified';

  $result
});

=example-2 hook

  package Example10;

  use Venus::Class 'attr', 'hook';

  attr 'calls';

  sub BUILD {
    my ($self, $args) = @_;
    $self->calls([]) if !$self->calls;
    push @{$self->calls}, 'BUILD';
  }

  hook 'before', 'build', sub {
    my ($self) = @_;
    $self->calls([]) if !$self->calls;
    push @{$self->calls}, 'before';
  };

  package main;

  my $example = Example10->new;
  my $calls = $example->calls;

  # ['before', 'BUILD']

=cut

$test->for('example', 2, 'hook', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['before', 'BUILD'];

  $result
});

=function in

The in function accepts an arrayref, hashref, or
L<"mappable"|Venus::Role::Mappable> and returns true if the type and value of
the rvalue is the same for any items in the collection.

=signature in

  in(arrayref | hashref | consumes[Venus::Role::Mappable] $lvalue, any $rvalue) (boolean)

=metadata in

{
  since => '4.15',
}

=cut

=example-1 in

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in [1, '1'], 1;

  # true

=cut

$test->for('example', 1, 'in', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 in

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in [1, 1], 0;

  # false

=cut

$test->for('example', 2, 'in', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-3 in

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in {1, 2}, 1;

  # false

=cut

$test->for('example', 3, 'in', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-4 in

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in {1, 1}, 1;

  # true

=cut

$test->for('example', 4, 'in', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-5 in

  # given: synopsis

  package main;

  use Venus 'in';

  my $in = in [[0], [1]], [1];

  # true

=cut

$test->for('example', 5, 'in', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=function is

The is function returns true if the lvalue and rvalue are identical, i.e.
refers to the same memory address, otherwise returns false.

=signature is

  is(any $lvalue, any $rvalue) (boolean)

=metadata is

{
  since => '4.15',
}

=cut

=example-1 is

  # given: synopsis

  package main;

  use Venus 'is';

  my $is = is 1, 1;

  # false

=cut

$test->for('example', 1, 'is', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-2 is

  # given: synopsis

  package main;

  use Venus 'is', 'number';

  my $a = number 1;

  my $is = is $a, 1;

  # false

=cut

$test->for('example', 2, 'is', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-3 is

  # given: synopsis

  package main;

  use Venus 'is', 'number';

  my $a = number 1;

  my $is = is $a, $a;

  # true

=cut

$test->for('example', 3, 'is', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-4 is

  # given: synopsis

  package main;

  use Venus 'is', 'number';

  my $a = number 1;
  my $b = number 1;

  my $is = is $a, $b;

  # false

=cut

$test->for('example', 4, 'is', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_blessed

The is_blessed function uses L</check> to validate that the data provided is an
object returns true, otherwise returns false.

=signature is_blessed

  is_blessed(any $data) (boolean)

=metadata is_blessed

{
  since => '4.15',
}

=cut

=example-1 is_blessed

  # given: synopsis

  package main;

  use Venus 'is_blessed';

  my $is_blessed = is_blessed bless {};

  # true

=cut

$test->for('example', 1, 'is_blessed', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_blessed

  # given: synopsis

  package main;

  use Venus 'is_blessed';

  my $is_blessed = is_blessed {};

  # false

=cut

$test->for('example', 2, 'is_blessed', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_boolean

The is_boolean function uses L</check> to validate that the data provided is a
boolean returns true, otherwise returns false.

=signature is_boolean

  is_boolean(any $data) (boolean)

=metadata is_boolean

{
  since => '4.15',
}

=cut

=example-1 is_boolean

  # given: synopsis

  package main;

  use Venus 'is_boolean';

  my $is_boolean = is_boolean true;

  # true

=cut

$test->for('example', 1, 'is_boolean', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_boolean

  # given: synopsis

  package main;

  use Venus 'is_boolean';

  my $is_boolean = is_boolean 1;

  # false

=cut

$test->for('example', 2, 'is_boolean', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_coderef

The is_coderef function uses L</check> to validate that the data provided is a
coderef returns true, otherwise returns false.

=signature is_coderef

  is_coderef(any $data) (boolean)

=metadata is_coderef

{
  since => '4.15',
}

=cut

=example-1 is_coderef

  # given: synopsis

  package main;

  use Venus 'is_coderef';

  my $is_coderef = is_coderef sub{};

  # true

=cut

$test->for('example', 1, 'is_coderef', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_coderef

  # given: synopsis

  package main;

  use Venus 'is_coderef';

  my $is_coderef = is_coderef {};

  # false

=cut

$test->for('example', 2, 'is_coderef', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_dirhandle

The is_dirhandle function uses L</check> to validate that the data provided is
a dirhandle returns true, otherwise returns false.

=signature is_dirhandle

  is_dirhandle(any $data) (boolean)

=metadata is_dirhandle

{
  since => '4.15',
}

=cut

=example-1 is_dirhandle

  # given: synopsis

  package main;

  use Venus 'is_dirhandle';

  opendir my $dh, 't';

  my $is_dirhandle = is_dirhandle $dh;

  # true

=cut

# Unsupported on Windows: The dirfd function is unimplemented
$test->skip_if('os_is_win')->for('example', 1, 'is_dirhandle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_dirhandle

  # given: synopsis

  package main;

  use Venus 'is_dirhandle';

  open my $fh, '<', 't/data/moon';

  my $is_dirhandle = is_dirhandle $fh;

  # false

=cut

$test->for('example', 2, 'is_dirhandle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_enum

The is_enum function uses L</check> to validate that the data provided is an
enum returns true, otherwise returns false.

=signature is_enum

  is_enum(any $data, value @args) (boolean)

=metadata is_enum

{
  since => '4.15',
}

=cut

=example-1 is_enum

  # given: synopsis

  package main;

  use Venus 'is_enum';

  my $is_enum = is_enum 'yes', 'yes', 'no'

  # true

=cut

$test->for('example', 1, 'is_enum', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_enum

  # given: synopsis

  package main;

  use Venus 'is_enum';

  my $is_enum = is_enum 'yes', 'Yes', 'No';

  # false

=cut

$test->for('example', 2, 'is_enum', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_error

The is_error function accepts a scalar value and returns true if the value is
(or is derived from) L<Venus::Error>. This function can dispatch method calls
and execute callbacks, and returns true of the return value from the callback
is truthy, and false otherwise.

=signature is_error

  is_error(any $data, string | coderef $code, any @args) (boolean)

=metadata is_error

{
  since => '4.15',
}

=cut

=example-1 is_error

  package main;

  use Venus 'is_error';

  my $is_error = is_error 0;

  # false

=cut

$test->for('example', 1, 'is_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-2 is_error

  package main;

  use Venus 'is_error';

  my $is_error = is_error 1;

  # false

=cut

$test->for('example', 2, 'is_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-3 is_error

  package main;

  use Venus 'catch', 'fault', 'is_error';

  my $fault = catch {fault};

  my $is_error = is_error $fault;

  # false

=cut

$test->for('example', 3, 'is_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-4 is_error

  package main;

  use Venus 'catch', 'error', 'is_error';

  my $error = catch {error};

  my $is_error = is_error $error;

  # true

=cut

$test->for('example', 4, 'is_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-5 is_error

  package main;

  use Venus 'catch', 'error', 'is_error';

  my $error = catch {error {verbose => true}};

  my $is_error = is_error $error, 'verbose';

  # true

=cut

$test->for('example', 5, 'is_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-6 is_error

  package main;

  use Venus 'catch', 'error', 'is_error';

  my $error = catch {error {verbose => false}};

  my $is_error = is_error $error, 'verbose';

  # false

=cut

$test->for('example', 6, 'is_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=function is_false

The is_false function accepts a scalar value and returns true if the value is
falsy. This function can dispatch method calls and execute callbacks.

=signature is_false

  is_false(any $data, string | coderef $code, any @args) (boolean)

=metadata is_false

{
  since => '3.04',
}

=cut

=example-1 is_false

  package main;

  use Venus 'is_false';

  my $is_false = is_false 0;

  # true

=cut

$test->for('example', 1, 'is_false', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-2 is_false

  package main;

  use Venus 'is_false';

  my $is_false = is_false 1;

  # false

=cut

$test->for('example', 2, 'is_false', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-3 is_false

  package main;

  use Venus 'array', 'is_false';

  my $array = array [];

  my $is_false = is_false $array;

  # false

=cut

$test->for('example', 3, 'is_false', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-4 is_false

  package main;

  use Venus 'array', 'is_false';

  my $array = array [];

  my $is_false = is_false $array, 'count';

  # true

=cut

$test->for('example', 4, 'is_false', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-5 is_false

  package main;

  use Venus 'array', 'is_false';

  my $array = array [1];

  my $is_false = is_false $array, 'count';

  # false

=cut

$test->for('example', 5, 'is_false', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-6 is_false

  package main;

  use Venus 'is_false';

  my $array = undef;

  my $is_false = is_false $array, 'count';

  # true

=cut

$test->for('example', 6, 'is_false', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=function is_fault

The is_fault function accepts a scalar value and returns true if the value is
(or is derived from) L<Venus::Fault>.

=signature is_fault

  is_fault(any $data) (boolean)

=metadata is_fault

{
  since => '4.15',
}

=cut

=example-1 is_fault

  package main;

  use Venus 'is_fault';

  my $is_fault = is_fault 0;

  # false

=cut

$test->for('example', 1, 'is_fault', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-2 is_fault

  package main;

  use Venus 'is_fault';

  my $is_fault = is_fault 1;

  # false

=cut

$test->for('example', 2, 'is_fault', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-3 is_fault

  package main;

  use Venus 'catch', 'fault', 'is_fault';

  my $fault = catch {fault};

  my $is_fault = is_fault $fault;

  # true

=cut

$test->for('example', 3, 'is_fault', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-4 is_fault

  package main;

  use Venus 'catch', 'error', 'is_fault';

  my $error = catch {error};

  my $is_fault = is_fault $error;

  # false

=cut

$test->for('example', 4, 'is_fault', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=function is_filehandle

The is_filehandle function uses L</check> to validate that the data provided is
a filehandle returns true, otherwise returns false.

=signature is_filehandle

  is_filehandle(any $data) (boolean)

=metadata is_filehandle

{
  since => '4.15',
}

=cut

=example-1 is_filehandle

  # given: synopsis

  package main;

  use Venus 'is_filehandle';

  open my $fh, '<', 't/data/moon';

  my $is_filehandle = is_filehandle $fh;

  # true

=cut

$test->for('example', 1, 'is_filehandle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_filehandle

  # given: synopsis

  package main;

  use Venus 'is_filehandle';

  opendir my $dh, 't';

  my $is_filehandle = is_filehandle $dh;

  # false

=cut

$test->for('example', 2, 'is_filehandle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_float

The is_float function uses L</check> to validate that the data provided is a
float returns true, otherwise returns false.

=signature is_float

  is_float(any $data) (boolean)

=metadata is_float

{
  since => '4.15',
}

=cut

=example-1 is_float

  # given: synopsis

  package main;

  use Venus 'is_float';

  my $is_float = is_float .123;

  # true

=cut

$test->for('example', 1, 'is_float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_float

  # given: synopsis

  package main;

  use Venus 'is_float';

  my $is_float = is_float 123;

  # false

=cut

$test->for('example', 2, 'is_float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_glob

The is_glob function uses L</check> to validate that the data provided is a
glob returns true, otherwise returns false.

=signature is_glob

  is_glob(any $data) (boolean)

=metadata is_glob

{
  since => '4.15',
}

=cut

=example-1 is_glob

  # given: synopsis

  package main;

  use Venus 'is_glob';

  my $is_glob = is_glob \*main;

  # true

=cut

$test->for('example', 1, 'is_glob', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_glob

  # given: synopsis

  package main;

  use Venus 'is_glob';

  my $is_glob = is_glob *::main;

  # false

=cut

$test->for('example', 2, 'is_glob', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_hashref

The is_hashref function uses L</check> to validate that the data provided is a
hashref returns true, otherwise returns false.

=signature is_hashref

  is_hashref(any $data) (boolean)

=metadata is_hashref

{
  since => '4.15',
}

=cut

=example-1 is_hashref

  # given: synopsis

  package main;

  use Venus 'is_hashref';

  my $is_hashref = is_hashref {};

  # true

=cut

$test->for('example', 1, 'is_hashref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_hashref

  # given: synopsis

  package main;

  use Venus 'is_hashref';

  my $is_hashref = is_hashref [];

  # false

=cut

$test->for('example', 2, 'is_hashref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_number

The is_number function uses L</check> to validate that the data provided is a
number returns true, otherwise returns false.

=signature is_number

  is_number(any $data) (boolean)

=metadata is_number

{
  since => '4.15',
}

=cut

=example-1 is_number

  # given: synopsis

  package main;

  use Venus 'is_number';

  my $is_number = is_number 0;

  # true

=cut

$test->for('example', 1, 'is_number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_number

  # given: synopsis

  package main;

  use Venus 'is_number';

  my $is_number = is_number '0';

  # false

=cut

$test->for('example', 2, 'is_number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_object

The is_object function uses L</check> to validate that the data provided is an
object returns true, otherwise returns false.

=signature is_object

  is_object(any $data) (boolean)

=metadata is_object

{
  since => '4.15',
}

=cut

=example-1 is_object

  # given: synopsis

  package main;

  use Venus 'is_object';

  my $is_object = is_object bless {};

  # true

=cut

$test->for('example', 1, 'is_object', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_object

  # given: synopsis

  package main;

  use Venus 'is_object';

  my $is_object = is_object {};

  # false

=cut

$test->for('example', 2, 'is_object', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_package

The is_package function uses L</check> to validate that the data provided is a
package returns true, otherwise returns false.

=signature is_package

  is_package(any $data) (boolean)

=metadata is_package

{
  since => '4.15',
}

=cut

=example-1 is_package

  # given: synopsis

  package main;

  use Venus 'is_package';

  my $is_package = is_package 'Venus';

  # true

=cut

$test->for('example', 1, 'is_package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_package

  # given: synopsis

  package main;

  use Venus 'is_package';

  my $is_package = is_package 'MyApp';

  # false

=cut

$test->for('example', 2, 'is_package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_reference

The is_reference function uses L</check> to validate that the data provided is
a reference returns true, otherwise returns false.

=signature is_reference

  is_reference(any $data) (boolean)

=metadata is_reference

{
  since => '4.15',
}

=cut

=example-1 is_reference

  # given: synopsis

  package main;

  use Venus 'is_reference';

  my $is_reference = is_reference \0;

  # true

=cut

$test->for('example', 1, 'is_reference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_reference

  # given: synopsis

  package main;

  use Venus 'is_reference';

  my $is_reference = is_reference 0;

  # false

=cut

$test->for('example', 2, 'is_reference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_regexp

The is_regexp function uses L</check> to validate that the data provided is a
regexp returns true, otherwise returns false.

=signature is_regexp

  is_regexp(any $data) (boolean)

=metadata is_regexp

{
  since => '4.15',
}

=cut

=example-1 is_regexp

  # given: synopsis

  package main;

  use Venus 'is_regexp';

  my $is_regexp = is_regexp qr/hello/;

  # true

=cut

$test->for('example', 1, 'is_regexp', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_regexp

  # given: synopsis

  package main;

  use Venus 'is_regexp';

  my $is_regexp = is_regexp 'hello';

  # false

=cut

$test->for('example', 2, 'is_regexp', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_scalarref

The is_scalarref function uses L</check> to validate that the data provided is
a scalarref returns true, otherwise returns false.

=signature is_scalarref

  is_scalarref(any $data) (boolean)

=metadata is_scalarref

{
  since => '4.15',
}

=cut

=example-1 is_scalarref

  # given: synopsis

  package main;

  use Venus 'is_scalarref';

  my $is_scalarref = is_scalarref \1;

  # true

=cut

$test->for('example', 1, 'is_scalarref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_scalarref

  # given: synopsis

  package main;

  use Venus 'is_scalarref';

  my $is_scalarref = is_scalarref 1;

  # false

=cut

$test->for('example', 2, 'is_scalarref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_string

The is_string function uses L</check> to validate that the data provided is a
string returns true, otherwise returns false.

=signature is_string

  is_string(any $data) (boolean)

=metadata is_string

{
  since => '4.15',
}

=cut

=example-1 is_string

  # given: synopsis

  package main;

  use Venus 'is_string';

  my $is_string = is_string '0';

  # true

=cut

$test->for('example', 1, 'is_string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_string

  # given: synopsis

  package main;

  use Venus 'is_string';

  my $is_string = is_string 0;

  # false

=cut

$test->for('example', 2, 'is_string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_true

The is_true function accepts a scalar value and returns true if the value is
truthy. This function can dispatch method calls and execute callbacks.

=signature is_true

  is_true(any $data, string | coderef $code, any @args) (boolean)

=metadata is_true

{
  since => '3.04',
}

=cut

=example-1 is_true

  package main;

  use Venus 'is_true';

  my $is_true = is_true 1;

  # true

=cut

$test->for('example', 1, 'is_true', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-2 is_true

  package main;

  use Venus 'is_true';

  my $is_true = is_true 0;

  # false

=cut

$test->for('example', 2, 'is_true', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-3 is_true

  package main;

  use Venus 'array', 'is_true';

  my $array = array [];

  my $is_true = is_true $array;

  # true

=cut

$test->for('example', 3, 'is_true', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-4 is_true

  package main;

  use Venus 'array', 'is_true';

  my $array = array [];

  my $is_true = is_true $array, 'count';

  # false

=cut

$test->for('example', 4, 'is_true', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-5 is_true

  package main;

  use Venus 'array', 'is_true';

  my $array = array [1];

  my $is_true = is_true $array, 'count';

  # true

=cut

$test->for('example', 5, 'is_true', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-6 is_true

  package main;

  use Venus 'is_true';

  my $array = undef;

  my $is_true = is_true $array, 'count';

  # false

=cut

$test->for('example', 6, 'is_true', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=function is_undef

The is_undef function uses L</check> to validate that the data provided is an
undef returns true, otherwise returns false.

=signature is_undef

  is_undef(any $data) (boolean)

=metadata is_undef

{
  since => '4.15',
}

=cut

=example-1 is_undef

  # given: synopsis

  package main;

  use Venus 'is_undef';

  my $is_undef = is_undef undef;

  # true

=cut

$test->for('example', 1, 'is_undef', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_undef

  # given: synopsis

  package main;

  use Venus 'is_undef';

  my $is_undef = is_undef '';

  # false

=cut

$test->for('example', 2, 'is_undef', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_value

The is_value function uses L</check> to validate that the data provided is an
value returns true, otherwise returns false.

=signature is_value

  is_value(any $data) (boolean)

=metadata is_value

{
  since => '4.15',
}

=cut

=example-1 is_value

  # given: synopsis

  package main;

  use Venus 'is_value';

  my $is_value = is_value 0;

  # true

=cut

$test->for('example', 1, 'is_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_value

  # given: synopsis

  package main;

  use Venus 'is_value';

  my $is_value = is_value sub{};

  # false

=cut

$test->for('example', 2, 'is_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function is_yesno

The is_yesno function uses L</check> to validate that the data provided is a
yesno returns true, otherwise returns false.

=signature is_yesno

  is_yesno(any $data) (boolean)

=metadata is_yesno

{
  since => '4.15',
}

=cut

=example-1 is_yesno

  # given: synopsis

  package main;

  use Venus 'is_yesno';

  my $is_yesno = is_yesno 0;

  # true

=cut

$test->for('example', 1, 'is_yesno', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 is_yesno

  # given: synopsis

  package main;

  use Venus 'is_yesno';

  my $is_yesno = is_yesno undef;

  # false

=cut

$test->for('example', 2, 'is_yesno', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function json

The json function builds a L<Venus::Json> object and will either
L<Venus::Json/decode> or L<Venus::Json/encode> based on the argument provided
and returns the result.

=signature json

  json(string $call, any $data) (any)

=metadata json

{
  since => '2.40',
}

=cut

=example-1 json

  package main;

  use Venus 'json';

  my $decode = json 'decode', '{"codename":["Ready","Robot"],"stable":true}';

  # { codename => ["Ready", "Robot"], stable => 1 }

=cut

$test->for('example', 1, 'json', sub {
  if (require Venus::Json && not Venus::Json->package) {
    plan skip_all => 'No suitable JSON library found';
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, { codename => ["Ready", "Robot"], stable => 1 };

  $result
});

=example-2 json

  package main;

  use Venus 'json';

  my $encode = json 'encode', { codename => ["Ready", "Robot"], stable => true };

  # '{"codename":["Ready","Robot"],"stable":true}'

=cut

$test->for('example', 2, 'json', sub {
  if (require Venus::Json && not Venus::Json->package) {
    plan skip_all => 'No suitable JSON library found';
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->result;
  $result =~ s/[\s\n]+//g;
  is_deeply $result, '{"codename":["Ready","Robot"],"stable":true}';

  $result
});

=example-3 json

  package main;

  use Venus 'json';

  my $json = json;

  # bless({...}, 'Venus::Json')

=cut

$test->for('example', 3, 'json', sub {
  if (require Venus::Json && not Venus::Json->package) {
    plan skip_all => 'No suitable JSON library found';
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Json';

  $result
});

=example-4 json

  package main;

  use Venus 'json';

  my $json = json 'class', {data => "..."};

  # Exception! (isa Venus::Fault)

=cut

$test->for('example', 4, 'json', sub {
  if (require Venus::Json && not Venus::Json->package) {
    plan skip_all => 'No suitable JSON library found';
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->catch('Venus::Fault')->result;
  isa_ok $result, 'Venus::Fault';
  like $result, qr/Invalid "json" action "class"/;

  $result
});

=function kvargs

The kvargs function takes a list of arguments and returns a hashref. If a
single hashref is provided, it is returned as-is. Otherwise, the arguments are
treated as key-value pairs. If an odd number of arguments is provided, the last
key will have C<undef> as its value.

=signature kvargs

  kvargs(any @args) (hashref)

=metadata kvargs

{
  since => '5.00',
}

=cut

=example-1 kvargs

  package main;

  use Venus 'kvargs';

  my $kvargs = kvargs {name => 'Elliot'};

  # {name => 'Elliot'}

=cut

$test->for('example', 1, 'kvargs', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {name => 'Elliot'};

  $result
});

=example-2 kvargs

  package main;

  use Venus 'kvargs';

  my $kvargs = kvargs name => 'Elliot', role => 'hacker';

  # {name => 'Elliot', role => 'hacker'}

=cut

$test->for('example', 2, 'kvargs', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {name => 'Elliot', role => 'hacker'};

  $result
});

=example-3 kvargs

  package main;

  use Venus 'kvargs';

  my $kvargs = kvargs name => 'Elliot', 'role';

  # {name => 'Elliot', role => undef}

=cut

$test->for('example', 3, 'kvargs', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {name => 'Elliot', role => undef};

  $result
});

=example-4 kvargs

  package main;

  use Venus 'kvargs';

  my $kvargs = kvargs;

  # {}

=cut

$test->for('example', 4, 'kvargs', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=function list

The list function accepts a list of values and flattens any arrayrefs,
returning a list of scalars.

=signature list

  list(any @args) (any)

=metadata list

{
  since => '3.04',
}

=cut

=example-1 list

  package main;

  use Venus 'list';

  my @list = list 1..4;

  # (1..4)

=cut

$test->for('example', 1, 'list', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [1..4];

  @result
});

=example-2 list

  package main;

  use Venus 'list';

  my @list = list [1..4];

  # (1..4)

=cut

$test->for('example', 2, 'list', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [1..4];

  @result
});

=example-3 list

  package main;

  use Venus 'list';

  my @list = list [1..4], 5, [6..10];

  # (1..10)

=cut

$test->for('example', 3, 'list', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [1..10];

  @result
});

=function load

The load function loads the package provided and returns a L<Venus::Space> object.

=signature load

  load(any $name) (Venus::Space)

=metadata load

{
  since => '2.32',
}

=example-1 load

  package main;

  use Venus 'load';

  my $space = load 'Venus::Scalar';

  # bless({value => 'Venus::Scalar'}, 'Venus::Space')

=cut

$test->for('example', 1, 'load', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Space');
  is_deeply $result->value, 'Venus::Scalar';

  $result
});

=function log

The log function prints the arguments provided to STDOUT, stringifying complex
values, and returns a L<Venus::Log> object. If the first argument is a log
level name, e.g. C<debug>, C<error>, C<fatal>, C<info>, C<trace>, or C<warn>,
it will be used when emitting the event. The desired log level is specified by
the C<VENUS_LOG_LEVEL> environment variable and defaults to C<trace>.

=signature log

  log(any @args) (Venus::Log)

=metadata log

{
  since => '2.40',
}

=cut

=example-1 log

  package main;

  use Venus 'log';

  my $log = log;

  # bless({...}, 'Venus::Log')

  # log time, rand, 1..9;

  # 00000000 0.000000, 1..9

=cut

$test->for('example', 1, 'log', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Log';

  $result
});

=function make

The make function L<"calls"|Venus/call> the C<new> routine on the invocant and
returns the result which should be a package string or an object.

=signature make

  make(string $package, any @args) (any)

=metadata make

{
  since => '2.32',
}

=example-1 make

  package main;

  use Venus 'make';

  my $made = make('Digest::SHA');

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=cut

$test->for('example', 1, 'make', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Digest::SHA');

  $result
});

=example-2 make

  package main;

  use Venus 'make';

  my $made = make('Digest', 'SHA');

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=cut

$test->for('example', 2, 'make', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Digest::SHA');

  $result
});

=function map

The map function returns a L<Venus::Map> object for the hashref provided.

=signature map

  map(hashref $value) (Venus::Map)

=metadata map

{
  since => '4.15',
}

=example-1 map

  package main;

  use Venus;

  my $map = Venus::map {1..4};

  # bless(..., 'Venus::Map')

=cut

$test->for('example', 1, 'map', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Map');
  is_deeply $result->get, {1..4};

  $result
});

=example-2 map

  package main;

  use Venus;

  my $map = Venus::map {1..4}, 'count';

  # 2

=cut

$test->for('example', 2, 'map', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=function match

The match function builds a L<Venus::Match> object, passing it and the value
provided to the callback provided, and returns the return value from
L<Venus::Match/result>.

=signature match

  match(any $value, coderef $callback) (any)

=metadata match

{
  since => '2.50',
}

=cut

=example-1 match

  package main;

  use Venus 'match';

  my $match = match 5;

  # bless({...}, 'Venus::Match')

  # $match->result;

  # undef

=cut

$test->for('example', 1, 'match', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Match';

  $result
});

=example-2 match

  package main;

  use Venus 'match';

  my $match = match 5, sub {{
    1 => 'one',
    2 => 'two',
    5 => 'five',
  }};

  # 'five'

=cut

$test->for('example', 2, 'match', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 'five';

  $result
});

=example-3 match

  package main;

  use Venus 'match';

  my $match = match 5, sub {{
    1 => 'one',
    2 => 'two',
    3 => 'three',
  }};

  # undef

=cut

$test->for('example', 3, 'match', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-4 match

  package main;

  use Venus 'match';

  my $match = match 5, sub {
    my ($case) = @_;

    $case->when(sub{$_ < 5})->then('< 5');
    $case->when(sub{$_ > 5})->then('> 5');
  };

  # undef

=cut

$test->for('example', 4, 'match', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-5 match

  package main;

  use Venus 'match';

  my $match = match 6, sub {
    my ($case, $data) = @_;

    $case->when(sub{$_ < 5})->then("$data < 5");
    $case->when(sub{$_ > 5})->then("$data > 5");
  };

  # '6 > 5'

=cut

$test->for('example', 5, 'match', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, '6 > 5';

  $result
});

=example-6 match

  package main;

  use Venus 'match';

  my $match = match 4, sub {

    $_->when(sub{$_ < 5})->then("$_[1] < 5");
    $_->when(sub{$_ > 5})->then("$_[1] > 5");
  };

  # '4 < 5'

=cut

$test->for('example', 6, 'match', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, '4 < 5';

  $result
});

=function merge

The merge function returns a value which is a merger of all of the arguments
provided. This function is an alias for L</merge_join> given the principle of
least surprise.

=signature merge

  merge(any @args) (any)

=metadata merge

{
  since => '2.32',
}

=example-1 merge

  package main;

  use Venus 'merge';

  my $merged = merge({1..4}, {5, 6});

  # {1..6}

=cut

$test->for('example', 1, 'merge', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {1..6};

  $result
});

=example-2 merge

  package main;

  use Venus 'merge';

  my $merged = merge({1..4}, {5, 6}, {7, 8, 9, 0});

  # {1..9, 0}

=cut

$test->for('example', 2, 'merge', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, {1..9,0};

  $result
});

=function merge_flat

The merge_flat function merges two (or more) values and returns a new values
based on the types of the inputs:

B<Note:> This function appends hashref values to an arrayref when encountered.

+=over 4

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
append the C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we append the items in C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
append the values in C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, overwriting existing
keys where there's overlap.

+=back

=signature merge_flat

  merge_flat(any @args) (any)

=metadata merge_flat

{
  since => '4.15',
}

=cut

=example-1 merge_flat

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat;

  # undef

=cut

$test->for('example', 1, 'merge_flat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_flat

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat 1;

  # 1

=cut

$test->for('example', 2, 'merge_flat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_flat

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat 1, 2;

  # 2

=cut

$test->for('example', 3, 'merge_flat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-4 merge_flat

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat 1, [2, 3];

  # [2, 3]

=cut

$test->for('example', 4, 'merge_flat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2, 3];

  $result
});

=example-5 merge_flat

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat 1, {a => 1};

  # {a => 1}

=cut

$test->for('example', 5, 'merge_flat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 1};

  $result
});

=example-6 merge_flat

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat [1, 2], 3;

  # [1, 2, 3]

=cut

$test->for('example', 6, 'merge_flat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=example-7 merge_flat

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat [1, 2], {a => 3, b => 4};

  # [1, 2, 3, 4]

=cut

$test->for('example', 7, 'merge_flat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply [sort @$result], [1, 2, 3, 4];

  $result
});

=example-8 merge_flat

  # given: synopsis

  package main;

  use Venus 'merge_flat';

  my $merge_flat = merge_flat(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 20,
  #     z => 456
  #   },
  #   c => {z => 123},
  #   d => 2,
  #   e => [5, 6, 7],
  #   f => [6, 8],
  #   g => [4, 5],
  # }

=cut

$test->for('example', 8, 'merge_flat', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    a => 1,
    b => {
      x => 10,
      y => 20,
      z => 456
    },
    c => {z => 123},
    d => 2,
    e => [5, 6, 7],
    f => [6, 8],
    g => [4, 5],
  };

  is_deeply(merge_flat(10, 20), 20);
  is_deeply(merge_flat(10, [1, 2]), [1, 2]);
  is_deeply(merge_flat(10, {a => 1}), {a => 1});
  is_deeply(merge_flat([1, 2], 3), [1, 2, 3]);
  is_deeply(merge_flat([1, 2], [3, 4]), [1, 2, 3, 4]);
  is_deeply([sort(@{merge_flat([1, 2], {a => 3, b => 4})})], [1, 2, 3, 4]);
  is_deeply(merge_flat({a => 1, b => 2}, 10), 10);
  is_deeply(merge_flat({a => 1, b => 2}, [3, 4]), [3, 4]);
  is_deeply(merge_flat({a => 1, b => 2}, {b => 3, c => 4}), {a => 1, b => 3, c => 4});

  $result
});

=function merge_flat_mutate

The merge_flat_mutate performs a merge operaiton in accordance with
L</merge_flat> except that it mutates the values being merged and returns the
mutated value.

=signature merge_flat_mutate

  merge_flat_mutate(any @args) (any)

=metadata merge_flat_mutate

{
  since => '4.15',
}

=cut

=example-1 merge_flat_mutate

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  my $merge_flat_mutate = merge_flat_mutate;

  # undef

=cut

$test->for('example', 1, 'merge_flat_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_flat_mutate

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  my $merge_flat_mutate = merge_flat_mutate 1;

  # 1

=cut

$test->for('example', 2, 'merge_flat_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_flat_mutate

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = 1;

  my $merge_flat_mutate = merge_flat_mutate $result, 2;

  # 2

  $result;

  # 2

=cut

$test->for('example', 3, 'merge_flat_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-4 merge_flat_mutate

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = 1;

  my $merge_flat_mutate = merge_flat_mutate $result, [2, 3];

  # [2, 3]

  $result;

  # [2, 3]

=cut

$test->for('example', 4, 'merge_flat_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2, 3];

  $result
});

=example-5 merge_flat_mutate

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = 1;

  my $merge_flat_mutate = merge_flat_mutate $result, {a => 1};

  # {a => 1}

  $result;

  # {a => 1}

=cut

$test->for('example', 5, 'merge_flat_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 1};

  $result
});

=example-6 merge_flat_mutate

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = [1, 2];

  my $merge_flat_mutate = merge_flat_mutate $result, 3;

  # [1, 2, 3]

  $result;

  # [1, 2, 3]

=cut

$test->for('example', 6, 'merge_flat_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=example-7 merge_flat_mutate

  # given: synopsis

  package main;

  use Venus 'merge_flat_mutate';

  $result = [1, 2];

  my $merge_flat_mutate = merge_flat_mutate $result, {a => 3, b => 4};

  # [1, 2, 3, 4]

  $result;

  # [1, 2, 3, 4]

=cut

$test->for('example', 7, 'merge_flat_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply [sort @$result], [1, 2, 3, 4];

  $result = 10;
  merge_flat_mutate($result, 20);
  is_deeply($result, 20);

  $result = 10;
  merge_flat_mutate($result, [1, 2]);
  is_deeply($result, [1, 2]);

  $result = 10;
  merge_flat_mutate($result, {a => 1});
  is_deeply($result, {a => 1});

  $result = [1, 2];
  merge_flat_mutate($result, 3);
  is_deeply($result, [1, 2, 3]);

  $result = [1, 2];
  merge_flat_mutate($result, [3, 4]);
  is_deeply($result, [1, 2, 3, 4]);

  $result = [1, 2];
  merge_flat_mutate($result, {a => 3, b => 4});
  is_deeply([sort(@{$result})], [1, 2, 3, 4]);

  $result = {a => 1, b => 2};
  merge_flat_mutate($result, 10);
  is_deeply($result, 10);

  $result = {a => 1, b => 2};
  merge_flat_mutate($result, [3, 4]);
  is_deeply($result, [3, 4]);

  $result = {a => 1, b => 2};
  merge_flat_mutate($result, {b => 3, c => 4});
  is_deeply($result, {a => 1, b => 3, c => 4});

  $result
});

=function merge_join

The merge_join merges two (or more) values and returns a new values based on
the types of the inputs:

B<Note:> This function merges hashrefs with hashrefs, and appends arrayrefs
with arrayrefs.

+=over 4

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
append the C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we append the items in C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
append the C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, overwriting existing
keys where there's overlap.

+=back

=signature merge_join

  merge_join(any @args) (any)

=metadata merge_join

{
  since => '4.15',
}

=cut

=example-1 merge_join

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join;

  # undef

=cut

$test->for('example', 1, 'merge_join', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_join

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join 1;

  # 1

=cut

$test->for('example', 2, 'merge_join', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_join

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join 1, 2;

  # 2

=cut

$test->for('example', 3, 'merge_join', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-4 merge_join

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join 1, [2, 3];

  # [2, 3]

=cut

$test->for('example', 4, 'merge_join', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2, 3];

  $result
});

=example-5 merge_join

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join [1, 2], 3;

  # [1, 2, 3]

=cut

$test->for('example', 5, 'merge_join', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=example-6 merge_join

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join [1, 2], [3, 4];

  # [1, 2, 3, 4]

=cut

$test->for('example', 6, 'merge_join', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3, 4];

  $result
});

=example-7 merge_join

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join {a => 1}, {a => 2, b => 3};

  # {a => 2, b => 3}

=cut

$test->for('example', 7, 'merge_join', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 2, b => 3};

  $result
});

=example-8 merge_join

  # given: synopsis

  package main;

  use Venus 'merge_join';

  my $merge_join = merge_join(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 20,
  #     z => 456
  #   },
  #   c => {z => 123},
  #   d => 2,
  #   e => [5, 6, 7],
  #   f => [6, {7, 8}],
  #   g => [4, 5],
  # }

=cut

$test->for('example', 8, 'merge_join', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    a => 1,
    b => {
      x => 10,
      y => 20,
      z => 456
    },
    c => {z => 123},
    d => 2,
    e => [5, 6, 7],
    f => [6, {7, 8}],
    g => [4, 5],
  };

  is_deeply(merge_join(10, 20), 20);
  is_deeply(merge_join(10, [1, 2]), [1, 2]);
  is_deeply(merge_join(10, {a=>1}), {a=>1});
  is_deeply(merge_join([1, 2], 3), [1, 2, 3]);
  is_deeply(merge_join([1, 2], [3, 4]), [1, 2, 3, 4]);
  is_deeply(merge_join([1, 2], {a=>3, b=>4}), [1, 2, {a=>3, b=>4}]);
  is_deeply(merge_join({a=>1, b=>2}, 10), 10);
  is_deeply(merge_join({a=>1, b=>2}, [3, 4]), [3, 4]);
  is_deeply(merge_join({a=>1, b=>2}, {b=>3, c=>4}), {a=>1, b=>3, c=>4});

  $result
});

=function merge_join_mutate

The merge_join_mutate performs a merge operaiton in accordance with
L</merge_join> except that it mutates the values being merged and returns the
mutated value.

=signature merge_join_mutate

  merge_join_mutate(any @args) (any)

=metadata merge_join_mutate

{
  since => '4.15',
}

=cut

=example-1 merge_join_mutate

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  my $merge_join_mutate = merge_join_mutate;

  # undef

=cut

$test->for('example', 1, 'merge_join_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_join_mutate

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  my $merge_join_mutate = merge_join_mutate 1;

  # 1

=cut

$test->for('example', 2, 'merge_join_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_join_mutate

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = 1;

  my $merge_join_mutate = merge_join_mutate $result, 2;

  # 2

  $result;

  # 2

=cut

$test->for('example', 3, 'merge_join_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-4 merge_join_mutate

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = 1;

  my $merge_join_mutate = merge_join_mutate $result, [2, 3];

  # [2, 3]

  $result;

  # [2, 3]

=cut

$test->for('example', 4, 'merge_join_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2, 3];

  $result
});

=example-5 merge_join_mutate

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = [1, 2];

  my $merge_join_mutate = merge_join_mutate $result, 3;

  # [1, 2, 3]

  $result;

  # [1, 2, 3]

=cut

$test->for('example', 5, 'merge_join_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=example-6 merge_join_mutate

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = [1, 2];

  my $merge_join_mutate = merge_join_mutate $result, [3, 4];

  # [1, 2, 3, 4]

  $result;

  # [1, 2, 3, 4]

=cut

$test->for('example', 6, 'merge_join_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3, 4];

  $result
});

=example-7 merge_join_mutate

  # given: synopsis

  package main;

  use Venus 'merge_join_mutate';

  $result = {a => 1};

  my $merge_join_mutate = merge_join_mutate $result, {a => 2, b => 3};

  # {a => 2, b => 3}

  $result;

  # {a => 2, b => 3}

=cut

$test->for('example', 7, 'merge_join_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 2, b => 3};

  $result = 10;
  merge_join_mutate($result, 20);
  is_deeply($result, 20);

  $result = 10;
  merge_join_mutate($result, [1, 2]);
  is_deeply($result, [1, 2]);

  $result = 10;
  merge_join_mutate($result, {a=>1});
  is_deeply($result, {a=>1});

  $result = [1, 2];
  merge_join_mutate($result, 3);
  is_deeply($result, [1, 2, 3]);

  $result = [1, 2];
  merge_join_mutate($result, [3, 4]);
  is_deeply($result, [1, 2, 3, 4]);

  $result = [1, 2];
  merge_join_mutate($result, {a=>3, b=>4});
  is_deeply($result, [1, 2, {a=>3, b=>4}]);

  $result = {a=>1, b=>2};
  merge_join_mutate($result, 10);
  is_deeply($result, 10);

  $result = {a=>1, b=>2};
  merge_join_mutate($result, [3, 4]);
  is_deeply($result, [3, 4]);

  $result = {a=>1, b=>2};
  merge_join_mutate($result, {b=>3, c=>4});
  is_deeply($result, {a=>1, b=>3, c=>4});

  $result
});

=function merge_keep

The merge_keep function merges two (or more) values and returns a new values
based on the types of the inputs:

B<Note:> This function retains the existing data, appends arrayrefs with
arrayrefs, and only merges new keys and values when merging hashrefs with
hashrefs.

+=over 4

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<lvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<lvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<lvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
append the C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we append the items in C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
append the C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<lvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<lvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, but without
overwriting existing keys if there's overlap.

+=back

=signature merge_keep

  merge_keep(any @args) (any)

=metadata merge_keep

{
  since => '4.15',
}

=cut

=example-1 merge_keep

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep;

  # undef

=cut

$test->for('example', 1, 'merge_keep', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_keep

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep 1;

  # 1

=cut

$test->for('example', 2, 'merge_keep', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_keep

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep 1, 2;

  # 1

=cut

$test->for('example', 3, 'merge_keep', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-4 merge_keep

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep 1, [2, 3];

  # 1

=cut

$test->for('example', 4, 'merge_keep', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-5 merge_keep

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep [1, 2], 3;

  # [1, 2, 3]

=cut

$test->for('example', 5, 'merge_keep', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=example-6 merge_keep

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep [1, 2], [3, 4];

  # [1, 2, 3, 4]

=cut

$test->for('example', 6, 'merge_keep', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3, 4];

  $result
});

=example-7 merge_keep

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep {a => 1}, {a => 2, b => 3};

  # {a => 1, b => 3}

=cut

$test->for('example', 7, 'merge_keep', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 1, b => 3};

  $result
});

=example-8 merge_keep

  # given: synopsis

  package main;

  use Venus 'merge_keep';

  my $merge_keep = merge_keep(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {y => 30, z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 20,
  #     z => 456
  #   },
  #   c => 3,
  #   d => 0,
  #   e => [5, 6, 7],
  #   f => [6, {7, 8}],
  #   g => [4, 5],
  # }

=cut

$test->for('example', 8, 'merge_keep', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    a => 1,
    b => {
      x => 10,
      y => 20,
      z => 456
    },
    c => 3,
    d => 0,
    e => [5, 6, 7],
    f => [6, {7, 8}],
    g => [4, 5],
  };

  is_deeply(merge_keep(10, 20), 10);
  is_deeply(merge_keep(10, [1, 2]), 10);
  is_deeply(merge_keep(10, {a=>1}), 10);
  is_deeply(merge_keep([1, 2], 3), [1, 2, 3]);
  is_deeply(merge_keep([1, 2], [3, 4]), [1, 2, 3, 4]);
  is_deeply(merge_keep([1, 2], {a=>3, b=>4}), [1, 2, {a=>3, b=>4}]);
  is_deeply(merge_keep({a=>1, b=>2}, 10), {a=>1, b=>2});
  is_deeply(merge_keep({a=>1, b=>2}, [3, 4]), {a=>1, b=>2});
  is_deeply(merge_keep({a=>1, b=>2}, {b=>3, c=>4}), {a=>1, b=>2, c=>4});

  $result
});

=function merge_keep_mutate

The merge_keep_mutate performs a merge operaiton in accordance with
L</merge_keep> except that it mutates the values being merged and returns the
mutated value.

=signature merge_keep_mutate

  merge_keep_mutate(any @args) (any)

=metadata merge_keep_mutate

{
  since => '4.15',
}

=cut

=example-1 merge_keep_mutate

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  my $merge_keep_mutate = merge_keep_mutate;

  # undef

=cut

$test->for('example', 1, 'merge_keep_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_keep_mutate

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  my $merge_keep_mutate = merge_keep_mutate 1;

  # 1

=cut

$test->for('example', 2, 'merge_keep_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_keep_mutate

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = 1;

  my $merge_keep_mutate = merge_keep_mutate $result, 2;

  # 1

  $result;

  # 1

=cut

$test->for('example', 3, 'merge_keep_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-4 merge_keep_mutate

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = 1;

  my $merge_keep_mutate = merge_keep_mutate $result, [2, 3];

  # 1

  $result;

  # 1

=cut

$test->for('example', 4, 'merge_keep_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-5 merge_keep_mutate

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = [1, 2];

  my $merge_keep_mutate = merge_keep_mutate $result, 3;

  # [1, 2, 3]

  $result;

  # [1, 2, 3]

=cut

$test->for('example', 5, 'merge_keep_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=example-6 merge_keep_mutate

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = [1, 2];

  my $merge_keep_mutate = merge_keep_mutate $result, [3, 4];

  # [1, 2, 3, 4]

  $result;

  # [1, 2, 3, 4]

=cut

$test->for('example', 6, 'merge_keep_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3, 4];

  $result
});

=example-7 merge_keep_mutate

  # given: synopsis

  package main;

  use Venus 'merge_keep_mutate';

  $result = {a => 1};

  my $merge_keep_mutate = merge_keep_mutate $result, {a => 2, b => 3};

  # {a => 1, b => 3}

  $result;

  # {a => 1, b => 3}

=cut

$test->for('example', 7, 'merge_keep_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 1, b => 3};

  $result = 10;
  merge_keep_mutate($result, 20);
  is_deeply($result, 10);

  $result = 10;
  merge_keep_mutate($result, [1, 2]);
  is_deeply($result, 10);

  $result = 10;
  merge_keep_mutate($result, {a=>1});
  is_deeply($result, 10);

  $result = [1, 2];
  merge_keep_mutate($result, 3);
  is_deeply($result, [1, 2, 3]);

  $result = [1, 2];
  merge_keep_mutate($result, [3, 4]);
  is_deeply($result, [1, 2, 3, 4]);

  $result = [1, 2];
  merge_keep_mutate($result, {a=>3, b=>4});
  is_deeply($result, [1, 2, {a=>3, b=>4}]);

  $result = {a=>1, b=>2};
  merge_keep_mutate($result, 10);
  is_deeply($result, {a=>1, b=>2});

  $result = {a=>1, b=>2};
  merge_keep_mutate($result, [3, 4]);
  is_deeply($result, {a=>1, b=>2});

  $result = {a=>1, b=>2};
  merge_keep_mutate($result, {b=>3, c=>4});
  is_deeply($result, {a=>1, b=>2, c=>4});

  $result
});

=function merge_swap

The merge_swap function merges two (or more) values and returns a new values
based on the types of the inputs:

B<Note:> This function replaces the existing data, including when merging
hashrefs with hashrefs, and overwrites values (instead of appending) when
merging arrayrefs with arrayrefs.

+=over 4

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
append the C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we replace each items in C<lvalue> with the value at the corresponding position
in the C<rvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
append the C<rvalue> to the C<lvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, overwriting existing
keys if there's overlap.

+=back

=signature merge_swap

  merge_swap(any @args) (any)

=metadata merge_swap

{
  since => '4.15',
}

=cut

=example-1 merge_swap

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap;

  # undef

=cut

$test->for('example', 1, 'merge_swap', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_swap

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap 1;

  # 1

=cut

$test->for('example', 2, 'merge_swap', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_swap

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap 1, 2;

  # 2

=cut

$test->for('example', 3, 'merge_swap', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-4 merge_swap

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap 1, [2, 3];

  # [2, 3]

=cut

$test->for('example', 4, 'merge_swap', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2, 3];

  $result
});

=example-5 merge_swap

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap [1, 2], 3;

  # [1, 2, 3]

=cut

$test->for('example', 5, 'merge_swap', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=example-6 merge_swap

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap [1, 2, 3], [4, 5];

  # [4, 5, 3]

=cut

$test->for('example', 6, 'merge_swap', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [4, 5, 3];

  $result
});

=example-7 merge_swap

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap {a => 1}, {a => 2, b => 3};

  # {a => 2, b => 3}

=cut

$test->for('example', 7, 'merge_swap', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 2, b => 3};

  $result
});

=example-8 merge_swap

  # given: synopsis

  package main;

  use Venus 'merge_swap';

  my $merge_swap = merge_swap(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {y => 30, z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 30,
  #     z => 456
  #   },
  #   c => {z => 123},
  #   d => 2,
  #   e => [6, 7],
  #   f => [6, {7, 8}],
  #   g => [4, 5],
  # }

=cut

$test->for('example', 8, 'merge_swap', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    a => 1,
    b => {
      x => 10,
      y => 30,
      z => 456
    },
    c => {z => 123},
    d => 2,
    e => [6, 7],
    f => [6, {7, 8}],
    g => [4, 5],
  };

  is_deeply(merge_swap(10, 20), 20);
  is_deeply(merge_swap(10, [1, 2]), [1, 2]);
  is_deeply(merge_swap(10, {a=>1}), {a=>1});
  is_deeply(merge_swap([1, 2], 3), [1, 2, 3]);
  is_deeply(merge_swap([1, 2], [3, 4]), [3, 4]);
  is_deeply(merge_swap([1, 2], {a=>3, b=>4}), [1, 2, {a=>3, b=>4}]);
  is_deeply(merge_swap({a=>1, b=>2}, 10), 10);
  is_deeply(merge_swap({a=>1, b=>2}, [3, 4]), [3, 4]);
  is_deeply(merge_swap({a=>1, b=>2}, {b=>3, c=>4}), {a=>1, b=>3, c=>4});

  $result
});

=function merge_swap_mutate

The merge_swap_mutate performs a merge operaiton in accordance with
L</merge_swap> except that it mutates the values being merged and returns the
mutated value.

=signature merge_swap_mutate

  merge_swap_mutate(any @args) (any)

=metadata merge_swap_mutate

{
  since => '4.15',
}

=cut

=example-1 merge_swap_mutate

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = undef;

  my $merge_swap_mutate = merge_swap_mutate $result;

  # undef

  $result;

  # undef

=cut

$test->for('example', 1, 'merge_swap_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_swap_mutate

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = 1;

  my $merge_swap_mutate = merge_swap_mutate $result;

  # 1

  $result;

  # 1

=cut

$test->for('example', 2, 'merge_swap_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_swap_mutate

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = 1;

  my $merge_swap_mutate = merge_swap_mutate $result, 2;

  # 2

  $result;

  # 2

=cut

$test->for('example', 3, 'merge_swap_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-4 merge_swap_mutate

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = 1;

  my $merge_swap_mutate = merge_swap_mutate $result, [2, 3];

  # [2, 3]

  $result;

  # [2, 3]

=cut

$test->for('example', 4, 'merge_swap_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2, 3];

  $result
});

=example-5 merge_swap_mutate

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = [1, 2];

  my $merge_swap_mutate = merge_swap_mutate $result, 3;

  # [1, 2, 3]

  $result;

  # [1, 2, 3]

=cut

$test->for('example', 5, 'merge_swap_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1, 2, 3];

  $result
});

=example-6 merge_swap_mutate

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = [1, 2, 3];

  my $merge_swap_mutate = merge_swap_mutate $result, [4, 5];

  # [4, 5, 3]

  $result;

  # [4, 5, 3]

=cut

$test->for('example', 6, 'merge_swap_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [4, 5, 3];

  $result
});

=example-7 merge_swap_mutate

  # given: synopsis

  package main;

  use Venus 'merge_swap_mutate';

  $result = {a => 1};

  my $merge_swap_mutate = merge_swap_mutate $result, {a => 2, b => 3};

  # {a => 2, b => 3}

  $result;

  # {a => 2, b => 3}

=cut

$test->for('example', 7, 'merge_swap_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 2, b => 3};

  $result = 10;
  merge_swap_mutate($result, 20);
  is_deeply($result, 20);

  $result = 10;
  merge_swap_mutate($result, [1, 2]);
  is_deeply($result, [1, 2]);

  $result = 10;
  merge_swap_mutate($result, {a=>1});
  is_deeply($result, {a=>1});

  $result = [1, 2];
  merge_swap_mutate($result, 3);
  is_deeply($result, [1, 2, 3]);

  $result = [1, 2];
  merge_swap_mutate($result, [3, 4]);
  is_deeply($result, [3, 4]);

  $result = [1, 2];
  merge_swap_mutate($result, {a=>3, b=>4});
  is_deeply($result, [1, 2, {a=>3, b=>4}]);

  $result = {a=>1, b=>2};
  merge_swap_mutate($result, 10);
  is_deeply($result, 10);

  $result = {a=>1, b=>2};
  merge_swap_mutate($result, [3, 4]);
  is_deeply($result, [3, 4]);

  $result = {a=>1, b=>2};
  merge_swap_mutate($result, {b=>3, c=>4});
  is_deeply($result, {a=>1, b=>3, c=>4});

  $result
});

=function merge_take

The merge_take function merges two (or more) values and returns a new values
based on the types of the inputs:

B<Note:> This function always "takes" the new value, does not append arrayrefs,
and overwrites keys and values when merging hashrefs with hashrefs.

+=over 4

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "scalar" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "arrayref"
we keep the C<rvalue>.

+=item * When the C<lvalue> is a "arrayref" and the C<rvalue> is a "hashref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "scalar" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "arrayref" we
keep the C<rvalue>.

+=item * When the C<lvalue> is a "hashref" and the C<rvalue> is a "hashref" we
append the keys and values in C<rvalue> to the C<lvalue>, overwriting existing
keys if there's overlap.

+=back

=signature merge_take

  merge_take(any @args) (any)

=metadata merge_take

{
  since => '4.15',
}

=cut

=example-1 merge_take

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take;

  # undef

=cut

$test->for('example', 1, 'merge_take', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_take

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take 1;

  # 1

=cut

$test->for('example', 2, 'merge_take', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_take

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take 1, 2;

  # 2

=cut

$test->for('example', 3, 'merge_take', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-4 merge_take

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take [1], [2, 3];

  # [2, 3]

=cut

$test->for('example', 4, 'merge_take', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2, 3];

  $result
});

=example-5 merge_take

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take {a => 1, b => {x => 10}}, {b => {y => 20}, c => 3};

  # {a => 1, b => {x => 10, y => 20}, c => 3}

=cut

$test->for('example', 5, 'merge_take', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 1, b => {x => 10, y => 20}, c => 3};

  $result
});

=example-6 merge_take

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take [1, 2], 3;

  # 3

=cut

$test->for('example', 6, 'merge_take', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 3;

  $result
});

=example-7 merge_take

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take {a => 1}, 2;

  # 2

=cut

$test->for('example', 7, 'merge_take', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-8 merge_take

  # given: synopsis

  package main;

  use Venus 'merge_take';

  my $merge_take = merge_take(
    {
      a => 1,
      b => {x => 10},
      d => 0,
      g => [4],
    },
    {
      b => {y => 20},
      c => 3,
      e => [5],
      f => [6]
    },
    {
      b => {y => 30, z => 456},
      c => {z => 123},
      d => 2,
      e => [6, 7],
      f => {7, 8},
      g => 5,
    },
  );

  # {
  #   a => 1,
  #   b => {
  #     x => 10,
  #     y => 30,
  #     z => 456
  #   },
  #   c => {z => 123},
  #   d => 2,
  #   e => [6, 7],
  #   f => {7, 8},
  #   g => 5,
  # }

=cut

$test->for('example', 8, 'merge_take', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    a => 1,
    b => {
      x => 10,
      y => 30,
      z => 456
    },
    c => {z => 123},
    d => 2,
    e => [6, 7],
    f => {7, 8},
    g => 5,
  };

  is_deeply(merge_take(10, 20), 20);
  is_deeply(merge_take(10, [1, 2]), [1, 2]);
  is_deeply(merge_take(10, {a=>1}), {a=>1});
  is_deeply(merge_take([1, 2], 3), 3);
  is_deeply(merge_take([1, 2], [3, 4]), [3, 4]);
  is_deeply(merge_take([1, 2], {a=>3, b=>4}), {a=>3, b=>4});
  is_deeply(merge_take({a=>1, b=>2}, 10), 10);
  is_deeply(merge_take({a=>1, b=>2}, [3, 4]), [3, 4]);
  is_deeply(merge_take({a=>1, b=>2}, {b=>3, c=>4}), {a=>1, b=>3, c=>4});

  $result
});

=function merge_take_mutate

The merge_take_mutate performs a merge operaiton in accordance with
L</merge_take> except that it mutates the values being merged and returns the
mutated value.

=signature merge_take_mutate

  merge_take_mutate(any @args) (any)

=metadata merge_take_mutate

{
  since => '4.15',
}

=cut

=example-1 merge_take_mutate

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = undef;

  my $merge_take_mutate = merge_take_mutate $result;

  # undef

  $result;

  # undef

=cut

$test->for('example', 1, 'merge_take_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-2 merge_take_mutate

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = 1;

  my $merge_take_mutate = merge_take_mutate $result;

  # 1

  $result;

  # 1

=cut

$test->for('example', 2, 'merge_take_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=example-3 merge_take_mutate

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = 1;

  my $merge_take_mutate = merge_take_mutate $result, 2;

  # 2

  $result;

  # 2

=cut

$test->for('example', 3, 'merge_take_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result
});

=example-4 merge_take_mutate

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = [1];

  my $merge_take_mutate = merge_take_mutate $result, [2, 3];

  # [2, 3]

  $result;

  # [2, 3]

=cut

$test->for('example', 4, 'merge_take_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [2, 3];

  $result
});

=example-5 merge_take_mutate

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = {a => 1, b => {x => 10}};

  my $merge_take_mutate = merge_take_mutate $result, {b => {y => 20}, c => 3};

  # {a => 1, b => {x => 10, y => 20}, c => 3}

  $result;

  # {a => 1, b => {x => 10, y => 20}, c => 3}

=cut

$test->for('example', 5, 'merge_take_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {a => 1, b => {x => 10, y => 20}, c => 3};

  $result
});

=example-6 merge_take_mutate

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = [1, 2];

  my $merge_take_mutate = merge_take_mutate $result, 3;

  # 3

  $result;

  # 3

=cut

$test->for('example', 6, 'merge_take_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 3;

  $result
});

=example-7 merge_take_mutate

  # given: synopsis

  package main;

  use Venus 'merge_take_mutate';

  $result = {a => 1};

  my $merge_take_mutate = merge_take_mutate $result, 2;

  # 2

  $result;

  # 2

=cut

$test->for('example', 7, 'merge_take_mutate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 2;

  $result = 10;
  merge_take_mutate($result, 20);
  is_deeply($result, 20);

  $result = 10;
  merge_take_mutate($result, [1, 2]);
  is_deeply($result, [1, 2]);

  $result = 10;
  merge_take_mutate($result, {a=>1});
  is_deeply($result, {a=>1});

  $result = [1, 2];
  merge_take_mutate($result, 3);
  is_deeply($result, 3);

  $result = [1, 2];
  merge_take_mutate($result, [3, 4]);
  is_deeply($result, [3, 4]);

  $result = [1, 2];
  merge_take_mutate($result, {a=>3, b=>4});
  is_deeply($result, {a=>3, b=>4});

  $result = {a=>1, b=>2};
  merge_take_mutate($result, 10);
  is_deeply($result, 10);

  $result = {a=>1, b=>2};
  merge_take_mutate($result, [3, 4]);
  is_deeply($result, [3, 4]);

  $result = {a=>1, b=>2};
  merge_take_mutate($result, {b=>3, c=>4});
  is_deeply($result, {a=>1, b=>3, c=>4});

  $result
});

=function meta

The meta function builds and returns a L<Venus::Meta> object, or dispatches to
the coderef or method provided.

=signature meta

  meta(string $value, string | coderef $code, any @args) (any)

=metadata meta

{
  since => '2.55',
}

=cut

=example-1 meta

  package main;

  use Venus 'meta';

  my $meta = meta 'Venus';

  # bless({...}, 'Venus::Meta')

=cut

$test->for('example', 1, 'meta', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Meta";
  is_deeply $result->{name}, 'Venus';

  $result
});

=example-2 meta

  package main;

  use Venus 'meta';

  my $result = meta 'Venus', 'sub', 'meta';

  # 1

=cut

$test->for('example', 2, 'meta', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=function name

The name function builds and returns a L<Venus::Name> object, or dispatches to
the coderef or method provided.

=signature name

  name(string $value, string | coderef $code, any @args) (any)

=metadata name

{
  since => '2.55',
}

=cut

=example-1 name

  package main;

  use Venus 'name';

  my $name = name 'Foo/Bar';

  # bless({...}, 'Venus::Name')

=cut

$test->for('example', 1, 'name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Name';
  is_deeply $result->package, 'Foo::Bar';

  $result
});

=example-2 name

  package main;

  use Venus 'name';

  my $name = name 'Foo/Bar', 'package';

  # "Foo::Bar"

=cut

$test->for('example', 2, 'name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 'Foo::Bar';

  $result
});

=function number

The number function builds and returns a L<Venus::Number> object, or dispatches
to the coderef or method provided.

=signature number

  number(Num $value, string | coderef $code, any @args) (any)

=metadata number

{
  since => '2.55',
}

=cut

=example-1 number

  package main;

  use Venus 'number';

  my $number = number 1_000;

  # bless({...}, 'Venus::Number')

=cut

$test->for('example', 1, 'number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Number';
  is_deeply $result->get, 1_000;

  $result
});

=example-2 number

  package main;

  use Venus 'number';

  my $number = number 1_000, 'prepend', 1;

  # 11_000

=cut

$test->for('example', 2, 'number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 11_000;

  $result
});

=function opts

The opts function builds and returns a L<Venus::Opts> object, or dispatches to
the coderef or method provided.

=signature opts

  opts(arrayref $value, string | coderef $code, any @args) (any)

=metadata opts

{
  since => '2.55',
}

=cut

=example-1 opts

  package main;

  use Venus 'opts';

  my $opts = opts ['--resource', 'users'];

  # bless({...}, 'Venus::Opts')

=cut

$test->for('example', 1, 'opts', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Opts';

  $result
});

=example-2 opts

  package main;

  use Venus 'opts';

  my $opts = opts ['--resource', 'users'], 'reparse', ['resource|r=s', 'help|h'];

  # bless({...}, 'Venus::Opts')

  # my $resource = $opts->get('resource');

  # "users"

=cut

$test->for('example', 2, 'opts', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Opts';
  is_deeply $result->get('resource'), "users";

  $result
});

=function pairs

The pairs function accepts an arrayref or hashref and returns an arrayref of
arrayrefs holding keys (or indices) and values. The function returns an empty
arrayref for all other values provided. Returns a list in list context.

=signature pairs

  pairs(any $data) (arrayref)

=metadata pairs

{
  since => '3.04',
}

=cut

=example-1 pairs

  package main;

  use Venus 'pairs';

  my $pairs = pairs [1..4];

  # [[0,1], [1,2], [2,3], [3,4]]

=cut

$test->for('example', 1, 'pairs', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [[0,1], [1,2], [2,3], [3,4]];

  $result
});

=example-2 pairs

  package main;

  use Venus 'pairs';

  my $pairs = pairs {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4};

  # [['a',1], ['b',2], ['c',3], ['d',4]]

=cut

$test->for('example', 2, 'pairs', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['a',1], ['b',2], ['c',3], ['d',4]];

  $result
});

=example-3 pairs

  package main;

  use Venus 'pairs';

  my @pairs = pairs [1..4];

  # ([0,1], [1,2], [2,3], [3,4])

=cut

$test->for('example', 3, 'pairs', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [[0,1], [1,2], [2,3], [3,4]];

  @result
});

=example-4 pairs

  package main;

  use Venus 'pairs';

  my @pairs = pairs {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4};

  # (['a',1], ['b',2], ['c',3], ['d',4])

=cut

$test->for('example', 4, 'pairs', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [['a',1], ['b',2], ['c',3], ['d',4]];

  @result
});

=function path

The path function builds and returns a L<Venus::Path> object, or dispatches
to the coderef or method provided.

=signature path

  path(string $value, string | coderef $code, any @args) (any)

=metadata path

{
  since => '2.55',
}

=cut

=example-1 path

  package main;

  use Venus 'path';

  my $path = path 't/data/planets';

  # bless({...}, 'Venus::Path')

=cut

$test->for('example', 1, 'path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Path';
  ok $result->get =~ m{t${fsds}data${fsds}planets};

  $result
});

=example-2 path

  package main;

  use Venus 'path';

  my $path = path 't/data/planets', 'absolute';

  # bless({...}, 'Venus::Path')

=cut

$test->for('example', 2, 'path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Path';
  ok $result->get =~ m{t${fsds}data${fsds}planets};

  $result
});

=function perl

The perl function builds a L<Venus::Dump> object and will either
L<Venus::Dump/decode> or L<Venus::Dump/encode> based on the argument provided
and returns the result.

=signature perl

  perl(string $call, any $data) (any)

=metadata perl

{
  since => '2.40',
}

=cut

=example-1 perl

  package main;

  use Venus 'perl';

  my $decode = perl 'decode', '{stable=>bless({},\'Venus::True\')}';

  # { stable => 1 }

=cut

$test->for('example', 1, 'perl', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, { stable => 1 };

  $result
});

=example-2 perl

  package main;

  use Venus 'perl';

  my $encode = perl 'encode', { stable => true };

  # '{stable=>bless({},\'Venus::True\')}'

=cut

$test->for('example', 2, 'perl', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  $result =~ s/[\s\n]+//g;
  is_deeply $result, '{stable=>bless({},\'Venus::True\')}';

  $result
});

=example-3 perl

  package main;

  use Venus 'perl';

  my $perl = perl;

  # bless({...}, 'Venus::Dump')

=cut

$test->for('example', 3, 'perl', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Dump';

  $result
});

=example-4 perl

  package main;

  use Venus 'perl';

  my $perl = perl 'class', {data => "..."};

  # Exception! (isa Venus::Fault)

=cut

$test->for('example', 4, 'perl', sub {
  my ($tryable) = @_;
  my $result = $tryable->catch('Venus::Fault')->result;
  isa_ok $result, 'Venus::Fault';
  like $result, qr/Invalid "perl" action "class"/;

  $result
});

=function process

The process function builds and returns a L<Venus::Process> object, or
dispatches to the coderef or method provided.

=signature process

  process(string | coderef $code, any @args) (any)

=metadata process

{
  since => '2.55',
}

=cut

=example-1 process

  package main;

  use Venus 'process';

  my $process = process;

  # bless({...}, 'Venus::Process')

=cut

$test->for('example', 1, 'process', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Process";

  $result
});

=example-2 process

  package main;

  use Venus 'process';

  my $process = process 'do', 'alarm', 10;

  # bless({...}, 'Venus::Process')

=cut

$test->for('example', 2, 'process', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Process";
  is_deeply $result->alarm, 10;

  $result
});

=function proto

The proto function builds and returns a L<Venus::Prototype> object, or
dispatches to the coderef or method provided.

=signature proto

  proto(hashref $value, string | coderef $code, any @args) (any)

=metadata proto

{
  since => '2.55',
}

=cut

=example-1 proto

  package main;

  use Venus 'proto';

  my $proto = proto {
    '$counter' => 0,
  };

  # bless({...}, 'Venus::Prototype')

=cut

$test->for('example', 1, 'proto', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Prototype';
  is_deeply $result->counter, 0;

  $result
});

=example-2 proto

  package main;

  use Venus 'proto';

  my $proto = proto { '$counter' => 0 }, 'apply', {
    '&decrement' => sub { $_[0]->counter($_[0]->counter - 1) },
    '&increment' => sub { $_[0]->counter($_[0]->counter + 1) },
  };

  # bless({...}, 'Venus::Prototype')

=cut

$test->for('example', 2, 'proto', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Prototype';
  is_deeply $result->counter, 0;
  is_deeply $result->increment, 1;
  is_deeply $result->decrement, 0;

  $result
});

=function puts

The puts function select values from within the underlying data structure using
L<Venus::Array/path> or L<Venus::Hash/path>, optionally assigning the value to
the preceeding scalar reference and returns all the values selected.

=signature puts

  puts(any @args) (arrayref)

=metadata puts

{
  since => '3.20',
}

=cut

=example-1 puts

  package main;

  use Venus 'puts';

  my $data = {
    size => "small",
    fruit => "apple",
    meta => {
      expiry => '5d',
    },
    color => "red",
  };

  puts $data, (
    \my $fruit, 'fruit',
    \my $expiry, 'meta.expiry'
  );

  my $puts = [$fruit, $expiry];

  # ["apple", "5d"]

=cut

$test->for('example', 1, 'puts', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ["apple", "5d"];

  $result
});

=function raise

The raise function generates and throws a named exception object derived from
L<Venus::Error>, or provided base class, using the exception object arguments
provided.

=signature raise

  raise(string $class | tuple[string, string] $class, any @args) (Venus::Error)

=metadata raise

{
  since => '0.01',
}

=example-1 raise

  package main;

  use Venus 'raise';

  my $error = raise 'MyApp::Error';

  # bless({...}, 'MyApp::Error')

=cut

$test->for('example', 1, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('MyApp::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Exception!';

  $result
});

=example-2 raise

  package main;

  use Venus 'raise';

  my $error = raise ['MyApp::Error', 'Venus::Error'];

  # bless({...}, 'MyApp::Error')

=cut

$test->for('example', 2, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('MyApp::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Exception!';

  $result
});

=example-3 raise

  package main;

  use Venus 'raise';

  my $error = raise ['MyApp::Error', 'Venus::Error'], {
    message => 'Something failed!',
  };

  # bless({message => 'Something failed!', ...}, 'MyApp::Error')

=cut

$test->for('example', 3, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('MyApp::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Something failed!';

  $result
});

=example-4 raise

  package main;

  use Venus 'raise';

  my $error = raise 'MyApp::Error', message => 'Something failed!';

  # bless({message => 'Something failed!', ...}, 'MyApp::Error')

=cut

$test->for('example', 4, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('MyApp::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Something failed!';

  $result
});

=example-5 raise

  package main;

  use Venus 'raise';

  my $error = raise 'MyApp::Error', name => 'on.issue',  message => 'Something failed!';

  # bless({message => 'Something failed!', ...}, 'MyApp::Error')

=cut

$test->for('example', 5, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('MyApp::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Something failed!';
  ok $error->of('on.issue');

  $result
});

=function random

The random function builds and returns a L<Venus::Random> object, or dispatches
to the coderef or method provided.

=signature random

  random(string | coderef $code, any @args) (any)

=metadata random

{
  since => '2.55',
}

=cut

=example-1 random

  package main;

  use Venus 'random';

  my $random = random;

  # bless({...}, 'Venus::Random')

=cut

$test->for('example', 1, 'random', sub {
  if (require Venus::Random && Venus::Random->new(42)->range(1, 50) != 38) {
    plan skip_all => "OS ($^O) rand function is undeterministic";
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Random";

  $result
});

=example-2 random

  package main;

  use Venus 'random';

  my $random = random 'collect', 10, 'letter';

  # "ryKUPbJHYT"

=cut

$test->for('example', 2, 'random', sub {
  if (require Venus::Random && Venus::Random->new(42)->range(1, 50) != 38) {
    plan skip_all => "OS ($^O) rand function is undeterministic";
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=function range

The range function returns the result of a L<Venus::Array/range> operation.

=signature range

  range(number | string @args) (arrayref)

=metadata range

{
  since => '3.20',
}

=cut

=example-1 range

  package main;

  use Venus 'range';

  my $range = range [1..9], ':4';

  # [1..5]

=cut

$test->for('example', 1, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..5];

  $result
});

=example-2 range

  package main;

  use Venus 'range';

  my $range = range [1..9], '-4:-1';

  # [6..9]

=cut

$test->for('example', 2, 'range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [6..9];

  $result
});

=function read_env

The read_env function returns a new L<Venus::Config> object based on the string
of key/value pairs provided.

=signature read_env

  read_env(string $data) (Venus::Config)

=metadata read_env

{
  since => '4.15',
}

=cut

=example-1 read_env

  package main;

  use Venus 'read_env';

  my $read_env = read_env "APPNAME=Example\nAPPVER=0.01\n# Comment\n\n\nAPPTAG=\"Godzilla\"";

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'read_env', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Config');
  my $value = $result->value;
  is_deeply $value, {
    APPNAME => "Example",
    APPTAG => "Godzilla",
    APPVER => 0.01,
  };

  $result
});

=function read_env_file

The read_env_file function uses L<Venus::Path> to return a new L<Venus::Config>
object based on the file provided.

=signature read_env_file

  read_env_file(string $file) (Venus::Config)

=metadata read_env_file

{
  since => '4.15',
}

=example-1 read_env_file

  package main;

  use Venus 'read_env_file';

  my $config = read_env_file 't/conf/read.env';

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'read_env_file', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Config');
  my $value = $result->value;
  is_deeply $value->{APPNAME}, "Example";
  is_deeply $value->{APPTAG}, "Godzilla";
  is_deeply $value->{APPVER}, 0.01;

  $result
});

=function read_json

The read_json function returns a new L<Venus::Config> object based on the JSON
string provided.

=signature read_json

  read_json(string $data) (Venus::Config)

=metadata read_json

{
  since => '4.15',
}

=example-1 read_json

  package main;

  use Venus 'read_json';

  my $config = read_json q(
  {
    "$metadata": {
      "tmplog": "/tmp/log"
    },
    "$services": {
      "log": { "package": "Venus/Path", "argument": { "$metadata": "tmplog" } }
    }
  }
  );

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'read_json', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Json && not Venus::Json->package) {
    diag 'No suitable JSON library found' if $ENV{VENUS_DEBUG};
    $result = Venus::Config->new;
    ok 1;
  }
  else {
    ok $result = $tryable->result;
    ok $result->isa('Venus::Config');
    my $value = $result->value;
    ok exists $value->{'$services'};
    ok exists $value->{'$metadata'};
  }

  $result
});

=function read_json_file

The read_json_file function uses L<Venus::Path> to return a new
L<Venus::Config> object based on the file provided.

=signature read_json_file

  read_json_file(string $file) (Venus::Config)

=metadata read_json_file

{
  since => '4.15',
}

=example-1 read_json_file

  package main;

  use Venus 'read_json_file';

  my $config = read_json_file 't/conf/read.json';

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'read_json_file', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Json && not Venus::Json->package) {
    diag 'No suitable JSON library found' if $ENV{VENUS_DEBUG};
    $result = Venus::Config->new;
    ok 1;
  }
  else {
    ok $result = $tryable->result;
    ok $result->isa('Venus::Config');
    my $value = $result->value;
    ok exists $value->{'$services'};
    ok exists $value->{'$metadata'};
  }

  $result
});

=function read_perl

The read_perl function returns a new L<Venus::Config> object based on the Perl
string provided.

=signature read_perl

  read_perl(string $data) (Venus::Config)

=metadata read_perl

{
  since => '4.15',
}

=example-1 read_perl

  package main;

  use Venus 'read_perl';

  my $config = read_perl q(
  {
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  }
  );

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'read_perl', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Config');
  my $value = $result->value;
  ok exists $value->{'$services'};
  ok exists $value->{'$metadata'};

  $result
});

=function read_perl_file

The read_perl_file function uses L<Venus::Path> to return a new
L<Venus::Config> object based on the file provided.

=signature read_perl_file

  read_perl_file(string $file) (Venus::Config)

=metadata read_perl_file

{
  since => '4.15',
}

=example-1 read_perl_file

  package main;

  use Venus 'read_perl_file';

  my $config = read_perl_file 't/conf/read.perl';

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'read_perl_file', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Config');
  ok $result->isa('Venus::Config');
  my $value = $result->value;
  ok exists $value->{'$services'};
  ok exists $value->{'$metadata'};

  $result
});

=function read_yaml

The read_yaml function returns a new L<Venus::Config> object based on the YAML
string provided.

=signature read_yaml

  read_yaml(string $data) (Venus::Config)

=metadata read_yaml

{
  since => '4.15',
}

=example-1 read_yaml

  package main;

  use Venus 'read_yaml';

  my $config = read_yaml q(
  '$metadata':
    tmplog: /tmp/log
  '$services':
    log:
      package: "Venus/Path"
      argument:
        '$metadata': tmplog
  );

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'read_yaml', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Yaml && not Venus::Yaml->package) {
    diag 'No suitable YAML library found' if $ENV{VENUS_DEBUG};
    $result = Venus::Config->new;
    ok 1;
  }
  else {
    ok $result = $tryable->result;
    ok $result->isa('Venus::Config');
    my $value = $result->value;
    ok exists $value->{'$services'};
    ok exists $value->{'$metadata'};
  }

  $result
});

=function read_yaml_file

The read_yaml_file function uses L<Venus::Path> to return a new
L<Venus::Config> object based on the YAML string provided.

=signature read_yaml_file

  read_yaml_file(string $file) (Venus::Config)

=metadata read_yaml_file

{
  since => '4.15',
}

=example-1 read_yaml_file

  package main;

  use Venus 'read_yaml_file';

  my $config = read_yaml_file 't/conf/read.yaml';

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'read_yaml_file', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Yaml && not Venus::Yaml->package) {
    diag 'No suitable YAML library found' if $ENV{VENUS_DEBUG};
    $result = Venus::Config->new;
    ok 1;
  }
  else {
    ok $result = $tryable->result;
    ok $result->isa('Venus::Config');
    my $value = $result->value;
    ok exists $value->{'$services'};
    ok exists $value->{'$metadata'};
  }

  $result
});

=function regexp

The regexp function builds and returns a L<Venus::Regexp> object, or dispatches
to the coderef or method provided.

=signature regexp

  regexp(string $value, string | coderef $code, any @args) (any)

=metadata regexp

{
  since => '2.55',
}

=cut

=example-1 regexp

  package main;

  use Venus 'regexp';

  my $regexp = regexp '[0-9]';

  # bless({...}, 'Venus::Regexp')

=cut

$test->for('example', 1, 'regexp', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Regexp";

  $result
});

=example-2 regexp

  package main;

  use Venus 'regexp';

  my $replace = regexp '[0-9]', 'replace', 'ID 12345', '0', 'g';

  # bless({...}, 'Venus::Replace')

  # $replace->get;

  # "ID 00000"

=cut

$test->for('example', 2, 'regexp', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Replace";
  is_deeply $result->get, "ID 00000";

  $result
});

=function render

The render function accepts a string as a template and renders it using
L<Venus::Template>, and returns the result.

=signature render

  render(string $data, hashref $args) (string)

=metadata render

{
  since => '3.04',
}

=cut

=example-1 render

  package main;

  use Venus 'render';

  my $render = render 'hello {{name}}', {
    name => 'user',
  };

  # "hello user"

=cut

$test->for('example', 1, 'render', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "hello user";

  $result
});

=function replace

The replace function builds and returns a L<Venus::Replace> object, or
dispatches to the coderef or method provided.

=signature replace

  replace(arrayref $value, string | coderef $code, any @args) (any)

=metadata replace

{
  since => '2.55',
}

=cut

=example-1 replace

  package main;

  use Venus 'replace';

  my $replace = replace ['hello world', 'world', 'universe'];

  # bless({...}, 'Venus::Replace')

=cut

$test->for('example', 1, 'replace', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Replace";
  is_deeply $result->string, 'hello world';
  is_deeply $result->regexp, 'world';
  is_deeply $result->substr, 'universe';

  $result
});

=example-2 replace

  package main;

  use Venus 'replace';

  my $replace = replace ['hello world', 'world', 'universe'], 'get';

  # "hello universe"

=cut

$test->for('example', 2, 'replace', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "hello universe";

  $result
});

=function roll

The roll function takes a list of arguments, assuming the first argument is
invokable, and reorders the list such that the routine name provided comes
after the invocant (i.e. the 1st argument), creating a list acceptable to the
L</call> function.

=signature roll

  roll(string $name, any @args) (any)

=metadata roll

{
  since => '2.32',
}

=example-1 roll

  package main;

  use Venus 'roll';

  my @list = roll('sha1_hex', 'Digest::SHA');

  # ('Digest::SHA', 'sha1_hex');

=cut

$test->for('example', 1, 'roll', sub {
  my ($tryable) = @_;
  ok my @result = $tryable->result;
  is_deeply [@result], ['Digest::SHA', 'sha1_hex'];

  @result
});

=example-2 roll

  package main;

  use Venus 'roll';

  my @list = roll('sha1_hex', call(\'Digest::SHA', 'new'));

  # (bless(do{\(my $o = '...')}, 'Digest::SHA'), 'sha1_hex');

=cut

$test->for('example', 2, 'roll', sub {
  my ($tryable) = @_;
  ok my @result = $tryable->result;
  ok $result[0]->isa('Digest::SHA');
  is_deeply $result[1], 'sha1_hex';

  @result
});

=function search

The search function builds and returns a L<Venus::Search> object, or dispatches
to the coderef or method provided.

=signature search

  search(arrayref $value, string | coderef $code, any @args) (any)

=metadata search

{
  since => '2.55',
}

=cut

=example-1 search

  package main;

  use Venus 'search';

  my $search = search ['hello world', 'world'];

  # bless({...}, 'Venus::Search')

=cut

$test->for('example', 1, 'search', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Search";
  is_deeply $result->string, 'hello world';
  is_deeply $result->regexp, 'world';

  $result
});

=example-2 search

  package main;

  use Venus 'search';

  my $search = search ['hello world', 'world'], 'count';

  # 1

=cut

$test->for('example', 2, 'search', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 1;

  $result
});

=function set

The set function returns a L<Venus::Set> object for the arrayref provided.

=signature set

  set(arrayref $value) (Venus::Set)

=metadata set

{
  since => '4.11',
}

=example-1 set

  package main;

  use Venus;

  my $set = Venus::set [1..9];

  # bless(..., 'Venus::Set')

=cut

$test->for('example', 1, 'set', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Set');
  is_deeply $result->get, [1..9];

  $result
});

=example-2 set

  package main;

  use Venus;

  my $set = Venus::set [1..9], 'count';

  # 9

=cut

$test->for('example', 2, 'set', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, 9;

  $result
});

=function space

The space function returns a L<Venus::Space> object for the package provided.

=signature space

  space(any $name) (Venus::Space)

=metadata space

{
  since => '2.32',
}

=example-1 space

  package main;

  use Venus 'space';

  my $space = space 'Venus::Scalar';

  # bless({value => 'Venus::Scalar'}, 'Venus::Space')

=cut

$test->for('example', 1, 'space', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Space');
  is_deeply $result->value, 'Venus::Scalar';

  $result
});

=function schema

The schema function builds and returns a L<Venus::Schema> object, or dispatches
to the coderef or method provided.

=signature schema

  schema(string | coderef $code, any @args) (Venus::Schema)

=metadata schema

{
  since => '4.15',
}

=cut

=example-1 schema

  package main;

  use Venus 'schema';

  my $schema = schema;

  # bless({...}, "Venus::Schema")

=cut

$test->for('example', 1, 'schema', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Schema';

  $result
});

=example-2 schema

  package main;

  use Venus 'schema';

  my $schema = schema 'rule', {
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  };

  # bless({...}, "Venus::Schema")

=cut

$test->for('example', 2, 'schema', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Schema';
  is_deeply $result->ruleset, [{
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  }];

  $result
});

=example-3 schema

  package main;

  use Venus 'schema';

  my $schema = schema 'rules', {
    selector => 'fname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  },{
    selector => 'lname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  };

  # bless({...}, "Venus::Schema")

=cut

$test->for('example', 3, 'schema', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Schema';
  is_deeply $result->ruleset, [{
    selector => 'fname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  },{
    selector => 'lname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  }];

  $result
});

=function sets

The sets function find values from within the underlying data structure using
L<Venus::Array/path> or L<Venus::Hash/path>, where each argument pair is a
selector and value, and returns all the values provided. Returns a list in list
context. Note, nested data structures can be updated but not created.

=signature sets

  sets(string @args) (arrayref)

=metadata sets

{
  since => '4.15',
}

=cut

=example-1 sets

  package main;

  use Venus 'sets';

  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];

  my $sets = sets $data, '3' => 'bar', '1.bar' => 'bar';

  # ['bar', 'bar']

=cut

$test->for('example', 1, 'sets', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['bar', 'bar'];
  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];
  Venus::sets($data, '3' => 'bar', '1.bar' => 'bar');
  is_deeply $data, ['foo', {'bar' => 'bar'}, 'bar', 'bar'];

  $result
});

=example-2 sets

  package main;

  use Venus 'sets';

  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];

  my ($baz, $one_bar) = sets $data, '3' => 'bar', '1.bar' => 'bar';

  # ('bar', 'bar')

=cut

$test->for('example', 2, 'sets', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, ['bar', 'bar'];
  my $data = ['foo', {'bar' => 'baz'}, 'bar', ['baz']];
  Venus::sets($data, '3' => 'bar', '1.bar' => 'bar');
  is_deeply $data, ['foo', {'bar' => 'bar'}, 'bar', 'bar'];

  @result
});

=example-3 sets

  package main;

  use Venus 'sets';

  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};

  my $sets = sets $data, 'bar' => 'bar', 'foo.bar' => 'bar';

  # ['bar', 'bar']

=cut

$test->for('example', 3, 'sets', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['bar', 'bar'];
  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};
  Venus::sets($data, 'bar' => 'bar', 'foo.bar' => 'bar');
  is_deeply $data, {'foo' => {'bar' => 'bar'}, 'bar' => 'bar'};

  $result
});

=example-4 sets

  package main;

  use Venus 'sets';

  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};

  my ($bar, $foo_bar) = sets $data, 'bar' => 'bar', 'foo.bar' => 'bar';

  # ('bar', 'bar')

=cut

$test->for('example', 4, 'sets', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, ['bar', 'bar'];
  my $data = {'foo' => {'bar' => 'baz'}, 'bar' => ['baz']};
  Venus::sets($data, 'bar' => 'bar', 'foo.bar' => 'bar');
  is_deeply $data, {'foo' => {'bar' => 'bar'}, 'bar' => 'bar'};

  @result
});

=function sorts

The sorts function accepts a list of values, flattens any arrayrefs, and sorts
it using the default C<sort(LIST)> call style exclusively.

=signature sorts

  sorts(any @args) (any)

=metadata sorts

{
  since => '4.15',
}

=cut

=example-1 sorts

  package main;

  use Venus 'sorts';

  my @sorts = sorts 1..4;

  # (1..4)

=cut

$test->for('example', 1, 'sorts', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [1..4];

  @result
});

=example-2 sorts

  package main;

  use Venus 'sorts';

  my @sorts = sorts 4,3,2,1;

  # (1..4)

=cut

$test->for('example', 2, 'sorts', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [1..4];

  @result
});

=example-3 sorts

  package main;

  use Venus 'sorts';

  my @sorts = sorts [1..4], 5, [6..9];

  # (1..9)

=cut

$test->for('example', 3, 'sorts', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [1..9];

  @result
});

=function string

The string function builds and returns a L<Venus::String> object, or dispatches
to the coderef or method provided.

=signature string

  string(string $value, string | coderef $code, any @args) (any)

=metadata string

{
  since => '2.55',
}

=cut

=example-1 string

  package main;

  use Venus 'string';

  my $string = string 'hello world';

  # bless({...}, 'Venus::String')

=cut

$test->for('example', 1, 'string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::String';
  is_deeply $result->get, 'hello world';

  $result
});

=example-2 string

  package main;

  use Venus 'string';

  my $string = string 'hello world', 'camelcase';

  # "helloWorld"

=cut

$test->for('example', 2, 'string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 'helloWorld';

  $result
});

=function syscall

The syscall function perlforms system call, i.e. a L<perlfunc/qx> operation,
and returns C<true> if the command succeeds, otherwise returns C<false>. In
list context, returns the output of the operation and the exit code.

=signature syscall

  syscall(number | string @args) (any)

=metadata syscall

{
  since => '3.04',
}

=cut

=example-1 syscall

  package main;

  use Venus 'syscall';

  my $syscall = syscall 'perl', '-v';

  # true

=cut

$test->for('example', 1, 'syscall', sub {
  my ($tryable) = @_;
  local $TEST_VENUS_QX_DATA = 'perl';
  local $TEST_VENUS_QX_EXIT = 0;
  local $TEST_VENUS_QX_CODE = 0;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 1;

  $result
});

=example-2 syscall

  package main;

  use Venus 'syscall';

  my $syscall = syscall 'perl', '-z';

  # false

=cut

$test->for('example', 2, 'syscall', sub {
  my ($tryable) = @_;
  local $TEST_VENUS_QX_DATA = 'perl';
  local $TEST_VENUS_QX_EXIT = 7424;
  local $TEST_VENUS_QX_CODE = 29;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 0;

  !$result
});

=example-3 syscall

  package main;

  use Venus 'syscall';

  my ($data, $code) = syscall 'sun', '--heat-death';

  # ('done', 0)

=cut

$test->for('example', 3, 'syscall', sub {
  my ($tryable) = @_;
  local $TEST_VENUS_QX_DATA = 'done';
  local $TEST_VENUS_QX_EXIT = 0;
  local $TEST_VENUS_QX_CODE = 0;
  my @result = $tryable->result;
  is_deeply [@result], ['done', 0];

  @result
});

=example-4 syscall

  package main;

  use Venus 'syscall';

  my ($data, $code) = syscall 'earth', '--melt-icecaps';

  # ('', 127)

=cut

$test->for('example', 4, 'syscall', sub {
  my ($tryable) = @_;
  local $TEST_VENUS_QX_DATA = '';
  local $TEST_VENUS_QX_EXIT = -1;
  local $TEST_VENUS_QX_CODE = 127;
  my @result = $tryable->result;
  is_deeply [@result], ['', 127];

  @result
});

=function template

The template function builds and returns a L<Venus::Template> object, or
dispatches to the coderef or method provided.

=signature template

  template(string $value, string | coderef $code, any @args) (any)

=metadata template

{
  since => '2.55',
}

=cut

=example-1 template

  package main;

  use Venus 'template';

  my $template = template 'Hi {{name}}';

  # bless({...}, 'Venus::Template')

=cut

$test->for('example', 1, 'template', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Template';
  is_deeply $result->get, 'Hi {{name}}';

  $result
});

=example-2 template

  package main;

  use Venus 'template';

  my $template = template 'Hi {{name}}', 'render', undef, {
    name => 'stranger',
  };

  # "Hi stranger"

=cut

$test->for('example', 2, 'template', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, 'Hi stranger';

  $result
});

=function test

The test function builds and returns a L<Venus::Test> object, or dispatches to
the coderef or method provided.

=signature test

  test(string $value, string | coderef $code, any @args) (any)

=metadata test

{
  since => '2.55',
}

=cut

=example-1 test

  package main;

  use Venus 'test';

  my $test = test 't/Venus.t';

  # bless({...}, 'Venus::Test')

=cut

$test->for('example', 1, 'test', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Test";
  is_deeply $result->file, 't/Venus.t';

  $result
});

=example-2 test

  package main;

  use Venus 'test';

  my $test = test 't/Venus.t', 'for', 'synopsis';

  # bless({...}, 'Venus::Test')

=cut

$test->for('example', 2, 'test', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Test";
  is_deeply $result->file, 't/Venus.t';

  $result
});

=function text_pod

The text_pod function builds and returns a L<Venus::Text::Pod> object, or
dispatches to the coderef or method provided.

=signature text_pod

  text_pod(string $value, string | coderef $code, any @args) (any)

=metadata text_pod

{
  since => '4.15',
}

=cut

=example-1 text_pod

  package main;

  use Venus 'text_pod';

  my $text_pod = text_pod 't/data/sections';

  # bless({...}, 'Venus::Text::Pod')

=cut

$test->for('example', 1, 'text_pod', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Text::Pod';
  is_deeply $result->file, 't/data/sections';

  $result
});

=example-2 text_pod

  package main;

  use Venus 'text_pod';

  my $text_pod = text_pod 't/data/sections', 'string', undef, 'name';

  # "Example #1\nExample #2"

=cut

$test->for('example', 2, 'text_pod', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example #1\nExample #2";

  $result
});

=function text_pod_string

The text_pod_string function builds a L<Venus::Text::Pod> object for the
current file, i.e. L<perlfunc/__FILE__> or script, i.e. C<$0>, and returns the
result of a L<Venus::Text::Pod/string> operation using the arguments provided.

=signature text_pod_string

  text_pod_string(any @args) (any)

=metadata text_pod_string

{
  since => '4.15',
}

=cut

=example-1 text_pod_string

  package main;

  use Venus 'text_pod_string';

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #1
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #2
  #
  # =cut
  #
  # =head1 ABSTRACT
  #
  # Example Abstract
  #
  # =cut

  my $text_pod_string = text_pod_string 'name';

  # "Example #1\nExample #2"

=cut

$test->for('example', 1, 'text_pod_string', sub {
  my ($tryable) = @_;
  local $0 = 't/data/sections';
  my $result = $tryable->result;
  is_deeply $result, "Example #1\nExample #2";

  $result
});

=example-2 text_pod_string

  package main;

  use Venus 'text_pod_string';

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #1
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #2
  #
  # =cut
  #
  # =head1 ABSTRACT
  #
  # Example Abstract
  #
  # =cut

  my $text_pod_string = text_pod_string 'head1', 'ABSTRACT';

  # "Example Abstract"

=cut

$test->for('example', 2, 'text_pod_string', sub {
  my ($tryable) = @_;
  local $0 = 't/data/sections';
  my $result = $tryable->result;
  is_deeply $result, "Example Abstract";

  $result
});

=function text_tag

The text_tag function builds and returns a L<Venus::Text::Tag> object, or
dispatches to the coderef or method provided.

=signature text_tag

  text_tag(string $value, string | coderef $code, any @args) (any)

=metadata text_tag

{
  since => '4.15',
}

=cut

=example-1 text_tag

  package main;

  use Venus 'text_tag';

  my $text_tag = text_tag 't/data/sections';

  # bless({...}, 'Venus::Text::Tag')

=cut

$test->for('example', 1, 'text_tag', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Text::Tag';
  is_deeply $result->file, 't/data/sections';

  $result
});

=example-2 text_tag

  package main;

  use Venus 'text_tag';

  my $text_tag = text_tag 't/data/sections', 'string', undef, 'name';

  # "Example Name"

=cut

$test->for('example', 2, 'text_tag', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example Name";

  $result
});

=function text_tag_string

The text_tag_string function builds a L<Venus::Text::Tag> object for the
current file, i.e. L<perlfunc/__FILE__> or script, i.e. C<$0>, and returns the
result of a L<Venus::Text::Tag/string> operation using the arguments provided.

=signature text_tag_string

  text_tag_string(any @args) (any)

=metadata text_tag_string

{
  since => '4.15',
}

=cut

=example-1 text_tag_string

  package main;

  use Venus 'text_tag_string';

  # @@ name
  #
  # Example Name
  #
  # @@ end
  #
  # @@ titles #1
  #
  # Example Title #1
  #
  # @@ end
  #
  # @@ titles #2
  #
  # Example Title #2
  #
  # @@ end

  my $text_tag_string = text_tag_string 'name';

  # "Example Name"

=cut

$test->for('example', 1, 'text_tag_string', sub {
  my ($tryable) = @_;
  local $0 = 't/data/sections';
  my $result = $tryable->result;
  is_deeply $result, "Example Name";

  $result
});

=example-2 text_tag_string

  package main;

  use Venus 'text_tag_string';

  # @@ name
  #
  # Example Name
  #
  # @@ end
  #
  # @@ titles #1
  #
  # Example Title #1
  #
  # @@ end
  #
  # @@ titles #2
  #
  # Example Title #2
  #
  # @@ end

  my $text_tag_string = text_tag_string 'titles', '#1';

  # "Example Title #1"

=cut

$test->for('example', 2, 'text_tag_string', sub {
  my ($tryable) = @_;
  local $0 = 't/data/sections';
  my $result = $tryable->result;
  is_deeply $result, "Example Title #1";

  $result
});

=example-3 text_tag_string

  package main;

  use Venus 'text_tag_string';

  # @@ name
  #
  # Example Name
  #
  # @@ end
  #
  # @@ titles #1
  #
  # Example Title #1
  #
  # @@ end
  #
  # @@ titles #2
  #
  # Example Title #2
  #
  # @@ end

  my $text_tag_string = text_tag_string undef, 'name';

  # "Example Name"

=cut

$test->for('example', 3, 'text_tag_string', sub {
  my ($tryable) = @_;
  local $0 = 't/data/sections';
  my $result = $tryable->result;
  is_deeply $result, "Example Name";

  $result
});

=function then

The then function proxies the call request to the L</call> function and returns
the result as a list, prepended with the invocant.

=signature then

  then(string | object | coderef $self, any @args) (any)

=metadata then

{
  since => '2.32',
}

=example-1 then

  package main;

  use Venus 'then';

  my @list = then('Digest::SHA', 'sha1_hex');

  # ("Digest::SHA", "da39a3ee5e6b4b0d3255bfef95601890afd80709")

=cut

$test->for('example', 1, 'then', sub {
  my ($tryable) = @_;
  ok my @result = $tryable->result;
  is_deeply [@result], ["Digest::SHA", "da39a3ee5e6b4b0d3255bfef95601890afd80709"];

  @result
});

=function throw

The throw function builds and returns a L<Venus::Throw> object, or dispatches
to the coderef or method provided.

=signature throw

  throw(string | hashref $value, string | coderef $code, any @args) (any)

=metadata throw

{
  since => '2.55',
}

=cut

=example-1 throw

  package main;

  use Venus 'throw';

  my $throw = throw 'Example::Error';

  # bless({...}, 'Venus::Throw')

=cut

$test->for('example', 1, 'throw', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Throw";
  is_deeply $result->package, 'Example::Error';

  $result
});

=example-2 throw

  package main;

  use Venus 'throw';

  my $throw = throw 'Example::Error', 'error';

  # bless({...}, 'Example::Error')

=cut

$test->for('example', 2, 'throw', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Example::Error';

  $result
});

=example-3 throw

  package main;

  use Venus 'throw';

  my $throw = throw {
    name => 'on.execute',
    package => 'Example::Error',
    capture => ['...'],
    stash => {
      time => time,
    },
  };

  # bless({...}, 'Venus::Throw')

=cut

$test->for('example', 3, 'throw', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Throw';
  ok $result->package eq 'Example::Error';
  is_deeply $result->name, 'on.execute';
  ok $result->stash('captured');
  ok $result->stash('time');

  $result
});

=function true

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value.

=signature true

  true() (boolean)

=metadata true

{
  since => '0.01',
}

=example-1 true

  package main;

  use Venus;

  my $true = true;

  # 1

=cut

$test->for('example', 1, 'true', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 true

  package main;

  use Venus;

  my $false = !true;

  # 0

=cut

$test->for('example', 2, 'true', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  !$result
});

=function try

The try function builds and returns a L<Venus::Try> object, or dispatches to
the coderef or method provided.

=signature try

  try(any $data, string | coderef $code, any @args) (any)

=metadata try

{
  since => '2.55',
}

=cut

=example-1 try

  package main;

  use Venus 'try';

  my $try = try sub {};

  # bless({...}, 'Venus::Try')

  # my $result = $try->result;

  # ()

=cut

$test->for('example', 1, 'try', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Try";

  $result
});

=example-2 try

  package main;

  use Venus 'try';

  my $try = try sub { die };

  # bless({...}, 'Venus::Try')

  # my $result = $try->result;

  # Exception! (isa Venus::Error)

=cut

$test->for('example', 2, 'try', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Try";

  $result
});

=example-3 try

  package main;

  use Venus 'try';

  my $try = try sub { die }, 'maybe';

  # bless({...}, 'Venus::Try')

  # my $result = $try->result;

  # undef

=cut

$test->for('example', 3, 'try', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Try';
  ok !defined $result->result;

  $result
});

=function tv

The tv function compares the lvalue and rvalue and returns true if they have
the same type and value, otherwise returns false. b<Note:> Comparison of
coderefs, filehandles, and blessed objects with private state are impossible.
This function will only return true if these data types are L<"identical"|/is>.
It's also impossible to know which blessed objects have private state and
therefore could produce false-positives when comparing object in those cases.

=signature tv

  tv(any $lvalue, any $rvalue) (boolean)

=metadata tv

{
  since => '4.15',
}

=cut

=example-1 tv

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv 1, 1;

  # true

=cut

$test->for('example', 1, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 tv

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv '1', 1;

  # false

=cut

$test->for('example', 2, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-3 tv

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv ['0', 1..4], ['0', 1..4];

  # true

=cut

$test->for('example', 3, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-4 tv

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv ['0', 1..4], [0, 1..4];

  # false

=cut

$test->for('example', 4, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-5 tv

  # given: synopsis

  package main;

  use Venus 'tv';

  my $tv = tv undef, undef;

  # true

=cut

$test->for('example', 5, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-6 tv

  # given: synopsis

  package main;

  use Venus 'number', 'tv';

  my $a = number 1;

  my $tv = tv $a, undef;

  # false

=cut

$test->for('example', 6, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=example-7 tv

  # given: synopsis

  package main;

  use Venus 'number', 'tv';

  my $a = number 1;

  my $tv = tv $a, $a;

  # true

=cut

$test->for('example', 7, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-8 tv

  # given: synopsis

  package main;

  use Venus 'number', 'tv';

  my $a = number 1;
  my $b = number 1;

  my $tv = tv $a, $b;

  # true

=cut

$test->for('example', 8, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-9 tv

  # given: synopsis

  package main;

  use Venus 'number', 'tv';

  my $a = number 0;
  my $b = number 1;

  my $tv = tv $a, $b;

  # false

=cut

$test->for('example', 9, 'tv', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, false;

  !$result
});

=function type

The type function builds and returns a L<Venus::Type> object, or dispatches to
the coderef or method provided.

=signature type

  type(string | coderef $code, any @args) (any)

=metadata type

{
  since => '4.15',
}

=cut

=example-1 type

  package main;

  use Venus 'type';

  my $type = type;

  # bless({...}, 'Venus::Type')

=cut

$test->for('example', 1, 'type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Type');

  $result
});

=example-2 type

  package main;

  use Venus 'type';

  my $expression = type 'expression', 'string | number';

  # ["either", "string", "number"]

=cut

$test->for('example', 2, 'type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ["either", "string", "number"];

  $result
});

=example-3 type

  package main;

  use Venus 'type';

  my $expression = type 'expression', ["either", "string", "number"];

  # "string | number"

=cut

$test->for('example', 3, 'type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "string | number";

  $result
});

=function unpack

The unpack function builds and returns a L<Venus::Unpack> object.

=signature unpack

  unpack(any @args) (Venus::Unpack)

=metadata unpack

{
  since => '2.40',
}

=cut

=example-1 unpack

  package main;

  use Venus 'unpack';

  my $unpack = unpack;

  # bless({...}, 'Venus::Unpack')

  # $unpack->checks('string');

  # false

  # $unpack->checks('undef');

  # false

=cut

$test->for('example', 1, 'unpack', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Unpack';
  is_deeply scalar $result->args, [];
  is_deeply scalar $result->checks('string'), [];
  is_deeply scalar $result->checks('undef'), [];

  $result
});

=example-2 unpack

  package main;

  use Venus 'unpack';

  my $unpack = unpack rand;

  # bless({...}, 'Venus::Unpack')

  # $unpack->check('number');

  # false

  # $unpack->check('float');

  # true

=cut

$test->for('example', 2, 'unpack', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Unpack';
  ok scalar @{$result->args};
  is_deeply scalar $result->checks('number'), [0];
  is_deeply scalar $result->checks('float'), [1];

  $result
});

=function vars

The vars function builds and returns a L<Venus::Vars> object, or dispatches to
the coderef or method provided.

=signature vars

  vars(hashref $value, string | coderef $code, any @args) (any)

=metadata vars

{
  since => '2.55',
}

=cut

=example-1 vars

  package main;

  use Venus 'vars';

  my $vars = vars {};

  # bless({...}, 'Venus::Vars')

=cut

$test->for('example', 1, 'vars', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Vars';

  $result
});

=example-2 vars

  package main;

  use Venus 'vars';

  my $path = vars {}, 'exists', 'path';

  # "..."

=cut

$test->for('example', 2, 'vars', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=function vns

The vns function build a L<Venus> package based on the name provided, loads and
instantiates the package, and returns an instance of that package or dispatches
to the method provided and returns the result.

=signature vns

  vns(string $name, args $args, string | coderef $callback, any @args) (any)

=metadata vns

{
  since => '4.15',
}

=cut

=example-1 vns

  package main;

  use Venus 'vns';

  my $space = vns 'space';

  # bless({value => 'Venus'}, 'Venus::Space')

=cut

$test->for('example', 1, 'vns', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Space';
  is_deeply $result->value, 'Venus';

  $result
});

=example-2 vns

  package main;

  use Venus 'vns';

  my $space = vns 'space', 'Venus::String';

  # bless({value => 'Venus::String'}, 'Venus::Space')

=cut

$test->for('example', 2, 'vns', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Space';
  is_deeply $result->value, 'Venus::String';

  $result
});

=example-3 vns

  package main;

  use Venus 'vns';

  my $code = vns 'code', sub{};

  # bless({value => sub{...}}, 'Venus::Code')

=cut

$test->for('example', 3, 'vns', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Code';

  $result
});

=function what

The what function builds and returns a L<Venus::What> object, or dispatches to
the coderef or method provided.

=signature what

  what(any $data, string | coderef $code, any @args) (any)

=metadata what

{
  since => '4.11',
}

=cut

=example-1 what

  package main;

  use Venus 'what';

  my $what = what [1..4];

  # bless({...}, 'Venus::What')

  # $what->deduce;

  # bless({...}, 'Venus::Array')

=cut

$test->for('example', 1, 'what', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::What";
  my $returned = $result->deduce;
  isa_ok $returned, "Venus::Array";

  $result
});

=example-2 what

  package main;

  use Venus 'what';

  my $what = what [1..4], 'deduce';

  # bless({...}, 'Venus::Array')

=cut

$test->for('example', 2, 'what', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, "Venus::Array";

  $result
});

=function work

The work function builds a L<Venus::Process> object, forks the current process
using the callback provided via the L<Venus::Process/work> operation, and
returns an instance of L<Venus::Process> representing the current process.

=signature work

  work(coderef $callback) (Venus::Process)

=metadata work

{
  since => '2.40',
}

=cut

=example-1 work

  package main;

  use Venus 'work';

  my $parent = work sub {
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  };

  # bless({...}, 'Venus::Process')

=cut

$test->for('example', 1, 'work', sub {
  if ($Config{d_pseudofork}) {
    plan skip_all => 'Fork emulation not supported';
    return 1;
  }
  my ($tryable) = @_;
  local $TEST_VENUS_PROCESS_FORK = 0;
  ok my $result = $tryable->result;
  is_deeply $result, $TEST_VENUS_PROCESS_PID;

  $result
});

=function wrap

The wrap function installs a wrapper function in the calling package which when
called either returns the package string if no arguments are provided, or calls
L</make> on the package with whatever arguments are provided and returns the
result. Unless an alias is provided as a second argument, special characters
are stripped from the package to create the function name.

=signature wrap

  wrap(string $data, string $name) (coderef)

=metadata wrap

{
  since => '2.32',
}

=example-1 wrap

  package main;

  use Venus 'wrap';

  my $coderef = wrap('Digest::SHA');

  # sub { ... }

  # my $digest = DigestSHA();

  # "Digest::SHA"

  # my $digest = DigestSHA(1);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=cut

$test->for('example', 1, 'wrap', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, '*main::DigestSHA';
  is_deeply DigestSHA(), "Digest::SHA";
  ok DigestSHA(1)->isa("Digest::SHA");

  $result
});

=example-2 wrap

  package main;

  use Venus 'wrap';

  my $coderef = wrap('Digest::SHA', 'SHA');

  # sub { ... }

  # my $digest = SHA();

  # "Digest::SHA"

  # my $digest = SHA(1);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')

=cut

$test->for('example', 2, 'wrap', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, '*main::SHA';
  is_deeply SHA(), "Digest::SHA";
  ok SHA(1)->isa("Digest::SHA");

  $result
});

=function write_env

The write_env function returns a string representing environment variable
key/value pairs based on the L</value> held by the underlying L<Venus::Config>
object.

=signature write_env

  write_env(hashref $data) (string)

=metadata write_env

{
  since => '4.15',
}

=cut

=example-1 write_env

  package main;

  use Venus 'write_env';

  my $write_env = write_env {
    APPNAME => "Example",
    APPTAG => "Godzilla",
    APPVER => 0.01,
  };

  # "APPNAME=Example\nAPPTAG=Godzilla\nAPPVER=0.01"

=cut

$test->for('example', 1, 'write_env', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "APPNAME=Example\nAPPTAG=Godzilla\nAPPVER=0.01";

  $result
});

=function write_env_file

The write_env_file function saves a environment configuration file and returns
a new L<Venus::Config> object.

=signature write_env_file

  write_env_file(string $path, hashref $data) (Venus::Config)

=metadata write_env_file

{
  since => '4.15',
}

=example-1 write_env_file

  package main;

  use Venus 'write_env_file';

  my $write_env_file = write_env_file 't/conf/write.env', {
    APPNAME => "Example",
    APPTAG => "Godzilla",
    APPVER => 0.01,
  };

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'write_env_file', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Config');
  ok $result->value;
  $result = $result->read_file('t/conf/write.env');
  is_deeply $result->value->{APPNAME}, "Example";
  is_deeply $result->value->{APPTAG}, "Godzilla";
  is_deeply $result->value->{APPVER}, 0.01;

  $result
});

=function write_json

The write_json function returns a JSON encoded string based on the L</value>
held by the underlying L<Venus::Config> object.

=signature write_json

  write_json(hashref $data) (string)

=metadata write_json

{
  since => '4.15',
}

=example-1 write_json

  package main;

  use Venus 'write_json';

  my $write_json = write_json {
    '$services' => {
      log => { package => "Venus::Path" },
    },
  };

  # '{ "$services":{ "log":{ "package":"Venus::Path" } } }'

=cut

$test->for('example', 1, 'write_json', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Json && not Venus::Json->package) {
    diag 'No suitable JSON library found' if $ENV{VENUS_DEBUG};
    $result = Venus::Config->new;
    ok 1;
  }
  else {
    $result = $tryable->result;
    $result =~ s/[\n\s]//g;
    is_deeply $result, '{"$services":{"log":{"package":"Venus::Path"}}}';
  }

  $result
});

=function write_json_file

The write_json_file function saves a JSON configuration file and returns a new
L<Venus::Config> object.

=signature write_json_file

  write_json_file(string $path, hashref $data) (Venus::Config)

=metadata write_json_file

{
  since => '4.15',
}

=example-1 write_json_file

  package main;

  use Venus 'write_json_file';

  my $write_json_file = write_json_file 't/conf/write.json', {
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  };

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'write_json_file', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Json && not Venus::Json->package) {
    diag 'No suitable JSON library found' if $ENV{VENUS_DEBUG};
    $result = Venus::Config->new;
    ok 1;
  }
  else {
    ok $result = $tryable->result;
    ok $result->isa('Venus::Config');
    ok $result->value;
    $result = $result->read_file('t/conf/write.json');
    ok exists $result->value->{'$services'};
  }

  $result
});

=function write_perl

The write_perl function returns a FILE encoded string based on the L</value>
held by the underlying L<Venus::Config> object.

=signature write_perl

  write_perl(hashref $data) (string)

=metadata write_perl

{
  since => '4.15',
}

=example-1 write_perl

  package main;

  use Venus 'write_perl';

  my $write_perl = write_perl {
    '$services' => {
      log => { package => "Venus::Path" },
    },
  };

  # '{ "\$services" => { log => { package => "Venus::Path" } } }'

=cut

$test->for('example', 1, 'write_perl', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  $result =~ s/[\n\s]//g;
  is_deeply $result, '{"\$services"=>{log=>{package=>"Venus::Path"}}}';

  $result
});

=function write_perl_file

The write_perl_file function saves a Perl configuration file and returns a new
L<Venus::Config> object.

=signature write_perl_file

  write_perl_file(string $path, hashref $data) (Venus::Config)

=metadata write_perl_file

{
  since => '4.15',
}

=example-1 write_perl_file

  package main;

  use Venus 'write_perl_file';

  my $write_perl_file = write_perl_file 't/conf/write.perl', {
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  };

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'write_perl_file', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Config');
  ok $result->value;
  $result = $result->read_file('t/conf/write.perl');
  ok exists $result->value->{'$services'};

  $result
});

=function write_yaml

The write_yaml function returns a FILE encoded string based on the L</value>
held by the underlying L<Venus::Config> object.

=signature write_yaml

  write_yaml(hashref $data) (string)

=metadata write_yaml

{
  since => '4.15',
}

=example-1 write_yaml

  package main;

  use Venus 'write_yaml';

  my $write_yaml = write_yaml {
    '$services' => {
      log => { package => "Venus::Path" },
    },
  };

  # '---\n$services:\n\s\slog:\n\s\s\s\spackage:\sVenus::Path'

=cut

$test->for('example', 1, 'write_yaml', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Yaml && not Venus::Yaml->package) {
    diag 'No suitable YAML library found' if $ENV{VENUS_DEBUG};
    $result = Venus::Config->new;
    ok 1;
  }
  else {
    $result = $tryable->result;
    $result =~ s/[\n\s]//g;
    is_deeply $result, '---$services:log:package:Venus::Path';
  }

  $result
});

=function write_yaml_file

The write_yaml_file function saves a YAML configuration file and returns a new
L<Venus::Config> object.

=signature write_yaml_file

  write_yaml_file(string $path, hashref $data) (Venus::Config)

=metadata write_yaml_file

{
  since => '4.15',
}

=example-1 write_yaml_file

  package main;

  use Venus 'write_yaml_file';

  my $write_yaml_file = write_yaml_file 't/conf/write.yaml', {
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  };

  # bless(..., 'Venus::Config')

=cut

$test->for('example', 1, 'write_yaml_file', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Yaml && not Venus::Yaml->package) {
    diag 'No suitable YAML library found' if $ENV{VENUS_DEBUG};
    $result = Venus::Config->new;
    ok 1;
  }
  else {
    $result = $tryable->result;
    ok $result->isa('Venus::Config');
    ok $result->value;
    $result = $result->read_file('t/conf/write.yaml');
    ok exists $result->value->{'$services'};
  }

  $result
});

=function yaml

The yaml function builds a L<Venus::Yaml> object and will either
L<Venus::Yaml/decode> or L<Venus::Yaml/encode> based on the argument provided
and returns the result.

=signature yaml

  yaml(string $call, any $data) (any)

=metadata yaml

{
  since => '2.40',
}

=cut

=example-1 yaml

  package main;

  use Venus 'yaml';

  my $decode = yaml 'decode', "---\nname:\n- Ready\n- Robot\nstable: true\n";

  # { name => ["Ready", "Robot"], stable => 1 }

=cut

$test->for('example', 1, 'yaml', sub {
  if (require Venus::Yaml && not Venus::Yaml->package) {
    plan skip_all => 'No suitable YAML library found';
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, { name => ["Ready", "Robot"], stable => 1 };

  $result
});

=example-2 yaml

  package main;

  use Venus 'yaml';

  my $encode = yaml 'encode', { name => ["Ready", "Robot"], stable => true };

  # '---\nname:\n- Ready\n- Robot\nstable: true\n'

=cut

$test->for('example', 2, 'yaml', sub {
  if (require Venus::Yaml && not Venus::Yaml->package) {
    plan skip_all => 'No suitable YAML library found';
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->result;
  $result =~ s/\n/\\n/g;
  is_deeply $result, '---\nname:\n- Ready\n- Robot\nstable: true\n';

  $result
});

=example-3 yaml

  package main;

  use Venus 'yaml';

  my $yaml = yaml;

  # bless({...}, 'Venus::Yaml')

=cut

$test->for('example', 3, 'yaml', sub {
  if (require Venus::Yaml && not Venus::Yaml->package) {
    plan skip_all => 'No suitable YAML library found';
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Yaml';

  $result
});

=example-4 yaml

  package main;

  use Venus 'yaml';

  my $yaml = yaml 'class', {data => "..."};

  # Exception! (isa Venus::Fault)

=cut

$test->for('example', 4, 'yaml', sub {
  if (require Venus::Yaml && not Venus::Yaml->package) {
    plan skip_all => 'No suitable YAML library found';
    return 1;
  }
  my ($tryable) = @_;
  my $result = $tryable->catch('Venus::Fault')->result;
  isa_ok $result, 'Venus::Fault';
  like $result, qr/Invalid "yaml" action "class"/;

  $result
});

=feature venus-args

This library contains a L<Venus::Args> class which provides methods for
accessing C<@ARGS> items.

=cut

$test->for('feature', 'venus-args');

=feature venus-array

This library contains a L<Venus::Array> class which provides methods for
manipulating array data.

=cut

$test->for('feature', 'venus-array');

=feature venus-assert

This library contains a L<Venus::Assert> class which provides a mechanism for
asserting type constraints and coercion.

=cut

$test->for('feature', 'venus-assert');

=feature venus-atom

This library contains a L<Venus::Atom> class which provides a write-once object
representing a constant value.

=cut

$test->for('feature', 'venus-atom');

=feature venus-boolean

This library contains a L<Venus::Boolean> class which provides a representation
for boolean values.

=cut

$test->for('feature', 'venus-boolean');

=feature venus-box

This library contains a L<Venus::Box> class which provides a pure Perl boxing
mechanism.

=cut

$test->for('feature', 'venus-box');

=feature venus-call

This library contains a L<Venus::Call> class which provides a protocol for
dynamically invoking methods with optional opt-in type safety.

=cut

$test->for('feature', 'venus-call');

=feature venus-check

This library contains a L<Venus::Check> class which provides runtime dynamic type checking.

=cut

$test->for('feature', 'venus-check');

=feature venus-class

This library contains a L<Venus::Class> class which provides a class builder.

=cut

$test->for('feature', 'venus-class');

=feature venus-cli

This library contains a L<Venus::Cli> class which provides a superclass for
creating CLIs.

=cut

$test->for('feature', 'venus-cli');

=feature venus-code

This library contains a L<Venus::Code> class which provides methods for
manipulating subroutines.

=cut

$test->for('feature', 'venus-code');

=feature venus-coercion

This library contains a L<Venus::Coercion> class which provides data type coercions via L<Venus::Check>.

=cut

$test->for('feature', 'venus-coercion');



=feature venus-collect

This library contains a L<Venus::Collect> class which provides a mechanism for
iterating over mappable values.

=cut

$test->for('feature', 'venus-collect');



=feature venus-config

This library contains a L<Venus::Config> class which provides methods for
loading Perl, YAML, and JSON configuration data.

=cut

$test->for('feature', 'venus-config');

=feature venus-constraint

This library contains a L<Venus::Constraint> class which provides data type
constraints via L<Venus::Check>.

=cut

$test->for('feature', 'venus-constraint');

=feature venus-data

This library contains a L<Venus::Data> class which provides value object for
encapsulating data validation.

=cut

$test->for('feature', 'venus-date');

=feature venus-date

This library contains a L<Venus::Date> class which provides methods for
formatting, parsing, and manipulating dates.

=cut

$test->for('feature', 'venus-date');

=feature venus-dump

This library contains a L<Venus::Dump> class which provides methods for reading
and writing dumped Perl data.

=cut

$test->for('feature', 'venus-dump');

=feature venus-enum

This library contains a L<Venus::Enum> class which provides an interface for working with enumerations.

=cut

$test->for('feature', 'venus-enum');

=feature venus-error

This library contains a L<Venus::Error> class which represents a context-aware
error (exception object).

=cut

$test->for('feature', 'venus-error');

=feature venus-factory

This library contains a L<Venus::Factory> class which provides an object-oriented factory pattern for building objects.

=cut

$test->for('feature', 'venus-factory');

=feature venus-false

This library contains a L<Venus::False> class which provides the global
C<false> value.

=cut

$test->for('feature', 'venus-false');

=feature venus-fault

This library contains a L<Venus::Fault> class which represents a generic system
error (exception object).

=cut

$test->for('feature', 'venus-fault');

=feature venus-float

This library contains a L<Venus::Float> class which provides methods for
manipulating float data.

=cut

$test->for('feature', 'venus-float');

=feature venus-future

This library contains a L<Venus::Future> class which provides a
framework-agnostic implementation of the Future pattern.

=cut

$test->for('feature', 'venus-future');

=feature venus-gather

This library contains a L<Venus::Gather> class which provides an
object-oriented interface for complex pattern matching operations on
collections of data, e.g. array references.

=cut

$test->for('feature', 'venus-gather');

=feature venus-hash

This library contains a L<Venus::Hash> class which provides methods for
manipulating hash data.

=cut

$test->for('feature', 'venus-hash');

=feature venus-json

This library contains a L<Venus::Json> class which provides methods for reading
and writing JSON data.

=cut

$test->for('feature', 'venus-json');

=feature venus-log

This library contains a L<Venus::Log> class which provides methods for logging
information using various log levels.

=cut

$test->for('feature', 'venus-log');

=feature venus-map

This library contains a L<Venus::Map> class which provides a representation of
a collection of ordered key/value pairs.

=cut

$test->for('feature', 'venus-map');

=feature venus-match

This library contains a L<Venus::Match> class which provides an object-oriented
interface for complex pattern matching operations on scalar values.

=cut

$test->for('feature', 'venus-match');

=feature venus-meta

This library contains a L<Venus::Meta> class which provides configuration
information for L<Venus> derived classes.

=cut

$test->for('feature', 'venus-meta');

=feature venus-mixin

This library contains a L<Venus::Mixin> class which provides a mixin builder.

=cut

$test->for('feature', 'venus-mixin');

=feature venus-name

This library contains a L<Venus::Name> class which provides methods for parsing
and formatting package namespaces.

=cut

$test->for('feature', 'venus-name');

=feature venus-number

This library contains a L<Venus::Number> class which provides methods for
manipulating number data.

=cut

$test->for('feature', 'venus-number');

=feature venus-opts

This library contains a L<Venus::Opts> class which provides methods for
handling command-line arguments.

=cut

$test->for('feature', 'venus-opts');

=feature venus-os

This library contains a L<Venus::Os> class which provides methods for
determining the current operating system, as well as finding and executing
files.

=cut

$test->for('feature', 'venus-os');

=feature venus-path

This library contains a L<Venus::Path> class which provides methods for working
with file system paths.

=cut

$test->for('feature', 'venus-path');

=feature venus-process

This library contains a L<Venus::Process> class which provides methods for
handling and forking processes.

=cut

$test->for('feature', 'venus-process');

=feature venus-prototype

This library contains a L<Venus::Prototype> class which provides a simple
construct for enabling prototype-base programming.

=cut

$test->for('feature', 'venus-prototype');

=feature venus-random

This library contains a L<Venus::Random> class which provides an
object-oriented interface for Perl's pseudo-random number generator.

=cut

$test->for('feature', 'venus-random');

=feature venus-range

This library contains a L<Venus::Range> class which provides an object-oriented
interface for selecting elements from an arrayref using range expressions.

=cut

$test->for('feature', 'venus-range');

=feature venus-regexp

This library contains a L<Venus::Regexp> class which provides methods for
manipulating regexp data.

=cut

$test->for('feature', 'venus-regexp');

=feature venus-replace

This library contains a L<Venus::Replace> class which provides methods for
manipulating regexp replacement data.

=cut

$test->for('feature', 'venus-replace');

=feature venus-result

This library contains a L<Venus::Result> class which provides a container for
representing success and error states.

=cut

$test->for('feature', 'venus-result');

=feature venus-run

This library contains a L<Venus::Run> class which provides a base class for
providing a command execution system for creating CLIs (command-line
interfaces).

=cut

$test->for('feature', 'venus-run');

=feature venus-scalar

This library contains a L<Venus::Scalar> class which provides methods for
manipulating scalar data.

=cut

$test->for('feature', 'venus-scalar');

=feature venus-schema

This library contains a L<Venus::Schema> class which provides a mechanism for
validating complex data structures.

=cut

$test->for('feature', 'venus-schema');

=feature venus-sealed

This library contains a L<Venus::Sealed> class which provides a mechanism for
restricting access to the underlying data structure.

=cut

$test->for('feature', 'venus-sealed');

=feature venus-search

This library contains a L<Venus::Search> class which provides methods for
manipulating regexp search data.

=cut

$test->for('feature', 'venus-search');

=feature venus-set

This library contains a L<Venus::Set> class which provides a representation of
a collection of ordered key/value pairs.

=cut

$test->for('feature', 'venus-set');

=feature venus-space

This library contains a L<Venus::Space> class which provides methods for
parsing and manipulating package namespaces.

=cut

$test->for('feature', 'venus-space');

=feature venus-string

This library contains a L<Venus::String> class which provides methods for
manipulating string data.

=cut

$test->for('feature', 'venus-string');

=feature venus-task

This library contains a L<Venus::Task> class which provides a base class for
creating CLIs (command-line interfaces).

=cut

$test->for('feature', 'venus-task');

=feature venus-template

This library contains a L<Venus::Template> class which provides a templating
system, and methods for rendering template.

=cut

$test->for('feature', 'venus-template');

=feature venus-test

This library contains a L<Venus::Test> class which aims to provide a standard
for documenting L<Venus> derived software projects.

=cut

$test->for('feature', 'venus-test');

=feature venus-text

This library contains a L<Venus::Text> class which provides methods for
extracting C<DATA> sections and POD block.

=cut

$test->for('feature', 'venus-text');

=feature venus-text-pod

This library contains a L<Venus::Text::Pod> class which provides methods for
extracting POD blocks.

=cut

$test->for('feature', 'venus-text-pod');

=feature venus-text-tag

This library contains a L<Venus::Text::Tag> class which provides methods for
extracting C<DATA> sections.

=cut

$test->for('feature', 'venus-text-tag');

=feature venus-throw

This library contains a L<Venus::Throw> class which provides a mechanism for
generating and raising error objects.

=cut

$test->for('feature', 'venus-throw');

=feature venus-true

This library contains a L<Venus::True> class which provides the global C<true>
value.

=cut

$test->for('feature', 'venus-true');

=feature venus-try

This library contains a L<Venus::Try> class which provides an object-oriented
interface for performing complex try/catch operations.

=cut

$test->for('feature', 'venus-try');

=feature venus-type

This library contains a L<Venus::Type> class which provides a mechanism for
parsing, generating, and validating data type expressions.

=cut

$test->for('feature', 'venus-type');

=feature venus-undef

This library contains a L<Venus::Undef> class which provides methods for
manipulating undef data.

=cut

$test->for('feature', 'venus-undef');

=feature venus-unpack

This library contains a L<Venus::Unpack> class which provides methods for
validating, coercing, and otherwise operating on lists of arguments.

=cut

$test->for('feature', 'venus-unpack');

=feature venus-validate

This library contains a L<Venus::Validate> class which provides a mechanism for
performing data validation of simple and hierarchal data.

=cut

$test->for('feature', 'venus-validate');

=feature venus-vars

This library contains a L<Venus::Vars> class which provides methods for
accessing C<%ENV> items.

=cut

$test->for('feature', 'venus-vars');

=feature venus-what

This library contains a L<Venus::What> class which provides methods for casting
native data types to objects.

=cut

$test->for('feature', 'venus-what');

=feature venus-yaml

This library contains a L<Venus::Yaml> class which provides methods for reading
and writing YAML data.

=cut

$test->for('feature', 'venus-yaml');

=authors

Awncorp, C<awncorp@cpan.org>

=cut

$test->for('authors');

=license

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut

$test->for('license');

# END

$test->render('lib/Venus.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
