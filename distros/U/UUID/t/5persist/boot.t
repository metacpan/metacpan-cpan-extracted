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
my $FILE = __FILE__;
$FILE =~ s/\\/\\\\/g; # windows!

##############################################################################
# make sure we can get the state path.
#

# default statepath is disabled, so undef.
($rv,$er) = t{ UUID::_persist() };
is $rv, undef, 'default path seems correct';
is $er, undef, 'default path correct';

##############################################################################
# set state path.
#

# set to custom (use number as test)
($rv,$er) = t{ UUID::_persist(8675309) };
ok $rv,        'persist seems to work';
is $er, undef, 'persist works';

# check
($rv,$er) = t{ UUID::_persist() };
is $rv, '8675309', 'path correct';
is $er, undef,     'path correct no error';

# recheck (as number)
($rv,$er) = t{ UUID::_persist() };
is $rv, 8675309, 'path still correct';
is $er, undef,   'path still correct no error';

# set to custom, too many args
($rv,$er) = t{ UUID::_persist(qw(foo bar bam)) };
#note $er;
is $rv, undef,               'persist too many seems to die';
like $er, qr/Usage:/,        'persist too many dies';
like $er, qr/at $FILE line/, 'persist too many location';

# rerecheck
($rv,$er) = t{ UUID::_persist() };
is $rv, '8675309', 'path really still correct';
is $er, undef,     'path really still correct no error';

##############################################################################
# disable state paths.
#

# disable
($rv,$er) = t{ UUID::_persist(undef) };
is $rv, 1,     'persist undef seems to work';
is $er, undef, 'persist undef works';

# check
($rv,$er) = t{ UUID::_persist() };
is $rv, undef, 'disable seems correct';
is $er, undef, 'disable correct';

done_testing;
