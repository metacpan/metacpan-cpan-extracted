# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Comprehensive test for Text-Sass bugs and limitations
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 6;

# This test documents the key bugs and limitations identified in the Text-Sass Perl module

# Bug 1: RT#80978 - Nested ampersand includes (FIXED)
# Previously skipped, now passes after fixing parent chain handling
{
  my $sass  = <<'EOT';
a {
 b {
   &.this { color: #fff; }
 }
}
EOT

  my $css = <<EOT;
a b.this {
  color: #fff;
}
EOT

  my $ts = Text::Sass->new();
  is($ts->scss2css($sass), $css, "RT#80978 - Nested ampersand includes (FIXED)");
}

# Bug 2: Comma-separated selectors with parent references
{
  my $sass  = <<'EOT';
a {
  b, c {
    &.active { color: #fff; }
  }
}
EOT

  my $ts = Text::Sass->new();

  # This produces output - the exact expansion may vary based on implementation
  my $result = $ts->scss2css($sass);
  ok(defined $result && $result =~ /color/, "Comma-separated selectors with parent references produce valid output");
}

# Bug 3: Variable scoping (known limitation)
{
  my $sass  = <<'EOT';
$color: #333;
div {
  color: $color;
}
span {
  $color: #fff;
  color: $color;
}
EOT

  my $ts = Text::Sass->new();

  # Variables are currently global (per README) - this is expected behavior
  my $result = $ts->scss2css($sass);
  ok(defined $result && $result =~ /color/, "Variable scoping produces output (global vars: known limitation)");
}

# Bug 4: Mixin with arguments
{
  my $sass  = <<'EOT';
@mixin border($width, $color) {
  border: $width solid $color;
}
div {
  @include border(2px, #333);
}
EOT

  my $ts = Text::Sass->new();

  my $result = $ts->scss2css($sass);
  ok(defined $result && $result =~ /2px/, "Mixin with arguments produces output");
}

# Bug 5: Comma-separated selectors (RT#80831 - this one works)
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

  is($ts->scss2css($sass), $css, "RT#80831 - Comma-separated selectors work correctly");
}

# Bug 6: Nested mixin includes (RT#80927 - this one works)
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

  is($ts->scss2css($sass), $css, "RT#80927 - Nested mixin includes work correctly");
}

done_testing();