package Venus::Boolean;

use 5.018;

use strict;
use warnings;

use Moo;

extends 'Venus::Kind::Value';

use Scalar::Util ();

state $true = Scalar::Util::dualvar(1, "1");
state $true_ref = \$true;
state $true_type = 'true';

state $false = Scalar::Util::dualvar(0, "0");
state $false_ref = \$false;
state $false_type = 'false';

use overload (
  '!' => sub{$_[0]->get ? $false : $true},
  '<' => sub{!!$_[0] < !!$_[1] ? $true : $false},
  '<=' => sub{!!$_[0] <= !!$_[1] ? $true : $false},
  '>' => sub{!!$_[0] > !!$_[1] ? $true : $false},
  '>=' => sub{!!$_[0] >= !!$_[1] ? $true : $false},
  '!=' => sub{!!$_[0] != !!$_[1] ? $true : $false},
  '==' => sub{!!$_[0] == !!$_[1] ? $true : $false},
  'bool' => sub{!!$_[0] ? $true : $false},
  'eq' => sub{"$_[0]" eq "$_[1]" ? $true : $false},
  'ne' => sub{"$_[0]" ne "$_[1]" ? $true : $false},
  'qr' => sub{"$_[0]" ? qr/$true/ : qr/$false/},
);

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    value => $data,
  };
}

sub build_args {
  my ($self, $data) = @_;

  $data->{value} = (defined $data->{value} && !!$data->{value})
    ? $true
    : $false;

  return $data;
}

sub build_nil {
  my ($self, $data) = @_;

  return {
    value => {},
  };
}

sub build_self {
  my ($self, $data) = @_;

  $data->{value} = BOOL(TO_BOOL($data->{value}));

  return $self;
}

# METHODS

sub default {
  return $false;
}

sub is_false {
  my ($self) = @_;

  return $self->get ? $false : $true;
}

sub is_true {
  my ($self) = @_;

  return $self->get ? $true : $false;
}

sub negate {
  my ($self) = @_;

  return $self->get ? $false : $true;
}

sub type {
  my ($self) = @_;

  return $self->get ? $true_type : $false_type;
}

sub BOOL {
  return $_[0] ? $true : $false;
}

sub BOOL_REF {
  return $_[0] ? $true_ref : $false_ref;
}

sub FALSE {
  return $false;
}

sub FROM_BOOL {
  my ($value) = @_;

  my $object = Scalar::Util::blessed($value);
  my $scalar = ((Scalar::Util::reftype($value) // '') eq 'SCALAR') ? 1 : 0;

  if ($object && $scalar && defined($$value) && !ref($$value) && $$value == 1) {
    return $true;
  }
  elsif ($object && $scalar && defined($$value) && !ref($$value) && $$value == 0) {
    return $false;
  }
  elsif ($object && $value->isa('Venus::Boolean')) {
    return $value->get;
  }
  else {
    return $value;
  }
}

sub TO_BOOL {
  my ($value) = @_;

  my $isdual = Scalar::Util::isdual($value);

  if ($isdual && ("$value" == "1" && ($value + 0) == 1)) {
    return $true;
  }
  elsif ($isdual && ("$value" == "0" && ($value + 0) == 0)) {
    return $false;
  }
  else {
    return $value;
  }
}

sub TO_BOOL_REF {
  my ($value) = @_;

  my $isdual = Scalar::Util::isdual($value);

  if ($isdual && ("$value" == "1" && ($value + 0) == 1)) {
    return $true_ref;
  }
  elsif ($isdual && ("$value" == "0" && ($value + 0) == 0)) {
    return $false_ref;
  }
  else {
    return $value;
  }
}

sub TO_BOOL_OBJ {
  my ($value) = @_;

  require JSON::PP;

  my $isdual = Scalar::Util::isdual($value);

  if ($isdual && ("$value" == "1" && ($value + 0) == 1)) {
    return JSON::PP::true();
  }
  elsif ($isdual && ("$value" == "0" && ($value + 0) == 0)) {
    return JSON::PP::false();
  }
  else {
    return $value;
  }
}

sub TO_JSON {
  my ($self) = @_;

  no strict 'refs';

  return $self->get ? $true_ref : $false_ref;
}

sub TRUE {
  return $true;
}

1;



=head1 NAME

Venus::Boolean - Boolean Class

=cut

=head1 ABSTRACT

Boolean Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Boolean;

  my $boolean = Venus::Boolean->new;

  # $boolean->negate;

=cut

=head1 DESCRIPTION

This package provides a representation for boolean values.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Value>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 default

  default() (Bool)

The default method returns the default value, i.e. C<0>.

I<Since C<0.01>>

=over 4

=item default example 1

  # given: synopsis;

  my $default = $boolean->default;

  # 0

=back

=cut

=head2 is_false

  is_false() (Bool)

The is_false method returns C<false> if the boolean is falsy, otherwise returns
C<true>.

I<Since C<0.01>>

=over 4

=item is_false example 1

  # given: synopsis;

  my $is_false = $boolean->is_false;

  # 1

=back

=cut

=head2 is_true

  is_true() (Bool)

The is_true method returns C<true> if the boolean is truthy, otherwise returns
C<false>.

I<Since C<0.01>>

=over 4

=item is_true example 1

  # given: synopsis;

  my $is_true = $boolean->is_true;

  # 0

=back

=cut

=head2 negate

  negate() (Bool)

The negate method returns C<true> if the boolean is falsy, otherwise returns
C<false>.

I<Since C<0.01>>

=over 4

=item negate example 1

  # given: synopsis;

  my $negate = $boolean->negate;

  # 1

=back

=cut

=head2 type

  type() (Str)

The type method returns the word C<'true'> if the boolean is truthy, otherwise
returns C<'false'>.

I<Since C<0.01>>

=over 4

=item type example 1

  # given: synopsis;

  my $type = $boolean->type;

  # "false"

=back

=cut

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<(!)>

This package overloads the C<!> operator.

B<example 1>

  # given: synopsis;

  my $result = !$boolean;

  # 1

=back

=over 4

=item operation: C<(<)>

This package overloads the C<<> operator.

B<example 1>

  # given: synopsis;

  my $result = $boolean < 1;

  # 1

=back

=over 4

=item operation: C<(<=)>

This package overloads the C<<=> operator.

B<example 1>

  # given: synopsis;

  my $result = $boolean <= 0;

  # 1

=back

=over 4

=item operation: C<(>)>

This package overloads the C<>> operator.

B<example 1>

  # given: synopsis;

  my $result = $boolean > 0;

  # 0

=back

=over 4

=item operation: C<(>=)>

This package overloads the C<>=> operator.

B<example 1>

  # given: synopsis;

  my $result = $boolean >= 0;

  # 1

=back

=over 4

=item operation: C<(!=)>

This package overloads the C<!=> operator.

B<example 1>

  # given: synopsis;

  my $result = $boolean != 1;

  # 1

=back

=over 4

=item operation: C<(==)>

This package overloads the C<==> operator.

B<example 1>

  # given: synopsis;

  my $result = $boolean == 0;

  # 1

=back

=over 4

=item operation: C<(bool)>

This package overloads the C<bool> operator.

B<example 1>

  # given: synopsis;

  my $result = !!$boolean;

  # 0

=back

=over 4

=item operation: C<(eq)>

This package overloads the C<eq> operator.

B<example 1>

  # given: synopsis;

  my $result = $boolean eq '0';

  # 1

=back

=over 4

=item operation: C<(ne)>

This package overloads the C<ne> operator.

B<example 1>

  # given: synopsis;

  my $result = $boolean ne '1';

  # 1

=back

=over 4

=item operation: C<(qr)>

This package overloads the C<qr> operator.

B<example 1>

  # given: synopsis;

  my $result = '0' =~ qr/$boolean/;

  # 1

=back

=head1 AUTHORS

Cpanery, C<cpanery@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2021, Cpanery

Read the L<"license"|https://github.com/cpanery/venus/blob/master/LICENSE> file.

=cut