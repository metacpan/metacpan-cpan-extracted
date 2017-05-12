# $Id: gen_constants.pm,v 1.3 1997/04/30 04:30:06 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# gen_constants populates @main::constants (for later generation of
# constants.xs).

sub RPCL::Syntax::gen_constants {}

sub RPCL::ConstDef::gen_constants {
  my ($self) = @_;
  push(@main::constants, $self->ident);
}

sub RPCL::EnumVal::gen_constants {
  my ($self) = @_;
  push(@main::constants, $self->ident);
}

sub RPCL::ProgramDef::gen_constants {
  my ($self) = @_;
  push(@main::constants, $self->ident);
  foreach $ver (@{$self->versions}) {
    $ver->gen_constants;
  }
}

sub RPCL::Version::gen_constants {
  my ($self) = @_;
  push(@main::constants, $self->ident);
  foreach $proc (@{$self->procedures}) {
    $proc->gen_constants;
  }
}

sub RPCL::Procedure::gen_constants {
  my ($self) = @_;
  push(@main::constants, $self->ident);
}

sub RPCL::EnumDef::gen_constants {
  my ($self) = @_;
  foreach $val (@{$self->vals}) {
    $val->gen_constants;
  }
}

1;
