package Venus::Error;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Encaseable';
with 'Venus::Role::Explainable';

# OVERLOADS

use overload (
  '""' => 'explain',
  'eq' => sub{$_[0]->render eq "$_[1]"},
  'ne' => sub{$_[0]->render ne "$_[1]"},
  'qr' => sub{qr/@{[quotemeta($_[0]->render)]}/},
  '~~' => 'explain',
  fallback => 1,
);

# ATTRIBUTES

attr 'name';
attr 'cause';
attr 'context';
attr 'message';
attr 'offset';
attr 'verbose';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    message => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  if ($data->{name}) {
    $self->name($data->{name});
  }

  if (!$self->context) {
    $self->context('N/A');
  }

  if (!$self->message) {
    $self->message('Exception!');
  }

  if (!exists $data->{verbose}) {
    $self->verbose($ENV{VENUS_ERROR_VERBOSE} // 1);
  }

  if (!exists $data->{offset}) {
    $self->offset($ENV{VENUS_ERROR_TRACE_OFFSET} // 2);
  }

  if (!@{$self->frames}) {
    $self->trace($self->offset);
  }

  if (my $stash = delete $data->{stash}) {
    %{$self->stash} = %{$stash};
  }

  return $self;
}

# METHODS

sub arguments {
  my ($self, $index) = @_;

  my $captured = $self->captured;

  return undef if !$captured;

  my $arguments = $captured->{arguments};

  return $arguments if !defined $index;

  return undef if !$arguments;

  return $arguments->[$index];
}

sub as {
  my ($self, $name) = @_;

  $name = $self->id($name);

  my $method = $self->method('as', $name);

  $self = ref $self ? $self : $self->new;

  return $self->do('name', $name) if !$self->can($method);

  return $self->$method;
}

sub callframe {
  my ($self, $index) = @_;

  my $captured = $self->captured;

  return undef if !$captured;

  my $callframe = $captured->{callframe};

  return $callframe if !defined $index;

  return undef if !$callframe;

  return $callframe->[$index];
}

sub capture {
  my ($self, @args) = @_;

  $self->stash(captured => {
    callframe => [caller($self->offset // 0)],
    arguments => [@args],
  });

  return $self;
}

sub captured {
  my ($self) = @_;

  my $captured = $self->stash->{captured};

  return $captured;
}

sub copy {
  my ($self, $data) = @_;

  if (!$data->isa('Venus::Error')) {
    return $self;
  }

  if ($data->name) {
    $self->name($data->name)
  }

  if ($data->context) {
    $self->context($data->context)
  }

  if ($data->message) {
    $self->message($data->message)
  }

  if (defined $data->verbose) {
    $self->verbose($data->verbose)
  }

  if (@{$data->frames}) {
    $self->recase('frames', $data->frames)
  }

  if (my $stash = $data->stash) {
    %{$self->stash} = (%{$self->stash}, %{$stash});
  }

  return $self;
}

sub explain {
  my ($self) = @_;

  $self->trace(1, 1) if !@{$self->frames};

  my $frames = $self->frames;
  my $message = $self->render;

  my @stacktrace = "$message" =~ s/^\s+|\s+$//gr;

  return join "\n", @stacktrace, "" if !$self->verbose;

  push @stacktrace, 'Name:', $self->name || 'N/A';
  push @stacktrace, 'Type:', ref($self);
  push @stacktrace, 'Context:', $self->context || 'N/A';

  no warnings 'once';

  require Data::Dumper;

  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::Trailingcomma = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Pad = '';
  local $Data::Dumper::Varname = 'VAR';
  local $Data::Dumper::Useqq = 0;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Freezer = '';
  local $Data::Dumper::Toaster = '';
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Bless = 'bless';
  local $Data::Dumper::Pair = ' => ';
  local $Data::Dumper::Maxdepth = 0;
  local $Data::Dumper::Maxrecurse = 1000;
  local $Data::Dumper::Useperl = 0;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sparseseen = 0;

  my $stashed = Data::Dumper->Dump([$self->stash]);

  $stashed =~ s/^'|'$//g;

  chomp $stashed;

  push @stacktrace, 'Stashed:', $stashed;
  push @stacktrace, 'Traceback (reverse chronological order):' if @$frames > 1;

  use warnings 'once';

  @stacktrace = (join("\n\n", grep defined, @stacktrace), '');

  for (my $i = 1; $i < @$frames; $i++) {
    my $pack = $frames->[$i][0];
    my $file = $frames->[$i][1];
    my $line = $frames->[$i][2];
    my $subr = $frames->[$i][3];

    push @stacktrace, "$subr\n  in $file at line $line";
  }

  my $cause = $self->cause;

  if ($cause) {
    $cause = join("\n", "", "Cause:\n", "$cause");
    chomp $cause;
    push @stacktrace, $cause;
  }

  return join "\n", @stacktrace, "";
}

sub frame {
  my ($self, $index) = @_;

  my $frames = $self->frames;

  $index //= 0;

  return {
    package => $frames->[$index][0],
    filename => $frames->[$index][1],
    line => $frames->[$index][2],
    subroutine => $frames->[$index][3],
    hasargs => $frames->[$index][4],
    wantarray => $frames->[$index][5],
    evaltext => $frames->[$index][6],
    is_require => $frames->[$index][7],
    hints => $frames->[$index][8],
    bitmask => $frames->[$index][9],
    hinthash => $frames->[$index][10],
  };
}

sub frames {
  my ($self) = @_;

  return $self->encase('frames', []);
}

sub get {
  my ($self, @args) = @_;

  @args = map $self->$_, @args;

  return wantarray ? (@args) : $args[0];
}

sub id {
  my ($self, @args) = @_;

  my $name = join '.', grep defined, @args;

  $name = lc $name =~ s/\W+/./gr if $name;

  return $name;
}

sub input {
  my ($self, @args) = @_;

  $self->stash(input => {
    callframe => [caller($self->offset // 0)],
    arguments => [@args],
  });

  return $self;
}

sub is {
  my ($self, $name) = @_;

  $name = $self->id($name);

  my $method = $self->method('is', $name);

  return false if !$self->name && !$self->can($method);

  return $self->name eq $name ? true : false if $self->name && !$self->can($method);

  return (ref $self ? $self: $self->new)->$method ? true : false;
}

sub label {
  my ($self, $name) = @_;

  $name = lc $name =~ s/\W/_/gr if $name;

  return $name;
}

sub method {
  my ($self, @name) = @_;

  @name = map {lc s/\W/_/gr} @name;

  return join '_', @name;
}

sub name {
  my ($self, $name) = @_;

  return $self->ITEM('name', defined $name ? $self->id($name) || () : ());
}

sub of {
  my ($self, $name) = @_;

  $name = $self->id($name);

  my $method = $self->method('of', $name);

  return false if !$self->name && !$self->can($method);

  return $self->name =~ /$name/ ? true : false if $self->name && !$self->can($method);

  return (ref $self ? $self: $self->new)->$method ? true : false;
}

sub on {
  my ($self, $name) = @_;

  $self = ref $self ? $self : $self->new;

  $name ||= (split(/::/, (caller($self->offset // 0))[3]))[-1];

  $self->name($self->id('on', $name)) if $name && $name ne '__ANON__' && $name ne '(eval)';

  return $self;
}

sub output {
  my ($self, @args) = @_;

  $self->stash(output => {
    callframe => [caller($self->offset // 0)],
    arguments => [@args],
  });

  return $self;
}

sub render {
  my ($self) = @_;

  my $message = $self->message;
  my $stashed = $self->stash;

  while (my($key, $value) = each(%$stashed)) {
    next if !defined $value;
    my $token = quotemeta $key;
    $message =~ s/\{\{\s*$token\s*\}\}/$value/g;
  }

  return $message;
}

sub reset {
  my ($self) = @_;

  $self->verbose($ENV{VENUS_ERROR_VERBOSE} // 1) if !defined $self->verbose;

  $self->offset($ENV{VENUS_ERROR_TRACE_OFFSET} // 1) if !defined $self->offset;

  $self->context((caller(($self->offset // 0) + 1))[3]);

  $self->trace(($self->offset // 0) + 1);

  return $self;
}

sub set {
  my ($self, @args) = @_;

  if (@args > 2 && not @args % 2) {
    my %data = @args;

    $self->$_($data{$_}) for keys %data;

    return $self;
  }

  if (@args > 0 && ref $args[0] eq 'HASH') {
    my %data = %{$args[0]};

    $self->$_($data{$_}) for keys %data;

    return $self;
  }

  my ($key, @value) = @args;

  $self->$key(@value);

  return $self;
}

sub stash {
  my ($self, @args) = @_;

  if (@args > 2 && not @args % 2) {
    my %data = @args;

    $self->stash($_, $data{$_}) for keys %data;

    return $self->stash;
  }

  if (@args > 0 && ref $args[0] eq 'HASH') {
    my %data = %{$args[0]};

    if (!%data) {
      return $self->recase('stashed', {});
    }

    $self->stash($_, $data{$_}) for keys %data;

    return $self->stash;
  }

  my ($key, @value) = @args;

  my $stashed = $self->encase('stashed', {});

  return $stashed if !defined $key;

  return $stashed->{$key} if !@value;

  my $value = $stashed->{$key} = $value[0];

  return $value;
}

sub sysinfo {
  my ($self) = @_;

  $self->system_name;
  $self->system_path;
  $self->system_perl_path;
  $self->system_perl_version;
  $self->system_process_id;
  $self->system_script_args;
  $self->system_script_path;

  return $self;
}

sub system_name {
  my ($self, @args) = @_;

  $self->stash('system_name', @args ? $args[0] : $^O);

  return $self;
}

sub system_path {
  my ($self, @args) = @_;

  require Cwd;

  $self->stash('system_path', @args ? $args[0] : Cwd->getcwd);

  return $self;
}

sub system_perl_path {
  my ($self, @args) = @_;

  $self->stash('system_perl_path', @args ? $args[0] : $^X);

  return $self;
}

sub system_perl_version {
  my ($self, @args) = @_;

  $self->stash('system_perl_version', @args ? $args[0] : "$^V");

  return $self;
}

sub system_process_id {
  my ($self, @args) = @_;

  $self->stash('system_process_id', @args ? $args[0] : $$);

  return $self;
}

sub system_script_args {
  my ($self, @args) = @_;

  $self->stash('system_script_args', @args ? [@args] : [@ARGV]);

  return $self;
}

sub system_script_path {
  my ($self, @args) = @_;

  $self->stash('system_script_path', @args ? $args[0] : $0);

  return $self;
}

sub trace {
  my ($self, $offset, $limit) = @_;

  my $frames = $self->frames;

  @$frames = ();

  for (my $i = $offset // $self->offset; my @caller = caller($i); $i++) {
    push @$frames, [@caller];

    last if defined $limit && $i + 1 == $offset + $limit;
  }

  return $self;
}

sub throw {
  my ($self, @args) = @_;

  $self = $self->new(@args) if !ref $self;

  die $self;
}

1;



=head1 NAME

Venus::Error - Error Class

=cut

=head1 ABSTRACT

Error Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Error;

  my $error = Venus::Error->new;

  # $error->throw;

=cut

=head1 DESCRIPTION

This package represents a context-aware error (exception object). The default
for error verbosity can be controlled via the C<VENUS_ERROR_VERBOSE>
environment variable, e.g. a setting of C<0> disables stack traces. The default
trace-offset can be controlled via the C<VENUS_ERROR_TRACE_OFFSET> environment
variable, e.g. a setting of C<0> indicates no offset.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 name

  name(string $name) (string)

The name attribute is read-write, accepts C<string> values, and is optional.

I<Since C<0.01>>

=over 4

=item name example 1

  # given: synopsis

  package main;

  my $set_name = $error->name("on.save");

  # "on.save"

=back

=over 4

=item name example 2

  # given: synopsis

  # given: example-1 name

  package main;

  my $get_name = $error->name;

  # "on.save"

=back

=cut

=head2 cause

  cause(Venus::Error $error) (Venus::Error)

The cause attribute is read-write, accepts C<Venus::Error> values, and is
optional.

I<Since C<4.15>>

=over 4

=item cause example 1

  # given: synopsis

  package main;

  my $set_cause = $error->cause(Venus::Error->new);

  # bless(..., "Venus::Error")

=back

=over 4

=item cause example 2

  # given: synopsis

  # given: example-1 cause

  package main;

  my $get_cause = $error->cause;

  # bless(..., "Venus::Error")

=back

=cut

=head2 context

  context(string $context) (string)

The context attribute is read-write, accepts C<string> values, and is optional.
Defaults to C<'N/A'>.

I<Since C<0.01>>

=over 4

=item context example 1

  # given: synopsis

  package main;

  my $set_context = $error->context("main::main");

  # "main::main"

=back

=over 4

=item context example 2

  # given: synopsis

  # given: example-1 context

  package main;

  my $get_context = $error->context;

  # "main::main"

=back

=cut

=head2 message

  message(string $message) (string)

The message attribute is read-write, accepts C<string> values, and is optional.
Defaults to C<'Exception!'>.

I<Since C<0.01>>

=over 4

=item message example 1

  # given: synopsis

  package main;

  my $set_message = $error->message("Exception!");

  # "Exception!"

=back

=over 4

=item message example 2

  # given: synopsis

  # given: example-1 message

  package main;

  my $get_message = $error->message;

  # "Exception!"

=back

=cut

=head2 verbose

  verbose(number $verbose) (number)

The verbose attribute is read-write, accepts C<number> values, and is optional.
Defaults to C<true>.

I<Since C<0.01>>

=over 4

=item verbose example 1

  # given: synopsis

  package main;

  my $set_verbose = $error->verbose(true);

  # true

=back

=over 4

=item verbose example 2

  # given: synopsis

  # given: example-1 verbose

  package main;

  my $get_verbose = $error->verbose;

  # true

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Explainable>

L<Venus::Role::Encaseable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 arguments

  arguments(number $index) (any)

The arguments method returns the stashed arguments under L</captured>, or a
specific argument if an index is provided.

I<Since C<2.55>>

=over 4

=item arguments example 1

  # given: synopsis

  my $arguments = $error->arguments;

  # undef

=back

=over 4

=item arguments example 2

  package main;

  use Venus::Error;

  my $error = Venus::Error->new->capture(1..4);

  my $arguments = $error->arguments;

  # [1..4]

=back

=over 4

=item arguments example 3

  package main;

  use Venus::Error;

  my $error = Venus::Error->new->capture(1..4);

  my $arguments = $error->arguments(0);

  # 1

=back

=cut

=head2 as

  as(string $name) (Venus::Error)

The as method returns an error object using the return value(s) of the "as"
method specified, which should be defined as C<"as_${name}">, which will be
called automatically by this method. If no C<"as_${name}"> method exists, this
method will set the L</name> attribute to the value provided.

I<Since C<1.02>>

=over 4

=item as example 1

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

=back

=over 4

=item as example 2

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

=back

=over 4

=item as example 3

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $error = Virtual::Error->new->as('on_save_error');

  $error->throw;

  # name is "on_save_error"

  # Exception! (isa Venus::Error)

=back

=over 4

=item as example 4

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $error = Virtual::Error->new->as('on.SAVE.error');

  $error->throw;

  # name is "on_save_error"

  # Exception! (isa Venus::Error)

=back

=cut

=head2 callframe

  callframe(number $index) (any)

The callframe method returns the stashed callframe under L</captured>, or a
specific argument if an index is provided.

I<Since C<2.55>>

=over 4

=item callframe example 1

  # given: synopsis

  my $callframe = $error->callframe;

  # undef

=back

=over 4

=item callframe example 2

  package main;

  use Venus::Error;

  my $error = Venus::Error->new->do('offset', 0)->capture;

  my $callframe = $error->callframe;

  # [...]

=back

=over 4

=item callframe example 3

  package main;

  use Venus::Error;

  my $error = Venus::Error->new->do('offset', 0)->capture;

  my $package = $error->callframe(0);

  # 'main'

=back

=cut

=head2 capture

  capture(any @args) (Venus::Error)

The capture method captures the L<caller> info at the L</frame> specified, in
the object stash, and returns the invocant.

I<Since C<4.15>>

=over 4

=item capture example 1

  # given: synopsis

  package main;

  $error = $error->capture;

  # bless({...}, 'Venus::Error')

=back

=cut

=head2 captured

  captured() (hashref)

The captured method returns the value stashed as C<"captured">.

I<Since C<2.55>>

=over 4

=item captured example 1

  # given: synopsis

  my $captured = $error->captured;

  # undef

=back

=cut

=head2 copy

  copy(Venus::Error $error) (Venus::Error)

The copy method copied the properties of the L<Venus::Error> provided into the
invocant and returns the invocant.

I<Since C<4.15>>

=over 4

=item copy example 1

  # given: synopsis

  package main;

  my $oops = Venus::Error->as('on.oops');

  my $copy = $error->copy($oops);

  # bless({ ... }, 'Venus::Error')

  # $error->name;

  # "on.oops"

=back

=over 4

=item copy example 2

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

=back

=cut

=head2 explain

  explain() (string)

The explain method returns the error message and is used in stringification
operations.

I<Since C<0.01>>

=over 4

=item explain example 1

  # given: synopsis;

  $error->verbose(0);

  my $explain = $error->explain;

  # "Exception!" in ...

=back

=over 4

=item explain example 2

  # given: synopsis;

  $error->verbose(1);

  my $explain = $error->explain;

  # "Exception!" in ...

=back

=over 4

=item explain example 3

  # given: synopsis;

  $error->name('on.save.error');

  $error->verbose(1);

  my $explain = $error->explain;

  # "Exception!" in ...

=back

=over 4

=item explain example 4

  # given: synopsis;

  $error->name('on.save.error');

  $error->stash('what', 'Unknown');

  $error->verbose(1);

  my $explain = $error->explain;

  # "Exception!" in ...

=back

=over 4

=item explain example 5

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

=back

=cut

=head2 frame

  frame(number $index) (hashref)

The frame method returns the data from C<caller> on the frames captured, and
returns a hashref where the keys map to the keys described by
L<perlfunc/caller>.

I<Since C<1.11>>

=over 4

=item frame example 1

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

=back

=over 4

=item frame example 2

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

=back

=cut

=head2 frames

  frames() (arrayref)

The frames method returns the compiled and stashed stack trace data.

I<Since C<0.01>>

=over 4

=item frames example 1

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

=back

=cut

=head2 get

  get(string @args) (any)

The get method takes one or more attribute and/or method names and returns the
result of calling each attribute and/or method. In scalar context returns a
single value. In list context results a list of values.

I<Since C<4.15>>

=over 4

=item get example 1

  # given: synopsis

  package main;

  my $get = $error->get('verbose');

  # true

=back

=over 4

=item get example 2

  # given: synopsis

  package main;

  my $get = $error->get('verbose', 'context');

  # true

=back

=over 4

=item get example 3

  # given: synopsis

  package main;

  my @get = $error->get('verbose', 'message');

  # (true, 'Exception!')

=back

=cut

=head2 input

  input(any @args) (Venus::Error)

The input method captures the arguments provided as associates them with a
L<"callframe"|perlfunc/caller> based on the level specified by L</offset>, in
the object stash, and returns the invocant.

I<Since C<4.15>>

=over 4

=item input example 1

  # given: synopsis

  package main;

  $error = $error->input(1..4);

  # bless({...}, 'Venus::Error')

=back

=cut

=head2 is

  is(string $name) (boolean)

The is method returns truthy or falsy based on the return value(s) of the "is"
method specified, which should be defined as C<"is_${name}">, which will be
called automatically by this method. If no C<"is_${name}"> method exists, this
method will check if the L</name> attribute is equal to the value provided.

I<Since C<1.02>>

=over 4

=item is example 1

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

=back

=over 4

=item is example 2

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

=back

=over 4

=item is example 3

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

=back

=over 4

=item is example 4

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $is = Virtual::Error->new->as('on_save_error')->is('on_save_error');

  # 1

=back

=over 4

=item is example 5

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $is = Virtual::Error->new->as('on.SAVE.error')->is('on.save.error');

  # 1

=back

=cut

=head2 new

  new(any @args) (Venus::Error)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Error;

  my $new = Venus::Error->new;

  # bless(..., "Venus::Error")

=back

=over 4

=item new example 2

  package main;

  use Venus::Error;

  my $new = Venus::Error->new('Oops!');

  # bless(..., "Venus::Error")

=back

=over 4

=item new example 3

  package main;

  use Venus::Error;

  my $new = Venus::Error->new(message => 'Oops!');

  # bless(..., "Venus::Error")

=back

=cut

=head2 of

  of(string $name) (boolean)

The of method returns truthy or falsy based on the return value(s) of the "of"
method specified, which should be defined as C<"of_${name}">, which will be
called automatically by this method. If no C<"of_${name}"> method exists, this
method will check if the L</name> attribute contains the value provided.

I<Since C<1.11>>

=over 4

=item of example 1

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

=back

=over 4

=item of example 2

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

=back

=over 4

=item of example 3

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

=back

=over 4

=item of example 4

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $of = Virtual::Error->new->as('on_save_error')->of('on.save');

  # 1

=back

=over 4

=item of example 5

  package Virtual::Error;

  use Venus::Class;

  base 'Venus::Error';

  package main;

  my $of = Virtual::Error->new->as('on.SAVE.error')->of('on.save');

  # 1

=back

=cut

=head2 on

  on(string $name) (Venus::Error)

The on method sets a L</name> for the error in the form of
C<"on.$subroutine.$name"> or C<"on.$name"> (if outside of a subroutine) and
returns the invocant.

I<Since C<4.15>>

=over 4

=item on example 1

  # given: synopsis

  package main;

  $error = $error->on('handler');

  # bless({...}, 'Venus::Error')

  # $error->name;

  # "on.handler"

=back

=cut

=head2 output

  output(any @args) (Venus::Error)

The output method captures the arguments provided as associates them with a
L<"callframe"|perlfunc/caller> based on the level specified by L</offset>, in
the object stash, and returns the invocant.

I<Since C<4.15>>

=over 4

=item output example 1

  # given: synopsis

  package main;

  $error = $error->output(1..4);

  # bless({...}, 'Venus::Error')

=back

=cut

=head2 render

  render() (string)

The render method replaces tokens in the message with values from the stash and
returns the formatted string. The token style and formatting operation is
equivalent to the L<Venus::String/render> operation.

I<Since C<3.30>>

=over 4

=item render example 1

  # given: synopsis

  package main;

  $error->message('Signal received: {{signal}}');

  $error->stash(signal => 'SIGKILL');

  my $render = $error->render;

  # "Signal received: SIGKILL"

=back

=cut

=head2 reset

  reset() (Venus::Error)

The reset method resets the L</offset> and L</verbose> attributes if they're
not already set, resets the L</context> based on the L<caller>, and rebuilds
the stacktrace, then returns the invocant.

I<Since C<4.15>>

=over 4

=item reset example 1

  # given: synopsis

  package main;

  my $reset = $error->reset;

  # bless(..., "Venus::Error")

=back

=over 4

=item reset example 2

  package main;

  use Venus::Error;

  my $error = Venus::Error->new(offset => 0, verbose => 0);

  my $reset = $error->reset;

  # bless(..., "Venus::Error")

=back

=cut

=head2 set

  set(any @args) (any)

The set method sets one or more attributes and/or methods on the invocant. This
method accepts key/value pairs or a hashref of key/value pairs and returns the
invocant.

I<Since C<4.15>>

=over 4

=item set example 1

  # given: synopsis

  package main;

  my $set = $error->set(message => 'Oops!');

  # bless(..., "Venus::Error")

=back

=over 4

=item set example 2

  # given: synopsis

  package main;

  my $set = $error->set(message => 'Oops!', verbose => false);

  # bless(..., "Venus::Error")

=back

=over 4

=item set example 3

  # given: synopsis

  package main;

  my $set = $error->set({message => 'Oops!', verbose => false});

  # bless(..., "Venus::Error")

=back

=cut

=head2 stash

  stash(string $key, any $value) (any)

The stash method gets and sets ad-hoc data related to the invocant.

I<Since C<4.15>>

=over 4

=item stash example 1

  # given: synopsis

  package main;

  my $stash = $error->stash;

  # {}

=back

=over 4

=item stash example 2

  # given: synopsis

  package main;

  my $stash = $error->stash('package');

  # undef

=back

=over 4

=item stash example 3

  # given: synopsis

  package main;

  my $stash = $error->stash('package', 'Example');

  # "Example"

=back

=over 4

=item stash example 4

  # given: synopsis

  package main;

  $error->stash('package', 'Example');

  my $stash = $error->stash('package');

  # "Example"

=back

=over 4

=item stash example 5

  # given: synopsis

  package main;

  my $stash = $error->stash('package', 'Example', routine => 'execute');

  # {
  #   package => "Example",
  #   routine => "execute",
  # }

=back

=over 4

=item stash example 6

  # given: synopsis

  package main;

  my $stash = $error->stash({'package', 'Example', routine => 'execute'});

  # {
  #   package => "Example",
  #   routine => "execute",
  # }

=back

=cut

=head2 sysinfo

  sysinfo() (Venus::Error)

The sysinfo method calls all the C<system_*> methods and L<"stashes"|/stash>
the system information.

I<Since C<4.15>>

=over 4

=item sysinfo example 1

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

=back

=cut

=head2 system_name

  system_name(string $value) (Venus::Error)

The system_name method L<"stashes"|/stash> a value representing the
I<"system name"> and returns the invocant. If no value is provided this method
will use C<$^O> as the default.

I<Since C<4.15>>

=over 4

=item system_name example 1

  # given: synopsis

  package main;

  my $system_name = $error->system_name;

  # bless(..., "Venus::Error")

  # $error->stash('system_name');

  # $^O

=back

=over 4

=item system_name example 2

  # given: synopsis

  package main;

  my $system_name = $error->system_name($^O);

  # bless(..., "Venus::Error")

  # $error->stash('system_name');

  # $^O

=back

=cut

=head2 system_path

  system_path(string $value) (Venus::Error)

The system_path method L<"stashes"|/stash> a value representing the
I<"system_path"> and returns the invocant. If no value is provided this method
will use C<Cwd/getcwd> as the default.

I<Since C<4.15>>

=over 4

=item system_path example 1

  # given: synopsis

  package main;

  my $system_path = $error->system_path;

  # bless(..., "Venus::Error")

  # $error->stash('system_path');

  # /path/to/cwd

=back

=over 4

=item system_path example 2

  # given: synopsis

  package main;

  use Cwd ();

  my $system_path = $error->system_path(Cwd->getcwd);

  # bless(..., "Venus::Error")

  # $error->stash('system_path');

  # /path/to/cwd

=back

=cut

=head2 system_perl_path

  system_perl_path(string $value) (Venus::Error)

The system_perl_path method L<"stashes"|/stash> a value representing the
I<"system_perl_path"> and returns the invocant. If no value is provided this
method will use C<$^X> as the default.

I<Since C<4.15>>

=over 4

=item system_perl_path example 1

  # given: synopsis

  package main;

  my $system_perl_path = $error->system_perl_path;

  # bless(..., "Venus::Error")

  # $error->stash('system_perl_path');

  # $^X

=back

=over 4

=item system_perl_path example 2

  # given: synopsis

  package main;

  my $system_perl_path = $error->system_perl_path($^X);

  # bless(..., "Venus::Error")

  # $error->stash('system_perl_path');

  # $^X

=back

=cut

=head2 system_perl_version

  system_perl_version(string $value) (Venus::Error)

The system_perl_version method L<"stashes"|/stash> a value representing the
I<"system_perl_version"> and returns the invocant. If no value is provided this
method will use C<$^V> as the default.

I<Since C<4.15>>

=over 4

=item system_perl_version example 1

  # given: synopsis

  package main;

  my $system_perl_version = $error->system_perl_version;

  # bless(..., "Venus::Error")

  # $error->stash('system_perl_version');

  # $^V

=back

=over 4

=item system_perl_version example 2

  # given: synopsis

  package main;

  my $system_perl_version = $error->system_perl_version($^V);

  # bless(..., "Venus::Error")

  # $error->stash('system_perl_version');

  # $^V

=back

=cut

=head2 system_process_id

  system_process_id(string $value) (Venus::Error)

The system_process_id method L<"stashes"|/stash> a value representing the
I<"system_process_id"> and returns the invocant. If no value is provided this
method will use C<$$> as the default.

I<Since C<4.15>>

=over 4

=item system_process_id example 1

  # given: synopsis

  package main;

  my $system_process_id = $error->system_process_id;

  # bless(..., "Venus::Error")

  # $error->stash('system_process_id');

  # $$

=back

=over 4

=item system_process_id example 2

  # given: synopsis

  package main;

  my $system_process_id = $error->system_process_id($$);

  # bless(..., "Venus::Error")

  # $error->stash('system_process_id');

  # $$

=back

=cut

=head2 system_script_args

  system_script_args(string $value) (Venus::Error)

The system_script_args method L<"stashes"|/stash> a value representing the
I<"system"> and returns the invocant. If no value is provided this method will
use C<[@ARGV]> as the default.

I<Since C<4.15>>

=over 4

=item system_script_args example 1

  # given: synopsis

  package main;

  my $system_script_args = $error->system_script_args;

  # bless(..., "Venus::Error")

  # $error->stash('system_script_args');

  # [@ARGV]

=back

=over 4

=item system_script_args example 2

  # given: synopsis

  package main;

  my $system_script_args = $error->system_script_args(@ARGV);

  # bless(..., "Venus::Error")

  # $error->stash('system_script_args');

  # [@ARGV]

=back

=cut

=head2 system_script_path

  system_script_path(string $value) (Venus::Error)

The system_script_path method L<"stashes"|/stash> a value representing the
I<"system_script_path"> and returns the invocant. If no value is provided this
method will use C<$0> as the default.

I<Since C<4.15>>

=over 4

=item system_script_path example 1

  # given: synopsis

  package main;

  my $system_script_path = $error->system_script_path;

  # bless(..., "Venus::Error")

  # $error->stash('system_script_path');

  # $0

=back

=over 4

=item system_script_path example 2

  # given: synopsis

  package main;

  my $system_script_path = $error->system_script_path($0);

  # bless(..., "Venus::Error")

  # $error->stash('system_script_path');

  # $0

=back

=cut

=head2 throw

  throw(any @data) (Venus::Error)

The throw method throws an error if the invocant is an object, or creates an
error object using the arguments provided and throws the created object.

I<Since C<0.01>>

=over 4

=item throw example 1

  # given: synopsis;

  my $throw = $error->throw;

  # bless({ ... }, 'Venus::Error')

=back

=cut

=head2 trace

  trace(number $offset, number $limit) (Venus::Error)

The trace method compiles a stack trace and returns the object. By default it
skips the first frame.

I<Since C<0.01>>

=over 4

=item trace example 1

  # given: synopsis;

  my $trace = $error->trace;

  # bless({ ... }, 'Venus::Error')

=back

=over 4

=item trace example 2

  # given: synopsis;

  my $trace = $error->trace(0, 1);

  # bless({ ... }, 'Venus::Error')

=back

=over 4

=item trace example 3

  # given: synopsis;

  my $trace = $error->trace(0, 2);

  # bless({ ... }, 'Venus::Error')

=back

=cut

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  # given: synopsis;

  my $result = "$error";

  # "Exception!"

=back

=over 4

=item operation: C<(eq)>

This package overloads the C<eq> operator.

B<example 1>

  # given: synopsis;

  my $result = $error eq 'Exception!';

  # 1

=back

=over 4

=item operation: C<(ne)>

This package overloads the C<ne> operator.

B<example 1>

  # given: synopsis;

  my $result = $error ne 'exception!';

  # 1

=back

=over 4

=item operation: C<(qr)>

This package overloads the C<qr> operator.

B<example 1>

  # given: synopsis;

  my $test = 'Exception!' =~ qr/$error/;

  # 1

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  # given: synopsis;

  my $result = $error ~~ 'Exception!';

  # 1

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut