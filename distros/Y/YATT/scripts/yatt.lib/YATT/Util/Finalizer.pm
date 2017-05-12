# -*- mode: perl; coding: utf-8 -*-
package YATT::Util::Finalizer;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use base qw(Exporter);
BEGIN {
  our @EXPORT    = qw(with_select capture finally);
  our @EXPORT_OK = @EXPORT;
}

sub new {
  my ($pack, $code) = splice @_, 0, 2;
  bless [$code, @_], $pack;
}

sub finally (&@) {
  __PACKAGE__->new(@_);
}

sub DESTROY {
  my $self = shift;
  if ($@) {
    # XXX: This can be hard to catch.
    syswrite STDOUT, "\n\n[$@]" if $ENV{DEBUG_ERROR};
  }
  my $code = $self->[0] or return;
  $code->(@$self[1 .. $#$self]);
}

sub cancel {
  undef shift->[0];
}

sub with_select {
  # newfh, body, [strref]
  my $strref;
  unless (defined $_[0]) {
    $strref = $_[2] || do {my $str = ""; \$str};
    open $_[0], '>', $strref or die "Can't open strref: $!";
  }
  my $finalizer = finally {
    select($_[0]);
  } select;
  select($_[0]);
  $_[1]->($finalizer);
  defined $strref && $$strref;
}

sub capture (&@) {
  with_select my ($fh), $_[0];
}

1;
