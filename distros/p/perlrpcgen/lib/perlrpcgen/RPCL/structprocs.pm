# $Id: structprocs.pm,v 1.6 1997/04/30 04:30:09 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# structprocs takes a module name and a filehandle reference and prints XS
# stubs for structure accessors to the filehandle.

sub RPCL::Syntax::structprocs {}

sub RPCL::StructDef::structprocs {
    my ($self, $mod, $fh) = @_;
    my $ident = $self->ident;
    my $ctype = $self->ctype;
    my $type = $self->perltype($mod);
    my $ftype = $type;
    $ftype =~ s/::/__/;

    print $fh <<EOF;
MODULE = ${mod}::Data	PACKAGE = $type

EOF

    print $fh &constructor($type, $ctype);
    print $fh &sizeof($type, $ctype);
    #print $fh $self->destructor($mod);

    foreach $decl (@{$self->decls}) {
	$decl->type->getter($mod, $self, $decl->ident, $fh);
	$decl->type->setter($mod, $self, $decl->ident, $fh);
    }
}

sub RPCL::Type::getter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
$ret
$field(arg)
    $arg arg

    CODE:
	RETVAL = arg->${u}$field;

    OUTPUT:
	RETVAL

EOF
}

sub RPCL::Type::setter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
void
set_$field(arg, val)
    $arg arg
    $ret val

    CODE:
	arg->${u}$field = val;

EOF
}

sub RPCL::TypedefDef::getter { die "typedef" }
sub RPCL::TypedefDef::setter { die "typedef" }

sub RPCL::TypeFixedArr::setter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);
    my $size = $self->size->value;
    my $ctype = $self->type->ctype;

    print $fh <<EOF;
void
set_$field(arg, val)
    $arg arg
    $ret val

    CODE:
	Copy(val, &(arg->${u}$field), $size, $ctype);

EOF
}

sub RPCL::TypeFixedOpq::setter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);
    my $size = $self->size->value;

    print $fh <<EOF;
void
set_$field(arg, val)
    $arg arg
    $ret val

    CODE:
	Copy(val, &(arg->${u}$field), $size, char);

EOF
}

*{RPCL::TypeFixedStr::setter} = \&RPCL::TypeFixedOpq::setter;

sub RPCL::TypeVarArr::getter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
$ret
$field(arg)
    $arg arg

    CODE:
	{
	    RETVAL.val = arg->${u}${field}.${field}_val;
            RETVAL.len = arg->${u}${field}.${field}_len;
	}

    OUTPUT:
	RETVAL

EOF
}

sub RPCL::TypeVarArr::setter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
void
set_$field(arg, val)
    $arg arg
    $ret val

    CODE:
	{
	    arg->${u}${field}.${field}_val = val.val;
	    arg->${u}${field}.${field}_len = val.len;
	}

EOF
}

sub RPCL::TypeVarOpq::getter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
$ret
$field(arg)
    $arg arg

    CODE:
	{
	    RETVAL.val = arg->${u}${field}.${field}_val;
            RETVAL.len = arg->${u}${field}.${field}_len;
	}

    OUTPUT:
	RETVAL

EOF
}

sub RPCL::TypeVarOpq::setter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
void
set_$field(arg, val)
    $arg arg
    $ret val

    CODE:
	{
	    arg->${u}${field}.${field}_val = val.val;
	    arg->${u}${field}.${field}_len = val.len;
	}

EOF
}

sub RPCL::TypeVarStr::getter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
$ret
$field(arg)
    $arg arg

    CODE:
	RETVAL = arg->${u}${field};

    OUTPUT:
	RETVAL

EOF
}

sub RPCL::TypeVarStr::setter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
void
set_$field(arg, val)
    $arg arg
    $ret val

    CODE:
	arg->${u}${field} = val;

EOF
}

sub RPCL::StructDef::setter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
void
set_$field(arg, val)
    $arg arg
    $ret val

    CODE:
	arg->${u}$field = *val;

EOF
}

sub RPCL::StructDef::getter {
    my ($self, $mod, $struct, $field, $fh, $u) = @_;
    my $ret = $self->perltype($mod);
    my $arg = $struct->perltype($mod);

    print $fh <<EOF;
$ret
$field(arg)
    $arg arg

    CODE:
	RETVAL = &(arg->${u}$field);

    OUTPUT:
	RETVAL

EOF
}

*{RPCL::StructPDef::setter} = \&RPCL::Type::setter;
*{RPCL::StructPDef::getter} = \&RPCL::Type::getter;

sub RPCL::UnionDef::structprocs {
    my ($self, $mod, $fh) = @_;
    my $ident = $self->ident;
    my $ctype = $self->ctype;
    my $type = $self->perltype($mod);

    print $fh <<EOF;
MODULE = ${mod}::Data	PACKAGE = $type

EOF

    print $fh &constructor($type, $ctype);
    print $fh &sizeof($type, $ctype);
    #print $fh $self->destructor($mod);

    $self->decl->type->getter($mod, $self, $self->decl->ident, $fh);
    $self->decl->type->setter($mod, $self, $self->decl->ident, $fh);

    my $u = $ident . '_u.';
    foreach $case (@{$self->cases}) {
      next if $case->decl->type->isa(RPCL::TypeVoid);
      $case->decl->type->getter($mod, $self, $case->decl->ident, $fh, $u);
      $case->decl->type->setter($mod, $self, $case->decl->ident, $fh, $u);
    }
}

sub constructor {
  my ($type, $ctype) = @_;
    my $ftype = $type;
    $ftype =~ s/::/__/;
  
    return <<EOF;
$type
new(...)
    CODE:
	switch (items) {
	case 0:
	  New(0, RETVAL, 1, $ctype);
	  EXTEND(sp, 1);
	  break;
	case 1:
	  New(0, RETVAL, 1, $ctype);
	  break;
	case 2:
	  if (sv_derived_from(ST(1), "$type")) {
	    IV tmp = SvIV((SV*)SvRV(ST(1)));
	    New(0, RETVAL, 1, $ctype);
	    *RETVAL = *($ftype)tmp;
	  }
	  else
	    croak("arg is not of type type");
	  break;
	default:
	  croak("Usage: ${type}::new([arg])");
	}

    OUTPUT:
	RETVAL

EOF
}

sub sizeof {
  my ($type, $ctype) = @_;

  return <<EOF;
unsigned int
sizeof()
    CODE:
	EXTEND(sp, 1);
	RETVAL = sizeof($ctype);

    OUTPUT:
	RETVAL

EOF
}

sub RPCL::Type::destruct_field {}

sub RPCL::TypeVarStr::destruct_field {
  my ($self, $ident, $u) = @_;
  return "	safefree(arg->${u}$ident);\n"
}

sub RPCL::TypeVarOpq::destruct_field {
  my ($self, $ident, $u) = @_;
  return "	safefree(arg->${u}$ident.${ident}_val);\n"
}

sub RPCL::StructDef::destructor {
  my ($self, $mod) = @_;
  my $type = $self->perltype($mod);
  my $ctype = $self->ctype;
  my $des;

  $des = <<EOF;
void
DESTROY(arg)
    $type arg

    CODE:
EOF

  foreach $decl (@{$self->decls}) {
    $des .= $decl->type->destruct_field($decl->ident);
  }

  $des .= <<EOF;
	safefree(arg);

EOF

  return $des;
}

sub RPCL::UnionDef::destructor {
  my ($self, $mod) = @_;
  my $type = $self->perltype($mod);
  my $ctype = $self->ctype;
  my $ident = $self->ident;
  my $des;

  $des = <<EOF;
void
DESTROY(arg)
    $type arg

    CODE:
EOF

  my $u = $ident . '_u.';
  foreach $case (@{$self->cases}) {
    $des .= $case->decl->type->destruct_field($case->decl->ident, $u);
  }

  $des .= <<EOF;
	safefree(arg);

EOF

  return $des;
}

1;
