package Test::Given::Check;
use strict;
use warnings;

use B::Deparse ();

sub new {
  my ($class, $sub) = @_;
  my $self = {
    sub => $sub,
  };
  bless $self, $class;
}

sub execute {
  my ($self, $exceptions) = @_;
  return 1 if !$self->{sub};

  my $rv = eval {
    $self->{sub}->($exceptions);
  };
  if ($@) {
    warn $@;
    $rv = '';
  }
  return $rv;
}

our $deparser = B::Deparse->new('-l');
sub _decompile {
  my ($self) = @_;
  unless ( exists $self->{code} ) {
    my @code = split( /\n/, $deparser->coderef2text($self->{sub}) );
    @code = (@code > 1) ? @code[1..$#code-1] : ();
    $self->{code} = \@code;
  }
  return $self->{code};
}

sub name {
  my ($self) = @_;
  return '' if !$self->{sub};

  my @code = grep { !/^ *(?:package|use|no|#line) / } @{ $self->_decompile() };
  my ($line) = _clean_code( $code[$#code] );
  $line =~ s/;$//;
  return $line;
}

sub message {
  my ($self) = @_;
  return '' if !$self->{sub};

  my @lines = @{ $self->_decompile() };
  my @code = _clean_code(grep { !/^ *(?:package|use|no|#line) / } @lines);
  my ($line_number) = grep { /^ *#line / } @lines;

  my $msg = $self->type() . ": $line_number\n  " . join("\n  ", @code);

  if ( my ($left, $cmp, $right) = _split_expression( $code[$#code] ) ) {
    my @package = grep { /^ *package / } @lines;
    @package = 'package main;' unless @package;

    my @use = grep { /^ *(?:use|no) / } @lines;
    push @use, "no warnings 'all';";

    my $left_value = _eval_in_context(@package, @use, $left);
    my $right_value = _eval_in_context(@package, @use, $right);

    unless ($left_value =~ /<Error:/ && $right_value =~ /<Error:/) {
      $msg .= "\n    $left_value\t<- $left\n    $right_value\t<- $right";
    }
  }
  return $msg;
}

sub _split_expression {
  return $_[0] =~ /^\s*(?:return\s+)?(.*) ([!=<>]=|[<>]|<=>|eq|ne|cmp|[lg][te]|[!=]~) (.*?)\s*;?$/;
}

sub _eval_in_context {
  my $result = eval( join("\n", @_) );

  if ($@) {
    $result = $@;
    $result =~ s/ at \(eval \d+\) line \d+.*\n?//;
    $result = "<Error: $result>";
  }

  $result = '<undef>' unless defined $result;
  return $result;
}

# convert $$var to $var->
sub _clean_code {
  map {
    s/\$(\$.*?)([\{\[])/$1->$2/g;
    s/^    //;
    $_;
  } @_;
}

package Test::Given::Invariant;
use parent 'Test::Given::Check';
sub type { 'Invariant' }

package Test::Given::Then;
use parent 'Test::Given::Check';
sub type { 'Then' }

package Test::Given::And;
use parent 'Test::Given::Check';
sub type { 'And' }

package Test::Given::Test;

use Test::Given::Builder;
my $TEST_CLASS = 'Test::Given::Builder';

sub new {
  my ($class, $sub) = @_;
  my $self = {
    checks => [ Test::Given::Then->new($sub) ],
  };
  bless $self, $class;
}
sub add_check {
  my ($self) = shift;
  push @{ $self->{checks} }, Test::Given::And->new(@_);  
}
sub execute {
  my ($self, $context) = @_;
  $context->reset();
  $context->apply_givens();
  $context->apply_whens();
  my $exceptions = $context->exceptions();
  my @failed = grep { not $_->execute($exceptions) } @{ $self->{checks} };
  push @failed, $context->apply_invariants($exceptions);
  my $passed = not @failed;
  ok($passed, name($self->{checks}));
  diag(message(\@failed)) unless $passed;
  return $passed;
}

sub name {
  my ($checks) = @_;
  return $checks->[0]->name();
}

sub message {
  my ($failed) = @_;
  return join("\n\n", map { $_->message() } @$failed);
}

1;
