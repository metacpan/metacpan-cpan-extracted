# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########

use strict;
use warnings;
use Text::Sass;
use Test::More tests => 2;

{
  my $scss = <<'EOT';
li {
  background: darken(darken(#3bbfce, 9%), 1%);
}
EOT

  SKIP: {
    skip "Nested function calls don't work", 1;
    my $ts = Text::Sass->new();
    like($ts->scss2css($scss), qr/\Qbackground: #299daa;\E/,
      "nested function calls");
  }
}

{
  my $scss = <<'EOT';
$blue: #3bbfce;
$darkBlue: darken($blue, 9%);
li {
  background: darken($darkBlue, 1%);
}
EOT

  my $ts = Text::Sass->new();
  like($ts->scss2css($scss), qr/\Qbackground: #299daa;\E/,
    "nested function calls created via intermediate variable");
}

