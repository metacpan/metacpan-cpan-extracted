package Venus::Role;

use 5.018;

use strict;
use warnings;

# IMPORT

sub import {
  my ($class, @args) = @_;

  my $target = caller;

  require Moo;

  die $@ if not eval "package $target; use Moo::Role; use Venus; 1";

  my $has = $target->can('has') or return;

  no strict 'refs';
  no warnings 'redefine';

  *{"${target}::base"} = *{"${target}::extends"} if !$target->can('base');
  *{"${target}::has"} = generate([$class, $target], $has);

  return;
}

# FUNCTIONS

my $wrappers = {
};

sub generate {
  my ($info, $orig) = @_;

  return sub { @_ = options($info, @_); goto $orig };
}

sub options {
  my ($info, $name, %opts) = @_;

  %opts = (is => 'rw') unless %opts;

  $opts{mod} = 1 if $name =~ s/^\+//;

  %opts = (%opts, $wrappers->{new}->($info, $name, %opts)) if defined $opts{new};
  %opts = (%opts, $wrappers->{bld}->($info, $name, %opts)) if defined $opts{bld};
  %opts = (%opts, $wrappers->{clr}->($info, $name, %opts)) if defined $opts{clr};
  %opts = (%opts, $wrappers->{crc}->($info, $name, %opts)) if defined $opts{crc};
  %opts = (%opts, $wrappers->{def}->($info, $name, %opts)) if defined $opts{def};
  %opts = (%opts, $wrappers->{hnd}->($info, $name, %opts)) if defined $opts{hnd};
  %opts = (%opts, $wrappers->{isa}->($info, $name, %opts)) if defined $opts{isa};
  %opts = (%opts, $wrappers->{lzy}->($info, $name, %opts)) if defined $opts{lzy};
  %opts = (%opts, $wrappers->{opt}->($info, $name, %opts)) if defined $opts{opt};
  %opts = (%opts, $wrappers->{pre}->($info, $name, %opts)) if defined $opts{pre};
  %opts = (%opts, $wrappers->{rdr}->($info, $name, %opts)) if defined $opts{rdr};
  %opts = (%opts, $wrappers->{req}->($info, $name, %opts)) if defined $opts{req};
  %opts = (%opts, $wrappers->{tgr}->($info, $name, %opts)) if defined $opts{tgr};
  %opts = (%opts, $wrappers->{use}->($info, $name, %opts)) if defined $opts{use};
  %opts = (%opts, $wrappers->{wkr}->($info, $name, %opts)) if defined $opts{wkr};
  %opts = (%opts, $wrappers->{wrt}->($info, $name, %opts)) if defined $opts{wrt};

  $name = "+$name" if delete $opts{mod} || delete $opts{modify};

  return ($name, %opts);
}

$wrappers->{new} = sub {
  my ($info, $name, %opts) = @_;

  if (delete $opts{new}) {
    $opts{builder} = "new_${name}";
    $opts{lazy} = 1;
  }

  return (%opts);
};

$wrappers->{bld} = sub {
  my ($info, $name, %opts) = @_;

  $opts{builder} = delete $opts{bld};

  return (%opts);
};

$wrappers->{clr} = sub {
  my ($info, $name, %opts) = @_;

  $opts{clearer} = delete $opts{clr};

  return (%opts);
};

$wrappers->{crc} = sub {
  my ($info, $name, %opts) = @_;

  $opts{coerce} = delete $opts{crc};

  return (%opts);
};

$wrappers->{def} = sub {
  my ($info, $name, %opts) = @_;

  $opts{default} = delete $opts{def};

  return (%opts);
};

$wrappers->{hnd} = sub {
  my ($info, $name, %opts) = @_;

  $opts{handles} = delete $opts{hnd};

  return (%opts);
};

$wrappers->{isa} = sub {
  my ($info, $name, %opts) = @_;

  return (%opts) if ref($opts{isa});

  die $@ if not eval "require registry; 1";

  my $registry = registry::access($info->[1]);

  return (%opts) if !$registry;

  my $constraint = $registry->lookup($opts{isa});

  return (%opts) if !$constraint;

  $opts{isa} = $constraint;

  return (%opts);
};

$wrappers->{lzy} = sub {
  my ($info, $name, %opts) = @_;

  $opts{lazy} = delete $opts{lzy};

  return (%opts);
};

$wrappers->{opt} = sub {
  my ($info, $name, %opts) = @_;

  delete $opts{opt};

  $opts{required} = 0;

  return (%opts);
};

$wrappers->{pre} = sub {
  my ($info, $name, %opts) = @_;

  $opts{predicate} = delete $opts{pre};

  return (%opts);
};

$wrappers->{rdr} = sub {
  my ($info, $name, %opts) = @_;

  $opts{reader} = delete $opts{rdr};

  return (%opts);
};

$wrappers->{req} = sub {
  my ($info, $name, %opts) = @_;

  delete $opts{req};

  $opts{required} = 1;

  return (%opts);
};

$wrappers->{tgr} = sub {
  my ($info, $name, %opts) = @_;

  $opts{trigger} = delete $opts{tgr};

  return (%opts);
};

$wrappers->{use} = sub {
  my ($info, $name, %opts) = @_;

  if (my $use = delete $opts{use}) {
    $opts{builder} = $wrappers->{use_builder}->($info, $name, @$use);
    $opts{lazy} = 1;
  }

  return (%opts);
};

$wrappers->{use_builder} = sub {
  my ($info, $name, $sub, @args) = @_;

  return sub {
    my ($self) = @_;

    my $point = $self->can($sub);
    die "$name cannot 'use' method '$sub' via @{[$info->[1]]}" if !$point;

    @_ = ($self, @args);

    goto $point;
  };
};

$wrappers->{wkr} = sub {
  my ($info, $name, %opts) = @_;

  $opts{weak_ref} = delete $opts{wkr};

  return (%opts);
};

$wrappers->{wrt} = sub {
  my ($info, $name, %opts) = @_;

  $opts{writer} = delete $opts{wrt};

  return (%opts);
};

1;



=head1 NAME

Venus::Role - Role Builder

=cut

=head1 ABSTRACT

Role Builder for Perl 5

=cut

=head1 SYNOPSIS

  package Exemplar;

  use Venus::Role;

  sub handshake {
    return true;
  }

  package Example;

  use Venus::Class;

  with 'Exemplar';

  package main;

  my $example = Example->new;

  # $example->handshake;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a modified L<Moo> role,
i.e. L<Moo::Role>. All functions in L<Venus> are automatically imported unless
routines of the same name already exist.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Moo::Role>

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item has

This package supports the C<has> keyword function and all of its
configurations. See the L<Moo> documentation for more details.

B<example 1>

  package Example::Has;

  use Venus::Role;

  has 'data' => (
    is => 'ro',
    isa => sub { die }
  );

  package Example::HasData;

  use Venus::Class;

  with 'Example::Has';

  has '+data' => (
    is => 'ro',
    isa => sub { 1 }
  );

  package main;

  my $example = Example::HasData->new(data => time);

=back

=over 4

=item has-is

This package supports the C<is> directive, used to denote whether the attribute
is read-only or read-write. See the L<Moo> documentation for more details.

B<example 1>

  package Example::HasIs;

  use Venus::Class;

  has data => (
    is => 'ro'
  );

  package main;

  my $example = Example::HasIs->new(data => time);

=back

=over 4

=item has-isa

This package supports the C<isa> directive, used to define the type constraint
to validate the attribute against. See the L<Moo> documentation for more
details.

B<example 1>

  package Example::HasIsa;

  use registry;

  use Venus::Class;

  has data => (
    is => 'ro',
    isa => 'Str' # e.g. Types::Standard::Str
  );

  package main;

  my $example = Example::HasIsa->new(data => time);

=back

=over 4

=item has-req

This package supports the C<req> and C<required> directives, used to denote if
an attribute is required or optional. See the L<Moo> documentation for more
details.

B<example 1>

  package Example::HasReq;

  use Venus::Class;

  has data => (
    is => 'ro',
    req => 1 # required
  );

  package main;

  my $example = Example::HasReq->new(data => time);

=back

=over 4

=item has-opt

This package supports the C<opt> and C<optional> directives, used to denote if
an attribute is optional or required. See the L<Moo> documentation for more
details.

B<example 1>

  package Example::HasOpt;

  use Venus::Class;

  has data => (
    is => 'ro',
    opt => 1
  );

  package main;

  my $example = Example::HasOpt->new(data => time);

=back

=over 4

=item has-bld

This package supports the C<bld> and C<builder> directives, expects a C<1>, a
method name, or coderef and builds the attribute value if it wasn't provided to
the constructor. See the L<Moo> documentation for more details.

B<example 1>

  package Example::HasBld;

  use Venus::Class;

  has data => (
    is => 'ro',
    bld => 1
  );

  sub _build_data {
    return rand;
  }

  package main;

  my $example = Example::HasBld->new;

=back

=over 4

=item has-clr

This package supports the C<clr> and C<clearer> directives expects a C<1> or a
method name of the clearer method. See the L<Moo> documentation for more
details.

B<example 1>

  package Example::HasClr;

  use Venus::Class;

  has data => (
    is => 'ro',
    clr => 1
  );

  package main;

  my $example = Example::HasClr->new(data => time);

  # $example->clear_data;

=back

=over 4

=item has-crc

This package supports the C<crc> and C<coerce> directives denotes whether an
attribute's value should be automatically coerced. See the L<Moo> documentation
for more details.

B<example 1>

  package Example::HasCrc;

  use Venus::Class;

  has data => (
    is => 'ro',
    crc => sub {'0'}
  );

  package main;

  my $example = Example::HasCrc->new(data => time);

=back

=over 4

=item has-def

This package supports the C<def> and C<default> directives expects a
non-reference or a coderef to be used to build a default value if one is not
provided to the constructor. See the L<Moo> documentation for more details.

B<example 1>

  package Example::HasDef;

  use Venus::Class;

  has data => (
    is => 'ro',
    def => '0'
  );

  package main;

  my $example = Example::HasDef->new;

=back

=over 4

=item has-mod

This package supports the C<mod> and C<modify> directives denotes whether a
pre-existing attribute's definition is being modified. This ability is not
supported by the L<Moo> object superclass.

B<example 1>

  package Example::HasNomod;

  use Venus::Role;

  has data => (
    is => 'rw',
    opt => 1
  );

  package Example::HasMod;

  use Venus::Class;

  with 'Example::HasNomod';

  has data => (
    is => 'ro',
    req => 1,
    mod => 1
  );

  package main;

  my $example = Example::HasMod->new;

=back

=over 4

=item has-hnd

This package supports the C<hnd> and C<handles> directives denotes the methods
created on the object which dispatch to methods available on the attribute's
object. See the L<Moo> documentation for more details.

B<example 1>

  package Example::Time;

  use Venus::Class;

  sub maketime {
    return time;
  }

  package Example::HasHnd;

  use Venus::Class;

  has data => (
    is => 'ro',
    hnd => ['maketime']
  );

  package main;

  my $example = Example::HasHnd->new(data => Example::Time->new);

=back

=over 4

=item has-lzy

This package supports the C<lzy> and C<lazy> directives denotes whether the
attribute will be constructed on-demand, or on-construction. See the L<Moo>
documentation for more details.

B<example 1>

  package Example::HasLzy;

  use Venus::Class;

  has data => (
    is => 'ro',
    def => sub {time},
    lzy => 1
  );

  package main;

  my $example = Example::HasLzy->new;

=back

=over 4

=item has-new

This package supports the C<new> directive, if truthy, denotes that the
attribute will be constructed on-demand, i.e. is lazy, with a builder named
new_{attribute}. This ability is not supported by the L<Moo> object superclass.

B<example 1>

  package Example::HasNew;

  use Venus::Class;

  has data => (
    is => 'ro',
    new => 1
  );

  sub new_data {
    return time;
  }

  package main;

  my $example = Example::HasNew->new(data => time);

=back

=over 4

=item has-pre

This package supports the C<pre> and C<predicate> directives expects a C<1> or
a method name and generates a method for checking the existance of the
attribute. See the L<Moo> documentation for more details.

B<example 1>

  package Example::HasPre;

  use Venus::Class;

  has data => (
    is => 'ro',
    pre => 1
  );

  package main;

  my $example = Example::HasPre->new(data => time);

=back

=over 4

=item has-rdr

This package supports the C<rdr> and C<reader> directives denotes the name of
the method to be used to "read" and return the attribute's value. See the
L<Moo> documentation for more details.

B<example 1>

  package Example::HasRdr;

  use Venus::Class;

  has data => (
    is => 'ro',
    rdr => 'get_data'
  );

  package main;

  my $example = Example::HasRdr->new(data => time);

=back

=over 4

=item has-tgr

This package supports the C<tgr> and C<trigger> directives expects a C<1> or a
coderef and is executed whenever the attribute's value is changed. See the
L<Moo> documentation for more details.

B<example 1>

  package Example::HasTgr;

  use Venus::Class;

  has data => (
    is => 'ro',
    tgr => 1
  );

  sub _trigger_data {
    my ($self) = @_;

    $self->{triggered} = 1;

    return $self;
  }

  package main;

  my $example = Example::HasTgr->new(data => time);

=back

=over 4

=item has-use

This package supports the C<use> directive denotes that the attribute will be
constructed on-demand, i.e. is lazy, using a custom builder meant to perform
service construction. This directive exists to provide a simple dependency
injection mechanism for class attributes. This ability is not supported by the
L<Moo> object superclass.

B<example 1>

  package Example::HasUse;

  use Venus::Class;

  has data => (
    is => 'ro',
    use => ['service', 'time']
  );

  sub service {
    my ($self, $type, @args) = @_;

    $self->{serviced} = 1;

    return time if $type eq 'time';
  }

  package main;

  my $example = Example::HasUse->new;

=back

=over 4

=item has-wkr

This package supports the C<wkr> and C<weak_ref> directives is used to denote if
the attribute's value should be weakened. See the L<Moo> documentation for more
details.

B<example 1>

  package Example::HasWkr;

  use Venus::Class;

  has data => (
    is => 'ro',
    wkr => 1
  );

  package main;

  my $data = do {
    my ($a, $b);

    $a = { time => time };
    $b = { time => $a };

    $a->{time} = $b;
    $a
  };

  my $example = Example::HasWkr->new(data => $data);

=back

=over 4

=item has-wrt

This package supports the C<wrt> and C<writer> directives denotes the name of
the method to be used to "write" and return the attribute's value. See the
L<Moo> documentation for more details.

B<example 1>

  package Example::HasWrt;

  use Venus::Class;

  has data => (
    is => 'ro',
    wrt => 'set_data'
  );

  package main;

  my $example = Example::HasWrt->new;

=back

=head1 AUTHORS

Cpanery, C<cpanery@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2021, Cpanery

Read the L<"license"|https://github.com/cpanery/venus/blob/master/LICENSE> file.

=cut