package YATT::Lite::Util::CGICompat;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use YATT::Lite::Util qw/globref symtab/;

use CGI;

sub import {
  unless (symtab('CGI')->{'multi_param'}) {
    *{globref('CGI', 'multi_param')} = sub {
      shift->param(@_);
    };
  }
}

1;
