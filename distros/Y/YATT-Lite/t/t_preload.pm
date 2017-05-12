package
  YATT::t::t_preload;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
BEGIN { do "$FindBin::Bin/t_lib.pl" }

#
# Without these preloading, some tests failed under Devel::Cover
# (Caused by warnings like "Can't open ... for MD5 digest")
#
use YATT::Lite::LRXML ();
use YATT::Lite::LRXML::ParseBody ();
use YATT::Lite::LRXML::ParseEntpath ();
use YATT::Lite::Core ();
use YATT::Lite::CGen::Perl ();


1;
