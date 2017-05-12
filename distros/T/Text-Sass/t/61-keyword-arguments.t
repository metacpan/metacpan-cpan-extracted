# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########

use strict;
use warnings;
use Text::Sass;
use Test::More tests => 2;

# TODO: Check whole CSS when keyword arguments are implemented

{
  my $scss = <<'EOT';
$s: bla;
li {
  content: quote($string: $s);
}
EOT

  my $ts = Text::Sass->new();
  like($ts->scss2css($scss), qr/\bbla\b/,
    "variable substitution in keyword argument");
}

{
  my $scss = <<'EOT';
$s: bla;
li {
  content: quote($string:$s);
}
EOT

  my $ts = Text::Sass->new();
  like($ts->scss2css($scss), qr/\bbla\b/,
    "variable substitution in keyword argument after missing space");
}
