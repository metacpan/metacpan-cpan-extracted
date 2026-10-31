# -*- perl -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN {
  FindBin::again();
  local @_ = "$FindBin::Bin/../.."; do "$FindBin::Bin/../../t_lib.pl";
}


use mro 'c3';
use YATT::Lite::WebMVC0::SiteApp -as_base;

{
  my $site = MY->load_factory_for_psgi(
    $0,
    doc_root => "$FindBin::Bin/public",
  );

  return $site if $site->want_object;

  return $site->to_app;
}
