package YATT::Util::redundant_sprintf;
use strict;
use warnings qw(FATAL all NONFATAL misc);

sub import {
  warnings->unimport(qw/redundant/) if $] >= 5.021002;
}

1;
