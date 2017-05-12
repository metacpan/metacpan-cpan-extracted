use strict;
use warnings;
use Test::More tests => 1;
use Text::Sass;

{
  my $str = <<"EOT";
/* This comment is
 * several lines long.
 * since it uses the CSS comment syntax,
 * it will appear in the CSS output. */
body { color: black; }

// These comments are only one line long each.
// They won't appear in the CSS output,
// since they use the single-line comment syntax.
a { color: green; }
EOT

  my $sass = Text::Sass->new;
  is($sass->scss2css($str), <<"EOT", "strip multi-line and single-line comments");
body {
  color: black;
}

a {
  color: green;
}
EOT
}
