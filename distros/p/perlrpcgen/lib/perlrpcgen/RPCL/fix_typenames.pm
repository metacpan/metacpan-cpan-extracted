# $Id: fix_typenames.pm,v 1.4 1997/04/30 04:30:05 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# fix_typenames traces the parse tree and replaces references to
# TypeNames with references to the named type (from $main::types).

sub RPCL::Syntax::fix_typenames {
    my ($self) = @_;
    return $self;
}

sub RPCL::Decl::fix_typenames {
    my ($self) = @_;
    $self->set_type($self->type->fix_typenames);
    return $self;
}

sub RPCL::Case::fix_typenames {
    my ($self) = @_;
    $self->set_decl($self->decl->fix_typenames);
    return $self;
}

sub RPCL::CaseDefault::fix_typenames {
    my ($self) = @_;
    $self->set_decl($self->decl->fix_typenames);
    return $self;
}

sub RPCL::ProgramDef::fix_typenames {
    my ($self) = @_;
    foreach $ver (@{$self->versions}) {
	$ver = $ver->fix_typenames;
    }
    return $self;
}

sub RPCL::Version::fix_typenames {
    my ($self) = @_;
    foreach $proc (@{$self->procedures}) {
	$proc = $proc->fix_typenames;
    }
    return $self;
}

sub RPCL::Procedure::fix_typenames {
    my ($self) = @_;
    $self->set_rettype($self->rettype->fix_typenames);
    $self->set_argtype($self->argtype->fix_typenames);
    return $self;
}

#sub RPCL::Type::fix_typenames {
#    my ($self) = @_;
#    $self->set_type($self->type->fix_typenames);
#    return $self;
#}

sub RPCL::TypeSimple::fix_typenames {
    my ($self) = @_;
    return $self;
}

sub RPCL::TypeName::fix_typenames {
    my ($self) = @_;
    $main::types{$self->ident} = $main::types{$self->ident}->fix_typenames;
    return $main::types{$self->ident};
}

sub RPCL::UnionDef::fix_typenames {
    my ($self) = @_;
    if (!$fixed{$self->ident}) {
      $fixed{$self->ident} = 1;
      $self->set_decl($self->decl->fix_typenames);
      foreach $case (@{$self->cases}) {
	$case = $case->fix_typenames;
      }
    }
    return $self;
}

sub RPCL::StructDef::fix_typenames {
    my ($self) = @_;
    if (!$fixed{$self->ident}) {
      $fixed{$self->ident} = 1;
      foreach $decl (@{$self->decls}) {
	$decl = $decl->fix_typenames;
      }
    }
    return $self;
}

sub RPCL::EnumDef::fix_typenames {
    my ($self) = @_;
    return $self;
}

sub RPCL::TypePtr::fix_typenames {
  my ($self) = @_;
  $self->set_type($self->type->fix_typenames);
  return $self;
}

sub RPCL::TypedefDef::fix_typenames {
    my ($self) = @_;
    return $self->type->fix_typenames;
}

sub RPCL::TypeFixedArr::fix_typenames {
  my ($self) = @_;
  $self->set_type($self->type->fix_typenames);
  return $self;
}

sub RPCL::TypeVarArr::fix_typenames {
  my ($self) = @_;
  $self->set_type($self->type->fix_typenames);
  return $self;
}

1;
