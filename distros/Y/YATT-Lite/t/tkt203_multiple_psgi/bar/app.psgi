# -*- perl -*-
use strict;
use FindBin;

# use lib "$FindBin::Bin/lib", "$FindBin::Bin/local/lib/perl5";
BEGIN { local @_ = "$FindBin::Bin/../.."; do "$FindBin::Bin/../../t_lib.pl" }

use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my $site = MY->load_factory_for_psgi(
    $0,
    app_root => $FindBin::Bin,
    doc_root => "$FindBin::Bin/public",
    (-d "$FindBin::Bin/ytmpl" ? (app_base => '@ytmpl') : ()),
  );

  return $site if $site->want_object;

  $site->to_app;
}
