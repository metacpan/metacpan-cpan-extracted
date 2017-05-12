# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########

use strict;
use warnings;
use Text::Sass;
use Test::More tests => 6;

# $Text::Sass::DEBUG = 1;

my $css  = <<'EOT';
.border {
  margin: 16px;
}
EOT

{
  my $scss = <<'EOT';
$margin
  :  16px;

.border {
  margin: $margin;
}
EOT

  my $ts = Text::Sass->new();
  is($ts->scss2css($scss), $css, "multiline scss variable declaration");
}

{
  my $scss = <<'EOT';
$margin: 16px
;

.border {
  margin: $margin;
}
EOT

  my $ts = Text::Sass->new();
  is($ts->scss2css($scss), $css, "line break after scss variable declaration");
}

{
  my $scss = <<'EOT';
$margin :
floor(33px / 2);

.border {
  margin: $margin;
}
EOT

  my $ts = Text::Sass->new();
  is($ts->scss2css($scss), $css, "multiline scss variable declaration with function call");
}

{
  my $scss = <<'EOT';
.border {
  margin:
    16px
  ;
}
EOT

  my $ts = Text::Sass->new();
  is($ts->scss2css($scss), $css, "line break in simple property declaration");
}

# This snippet was causing infinite loop
{
  my $scss = <<'EOT';
$margin: 16px;
.border {
  margin:
    $margin;
}
EOT

  my $ts = Text::Sass->new();
  is($ts->scss2css($scss), $css, "line break in property declaration with variable");
}

{
  my $scss = <<'EOT';
$margin: 16px;
.title {
  margin:
    foo(
      $margin: 1
    );
}
.border {
  margin: $margin;
}
EOT

  my $ts = Text::Sass->new();
  like($ts->scss2css($scss), qr/\Q$css\E/, "line break in property declaration with variable");
}
