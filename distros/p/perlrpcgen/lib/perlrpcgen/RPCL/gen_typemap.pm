# $Id: gen_typemap.pm,v 1.6 1997/04/30 04:30:07 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# gen_typemap takes a module name, and populates a global hash
# $main::typemap of TypeMap structures describing the type map.

sub RPCL::Syntax::gen_typemap {}

sub RPCL::Decl::gen_typemap {
    my ($self, $mod) = @_;
    $self->type->gen_typemap($mod);
}

sub RPCL::Case::gen_typemap {
    my ($self, $mod) = @_;
    $self->decl->gen_typemap($mod);
}

sub RPCL::CaseDefault::gen_typemap {
    my ($self, $mod) = @_;
    $self->decl->gen_typemap($mod);
}

sub RPCL::ProgramDef::gen_typemap {
    my ($self, $mod) = @_;
    foreach $ver (@{$self->versions}) {
	$ver->gen_typemap($mod);
    }
}

sub RPCL::Version::gen_typemap {
    my ($self, $mod) = @_;
    foreach $proc (@{$self->procedures}) {
	$proc->gen_typemap($mod);
    }
}

sub RPCL::Procedure::gen_typemap {
    my ($self, $mod) = @_;
    $self->rettype->gen_typemap($mod);
    $self->argtype->gen_typemap($mod);
}

sub RPCL::Type::gen_typemap {
  my ($self, $mod) = @_;
  my $perltype = $self->perltype($mod);
  $main::typemap{$perltype} = $self->xstype;
  $main::typedef{$perltype} = $self->ctype;
}

sub RPCL::Type::gen_typein {}
sub RPCL::Type::gen_typeout {}

sub RPCL::TypeSimple::gen_typemap {}

sub RPCL::UnionDef::gen_typemap {
    my ($self, $mod) = @_;
    my $perltype = $self->perltype($mod);

    $self->RPCL::Type::gen_typemap($mod);
    $main::typedef{$perltype} = $self->ctype . " *";

    $self->decl->gen_typemap($mod);
    foreach $case (@{$self->cases}) {
	$case->gen_typemap($mod);
    }
}

sub RPCL::StructDef::gen_typemap {
    my ($self, $mod) = @_;
    my $perltype = $self->perltype($mod);

    $self->RPCL::Type::gen_typemap($mod);
    $main::typedef{$perltype} = $self->ctype . " *";

    foreach $decl (@{$self->decls}) {
	$decl->gen_typemap($mod);
    }
}

sub RPCL::StructPDef::gen_typemap {
    my ($self, $mod) = @_;
    my $perltype = $self->perltype($mod);

    $self->RPCL::Type::gen_typemap($mod);
    $main::typedef{$perltype} = $self->ctype;

    foreach $decl (@{$self->decls}) {
	$decl->gen_typemap($mod);
    }
}

sub RPCL::EnumDef::gen_typemap {
    my ($self, $mod) = @_;

    $self->RPCL::Type::gen_typemap($mod);
}

sub RPCL::TypedefDef::gen_typemap {
    my ($self, $mod) = @_;

    $self->RPCL::Type::gen_typemap($mod);
    $self->type->gen_typein($mod);
    $self->type->gen_typeout($mod);
}

sub RPCL::TypeFixedArr::gen_typemap {
  my ($self, $mod) = @_;
  $self->RPCL::Type::gen_typemap($mod);
  $self->gen_typein($mod);
  $self->gen_typeout($mod);
}

sub RPCL::TypeFixedArr::gen_typein {
  my ($self, $mod) = @_;
  my $size = $self->size->value;
  my $xstype = $self->xstype;
  my $perltype = $self->type->perltype($mod);
  my $ctype = $self->type->ctype;
  my $incheck = &type_incheck($perltype, 'pelem', '\\$var[i]');
  $incheck =~ s/"/\\"/g;

  $main::typein{$xstype} = <<EOF;
    {
      char *msg = \\"\$var must be ref to array of $size $perltype\\";
      AV *av;
      int i;

      if (!SvROK(\$arg) || SvTYPE(SvRV(\$arg)) != SVt_PVAV)
	croak(msg);

      av = (AV *)SvRV(\$arg);
      if (av_len(av) +1 != $size)
	croak(msg);

      for (i=0; i<$size; i++) {
	SV *pelem = *av_fetch(av, i, 0);
	$incheck;
      }
    }
EOF
}

sub RPCL::TypeFixedArr::gen_typeout {
  my ($self, $mod) = @_;
  my $size = $self->size->value;
  my $xstype = $self->xstype;
  my $perltype = $self->type->perltype($mod);
  my $outcheck = &type_outcheck($perltype, 'pelem', '\\$val[i]');
  $outcheck =~ s/"/\\"/g;

  $main::typeout{$xstype} = <<EOF;
    {
      AV *av = newAV();
      int i;

      av_extend(av, $size);
      for (i=0; i<$size; i++) {
	SV *pelem = sv_newmortal();
	$outcheck
	av_store(av, i, pelem);
      }

      \$arg = newRV((SV *)av);
    }
EOF
}

sub RPCL::TypeFixedOpq::gen_typemap {
  my ($self, $mod) = @_;
  $self->RPCL::Type::gen_typemap($mod);
  $self->gen_typein($mod);
  $self->gen_typeout($mod);
}

sub RPCL::TypeFixedOpq::gen_typein {
  my ($self, $mod) = @_;
  my $size = $self->size->value;
  my $xstype = $self->xstype;

  $main::typein{$xstype} = <<EOF;
    {
      int len;
      \$var = (\$type)SvPV(\$arg, len);
      if (len != $size)
	croak(\\"\$var must be a string of length $size\\");
    }
EOF
}

sub RPCL::TypeFixedOpq::gen_typeout {
  my ($self, $mod) = @_;
  my $xstype = $self->xstype;
  my $size = $self->size->value;

  $main::typeout{$xstype} = <<EOF;
    sv_setpvn((SV *)\$arg, \$var, $size);
EOF
}

sub RPCL::TypeFixedStr::gen_typemap {
  my ($self, $mod) = @_;
  $self->RPCL::Type::gen_typemap($mod);
  $self->gen_typein($mod);
  $self->gen_typeout($mod);
}

sub RPCL::TypeFixedStr::gen_typein {
  my ($self, $mod) = @_;
  my $size = $self->size->value;
  my $xstype = $self->xstype;

  $main::typein{$xstype} = <<EOF;
    {
      int len;
      \$var = (\$type)SvPV(\$arg, len);
      if (len != $size)
	croak(\\"\$var must be a string of length $size\\");
    }
EOF
}

sub RPCL::TypeFixedStr::gen_typeout {
  my ($self, $mod) = @_;
  my $xstype = $self->xstype;

  $main::typeout{$xstype} = <<EOF;
    sv_setpv((SV *)\$arg, \$var);
EOF
}

sub RPCL::TypeVarArr::gen_typemap {
  my ($self, $mod) = @_;
  $self->RPCL::Type::gen_typemap($mod);
  $self->gen_typein($mod);
  $self->gen_typeout($mod);
}

sub RPCL::TypeVarArr::gen_typein {
  my ($self, $mod) = @_;
  my $size = $self->size ? $self->size->value : undef;
  my $xstype = $self->xstype;
  my $perltype = $self->type->perltype($mod);
  my $ctype = $self->type->ctype;
  my $incheck = &type_incheck($perltype, 'pelem', '$var.val[i]');
  $incheck =~ s/"/\\"/g;

  if ($size) {
    $main::typein{$xstype} = <<EOF;
    {
      char *msg = \\"\$var must be ref to array of <= $size $perltype\\";
EOF
  }
  else {
    $main::typein{$xstype} = <<EOF;
    {
      char *msg = \\"\$var must be ref to array of $perltype\\";
EOF
  }

  $main::typein{$xstype} .= <<EOF;
      AV *av;
      int i;

      if (!SvROK(\$arg) || SvTYPE(SvRV(\$arg)) != SVt_PVAV)
	croak(msg);

      av = (AV *)SvRV(\$arg);
EOF

  if ($size) {
    $main::typein{$xstype} .= <<EOF;
      if ((\$var.len = (av_len(av) + 1)) > $size)
	croak(msg);
EOF
  }
  else {
    $main::typein{$xstype} .= <<EOF;
      \$var.len = av_len(av) +1;
EOF
  }

  $main::typein{$xstype} .= <<EOF;
      New(0, \$var.val, \$var.len, $ctype);
      for (i=0; i<\$var.len; i++) {
	SV *pelem = *av_fetch(av, i, 0);
	$incheck      }
    }
EOF

}

sub RPCL::TypeVarArr::gen_typeout {
  my ($self, $mod) = @_;
  my $size = $self->size ? $self->size->value : undef;
  my $xstype = $self->xstype;
  my $perltype = $self->type->perltype($mod);
  my $outcheck = &type_outcheck($perltype, 'pelem', '$var.val[i]');
  $outcheck =~ s/"/\\"/g;

  $main::typeout{$xstype} = <<EOF;
    {
      AV *av = newAV();
      int i;

      av_extend(av, \$var.len);
      for (i=0; i<\$var.len; i++) {
	SV *pelem = sv_newmortal();
	$outcheck
	av_store(av, i, pelem);
      }

      \$arg = newRV((SV *)av);
    }
EOF
}

sub RPCL::TypeVarOpq::gen_typemap {
  my ($self, $mod) = @_;
  $self->RPCL::Type::gen_typemap($mod);
  $self->gen_typein($mod);
  $self->gen_typeout($mod);
}

sub RPCL::TypeVarOpq::gen_typein {
  my ($self, $mod) = @_;
  my $size = $self->size ? $self->size->value : undef;
  my $xstype = $self->xstype;

  if ($size) {
    $main::typein{$xstype} = <<EOF;
    {
      char *buf = SvPV(\$arg, \$var.len);
      if (\$var.len > $size)
	croak(\\"\$var must be a string of length <= $size\\");
      New(0, \$var.val, \$var.len, char);
      Copy(buf, \$var.val, \$var.len, char);
    }
EOF
  }

  else {
    $main::typein{$xstype} = <<EOF;
    {
      char *buf = SvPV(\$arg, \$var.len);
      New(0, \$var.val, \$var.len, char);
      Copy(buf, \$var.val, \$var.len, char);
    }
EOF
  }
}

sub RPCL::TypeVarOpq::gen_typeout {
  my ($self, $mod) = @_;
  my $xstype = $self->xstype;

  $main::typeout{$xstype} = <<EOF;
    sv_setpvn((SV *)\$arg, \${var}.val, \${var}.len);
EOF
}

sub RPCL::TypeVarStr::gen_typemap {
  my ($self, $mod) = @_;
  $self->RPCL::Type::gen_typemap($mod);
  $self->gen_typein($mod);
  $self->gen_typeout($mod);
}

sub RPCL::TypeVarStr::gen_typein {
  my ($self, $mod) = @_;
  my $size = $self->size ? $self->size->value : undef;
  my $xstype = $self->xstype;

  if ($size) {
    $main::typein{$xstype} = <<EOF;
    {
      int len;
      char *buf = SvPV(\$arg, len);
      if (len > $size)
	croak(\\"\$var must be a string of length <= $size\\");
      New(0, \$var, len +1, char);
      Copy(buf, \$var, len +1, char);
    }
EOF
  }

  else {
    $main::typein{$xstype} = <<EOF;
    {
      int len;
      char *buf = SvPV(\$arg, len);
      New(0, \$var, len +1, char);
      Copy(buf, \$var, len +1, char);
    }
EOF
  }
}

sub RPCL::TypeVarStr::gen_typeout {
  my ($self, $mod) = @_;
  my $xstype = $self->xstype;

  $main::typeout{$xstype} = <<EOF;
    sv_setpv((SV *)\$arg, \$var);
EOF
}

# topological sort so typemaps come out right

sub RPCL::Syntax::topo_sort {
  my ($self, $marks, $order) = @_;
  $marks->{$self}++;
  push(@$order, $self);
}

sub RPCL::TypeFixedArr::topo_sort {
  my ($self, $marks, $order) = @_;
  $marks->{$self}++;
  $self->type->topo_sort($marks, $order) unless $marks->{$self->type};
  push(@$order, $self);
}

sub RPCL::TypeVarArr::topo_sort {
  my ($self, $marks, $order) = @_;
  $marks->{$self}++;
  print STDERR $self->type . "\n";
  $self->type->topo_sort($marks, $order) unless $marks->{$self->type};
  push(@$order, $self);
}

1;
