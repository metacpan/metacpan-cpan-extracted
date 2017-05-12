# $Id: types.pm,v 1.6 1997/04/30 04:30:10 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# -----------------------------------------------------------------------------
# xstype returns an  XS type describing the type (the right-hand
# side of a typemap entry).

# a T_PTRUBJ is a T_PTROBJ that also accepts undef on INPUT, which is
# turned into a NULL pointer. See perlrpcgen.
sub RPCL::Type::xstype { 'T_PTRUBJ' }

sub RPCL::EnumDef::xstype { 'T_IV' }

sub RPCL::TypedefDef::xstype {
    my ($self) = @_;
    $self->type->xstype;
}

sub RPCL::TypeFixedArr::xstype {
    my ($self) = @_;
    return 'T_' . $self->ident;
}

sub RPCL::TypeFixedStr::xstype {
    my ($self) = @_;
    return 'T_' . $self->ident;
}

sub RPCL::TypeFixedOpq::xstype {
    my ($self) = @_;
    return 'T_' . $self->ident;
}

sub RPCL::TypeVarArr::xstype {
    my ($self) = @_;
    return 'T_' . $self->ident;
}

sub RPCL::TypeVarOpq::xstype {
    my ($self) = @_;
    return 'T_' . $self->ident;
}

sub RPCL::TypeVarStr::xstype {
    my ($self) = @_;
    return 'T_' . $self->ident;
}



# -----------------------------------------------------------------------------
# perltype returns a Perl type describing the type (the left-hand side of a
# typemap entry). These types are typedef'ed to the corresponding C type
# (as given by $type->ctype) in typedefs.h.

sub RPCL::Type::perltype {
    my ($self, $mod) = @_;
    return $mod . '::' . $self->ident;
}

sub RPCL::TypedefDef::perltype {
    my ($self, $mod) = @_;
    $self->type->perltype($mod);
}

sub RPCL::TypeSimple::perltype {
  my ($self, $mod) = @_;
  return $self->ident;
}



# -----------------------------------------------------------------------------
# ctype returns the underlying C type describing the type. See xstype.

sub RPCL::Type::ctype {
    my ($self) = @_;
    return $self->ident;
}

sub RPCL::TypedefDef::ctype {
    my ($self) = @_;
    return $self->type->ctype;
}

sub RPCL::TypeFixedArr::ctype {
    my ($self) = @_;
    return $self->type->ctype . ' *';
}

sub RPCL::TypeFixedOpq::ctype {
    my ($self) = @_;
    return 'char *';
}

sub RPCL::TypeFixedStr::ctype {
    my ($self) = @_;
    return 'char *';
}

sub RPCL::TypeVarArr::ctype {
    my ($self) = @_;
    my $ctype = $self->type->ctype;
    my $ident = $self->ident;
    $main::structs{$ident} = "struct $ident { u_int len; $ctype *val; }";
    return "struct $ident";
}

sub RPCL::TypeVarOpq::ctype {
    my ($self) = @_;
    my $ident = $self->ident;
    $main::structs{$ident} = "struct $ident { u_int len; char *val; }";
    return "struct $ident";
}

sub RPCL::TypeVarStr::ctype {
    my ($self) = @_;
    return "char *";
}

sub RPCL::TypePtr::ctype {
    my ($self) = @_;
    return $self->type->ctype . ' *';
}

sub RPCL::TypeVoid::ctype { 'void' }
sub RPCL::TypeInt::ctype { 'int' }
sub RPCL::TypeUInt::ctype { 'unsigned int' }
sub RPCL::TypeFloat::ctype { 'float' }
sub RPCL::TypeDouble::ctype { 'double' }
sub RPCL::TypeBool::ctype { 'int' }



# -----------------------------------------------------------------------------
# ref returns 0 or more &s, to give the RPC call the proper type.

sub RPCL::TypedefDef::ref { die 'typedef' }
sub RPCL::TypeName::ref { die 'typename' }

sub RPCL::Type::ref { '&' }
sub RPCL::StructDef::ref { '' }
sub RPCL::StructPDef::ref { '&' }
sub RPCL::UnionDef::ref { '' }

sub RPCL::TypePtr::ref {
  my ($self) = @_;
  return $self->type->ref . '&';
}

# -----------------------------------------------------------------------------
# deref returns 0 or more *s, to give the RPC return the proper type.

sub RPCL::TypedefDef::deref { die 'typedef' }
sub RPCL::TypeName::deref { die 'typename' }

sub RPCL::Type::deref { '*' }
sub RPCL::StructDef::deref { '' }
sub RPCL::StructPDef::deref { '*' }
sub RPCL::UnionDef::deref { '' }

sub RPCL::TypePtr::deref {
  my ($self) = @_;
  return $self->type->deref . '*';
}

1;
