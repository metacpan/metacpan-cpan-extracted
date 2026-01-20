package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);
my $fsds = qr/[:\\\/\.]+/;

=name

Venus::Error

=cut

$test->for('name');

=tagline

Error Class

=cut

$test->for('tagline');

=abstract

Error Class for Perl 5

=cut

$test->for('abstract');

=includes

method: arguments
method: as
method: callframe
method: capture
method: captured
method: copy
method: explain
method: frame
method: frames
method: get
method: is
method: input
method: new
method: of
method: on
method: output
method: render
method: reset
method: set
method: stash
method: sysinfo
method: system_name
method: system_path
method: system_perl_path
method: system_perl_version
method: system_process_id
method: system_script_args
method: system_script_path
method: throw
method: trace

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Error;

  my $error = Venus::Error->new;

  # $error->throw;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=description

This package represents a context-aware error (exception object). The default
for error verbosity can be controlled via the C<VENUS_ERROR_VERBOSE>
environment variable, e.g. a setting of C<0> disables stack traces. The default
trace-offset can be controlled via the C<VENUS_ERROR_TRACE_OFFSET> environment
variable, e.g. a setting of C<0> indicates no offset.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Explainable
Venus::Role::Encaseable

=cut

$test->for('integrates');

=attribute name

The name attribute is read-write, accepts C<string> values, and is optional.

=signature name

  name(string $name) (string)

=metadata name

{
  since => '0.01',
}

=cut

=example-1 name

  # given: synopsis

  package main;

  my $set_name = $error->name("on.save");

  # "on.save"

=cut

$test->for('example', 1, 'name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "on.save";

  $result
});

=example-2 name

  # given: synopsis

  # given: example-1 name

  package main;

  my $get_name = $error->name;

  # "on.save"

=cut

$test->for('example', 2, 'name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "on.save";

  $result
});

=attribute cause

The cause attribute is read-write, accepts C<Venus::Error> values, and is
optional.

=signature cause

  cause(Venus::Error $error) (Venus::Error)

=metadata cause

{
  since => '4.15',
}

=cut

=example-1 cause

  # given: synopsis

  package main;

  my $set_cause = $error->cause(Venus::Error->new);

  # bless(..., "Venus::Error")

=cut

$test->for('example', 1, 'cause', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');

  $result
});

=example-2 cause

  # given: synopsis

  # given: example-1 cause

  package main;

  my $get_cause = $error->cause;

  # bless(..., "Venus::Error")

=cut

$test->for('example', 2, 'cause', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');

  $result
});

=attribute context

The context attribute is read-write, accepts C<string> values, and is optional.
Defaults to C<'N/A'>.

=signature context

  context(string $context) (string)

=metadata context

{
  since => '0.01',
}

=cut

=example-1 context

  # given: synopsis

  package main;

  my $set_context = $error->context("main::main");

  # "main::main"

=cut

$test->for('example', 1, 'context', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "main::main";

  $result
});

=example-2 context

  # given: synopsis

  # given: example-1 context

  package main;

  my $get_context = $error->context;

  # "main::main"

=cut

$test->for('example', 2, 'context', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "main::main";

  $result
});

=attribute message

The message attribute is read-write, accepts C<string> values, and is optional.
Defaults to C<'Exception!'>.

=signature message

  message(string $message) (string)

=metadata message

{
  since => '0.01',
}

=cut

=example-1 message

  # given: synopsis

  package main;

  my $set_message = $error->message("Exception!");

  # "Exception!"

=cut

$test->for('example', 1, 'message', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Exception!";

  $result
});

=example-2 message

  # given: synopsis

  # given: example-1 message

  package main;

  my $get_message = $error->message;

  # "Exception!"

=cut

$test->for('example', 2, 'message', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Exception!";

  $result
});

=attribute verbose

The verbose attribute is read-write, accepts C<number> values, and is optional.
Defaults to C<true>.

=signature verbose

  verbose(number $verbose) (number)

=metadata verbose

{
  since => '0.01',
}

=cut

=example-1 verbose

  # given: synopsis

  package main;

  my $set_verbose = $error->verbose(true);

  # true

=cut

$test->for('example', 1, 'verbose', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=example-2 verbose

  # given: synopsis

  # given: example-1 verbose

  package main;

  my $get_verbose = $error->verbose;

  # true

=cut

$test->for('example', 2, 'verbose', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, true;

  $result
});

=method as

The as method returns an error object using the return value(s) of the "as"
method specified, which should be defined as C<"as_${name}">, which will be
called automatically by this method. If no C<"as_${name}"> method exists, this
method will set the L</name> attribute to the value provided.

=signature as

  as(string $name) (Venus::Error)

=metadata as

{
  since => '1.02',
}

=example-1 as

  package System::Error;

  use Venus::Class;

  base 'Venus::Error';

  sub as_auth_error {
    my ($self) = @_;

    return $self->do('message', 'auth_error');
  }

  sub as_role_error {
    my ($self) = @_;

    return $self->do('message', 'role_error');
  }

  sub is_auth_error {
    my ($self) = @_;

    return $self->message eq 'auth_error';
  }

  sub is_role_error {
    my ($self) = @_;

    return $self->message eq 'role_error';
  }

  package main;

  my $error = System::Error->new->as('auth_error');

  $error->throw;

  # Exception! (isa Venus::Error)

=cut

$test->for('example', 1, 'as', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error->isa('System::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'auth_error';

  $result
});

=example-2 as

  package System::Error;

  use Venus::Class;

  base 'Venus::Error';

  sub as_auth_error {
    my ($self) = @_;

    return $self->do('message', 'auth_error');
  }

  sub as_role_error {
    my ($self) = @_;

    return $self->do('message', 'role_error');
  }

  sub is_auth_error {
    my ($self) = @_;

    return $self->message eq 'auth_error';
  }

  sub is_role_error {
    my ($self) = @_;

    return $self->message eq 'role_error';
  }

  package main;

  my $error = System::Error->new->as('role_error');

  $error->throw;

  # Exception! (isa Venus::Error)

=cut

$test->for('example', 2, 'as', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error->isa('System::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'role_error';

  $result
});

=example-3 as

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $error = Virtual::Error->new->as('on_save_error');

  $error->throw;

  # name is "on_save_error"

  # Exception! (isa Venus::Error)

=cut

$test->for('example', 3, 'as', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error->isa('Virtual::Error');
  ok $error->isa('Venus::Error');
  ok $error->name eq 'on_save_error';

  $result
});

=example-4 as

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $error = Virtual::Error->new->as('on.SAVE.error');

  $error->throw;

  # name is "on_save_error"

  # Exception! (isa Venus::Error)

=cut

$test->for('example', 4, 'as', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error->isa('Virtual::Error');
  ok $error->isa('Venus::Error');
  ok $error->name eq 'on.save.error';

  $result
});

=method arguments

The arguments method returns the stashed arguments under L</captured>, or a
specific argument if an index is provided.

=signature arguments

  arguments(number $index) (any)

=metadata arguments

{
  since => '2.55',
}

=cut

=example-1 arguments

  # given: synopsis

  my $arguments = $error->arguments;

  # undef

=cut

$test->for('example', 1, 'arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 arguments

  package main;

  use Venus::Error;

  my $error = Venus::Error->new->capture(1..4);

  my $arguments = $error->arguments;

  # [1..4]

=cut

$test->for('example', 2, 'arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [1..4];

  $result
});

=example-3 arguments

  package main;

  use Venus::Error;

  my $error = Venus::Error->new->capture(1..4);

  my $arguments = $error->arguments(0);

  # 1

=cut

$test->for('example', 3, 'arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method callframe

The callframe method returns the stashed callframe under L</captured>, or a
specific argument if an index is provided.

=signature callframe

  callframe(number $index) (any)

=metadata callframe

{
  since => '2.55',
}

=cut

=example-1 callframe

  # given: synopsis

  my $callframe = $error->callframe;

  # undef

=cut

$test->for('example', 1, 'callframe', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 callframe

  package main;

  use Venus::Error;

  my $error = Venus::Error->new->do('offset', 0)->capture;

  my $callframe = $error->callframe;

  # [...]

=cut

$test->for('example', 2, 'callframe', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';

  $result
});

=example-3 callframe

  package main;

  use Venus::Error;

  my $error = Venus::Error->new->do('offset', 0)->capture;

  my $package = $error->callframe(0);

  # 'main'

=cut

$test->for('example', 3, 'callframe', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'main';

  $result
});

=method capture

The capture method captures the L<caller> info at the L</frame> specified, in
the object stash, and returns the invocant.

=signature capture

  capture(any @args) (Venus::Error)

=metadata capture

{
  since => '4.15',
}

=cut

=example-1 capture

  # given: synopsis

  package main;

  $error = $error->capture;

  # bless({...}, 'Venus::Error')

=cut

$test->for('example', 1, 'capture', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Error';
  ok $result->stash('captured');
  ok exists $result->stash('captured')->{arguments};
  ok exists $result->stash('captured')->{callframe};

  $result
});

=method captured

The captured method returns the value stashed as C<"captured">.

=signature captured

  captured() (hashref)

=metadata captured

{
  since => '2.55',
}

=cut

=example-1 captured

  # given: synopsis

  my $captured = $error->captured;

  # undef

=cut

$test->for('example', 1, 'captured', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=method copy

The copy method copied the properties of the L<Venus::Error> provided into the
invocant and returns the invocant.

=signature copy

  copy(Venus::Error $error) (Venus::Error)

=metadata copy

{
  since => '4.15',
}

=cut

=example-1 copy

  # given: synopsis

  package main;

  my $oops = Venus::Error->as('on.oops');

  my $copy = $error->copy($oops);

  # bless({ ... }, 'Venus::Error')

  # $error->name;

  # "on.oops"

=cut

$test->for('example', 1, 'copy', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->name, 'on.oops';

  $result
});

=example-2 copy

  # given: synopsis

  package main;

  my $oops = Venus::Error->as('on.oops');

  $oops->message('Oops, something happened.');

  $oops->stash(what => 'Unknown');

  my $copy = $error->copy($oops);

  # bless({ ... }, 'Venus::Error')

  # $error->name;

  # "on.oops"

  # $error->message;

  # "Oops, something happened."

  # $error->stash('what');

  # "Unknown"

=cut

$test->for('example', 2, 'copy', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->name, 'on.oops';
  is $result->message, 'Oops, something happened.';
  is $result->stash('what'), 'Unknown';

  $result
});

=method explain

The explain method returns the error message and is used in stringification
operations.

=signature explain

  explain() (string)

=metadata explain

{
  since => '0.01',
}

=example-1 explain

  # given: synopsis;

  $error->verbose(0);

  my $explain = $error->explain;

  # "Exception!" in ...

=cut

$test->for('example', 1, 'explain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result =~ /^Exception!\n$/;

  $result
});

=example-2 explain

  # given: synopsis;

  $error->verbose(1);

  my $explain = $error->explain;

  # "Exception!" in ...

=cut

$test->for('example', 2, 'explain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $message = "Exception!";
  ok $result =~ /$message\n\n\w+/m;

  my $name = qr/Name:\n\nN\/A/;
  ok $result =~ /$name/m;

  my $type = qr/Type:\n\nVenus::Error/;
  ok $result =~ /$type/m;

  my $context = qr/Context:\n\nN\/A/;
  ok $result =~ /$context/m;

  my $stashed = qr/Stashed:\n\n\{\}/;
  ok $result =~ /$stashed/m;

  my $traceback = qr/Traceback \(reverse chronological order\):/;
  ok $result =~ /$traceback/m;

  $result
});

=example-3 explain

  # given: synopsis;

  $error->name('on.save.error');

  $error->verbose(1);

  my $explain = $error->explain;

  # "Exception!" in ...

=cut

$test->for('example', 3, 'explain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $message = "Exception!";
  ok $result =~ /$message\n\n\w+/m;

  my $name = qr/Name:\n\non\.save\.error/;
  ok $result =~ /$name/m;

  my $type = qr/Type:\n\nVenus::Error/;
  ok $result =~ /$type/m;

  my $context = qr/Context:\n\nN\/A/;
  ok $result =~ /$context/m;

  my $stashed = qr/Stashed:\n\n\{\}/;
  ok $result =~ /$stashed/m;

  my $traceback = qr/Traceback \(reverse chronological order\):/;
  ok $result =~ /$traceback/m;

  $result
});

=example-4 explain

  # given: synopsis;

  $error->name('on.save.error');

  $error->stash('what', 'Unknown');

  $error->verbose(1);

  my $explain = $error->explain;

  # "Exception!" in ...

=cut

$test->for('example', 4, 'explain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  my $message = "Exception!";
  ok $result =~ /$message\n\n\w+/m;

  my $name = qr/Name:\n\non\.save\.error/;
  ok $result =~ /$name/m;

  my $type = qr/Type:\n\nVenus::Error/;
  ok $result =~ /$type/m;

  my $context = qr/Context:\n\nN\/A/;
  ok $result =~ /$context/m;

  my $stashed = qr/Stashed:\n\n[\w\W]+what[\w\W]+\=\>[\w\W]+Unknown[\w\W]+/;
  ok $result =~ /$stashed/m;

  my $traceback = qr/Traceback \(reverse chronological order\):/;
  ok $result =~ /$traceback/m;

  $result
});

=example-5 explain

  package main;

  use Venus::Error;

  my $step3 = Venus::Error->new(
    name => 'step3',
    message => 'Step 3: Failed',
  );

  my $step2 = Venus::Error->new(
    name => 'step2',
    message => 'Step 2: Failed',
    cause => $step3,
  );

  my $step1 = Venus::Error->new(
    name => 'step1',
    message => 'Step 1: Failed',
    cause => $step2,
  );

  my $explain = $step1->explain;

  # "Step 1: Failed" in ...

=cut

$test->for('example', 5, 'explain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result =~ /^Step 1: Failed\n/;

  my $message = "Step 1: Failed";
  ok $result =~ /$message\n\n\w+/m;

  my $name = qr/Name:\n\nstep1/;
  ok $result =~ /$name/m;

  my $type = qr/Type:\n\nVenus::Error/;
  ok $result =~ /$type/m;

  my $context = qr/Context:\n\nN\/A/;
  ok $result =~ /$context/m;

  my $stashed = qr/Stashed:\n\n\{\}/;
  ok $result =~ /$stashed/m;

  my $traceback = qr/Traceback \(reverse chronological order\):/;
  ok $result =~ /$traceback/m;

  my $cause1 = qr/Cause:\n\nStep 2: Failed/;
  ok $result =~ /$cause1/m;

  my $cause2 = qr/Cause:\n\nStep 3: Failed/;
  ok $result =~ /$cause2/m;

  $result
});

=method frame

The frame method returns the data from C<caller> on the frames captured, and
returns a hashref where the keys map to the keys described by
L<perlfunc/caller>.

=signature frame

  frame(number $index) (hashref)

=metadata frame

{
  since => '1.11',
}

=example-1 frame

  # given: synopsis;

  my $frame = $error->frame;

  # {
  #   'bitmask' => '...',
  #   'evaltext' => '...',
  #   'filename' => '...',
  #   'hasargs' => '...',
  #   'hinthash' => '...',
  #   'hints' => '...',
  #   'is_require' => '...',
  #   'line' => '...',
  #   'package' => '...',
  #   'subroutine' => '...',
  #   'wantarray' => '...',
  # }

=cut

$test->for('example', 1, 'frame', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok exists $result->{bitmask};
  ok exists $result->{evaltext};
  ok exists $result->{filename};
  ok exists $result->{hasargs};
  ok exists $result->{hinthash};
  ok exists $result->{hints};
  ok exists $result->{is_require};
  ok exists $result->{line};
  ok exists $result->{package};
  ok exists $result->{subroutine};
  ok exists $result->{wantarray};

  $result
});

=example-2 frame

  # given: synopsis;

  my $frame = $error->frame(1);

  # {
  #   'bitmask' => '...',
  #   'evaltext' => '...',
  #   'filename' => '...',
  #   'hasargs' => '...',
  #   'hinthash' => '...',
  #   'hints' => '...',
  #   'is_require' => '...',
  #   'line' => '...',
  #   'package' => '...',
  #   'subroutine' => '...',
  #   'wantarray' => '...',
  # }

=cut

$test->for('example', 2, 'frame', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok exists $result->{bitmask};
  ok exists $result->{evaltext};
  ok exists $result->{filename};
  ok exists $result->{hasargs};
  ok exists $result->{hinthash};
  ok exists $result->{hints};
  ok exists $result->{is_require};
  ok exists $result->{line};
  ok exists $result->{package};
  ok exists $result->{subroutine};
  ok exists $result->{wantarray};

  $result
});

=method frames

The frames method returns the compiled and stashed stack trace data.

=signature frames

  frames() (arrayref)

=metadata frames

{
  since => '0.01',
}

=example-1 frames

  # given: synopsis;

  my $frames = $error->frames;

  # [
  #   ...
  #   [
  #     "main",
  #     "t/Venus_Error.t",
  #     ...
  #   ],
  # ]

=cut

$test->for('example', 1, 'frames', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  my $last_frame = $result->[-1];
  ok $last_frame->[0] eq 'main';
  ok $last_frame->[1] =~ m{t${fsds}Venus_Error.t$};

  $result
});

=method get

The get method takes one or more attribute and/or method names and returns the
result of calling each attribute and/or method. In scalar context returns a
single value. In list context results a list of values.

=signature get

  get(string @args) (any)

=metadata get

{
  since => '4.15',
}

=cut

=example-1 get

  # given: synopsis

  package main;

  my $get = $error->get('verbose');

  # true

=cut

$test->for('example', 1, 'get', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 get

  # given: synopsis

  package main;

  my $get = $error->get('verbose', 'context');

  # true

=cut

$test->for('example', 2, 'get', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-3 get

  # given: synopsis

  package main;

  my @get = $error->get('verbose', 'message');

  # (true, 'Exception!')

=cut

$test->for('example', 3, 'get', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], [true, 'Exception!'];

  @result
});

=method input

The input method captures the arguments provided as associates them with a
L<"callframe"|perlfunc/caller> based on the level specified by L</offset>, in
the object stash, and returns the invocant.

=signature input

  input(any @args) (Venus::Error)

=metadata input

{
  since => '4.15',
}

=cut

=example-1 input

  # given: synopsis

  package main;

  $error = $error->input(1..4);

  # bless({...}, 'Venus::Error')

=cut

$test->for('example', 1, 'input', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Error';
  ok $result->stash('input');
  ok exists $result->stash('input')->{arguments};
  ok exists $result->stash('input')->{callframe};
  is_deeply $result->stash('input')->{arguments}, [1..4];

  $result
});

=method is

The is method returns truthy or falsy based on the return value(s) of the "is"
method specified, which should be defined as C<"is_${name}">, which will be
called automatically by this method. If no C<"is_${name}"> method exists, this
method will check if the L</name> attribute is equal to the value provided.

=signature is

  is(string $name) (boolean)

=metadata is

{
  since => '1.02',
}

=example-1 is

  package System::Error;

  use Venus::Class;

  base 'Venus::Error';

  sub as_auth_error {
    my ($self) = @_;

    return $self->do('message', 'auth_error');
  }

  sub as_role_error {
    my ($self) = @_;

    return $self->do('message', 'role_error');
  }

  sub is_auth_error {
    my ($self) = @_;

    return $self->message eq 'auth_error';
  }

  sub is_role_error {
    my ($self) = @_;

    return $self->message eq 'role_error';
  }

  package main;

  my $is = System::Error->new->as('auth_error')->is('auth_error');

  # 1

=cut

$test->for('example', 1, 'is', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 is

  package System::Error;

  use Venus::Class;

  base 'Venus::Error';

  sub as_auth_error {
    my ($self) = @_;

    return $self->do('message', 'auth_error');
  }

  sub as_role_error {
    my ($self) = @_;

    return $self->do('message', 'role_error');
  }

  sub is_auth_error {
    my ($self) = @_;

    return $self->message eq 'auth_error';
  }

  sub is_role_error {
    my ($self) = @_;

    return $self->message eq 'role_error';
  }

  package main;

  my $is = System::Error->as('auth_error')->is('auth_error');

  # 1

=cut

$test->for('example', 2, 'is', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-3 is

  package System::Error;

  use Venus::Class;

  base 'Venus::Error';

  sub as_auth_error {
    my ($self) = @_;

    return $self->do('message', 'auth_error');
  }

  sub as_role_error {
    my ($self) = @_;

    return $self->do('message', 'role_error');
  }

  sub is_auth_error {
    my ($self) = @_;

    return $self->message eq 'auth_error';
  }

  sub is_role_error {
    my ($self) = @_;

    return $self->message eq 'role_error';
  }

  package main;

  my $is = System::Error->as('auth_error')->is('role_error');

  # 0

=cut

$test->for('example', 3, 'is', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=example-4 is

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $is = Virtual::Error->new->as('on_save_error')->is('on_save_error');

  # 1

=cut

$test->for('example', 4, 'is', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-5 is

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $is = Virtual::Error->new->as('on.SAVE.error')->is('on.save.error');

  # 1

=cut

$test->for('example', 5, 'is', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Error)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Error;

  my $new = Venus::Error->new;

  # bless(..., "Venus::Error")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Exception!';

  $result
});

=example-2 new

  package main;

  use Venus::Error;

  my $new = Venus::Error->new('Oops!');

  # bless(..., "Venus::Error")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Oops!';

  $result
});

=example-3 new

  package main;

  use Venus::Error;

  my $new = Venus::Error->new(message => 'Oops!');

  # bless(..., "Venus::Error")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->message, 'Oops!';

  $result
});

=method of

The of method returns truthy or falsy based on the return value(s) of the "of"
method specified, which should be defined as C<"of_${name}">, which will be
called automatically by this method. If no C<"of_${name}"> method exists, this
method will check if the L</name> attribute contains the value provided.

=signature of

  of(string $name) (boolean)

=metadata of

{
  since => '1.11',
}

=example-1 of

  package System::Error;

  use Venus::Class;

  base 'Venus::Error';

  sub as_auth_error {
    my ($self) = @_;

    return $self->do('name', 'auth_error');
  }

  sub as_role_error {
    my ($self) = @_;

    return $self->do('name', 'role_error');
  }

  sub is_auth_error {
    my ($self) = @_;

    return $self->name eq 'auth_error';
  }

  sub is_role_error {
    my ($self) = @_;

    return $self->name eq 'role_error';
  }

  package main;

  my $of = System::Error->as('auth_error')->of('role');

  # 0

=cut

$test->for('example', 1, 'of', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=example-2 of

  package System::Error;

  use Venus::Class;

  base 'Venus::Error';

  sub as_auth_error {
    my ($self) = @_;

    return $self->do('name', 'auth_error');
  }

  sub as_role_error {
    my ($self) = @_;

    return $self->do('name', 'role_error');
  }

  sub is_auth_error {
    my ($self) = @_;

    return $self->name eq 'auth_error';
  }

  sub is_role_error {
    my ($self) = @_;

    return $self->name eq 'role_error';
  }

  package main;

  my $of = System::Error->as('auth_error')->of('auth');

  # 1

=cut

$test->for('example', 2, 'of', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-3 of

  package System::Error;

  use Venus::Class;

  base 'Venus::Error';

  sub as_auth_error {
    my ($self) = @_;

    return $self->do('name', 'auth_error');
  }

  sub as_role_error {
    my ($self) = @_;

    return $self->do('name', 'role_error');
  }

  sub is_auth_error {
    my ($self) = @_;

    return $self->name eq 'auth_error';
  }

  sub is_role_error {
    my ($self) = @_;

    return $self->name eq 'role_error';
  }

  package main;

  my $of = System::Error->as('auth_error')->of('role_error');

  # 0

=cut

$test->for('example', 3, 'of', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=example-4 of

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $of = Virtual::Error->new->as('on_save_error')->of('on.save');

  # 1

=cut

$test->for('example', 4, 'of', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-5 of

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $of = Virtual::Error->new->as('on.SAVE.error')->of('on.save');

  # 1

=cut

$test->for('example', 5, 'of', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=method on

The on method sets a L</name> for the error in the form of
C<"on.$subroutine.$name"> or C<"on.$name"> (if outside of a subroutine) and
returns the invocant.

=signature on

  on(string $name) (Venus::Error)

=metadata on

{
  since => '4.15',
}

=cut

=example-1 on

  # given: synopsis

  package main;

  $error = $error->on('handler');

  # bless({...}, 'Venus::Error')

  # $error->name;

  # "on.handler"

=cut

$test->for('example', 1, 'on', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Error';
  is $result->name, 'on.handler';

  $result
});

=method output

The output method captures the arguments provided as associates them with a
L<"callframe"|perlfunc/caller> based on the level specified by L</offset>, in
the object stash, and returns the invocant.

=signature output

  output(any @args) (Venus::Error)

=metadata output

{
  since => '4.15',
}

=cut

=example-1 output

  # given: synopsis

  package main;

  $error = $error->output(1..4);

  # bless({...}, 'Venus::Error')

=cut

$test->for('example', 1, 'output', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  isa_ok $result, 'Venus::Error';
  ok $result->stash('output');
  ok exists $result->stash('output')->{arguments};
  ok exists $result->stash('output')->{callframe};
  is_deeply $result->stash('output')->{arguments}, [1..4];

  $result
});

=method render

The render method replaces tokens in the message with values from the stash and
returns the formatted string. The token style and formatting operation is
equivalent to the L<Venus::String/render> operation.

=signature render

  render() (string)

=metadata render

{
  since => '3.30',
}

=cut

=example-1 render

  # given: synopsis

  package main;

  $error->message('Signal received: {{signal}}');

  $error->stash(signal => 'SIGKILL');

  my $render = $error->render;

  # "Signal received: SIGKILL"

=cut

$test->for('example', 1, 'render', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Signal received: SIGKILL";

  $result
});

=method reset

The reset method resets the L</offset> and L</verbose> attributes if they're
not already set, resets the L</context> based on the L<caller>, and rebuilds
the stacktrace, then returns the invocant.

=signature reset

  reset() (Venus::Error)

=metadata reset

{
  since => '4.15',
}

=cut

=example-1 reset

  # given: synopsis

  package main;

  my $reset = $error->reset;

  # bless(..., "Venus::Error")

=cut

$test->for('example', 1, 'reset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  ok $result->offset;
  ok $result->verbose;
  ok !!@{$result->frames};

  $result
});

=example-2 reset

  package main;

  use Venus::Error;

  my $error = Venus::Error->new(offset => 0, verbose => 0);

  my $reset = $error->reset;

  # bless(..., "Venus::Error")

=cut

$test->for('example', 2, 'reset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is $result->offset, 0;
  is $result->verbose, 0;
  ok !!@{$result->frames};

  $result
});

=method set

The set method sets one or more attributes and/or methods on the invocant. This
method accepts key/value pairs or a hashref of key/value pairs and returns the
invocant.

=signature set

  set(any @args) (any)

=metadata set

{
  since => '4.15',
}

=cut

=example-1 set

  # given: synopsis

  package main;

  my $set = $error->set(message => 'Oops!');

  # bless(..., "Venus::Error")

=cut

$test->for('example', 1, 'set', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa("Venus::Error");
  is $result->message, 'Oops!';

  $result
});

=example-2 set

  # given: synopsis

  package main;

  my $set = $error->set(message => 'Oops!', verbose => false);

  # bless(..., "Venus::Error")

=cut

$test->for('example', 2, 'set', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa("Venus::Error");
  is $result->message, 'Oops!';
  is $result->verbose, false;

  $result
});

=example-3 set

  # given: synopsis

  package main;

  my $set = $error->set({message => 'Oops!', verbose => false});

  # bless(..., "Venus::Error")

=cut

$test->for('example', 3, 'set', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa("Venus::Error");
  is $result->message, 'Oops!';
  is $result->verbose, false;

  $result
});

=method stash

The stash method gets and sets ad-hoc data related to the invocant.

=signature stash

  stash(string $key, any $value) (any)

=metadata stash

{
  since => '4.15',
}

=cut

=example-1 stash

  # given: synopsis

  package main;

  my $stash = $error->stash;

  # {}

=cut

$test->for('example', 1, 'stash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 stash

  # given: synopsis

  package main;

  my $stash = $error->stash('package');

  # undef

=cut

$test->for('example', 2, 'stash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, undef;

  !$result
});

=example-3 stash

  # given: synopsis

  package main;

  my $stash = $error->stash('package', 'Example');

  # "Example"

=cut

$test->for('example', 3, 'stash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example";

  $result
});

=example-4 stash

  # given: synopsis

  package main;

  $error->stash('package', 'Example');

  my $stash = $error->stash('package');

  # "Example"

=cut

$test->for('example', 4, 'stash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example";

  $result
});

=example-5 stash

  # given: synopsis

  package main;

  my $stash = $error->stash('package', 'Example', routine => 'execute');

  # {
  #   package => "Example",
  #   routine => "execute",
  # }

=cut

$test->for('example', 5, 'stash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    package => "Example",
    routine => "execute",
  };

  $result
});

=example-6 stash

  # given: synopsis

  package main;

  my $stash = $error->stash({'package', 'Example', routine => 'execute'});

  # {
  #   package => "Example",
  #   routine => "execute",
  # }

=cut

$test->for('example', 6, 'stash', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    package => "Example",
    routine => "execute",
  };

  $result
});

=method sysinfo

The sysinfo method calls all the C<system_*> methods and L<"stashes"|/stash>
the system information.

=signature sysinfo

  sysinfo() (Venus::Error)

=metadata sysinfo

{
  since => '4.15',
}

=cut

=example-1 sysinfo

  # given: synopsis

  package main;

  my $sysinfo = $error->sysinfo;

  # bless(..., "Venus::Error")

  # $error->stash('system_name');

  # $^O

  # $error->stash('system_path');

  # /path/to/cwd

  # $error->stash('system_perl_path');

  # $^X

  # $error->stash('system_perl_path');

  # $^X

  # $error->stash('system_perl_version');

  # $^V

  # $error->stash('system_process_id');

  # $$

  # $error->stash('system_script_args');

  # [@ARGV]

  # $error->stash('system_script_path');

  # $0

=cut

$test->for('example', 1, 'sysinfo', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');

  require Cwd;
  is_deeply $result->stash('system_name'), $^O;
  is_deeply $result->stash('system_path'), Cwd->getcwd;
  is_deeply $result->stash('system_perl_path'), $^X;
  is_deeply $result->stash('system_perl_version'), $^V;
  is_deeply $result->stash('system_process_id'), $$;
  is_deeply $result->stash('system_script_args'), [@ARGV];
  is_deeply $result->stash('system_script_path'), $0;

  $result
});

=method system_name

The system_name method L<"stashes"|/stash> a value representing the
I<"system name"> and returns the invocant. If no value is provided this method
will use C<$^O> as the default.

=signature system_name

  system_name(string $value) (Venus::Error)

=metadata system_name

{
  since => '4.15',
}

=cut

=example-1 system_name

  # given: synopsis

  package main;

  my $system_name = $error->system_name;

  # bless(..., "Venus::Error")

  # $error->stash('system_name');

  # $^O

=cut

$test->for('example', 1, 'system_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_name'), $^O;

  $result
});

=example-2 system_name

  # given: synopsis

  package main;

  my $system_name = $error->system_name($^O);

  # bless(..., "Venus::Error")

  # $error->stash('system_name');

  # $^O

=cut

$test->for('example', 2, 'system_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_name'), $^O;

  $result
});

=method system_path

The system_path method L<"stashes"|/stash> a value representing the
I<"system_path"> and returns the invocant. If no value is provided this method
will use C<Cwd/getcwd> as the default.

=signature system_path

  system_path(string $value) (Venus::Error)

=metadata system_path

{
  since => '4.15',
}

=cut

=example-1 system_path

  # given: synopsis

  package main;

  my $system_path = $error->system_path;

  # bless(..., "Venus::Error")

  # $error->stash('system_path');

  # /path/to/cwd

=cut

$test->for('example', 1, 'system_path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');

  require Cwd;
  is_deeply $result->stash('system_path'), Cwd->getcwd;

  $result
});

=example-2 system_path

  # given: synopsis

  package main;

  use Cwd ();

  my $system_path = $error->system_path(Cwd->getcwd);

  # bless(..., "Venus::Error")

  # $error->stash('system_path');

  # /path/to/cwd

=cut

$test->for('example', 2, 'system_path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');

  require Cwd;
  is_deeply $result->stash('system_path'), Cwd->getcwd;

  $result
});

=method system_perl_path

The system_perl_path method L<"stashes"|/stash> a value representing the
I<"system_perl_path"> and returns the invocant. If no value is provided this
method will use C<$^X> as the default.

=signature system_perl_path

  system_perl_path(string $value) (Venus::Error)

=metadata system_perl_path

{
  since => '4.15',
}

=cut

=example-1 system_perl_path

  # given: synopsis

  package main;

  my $system_perl_path = $error->system_perl_path;

  # bless(..., "Venus::Error")

  # $error->stash('system_perl_path');

  # $^X

=cut

$test->for('example', 1, 'system_perl_path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_perl_path'), $^X;

  $result
});

=example-2 system_perl_path

  # given: synopsis

  package main;

  my $system_perl_path = $error->system_perl_path($^X);

  # bless(..., "Venus::Error")

  # $error->stash('system_perl_path');

  # $^X

=cut

$test->for('example', 2, 'system_perl_path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_perl_path'), $^X;

  $result
});

=method system_perl_version

The system_perl_version method L<"stashes"|/stash> a value representing the
I<"system_perl_version"> and returns the invocant. If no value is provided this
method will use C<$^V> as the default.

=signature system_perl_version

  system_perl_version(string $value) (Venus::Error)

=metadata system_perl_version

{
  since => '4.15',
}

=cut

=example-1 system_perl_version

  # given: synopsis

  package main;

  my $system_perl_version = $error->system_perl_version;

  # bless(..., "Venus::Error")

  # $error->stash('system_perl_version');

  # $^V

=cut

$test->for('example', 1, 'system_perl_version', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_perl_version'), $^V;

  $result
});

=example-2 system_perl_version

  # given: synopsis

  package main;

  my $system_perl_version = $error->system_perl_version($^V);

  # bless(..., "Venus::Error")

  # $error->stash('system_perl_version');

  # $^V

=cut

$test->for('example', 2, 'system_perl_version', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_perl_version'), $^V;

  $result
});

=method system_process_id

The system_process_id method L<"stashes"|/stash> a value representing the
I<"system_process_id"> and returns the invocant. If no value is provided this
method will use C<$$> as the default.

=signature system_process_id

  system_process_id(string $value) (Venus::Error)

=metadata system_process_id

{
  since => '4.15',
}

=cut

=example-1 system_process_id

  # given: synopsis

  package main;

  my $system_process_id = $error->system_process_id;

  # bless(..., "Venus::Error")

  # $error->stash('system_process_id');

  # $$

=cut

$test->for('example', 1, 'system_process_id', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_process_id'), $$;

  $result
});

=example-2 system_process_id

  # given: synopsis

  package main;

  my $system_process_id = $error->system_process_id($$);

  # bless(..., "Venus::Error")

  # $error->stash('system_process_id');

  # $$

=cut

$test->for('example', 2, 'system_process_id', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_process_id'), $$;

  $result
});

=method system_script_args

The system_script_args method L<"stashes"|/stash> a value representing the
I<"system"> and returns the invocant. If no value is provided this method will
use C<[@ARGV]> as the default.

=signature system_script_args

  system_script_args(string $value) (Venus::Error)

=metadata system_script_args

{
  since => '4.15',
}

=cut

=example-1 system_script_args

  # given: synopsis

  package main;

  my $system_script_args = $error->system_script_args;

  # bless(..., "Venus::Error")

  # $error->stash('system_script_args');

  # [@ARGV]

=cut

$test->for('example', 1, 'system_script_args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_script_args'), [@ARGV];

  $result
});

=example-2 system_script_args

  # given: synopsis

  package main;

  my $system_script_args = $error->system_script_args(@ARGV);

  # bless(..., "Venus::Error")

  # $error->stash('system_script_args');

  # [@ARGV]

=cut

$test->for('example', 2, 'system_script_args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_script_args'), [@ARGV];

  $result
});

=method system_script_path

The system_script_path method L<"stashes"|/stash> a value representing the
I<"system_script_path"> and returns the invocant. If no value is provided this
method will use C<$0> as the default.

=signature system_script_path

  system_script_path(string $value) (Venus::Error)

=metadata system_script_path

{
  since => '4.15',
}

=cut

=example-1 system_script_path

  # given: synopsis

  package main;

  my $system_script_path = $error->system_script_path;

  # bless(..., "Venus::Error")

  # $error->stash('system_script_path');

  # $0

=cut

$test->for('example', 1, 'system_script_path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_script_path'), $0;

  $result
});

=example-2 system_script_path

  # given: synopsis

  package main;

  my $system_script_path = $error->system_script_path($0);

  # bless(..., "Venus::Error")

  # $error->stash('system_script_path');

  # $0

=cut

$test->for('example', 2, 'system_script_path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  is_deeply $result->stash('system_script_path'), $0;

  $result
});

=method throw

The throw method throws an error if the invocant is an object, or creates an
error object using the arguments provided and throws the created object.

=signature throw

  throw(any @data) (Venus::Error)

=metadata throw

{
  since => '0.01',
}

=example-1 throw

  # given: synopsis;

  my $throw = $error->throw;

  # bless({ ... }, 'Venus::Error')

=cut

$test->for('example', 1, 'throw', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\my $error)->result;
  ok $error->isa('Venus::Error');

  $result
});

=method trace

The trace method compiles a stack trace and returns the object. By default it
skips the first frame.

=signature trace

  trace(number $offset, number $limit) (Venus::Error)

=metadata trace

{
  since => '0.01',
}

=example-1 trace

  # given: synopsis;

  my $trace = $error->trace;

  # bless({ ... }, 'Venus::Error')

=cut

$test->for('example', 1, 'trace', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  ok @{$result->frames} > 0;

  $result
});

=example-2 trace

  # given: synopsis;

  my $trace = $error->trace(0, 1);

  # bless({ ... }, 'Venus::Error')

=cut

$test->for('example', 2, 'trace', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  ok @{$result->frames} == 1;

  $result
});

=example-3 trace

  # given: synopsis;

  my $trace = $error->trace(0, 2);

  # bless({ ... }, 'Venus::Error')

=cut

$test->for('example', 3, 'trace', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');
  ok @{$result->frames} == 2;

  $result
});

=operator (eq)

This package overloads the C<eq> operator.

=cut

$test->for('operator', '(eq)');

=example-1 (eq)

  # given: synopsis;

  my $result = $error eq 'Exception!';

  # 1

=cut

$test->for('example', 1, '(eq)', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=operator (ne)

This package overloads the C<ne> operator.

=cut

$test->for('operator', '(ne)');

=example-1 (ne)

  # given: synopsis;

  my $result = $error ne 'exception!';

  # 1

=cut

$test->for('example', 1, '(ne)', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=operator (qr)

This package overloads the C<qr> operator.

=cut

$test->for('operator', '(qr)');

=example-1 (qr)

  # given: synopsis;

  my $test = 'Exception!' =~ qr/$error/;

  # 1

=cut

$test->for('example', 1, '(qr)', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=operator ("")

This package overloads the C<""> operator.

=cut

$test->for('operator', '("")');

=example-1 ("")

  # given: synopsis;

  my $result = "$error";

  # "Exception!"

=cut

$test->for('example', 1, '("")', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result =~ 'Exception!';

  $result
});

=operator (~~)

This package overloads the C<~~> operator.

=cut

$test->for('operator', '(~~)');

=example-1 (~~)

  # given: synopsis;

  my $result = $error ~~ 'Exception!';

  # 1

=cut

$test->for('example', 1, '(~~)', sub {
  1;
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Error.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;