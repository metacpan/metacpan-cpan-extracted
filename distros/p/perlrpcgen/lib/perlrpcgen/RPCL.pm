# $Id: RPCL.pm,v 1.1 1997/04/30 21:15:53 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# Defintions of various classes that make up parse trees.

package RPCL;

use perlrpcgen::DefClass;

# -----------------------------------------------------------------------------
# syntactic elements

defclass RPCL::Syntax,		[],		qw();

defclass RPCL::ConstDef,	RPCL::Syntax,	qw(ident value);
defclass RPCL::EnumVal,		RPCL::Syntax,	qw(ident val);
defclass RPCL::Decl,		RPCL::Syntax,	qw(type ident);
defclass RPCL::Case,		RPCL::Syntax,	qw(value decl);
defclass RPCL::CaseDefault,	RPCL::Syntax,	qw(decl);
defclass RPCL::ProgramDef,	RPCL::Syntax,	qw(ident versions value);
defclass RPCL::Version,		RPCL::Syntax,	qw(ident procedures value);
defclass RPCL::Procedure,	RPCL::Syntax,	qw(rettype ident argtype value);


# -----------------------------------------------------------------------------
# values

defclass RPCL::Value,		RPCL::Syntax,	qw();

defclass RPCL::Constant,	RPCL::Value,	qw(value);
defclass RPCL::NamedConstant,	RPCL::Value,	qw(ident);

sub RPCL::NamedConstant::value {
    my ($self) = @_;
    return $main::consts{$self->ident};
}


# -----------------------------------------------------------------------------
# types

defclass RPCL::Type,		RPCL::Syntax,	qw();

defclass RPCL::TypeSimple,	RPCL::Type,	qw();
defclass RPCL::TypeVoid,	RPCL::TypeSimple,	qw();

sub RPCL::TypeVoid::ident { 'void' }

defclass RPCL::TypeInt,		RPCL::TypeSimple,	qw();

sub RPCL::TypeInt::ident { 'int' }

defclass RPCL::TypeUInt,	RPCL::TypeSimple,	qw();

sub RPCL::TypeUInt::ident { 'unsigned' }

defclass RPCL::TypeFloat,	RPCL::TypeSimple,	qw();

sub RPCL::TypeFloat::ident { 'float' }

defclass RPCL::TypeDouble,	RPCL::TypeSimple,	qw();

sub RPCL::TypeFloat::ident { 'double' }

defclass RPCL::TypeBool,	RPCL::TypeSimple,	qw();

sub RPCL::TypeBool::ident { 'bool' }

defclass RPCL::TypeFixedArr,	RPCL::Type,	qw(type size);

sub RPCL::TypeFixedArr::ident {
    my ($self) = @_;
    return "FA_" . $self->type->ident . "_" . $self->size->value;
}

defclass RPCL::TypeFixedStr,	RPCL::Type,	qw(size);

sub RPCL::TypeFixedStr::ident {
    my ($self) = @_;
    return "FS_" . $self->size->value;
}

defclass RPCL::TypeFixedOpq,	RPCL::Type,	qw(size);

sub RPCL::TypeFixedOpq::ident {
    my ($self) = @_;
    return "FO_" . $self->size->value;
}


# XXX
# the fident argument is a hack so we know what to call the struct
# fields that rpcgen generates.
defclass RPCL::TypeVarArr,	RPCL::Type,	qw(type size fident);

sub RPCL::TypeVarArr::ident {
    my ($self) = @_;
    my $fident = $self->fident;

    if ($self->size) {
      return "VA_" . $self->type->ident . "_" . $self->size->value .
	"_$fident";
    }
    else {
      return "VA_" . $self->type->ident . "_ARB_$fident";
    }
}

defclass RPCL::TypeVarStr,	RPCL::Type,	qw(size fident);

sub RPCL::TypeVarStr::ident {
    my ($self) = @_;
    my $fident = $self->fident;

    if ($self->size) {
      return "VS_" . $self->size->value . "_$fident";
    }
    else {
      return "VS_ARB_$fident";
    }
}

defclass RPCL::TypeVarOpq,	RPCL::Type,	qw(size fident);

sub RPCL::TypeVarOpq::ident {
    my ($self) = @_;
    my $fident = $self->fident;

    if ($self->size) {
      return "VO_" . $self->size->value . "_$fident";
    }
    else {
      return "VO_ARB_$fident";
    }
}

defclass RPCL::TypePtr,		RPCL::Type,	qw(type);

sub RPCL::TypePtr::ident {
    my ($self) = @_;
#    return "PTR_" . $self->type->ident;
    return $self->type->ident; # XXX not right if type != struct/union?
}

defclass RPCL::TypeName,	RPCL::Type,	qw(ident);

#*{RPCL::TypeName::new} = sub {
#    my ($class, $ident) = @_;
#    if (!$RPCL::TypeName::typenames{$ident}) {
#	$RPCL::TypeName::typenames{$ident} =
#	    bless [ $ident ], $class;
#    }
#    return $RPCL::TypeName::typenames{$ident};
#}

defclass RPCL::UnionDef,	RPCL::Type,	qw(ident decl cases);
defclass RPCL::StructDef,	RPCL::Type,	qw(ident decls);
defclass RPCL::StructPDef,	RPCL::StructDef,	qw(ident decls);
defclass RPCL::EnumDef,		RPCL::Type,	qw(ident vals);
defclass RPCL::TypedefDef,	RPCL::Type,	qw(ident type);

1;
