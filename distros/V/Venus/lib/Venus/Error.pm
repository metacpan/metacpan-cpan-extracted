package Venus::Error;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Explainable';
with 'Venus::Role::Stashable';

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
attr 'context';
attr 'message';
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

  $self->name($data->{name}) if $self->name;
  $self->context('(None)') if !$self->context;
  $self->message('Exception!') if !$self->message;
  $self->verbose($ENV{VENUS_ERROR_VERBOSE} // 1) if !exists $data->{verbose};
  $self->trace($ENV{VENUS_ERROR_TRACE_OFFSET} // 2) if !@{$self->frames};

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

  my $method = "as_${name}";

  $self = ref $self ? $self : $self->new;

  if (!$self->can($method)) {
    return $self->do('name', $name);
  }

  return $self->$method;
}

sub assertion {
  my ($self) = @_;

  my $assertion = $self->SUPER::assertion;

  $assertion->match('string')->format(sub{
    (ref $self || $self)->new($_)
  });

  return $assertion;
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

sub captured {
  my ($self) = @_;

  return $self->stash('captured');
}

sub id {
  my ($self, $name) = @_;

  $name = lc $name =~ s/\W+/_/gr if $name;

  return $name;
}

sub explain {
  my ($self) = @_;

  $self->trace(1, 1) if !@{$self->frames};

  my $frames = $self->{'$frames'};
  my $message = $self->render;

  my @stacktrace = "$message" =~ s/^\s+|\s+$//gr;

  return join "\n", @stacktrace, "" if !$self->verbose;

  push @stacktrace, 'Name:', $self->name || '(None)';
  push @stacktrace, 'Type:', ref($self);
  push @stacktrace, 'Context:', $self->context || '(None)';

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

  return join "\n", @stacktrace, "";
}

sub frames {
  my ($self) = @_;

  return $self->{'$frames'} //= [];
}

sub is {
  my ($self, $name) = @_;

  $name = $self->id($name);

  my $method = "is_${name}";

  if ($self->name && !$self->can($method)) {
    return $self->name eq $name ? true : false;
  }

  return (ref $self ? $self: $self->new)->$method ? true : false;
}

sub name {
  my ($self, $name) = @_;

  return $self->ITEM('name', $self->id($name) // ());
}

sub of {
  my ($self, $name) = @_;

  $name = $self->id($name);

  my $method = "of_${name}";

  if ($self->name && !$self->can($method)) {
    return $self->name =~ /$name/ ? true : false;
  }

  return (ref $self ? $self: $self->new)->$method ? true : false;
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

sub render {
  my ($self) = @_;

  my $message = $self->message;
  my $stashed = $self->stash;

  while (my($key, $value) = each(%$stashed)) {
    my $token = quotemeta $key;
    $message =~ s/\{\{\s*$token\s*\}\}/$value/g;
  }

  return $message;
}

sub throw {
  my ($self, @args) = @_;

  $self = $self->new(@args) if !ref $self;

  die $self;
}

sub trace {
  my ($self, $offset, $limit) = @_;

  my $frames = $self->frames;

  @$frames = ();

  for (my $i = $offset // 1; my @caller = caller($i); $i++) {
    push @$frames, [@caller];

    last if defined $limit && $i + 1 == $offset + $limit;
  }

  return $self;
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

  name(Str)

This attribute is read-write, accepts C<(Str)> values, and is optional.

=cut

=head2 context

  context(Str)

This attribute is read-write, accepts C<(Str)> values, is optional, and defaults to C<'(None)'>.

=cut

=head2 message

  message(Str)

This attribute is read-write, accepts C<(Str)> values, is optional, and defaults to C<'Exception!'>.

=cut

=head2 verbose

  verbose(Int)

This attribute is read-write, accepts C<(Int)> values, is optional, and defaults to C<1>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Explainable>

L<Venus::Role::Stashable>

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

  use Venus::Throw;

  my $error = Venus::Throw->new->capture(1..4)->catch('error');

  my $arguments = $error->arguments;

  # [1..4]

=back

=over 4

=item arguments example 3

  package main;

  use Venus::Throw;

  my $error = Venus::Throw->new->capture(1..4)->catch('error');

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

  use Venus::Throw;

  my $error = Venus::Throw->new->do('frame', 0)->capture->catch('error');

  my $callframe = $error->callframe;

  # [...]

=back

=over 4

=item callframe example 3

  package main;

  use Venus::Throw;

  my $error = Venus::Throw->new->do('frame', 0)->capture->catch('error');

  my $package = $error->callframe(0);

  # 'main'

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

=head2 explain

  explain() (string)

The explain method returns the error message and is used in stringification
operations.

I<Since C<0.01>>

=over 4

=item explain example 1

  # given: synopsis;

  my $explain = $error->explain;

  # "Exception! in ...

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

  my $is = Virtual::Error->new->as('on.SAVE.error')->is('on_save_error');

  # 1

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