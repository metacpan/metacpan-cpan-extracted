package Test::Given::Context;
use strict;
use warnings;

BEGIN {
  require Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT_OK = qw(define_var);
}

use Test::Given::Check;
use Test::Given::Aspect;
use Test::Given::Builder;
my $TEST_CLASS = 'Test::Given::Builder';

sub new {
  my ($class, $description, $parent) = @_;
  bless {
    description => $description,
    parent      => $parent,
  }, $class;
}

sub add_context {
  my ($self, $description) = @_;
  my $subcontext = Test::Given::Context->new($description, $self);
  push @{ $self->{contexts} }, $subcontext;
  return $subcontext;
}

sub parent { shift->{parent} }

sub add_given     { shift->_add('givens',     _with_package(@_)) }
sub add_when      { shift->_add('whens',      _with_package(@_)) }
sub add_invariant { shift->_add('invariants', _with_package(@_)) }
sub add_done      { shift->_add('dones',      _with_package(@_)) }

sub add_then {
  my $self = shift;
  $self->_add('thens', @_);
}

sub add_and {
  my ($self) = shift;
  my $and_type = $self->{and_type};

  die "'And' requires previous Given, When, Invariant, Then, or onDone clause in current context\n" unless $and_type;

  if ( $and_type eq 'thens' ) {
    my $then_parent = ${ $self->{thens} }[$#{ $self->{thens} }];
    $then_parent->add_check(@_);
  }
  else {
    $self->_add($and_type, _with_package(@_));
  }
}

sub _with_package {
  if (@_ > 1) {
    unshift @_, (caller(2))[0];
    return reverse(@_);
  }
  return @_;
}

my %class_lu = (
  contexts =>   'Test::Given::Context',
  givens =>     'Test::Given::Given',
  whens =>      'Test::Given::When',
  invariants => 'Test::Given::Invariant',
  thens =>      'Test::Given::Test',
  dones =>      'Test::Given::Done',
);
sub _add {
  my ($self, $type, @args) = @_;
  $self->{and_type} = $type;
  my $class = $class_lu{$type};
  push @{ $self->{$type} }, $class->new(@args);
}

sub run_tests {
  my ($self, $indent) = @_;
  $indent ||= '';

  my $tb = $TEST_CLASS->builder;
  $tb->note($indent . $self->{description}) if $self->{parent};

  if ( !$self->{thens} && !_okay_to_have_no_tests($self) ) {
    warn "No 'Then' or 'Invariant' clauses in context: $self->{description}\n";
  }
  else {
    foreach my $then (@{ $self->{thens} }) {
      $then->execute($self);
    }
  }

  if ( $self->{contexts} ) {
    foreach my $context (@{ $self->{contexts} }) {
      $context->run_tests($indent . '* ');
    }
  }

  $self->apply_dones();
}

sub apply_givens {
  my ($self) = @_;
  $self->{parent}->apply_givens() if $self->{parent};
  map { $_->apply() } @{ $self->{givens} };
}

my @exceptions;
sub exceptions {
  return \@exceptions;
}

sub apply_whens {
  my ($self) = @_;
  $self->{parent}->apply_whens() if $self->{parent};
  map {
    eval { $_->apply() };
    push @exceptions, $@ if $@;
  } @{ $self->{whens} };
}

sub apply_invariants {
  my ($self, $exceptions) = @_;
  my @failed = ();
  push @failed, $self->{parent}->apply_invariants($exceptions) if $self->{parent};
  push @failed, grep { not $_->execute($exceptions) } @{ $self->{invariants} };
  return @failed;
}

sub apply_dones {
  my ($self) = @_;
  map { $_->apply() } @{ $self->{dones} };
}

sub _okay_to_have_no_tests {
  my ($self) = @_;
  return !$self->{parent} && !$self->{givens} && !$self->{whens} && !$self->{invariants};
}
sub _has_invariants {
  my ($self) = @_;
  my $context = $self;
  my $has_invariants;
  while ( $context && !$has_invariants ) {
    $has_invariants = $context->{invariants};
    $context = $context->{parent};
  }
  return $has_invariants;
}
sub test_count {
  my ($self) = @_;
  my $count = scalar @{ $self->{thens} || [] };

  if ( $count == 0 && $self->_has_invariants() ) {
    $self->add_then();
    $count = 1;
  }

  map { $count += $_->test_count() } @{ $self->{contexts} || [] } if $self->{contexts};
  return $count;
}

my $context_vars = {};
sub reset {
  my ($self) = @_;
  @exceptions = ();
  foreach my $package (keys %$context_vars) {
    no strict 'refs';
    foreach my $name (keys %{ $context_vars->{$package} }) {
      undef *{$package . $name};
    }
  }
}

sub define_var {
  my ($package, $name, $value) = @_;
  $context_vars->{$package}->{$name} = $value;
  no strict 'refs';
  *{$package . $name} = $value;
}

1;
