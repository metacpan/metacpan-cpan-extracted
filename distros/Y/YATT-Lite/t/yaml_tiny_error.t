#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::Lite::WebMVC0::SiteApp;

SKIP: {
  eval { require YAML::Tiny };
  skip "YAML::Tiny is not installed.", 1 if $@;
  
  my $version = YAML::Tiny->VERSION // 'unkown';
  diag "YAML::Tiny version ... $version";

  my $site = YATT::Lite::WebMVC0::SiteApp->new();

  eval { $site->read_file("dummy.yml") };
  my $error = $@ // '';
  $error =~ s/\n+$//;
  ok $error =~ qr/does not exist/, "raise error: $error";
}

done_testing();
