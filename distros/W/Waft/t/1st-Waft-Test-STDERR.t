
use Test;
BEGIN { plan tests => 3 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use English qw( -no_match_vars );
use Symbol;

use lib 't';
require Waft::Test::STDERR;

my $duplicate = gensym;

open $duplicate, '>&STDERR'
    or die 'Failed to duplicate STDERR';

open STDERR, '>t/STDERR.tmp'
    or die 'Failed to open STDERR piped to file';

warn "$PROGRAM_NAME-1\n";

my $gotten = do {
    my $stderr = Waft::Test::STDERR->new;

    warn "$PROGRAM_NAME-2\n";

    $stderr->get;
};

warn "$PROGRAM_NAME-3\n";

open STDERR, '>&=' . fileno $duplicate
    or die 'Failed to return STDERR';

unlink 't/STDERR.tmp';

ok( $gotten !~ / \Q$PROGRAM_NAME\E-1 /xms );
ok( $gotten =~ / \Q$PROGRAM_NAME\E-2 /xms );
ok( $gotten !~ / \Q$PROGRAM_NAME\E-3 /xms );
