# -*- perl -*-
use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my $site = __PACKAGE__->new(app_root => $FindBin::Bin,
                              doc_root => "$FindBin::Bin/html");
  $site->to_app;
}
