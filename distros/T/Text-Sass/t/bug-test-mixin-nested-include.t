# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Test for nested mixin includes
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass  = <<'EOT';
@mixin test { color: #fff; }
p {
   .a {
     .b {
        @include test;
     }
   }
   .c { @include test; }
}
EOT

  my $css = <<EOT;
p .a .b {
  color: #fff;
}

p .c {
  color: #fff;
}
EOT

  my $ts = Text::Sass->new();

  is($ts->scss2css($sass), $css, "Nested mixin includes");
}