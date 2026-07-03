use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok('Text::AsciidocDown');
  use_ok('Text::AsciidocDown::Include');
  use_ok('Text::AsciidocDown::Parser');
  use_ok('Text::AsciidocDown::Subs');
  use_ok('Text::AsciidocDown::Refs');
}

done_testing;
