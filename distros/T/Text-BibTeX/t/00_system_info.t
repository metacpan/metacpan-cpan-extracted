#!perl

use strict;
use warnings;
use Test::More tests => 1;

use_ok('Text::BibTeX');
diag "Text::BibTeX $Text::BibTeX::VERSION, perl $^V, "
   . "Unicode tables " . Text::BibTeX::unicode_version();
