# -*- perl -*-
use strict;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/local/lib/perl5";
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my $site = __PACKAGE__->new(
    app_root => $FindBin::Bin,
    doc_root => "$FindBin::Bin/public",
    (-d "$FindBin::Bin/ytmpl" ? (app_base => '@ytmpl') : ()),
  );

  ## You may prefer below since it supports app.yml:
  #
  # my $site = MY->load_factory_for_psgi($0, environment => $ENV{PLACK_ENV} // 'development', %opts);
  #

  $site->to_app;
}
