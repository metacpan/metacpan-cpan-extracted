package tdebug;

use constant::def DEBUG => 1;

DEBUG and warn  "DIAG: tdebug have DEBUG=1\n";
DEBUG or  print "PROD: tdebug have overriden DEBUG 1 => 0\n";

1;
