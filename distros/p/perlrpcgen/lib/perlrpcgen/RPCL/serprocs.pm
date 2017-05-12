# $Id: serprocs.pm,v 1.5 1997/04/30 04:30:08 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# serprocs generates C stubs which are called by the RPC driver
# code. They convert arguments into the right thing and pass
# everything to callperl().

sub RPCL::Syntax::serprocs {}

sub RPCL::ProgramDef::serprocs {
    my ($self, $mod, $fh) = @_;
    foreach $ver (@{$self->versions}) {
	$ver->serprocs($mod, $fh);
    }
}

sub RPCL::Version::serprocs {
    my ($self, $mod, $fh) = @_;
    foreach $proc (@{$self->procedures}) {
	$proc->serprocs($mod, $self->value, $fh);
    }
}

sub RPCL::Type::freestruct {}

sub RPCL::StructDef::freestruct {
  my ($self) = @_;
  my $ctype = $self->ctype;
  return <<EOF

      if (ret) {
	xdr_free(xdr_$ctype, (char *)ret);
	free(ret);
      }
EOF
}

*{RPCL::UnionDef::freestruct} = \&RPCL::StructDef::freestruct;

sub RPCL::Procedure::serprocs {
  my ($self, $mod, $version, $fh) = @_;
  my $ret = $self->rettype->ctype . " *";
  my $arg = $self->argtype->ctype . " *";
  my $proc = lc($self->ident) . '_' . $version;
  my $argderef = $self->argtype->deref;
  my $retref = $self->rettype->ref;
  my $argcheck = &type_outcheck($self->argtype->perltype($mod), 'arg',
				"(${argderef}argp)")
    unless $arg eq 'void *';
  my $retcheck = &type_incheck($self->rettype->perltype($mod), 'pret', 'ret')
    unless $ret eq 'void *';
  my $rret = $ret;
  my $freestruct = $self->rettype->freestruct;

  # cancel the pointer if return needs to be dereferenced.
  if ($retref) {
    $rret =~ s/ \*$//;
  }

  if ($ret eq 'void *') {
    if ($arg eq 'void *') {
      print $fh <<EOF;
$ret
$proc($arg argp, struct svc_req *rqstp, SVCXPRT *transp)
{
    static char *result;
    callperl("$proc", 0, rqstp, transp, 0);
    return (void *)&result;
}

EOF
    }
    else {
      print $fh <<EOF;
$ret
$proc($arg argp, struct svc_req *rqstp, SVCXPRT *transp)
{
    SV *arg = sv_newmortal();
    static char *result;
$argcheck
    callperl("$proc", arg, rqstp, transp, 0);
    return (void *)&result;
}

EOF
    }
  }
  else {
    if ($arg eq 'void *') {
      print $fh <<EOF;
$ret
$proc($arg argp, struct svc_req *rqstp, SVCXPRT *transp)
{
    static SV *pret = 0;
    static $rret ret;

    if (pret) {$freestruct
      SvREFCNT_dec(pret);
    }
    pret = callperl("$proc", 0, rqstp, transp, 1);
$retcheck;
    return ${retref}ret;
}

EOF
    }
    else {
      print $fh <<EOF;
$ret
$proc($arg argp, struct svc_req *rqstp, SVCXPRT *transp)
{
    static SV *pret = 0;
    SV *arg = sv_newmortal();
    static $rret ret;

    if (pret) {$freestruct
      SvREFCNT_dec(pret);
    }
$argcheck
    pret = callperl("$proc", arg, rqstp, transp, 1);
$retcheck;
    return ${retref}ret;
}

EOF
    }
  }
}

# This is all kind of gory. It would be nice to have a typemap
# abstraction for manipulating them.

sub main::type_outcheck {
  my ($type, $arg, $var) = @_;
  my $kind = $main::type_kind{$type};
  $kind = $main::typemap{$type} unless $kind;
  warn("No typemap for $type") unless $kind;
  my $ntype = $type;
  $type =~ tr/:/_/;
  # first look in external typemap...
  my $expr = $main::output_expr{$kind};
  # then in the one we're generating.
  $expr = $main::typeout{$kind} unless $expr;
  warn("No OUTPUT for $kind") unless $expr;
  return eval qq/"$expr"/;
}

sub main::type_incheck {
  my ($type, $arg, $var) = @_;
  my $kind = $main::type_kind{$type};
  $kind = $main::typemap{$type} unless $kind;
  warn("No typemap for $type") unless $kind;
  my $ntype = $type;
  $type =~ tr/:/_/;
  # first look in external typemap...
  my $expr = $main::input_expr{$kind};
  # then in the one we're generating.
  $expr = $main::typein{$kind} unless $expr;
  warn("No INPUT for $kind") unless $expr;
  return eval qq/"$expr"/;
}

1;
