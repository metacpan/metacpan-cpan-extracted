#!perl
# Usage: perl leaktrace.pl [--weak]
use utf8;
use strict;
use warnings;
use Test::LeakTrace;
use Test::More;
use Text::Sass::XS qw(sass_compile);

my $source = <<'SASS';
// Variable Definitions

$page-width:    800px;
$sidebar-width: 200px;
$primary-color: #eeeeee;

// Global Attributes

body {
  font: {
    family: sans-serif;
    size: 30em;
    weight: bold;
  }
}

// Scoped Styles

#contents {
  width: $page-width;
  #sidebar {
    float: right;
    width: $sidebar-width;
  }
  #main {
    width: $page-width - $sidebar-width;
    background: $primary-color;
    h2 { color: blue; }
  }
}

#footer {
  height: 200px;
}
SASS

no_leaks_ok {
    sass_compile( $source, { output_style => 3, source_comments => 0 } );
};

done_testing;
