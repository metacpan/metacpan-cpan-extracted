use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 1;
use Unicode::Util qw( graph_reverse );

# Unicode::Util tests for graph_reverse

# 'ю́xя̡̅̈' to 'я̡̅̈xю́'
is(
    graph_reverse("\x{44E}\x{301}x\x{44F}\x{305}\x{308}\x{321}"),
    "\x{44F}\x{305}\x{308}\x{321}x\x{44E}\x{301}",
    'graph_reverse on grapheme clusters'
);
