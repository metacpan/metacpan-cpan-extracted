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
    # use a number here. does it see a PV?
    @OPTS = ':persist=8675309';
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

my ($rv,$er) = t{ UUID::_persist() };
is $rv, 8675309, 'path seems correct';
is $er, undef,   'path correct';

done_testing;
