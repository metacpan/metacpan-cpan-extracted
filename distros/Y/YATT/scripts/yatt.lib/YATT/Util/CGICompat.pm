package YATT::Util::CGICompat;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use YATT::Util::Symbol qw/globref stash/;

use CGI;

sub import {
  unless (stash('CGI')->{'multi_param'}) {
    *{globref('CGI', 'multi_param')} = sub {
      shift->param(@_);
    };
  }
}

1;
