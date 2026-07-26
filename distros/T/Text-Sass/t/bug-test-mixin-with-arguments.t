# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Test for mixin with arguments
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 1;

{
  my $sass  = <<'EOT';
@mixin border($width, $color) {
  border: $width solid $color;
}
div {
  @include border(2px, #333);
}
EOT

  my $css = <<EOT;
div {
  border: 2px solid #333;
}
EOT

  my $ts = Text::Sass->new();

  is($ts->scss2css($sass), $css, "Mixin with arguments");
}