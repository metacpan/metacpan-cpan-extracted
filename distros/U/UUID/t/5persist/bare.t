#
# make sure bare :persist barfs.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use Try::Tiny;

require UUID;

ok 1, 'loaded';

sub t (&) {
    local $SIG{__WARN__} = sub {};
    my $t = shift;
    my ($rv, $err);
    $rv = try { $t->() } catch { $err = $_; undef };
    return $rv, $err;
}

my ($rv,$er) = t{ UUID->import(':persist') };
is $rv, undef,       'persist seems to die';
like $er, qr/error/, 'persist dies';

done_testing;
