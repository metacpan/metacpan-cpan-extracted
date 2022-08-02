package Venus::Error;

use 5.018;

use strict;
use warnings;

use Venus::Class;

base 'Venus::Kind::Utility';

with 'Venus::Role::Explainable';
with 'Venus::Role::Stashable';

use overload (
  '""' => 'explain',
  '.' => sub{$_[0]->message . "$_[1]"},
  'eq' => sub{$_[0]->message eq "$_[1]"},
  'ne' => sub{$_[0]->message ne "$_[1]"},
  'qr' => sub{qr/@{[quotemeta($_[0]->message)]}/},
  '~~' => 'explain',
  fallback => 1,
);

# ATTRIBUTES

attr 'context';
attr 'message';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    message => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  $self->context('(None)') if !$self->context;
  $self->message('Exception!') if !$self->message;
  $self->trace(2) if !@{$self->frames};

  return $self;
}

# METHODS

sub explain {
  my ($self) = @_;

  $self->trace(1, 1) if !@{$self->{'$frames'}};

  my $frames = $self->{'$frames'};

  my $file = $frames->[0][1];
  my $line = $frames->[0][2];
  my $pack = $frames->[0][0];
  my $subr = $frames->[0][3];

  my $message = $self->message;

  my @stacktrace = ("$message in $file at line $line");

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

This package represents a context-aware error (exception object).

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 context

  context(Str)

This attribute is read-write, accepts C<(Str)> values, is optional, and defaults to C<'(None)'>.

=cut

=head2 message

  message(Str)

This attribute is read-write, accepts C<(Str)> values, is optional, and defaults to C<'Exception!'>.

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

=head2 explain

  explain() (Str)

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

=head2 frames

  frames() (ArrayRef)

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

=head2 throw

  throw(Any @data) (Error)

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

  trace(Int $offset, Int $limit) (Error)

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

=item operation: C<(.)>

This package overloads the C<.> operator.

B<example 1>

  # given: synopsis;

  my $string = $error . ' Unknown';

  # "Exception! Unknown"

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

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  # given: synopsis;

  my $result = "$error";

  # "Exception!"

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  # given: synopsis;

  my $result = $error ~~ 'Exception!';

  # 1

=back