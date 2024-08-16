#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { local @_ = "$FindBin::Bin/.."; do "$FindBin::Bin/../t_lib.pl" }
#----------------------------------------
use utf8;

use Test::More;
use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp -as_base;
use YATT::Lite qw/Entity/;


BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      diag("$req is not installed.");
      skip_all();
    }
    $req->import;
  }
}

#========================================

use lib "$FindBin::Bin/lib";

{
  my $client = do {

    my $app_root = untaint_any($FindBin::Bin);

    my $site = MY->new(
      app_root => $app_root,
      doc_root => "$app_root/public",
      (-d "$app_root/ytmpl" ? (app_base => '@ytmpl') : ()),
      header_charset => 'utf-8',
      tmpl_encoding => 'utf-8',
      output_encoding => 'utf-8',
    );

    Entity source_of_runtime_error => sub {
      my ($this) = @_;
      require MyBackendFOOBAR;
      'MyBackendFOOBAR';
    };

    Plack::Test->create($site->to_app);
  };

  subtest "runtime module error", sub {
    my $res = $client->request(GET "/");

    like $res->content, qr/MissingUnknownModuleFooBarBaz/;
  };
}

#========================================
done_testing();

