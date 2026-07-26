# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Test for comma-separated selectors
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass  = <<'EOT';
#id {
  a .abc, b .def {
    color: #fff;
  }
}
EOT

  my $css = <<EOT;
#id a .abc, #id b .def {
  color: #fff;
}
EOT

  my $ts = Text::Sass->new();

  is($ts->scss2css($sass), $css, "Comma-separated selectors");
}