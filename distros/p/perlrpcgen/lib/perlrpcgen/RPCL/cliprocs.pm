# $Id: cliprocs.pm,v 1.8 1997/05/01 22:06:57 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# cliprocs takes a module name and a filehandle reference and prints XS
# stubs for client procedures to the filehandle.

sub RPCL::Syntax::cliprocs {}

sub RPCL::ProgramDef::cliprocs {
    my ($self, $mod, $fh) = @_;
    foreach $ver (@{$self->versions}) {
	$ver->cliprocs($mod, $fh);
    }
}

sub RPCL::Version::cliprocs {
    my ($self, $mod, $fh) = @_;
    foreach $proc (@{$self->procedures}) {
	$proc->cliprocs($mod, $self->value, $fh);
    }
}

sub RPCL::Procedure::cliprocs {
  my ($self, $mod, $version, $fh) = @_;
  my $ret = $self->rettype->perltype($mod);
  my $arg = $self->argtype->perltype($mod);
  my $proc = lc($self->ident) . '_' . $version;
  my $argref = $self->argtype->ref;
  my $retderef = $self->rettype->deref;

  if ($ret eq 'void') {
    if ($arg eq 'void') {
      print $fh <<EOF;
$ret
$proc(clnt)
    RPC::ONC::Client clnt

    CODE:
	if ($proc(0, clnt) == 0) {
	  char *msg = clnt_sperror(clnt, "${mod}::$proc");
	  set_perl_error_clnt(clnt);
	  croak(msg);
	}

EOF
    }
    else {
      print $fh <<EOF;
$ret
$proc(clnt,arg)
    RPC::ONC::Client clnt
    $arg arg

    CODE:
	if ($proc(${argref}arg, clnt) == 0) {
	  char *msg = clnt_sperror(clnt, "${mod}::$proc");
	  set_perl_error_clnt(clnt);
	  croak(msg);
	}

EOF
    }
  }
  else {
    if ($arg eq 'void') {
      print $fh <<EOF;
$ret
$proc(clnt)
    RPC::ONC::Client clnt

    CODE:
	if ((RETVAL = ${retderef}$proc(0, clnt)) == 0) {
	  char *msg = clnt_sperror(clnt, "${mod}::$proc");
	  set_perl_error_clnt(clnt);
	  croak(msg);
	}

    OUTPUT:
	RETVAL

EOF
    }
    else {
      print $fh <<EOF;
$ret
$proc(clnt,arg)
    RPC::ONC::Client clnt
    $arg arg

    CODE:
	if ((RETVAL = ${retderef}$proc(${argref}arg, clnt)) == 0) {
	  char *msg = clnt_sperror(clnt, "${mod}::$proc");
	  set_perl_error_clnt(clnt);
	  croak(msg);
	}

    OUTPUT:
	RETVAL

EOF
    }
  }
}

1;
