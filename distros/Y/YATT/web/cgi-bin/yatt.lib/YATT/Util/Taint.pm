# -*- mode: perl; coding: utf-8 -*-
package YATT::Util::Taint;
use base qw(Exporter);
use strict;
use warnings qw(FATAL all NONFATAL misc);

BEGIN {
  our @EXPORT_OK = qw(&untaint_any &is_tainted);
  our @EXPORT    = @EXPORT_OK;
}

if (eval {require Scalar::Util} and not $@) {
  *is_tainted = \&Scalar::Util::tainted;
} else {
  *is_tainted = sub {
    return not eval { eval("#" . substr(join("", @_), 0, 0)); 1 };
  };
}

sub untaint_any ($) {
  $1 if defined $_[0] && $_[0] =~ m{(.*)}s;
}

1;
