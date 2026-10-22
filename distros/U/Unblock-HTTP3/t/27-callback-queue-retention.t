use strict;
use warnings;

use Scalar::Util qw(isweak refaddr);
use Test2::V0;
use Unblock::HTTP3::Connection;

# Internal queue semantics: callbacks cannot retain a second strong
# reference to every completed request while pull-only use stays reliable.
my $conn = bless {
    ready_transactions => [],
    ready_informational => [],
}, 'Unblock::HTTP3::Connection';

my $pull = bless {}, 'Local::Transaction';
my $pull_id = refaddr($pull);
$conn->_enqueue_delivery('ready_transactions', $pull, 0);
ok(!isweak($conn->{ready_transactions}[0]),
    'pull-only notification stays strong');
undef $pull;
my $pulled = $conn->next_transaction;
is(refaddr($pulled), $pull_id,
    'strongly queued pull Transaction survives caller releasing it');
is(scalar @{ $conn->{ready_transactions} }, 0,
    'pulling removes strong notification');

my $callback = bless {}, 'Local::Transaction';
my $callback_id = refaddr($callback);
$conn->_enqueue_delivery('ready_transactions', $callback, 1);
ok(isweak($conn->{ready_transactions}[0]),
    'callback-delivered Transaction notification is weak in queue');
my $mixed = $conn->next_transaction;
is(refaddr($mixed), $callback_id,
    'live callback Transaction can also be retrieved through pull');
undef $mixed;
undef $callback;

my $dead = bless {}, 'Local::Transaction';
$conn->_enqueue_delivery('ready_transactions', $dead, 1);
undef $dead;
is($conn->next_transaction, undef,
    'an expired callback notification is skipped');
is(scalar @{ $conn->{ready_transactions} }, 0,
    'expired callback head is removed from queue');

for (1 .. 128) {
    my $temporary = bless {}, 'Local::Transaction';
    $conn->_enqueue_delivery('ready_transactions', $temporary, 1);
}
cmp_ok(scalar @{ $conn->{ready_transactions} }, '<=', 1,
    'consecutive callback-only notifications do not accumulate dead entries');
is($conn->next_transaction, undef,
    'expired weak notifications never fabricate a Transaction');

my $informational = bless {}, 'Local::Transaction';
$conn->_enqueue_delivery('ready_informational', $informational, 1);
ok(isweak($conn->{ready_informational}[0]),
    'informational callback notification is weak');
undef $informational;
is($conn->next_informational, undef,
    'expired informational callback notification is skipped');

my $pull_info = bless {}, 'Local::Transaction';
my $info_id = refaddr($pull_info);
$conn->_enqueue_delivery('ready_informational', $pull_info, 0);
undef $pull_info;
is(refaddr($conn->next_informational), $info_id,
    'pull-only informational notification stays strongly available');


# A live old callback Transaction can block head-only pruning forever.
# Later callback entries must be compacted even if that head stays alive.
my $held_head = bless {}, 'Local::Transaction';
my $held_head_id = refaddr($held_head);
$conn->_enqueue_delivery('ready_transactions', $held_head, 1);
my $pull_behind = bless {}, 'Local::Transaction';
my $pull_behind_id = refaddr($pull_behind);
$conn->_enqueue_delivery('ready_transactions', $pull_behind, 0);
undef $pull_behind;
for (1 .. 512) {
    my $temporary = bless {}, 'Local::Transaction';
    $conn->_enqueue_delivery('ready_transactions', $temporary, 1);
}
cmp_ok(scalar @{ $conn->{ready_transactions} }, '<=', 66,
    'live old callback head does not trap unbounded expired weak entries');
ok(isweak($conn->{ready_transactions}[0]),
    'compacted live callback head stays weak');
ok(!isweak($conn->{ready_transactions}[1]),
    'compacted queued pull-only Transaction stays strong');
is(refaddr($conn->next_transaction), $held_head_id,
    'compaction preserves oldest live callback notification');
is(refaddr($conn->next_transaction), $pull_behind_id,
    'compaction preserves strongly queued pull-only notification and FIFO');
is($conn->next_transaction, undef,
    'all expired callback notifications behind live head are skipped');

my $held_info = bless {}, 'Local::Transaction';
my $held_info_id = refaddr($held_info);
$conn->_enqueue_delivery('ready_informational', $held_info, 1);
for (1 .. 512) {
    my $temporary = bless {}, 'Local::Transaction';
    $conn->_enqueue_delivery('ready_informational', $temporary, 1);
}
cmp_ok(scalar @{ $conn->{ready_informational} }, '<=', 65,
    'informational callback queue also compacts expired non-head entries');
ok(isweak($conn->{ready_informational}[0]),
    'compacted informational head stays weak');
is(refaddr($conn->next_informational), $held_info_id,
    'live informational notification survives compaction');
is($conn->next_informational, undef,
    'expired informational notifications are skipped after compaction');

# Compaction must preserve the weakness of LIVE entries that actually
# move to an earlier array index, not only the unchanged weak head.
my $front_live = bless {}, 'Local::Transaction';
my $front_live_id = refaddr($front_live);
$conn->_enqueue_delivery('ready_transactions', $front_live, 1);
{
    my $expired_gap = bless {}, 'Local::Transaction';
    $conn->_enqueue_delivery('ready_transactions', $expired_gap, 1);
}
my $moved_live = bless {}, 'Local::Transaction';
my $moved_live_id = refaddr($moved_live);
$conn->_enqueue_delivery('ready_transactions', $moved_live, 1);
my $moved_pull = bless {}, 'Local::Transaction';
my $moved_pull_id = refaddr($moved_pull);
$conn->_enqueue_delivery('ready_transactions', $moved_pull, 0);
undef $moved_pull;
for (1 .. 128) {
    my $expired = bless {}, 'Local::Transaction';
    $conn->_enqueue_delivery('ready_transactions', $expired, 1);
}
cmp_ok(scalar @{ $conn->{ready_transactions} }, '<=', 66,
    'periodic sweep removes expired gap and tail behind live callbacks');
ok(isweak($conn->{ready_transactions}[0]),
    'original weak head remains weak after compaction');
ok(isweak($conn->{ready_transactions}[1]),
    'moved live callback notification remains weak after compaction');
ok(!isweak($conn->{ready_transactions}[2]),
    'moved pull-only notification remains strong after compaction');
is(refaddr($conn->next_transaction), $front_live_id,
    'original live callback delivered in FIFO order');
is(refaddr($conn->next_transaction), $moved_live_id,
    'moved live weak callback delivered next in FIFO order');
is(refaddr($conn->next_transaction), $moved_pull_id,
    'moved strong pull notification remains retrievable');
is($conn->next_transaction, undef,
    'no expired weak entries survive retrieval');

done_testing;
