package tnodebug;

use constant::def DEBUG => 0;

DEBUG and warn  "DIAG: tnodebug have overriden no DEBUG 0 => 1";
DEBUG or  print "PROD: tnodebug have no DEBUG\n";

1;
