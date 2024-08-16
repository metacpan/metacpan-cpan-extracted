# -*- perl -*-
use strict;
use FindBin;
use lib "$FindBin::Bin/lib", do {
  # Below finds lib/YATT and adds it to @INC. Usually not required for your App.
  do "$FindBin::Bin/util/find_yatt_lib.pl";
};

use YATT::Lite::WebMVC0::SiteApp -as_base;

use YATT::Lite::WebMVC0::Partial::Session3;
{
  my $site = MY->load_factory_for_psgi($0, environment => $ENV{PLACK_ENV} // 'development');

  $site->to_app;
}
