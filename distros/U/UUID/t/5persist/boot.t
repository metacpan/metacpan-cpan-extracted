# 
# make sure internals work.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use File::Spec ();
use Try::Tiny;

require UUID;

ok 1, 'loaded';

sub t (&) {
    my $t = shift;
    my ($rv, $err);
    $rv = try { $t->() }
        catch { $err = $_; undef };
    return $rv, $err;
}

my ($rv, $er);

##############################################################################
# make sure we can get the state path.
#

# default statepath is disabled, so undef.
($rv,$er) = t{ UUID::_statepath() };
is $rv, undef, 'statepath seems to work';
is $er, undef, 'statepath works';

# get statepath, with args.
($rv,$er) = t{ UUID::_statepath(0) };
is $rv, undef,        'statepath with too many dies';
like $er, qr/Usage:/, 'statepath with too many error';

##############################################################################
# set state path.
#

# set to custom
($rv,$er) = t{ UUID::_persist('foo') };
ok $rv,        'persist seems to work';
is $er, undef, 'persist works';

# check
($rv,$er) = t{ UUID::_statepath() };
is $rv, 'foo', 'path correct';
is $er, undef, 'path correct no error';

# set to custom, too few args
($rv,$er) = t{ UUID::_persist() };
is $rv, undef,        'persist too few seems to die';
like $er, qr/Usage:/, 'persist too few dies';

# recheck
($rv,$er) = t{ UUID::_statepath() };
is $rv, 'foo', 'path still correct';
is $er, undef, 'path still correct no error';

# set to custom, too many args
($rv,$er) = t{ UUID::_persist(qw(foo bar bam)) };
is $rv, undef,        'persist too many seems to die';
like $er, qr/Usage:/, 'persist too many dies';

# rerecheck
($rv,$er) = t{ UUID::_statepath() };
is $rv, 'foo', 'path really still correct';
is $er, undef, 'path really still correct no error';

##############################################################################
# disable state paths.
#

# disable
($rv,$er) = t{ UUID::_persist(undef) };
is $rv, 1,     'persist undef seems to work';
is $er, undef, 'persist undef works';

# check
($rv,$er) = t{ UUID::_statepath() };
is $rv, undef, 'disable seems correct';
is $er, undef, 'disable correct';

done_testing;
