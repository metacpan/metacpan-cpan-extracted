# -*- mode: perl; coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { local @_ = "$FindBin::Bin/.."; do "$FindBin::Bin/../t_lib.pl" }

my $app_root = ::dirname(::untaint_any(__FILE__));

use YATT::Lite::WebMVC0::SiteApp -as_base;

{
  my MY $dispatcher = do {
    my @args = (app_ns => 'MyApp'
                , app_root => $app_root
                , doc_root => $app_root);
    MY->new(@args);
  };

  return $dispatcher->to_app;
}
