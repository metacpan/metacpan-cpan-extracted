# -*- perl -*-
use strict;
use warnings;

use FindBin; BEGIN {FindBin->again}

use YATT::Lite::WebMVC0::SiteApp -as_base;

my $app_root = $FindBin::Bin;
{
  my MY $site = MY->load_factory_for_psgi(
    $0,
    doc_root => "$app_root/public",
  );

  return $site if MY->want_object;

  return $site->to_app;
}
