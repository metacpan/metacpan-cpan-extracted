#
# make sure :persist=FOO works.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use Try::Tiny;

use vars '@OPTS';

BEGIN {
    @OPTS = ':persist=foo';
    ok 1, 'began';
}

use UUID @OPTS;

ok 1, 'loaded';

sub t (&) {
    my $t = shift;
    my ($rv, $err);
    $rv = try { $t->() }
        catch { $err = $_; undef };
    return $rv, $err;
}

my ($rv,$er) = t{ UUID::_statepath() };
is $rv, 'foo', 'path seems correct';
is $er, undef, 'path correct';

done_testing;
