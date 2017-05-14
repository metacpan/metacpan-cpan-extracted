use Test::Most 'die';

use lib 'lib';
use 5.12.0;
use Unknown::Values;

# Kleene's three-value logic

use constant true  => 1;
use constant false => 0;
my $value = unknown;

sub is_false($) {
    my $value = shift;
    return ( !$value && !is_unknown($value) );
}

# sanity
ok is_unknown unknown, 'unknown should be unknown';
ok !is_unknown undef, 'undef is not unknown';
ok !is_unknown false, 'a defined false value is not unknown';
ok !is_unknown true,  'a defined true value is not unknown';

# negation
ok is_unknown !unknown, 'not unknown should evaluate to unknown';

# logical or
ok unknown            || true,  'unknown || true should be true';
ok is_unknown unknown || false, 'unknown || false should be unknown';
ok is_unknown unknown || unknown, 'unknown || unknown should be unknown';

ok + ( unknown            or true ),  'unknown or true should be true';
ok + ( is_unknown unknown or false ), 'unknown or false should be unknown';
ok + ( is_unknown unknown or unknown ), 'unknown or unknown should be unknown';

# logical and
ok is_unknown unknown && true, 'unknown && true should be unknown';
ok is_false( unknown && false ), 'unknown && false should be false';
ok is_unknown unknown && unknown, 'unknown && unknown should be unknown';

ok + ( is_unknown unknown and true ), 'unknown and true should be unknown';
ok + ( is_false( unknown and false ) ), 'unknown and false should be false';
ok + ( is_unknown unknown and unknown ),
  'unknown and unknown should be unknown';

done_testing;
