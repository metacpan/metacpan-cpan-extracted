use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 2;
use Unicode::Util qw( graph_chop code_chop );

# Unicode::Util tests for graph_chop and code_chop

my $grapheme = "x\x{44E}\x{301}";  # xю́

is graph_chop($grapheme), 'x', 'graph_chop returns all but the last grapheme';
is code_chop($grapheme), "x\x{44E}", 'code_chop returns all but the last codepoint';
