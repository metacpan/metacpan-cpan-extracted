use 5.020;
use strict;
use warnings;
use utf8;
use Test::More;
use Future;
use Future::AsyncAwait;
use Scalar::Util qw(refaddr);
use WebDyne::Cloudflare::Hyperdrive;

my @calls;
my $sequence=0;
my $result_hr={ columns => [{ name => 'x', oid => 23 }, { name => 'x', oid => 25 }], rows => [[1, 'last'], [2, undef]], count => 2, command => 'SELECT' };
my %fail;
my $gate_or;
my $scope_hr={ extensions => { 'webdyne.cloudflare.hyperdrive' => { version => 1, capability => 'test', bindings => ['DB'] } } };
no warnings 'redefine';
local *WebDyne::Cloudflare::Hyperdrive::Transport::call=async sub {
    my ($self, $operation, %opt)=@_;
    push(@calls, { operation => $operation, %opt });
    die $fail{$operation} if exists($fail{$operation});
    await $gate_or if $gate_or&&($operation eq 'query');
    return { connection => 'connection-' . ++$sequence } if $operation eq 'open';
    return { owner => 'transaction-owner' } if $operation eq 'begin';
    return $result_hr if $operation eq 'query';
    return {};
};

my $db_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr);
my $statement_or=$db_or->prepare('select $1, $2');
is(scalar(@calls), 0, 'construction and prepare do not open a connection');
is_deeply($statement_or->fetchall_arrayref(), [], 'unexecuted statement has no rows');
is($statement_or->execute('first', undef)->get(), 2, 'execute returns row count');
is_deeply($calls[-1]{'params'}, [['text', 'first'], ['null']], 'DBI-style bound arguments remain separate');
is_deeply($statement_or->columns(), $result_hr->{'columns'}, 'ordered duplicate metadata retained');
is($statement_or->command(), 'SELECT', 'command available');
is_deeply($statement_or->fetchrow_arrayref(), [1, 'last'], 'first array row');
is_deeply($statement_or->fetchrow_hashref(), { x => undef }, 'duplicate column names use last value, including NULL');
is($statement_or->fetchrow_arrayref(), undef, 'fetch exhaustion is undef');
is_deeply($statement_or->fetchall_arrayref(), [], 'fetchall exhaustion is empty array');
$statement_or->execute()->get();
is_deeply($calls[-1]{'params'}, [['text', 'first'], ['null']], 'execute without arguments reuses bindings');
is_deeply($statement_or->fetchall_arrayref({}), [{ x => 'last' }, { x => undef }], 'fetchall hash rows');
$statement_or->finish();
is($statement_or->fetchrow_hashref(), undef, 'finish releases results');
is_deeply($statement_or->columns(), [], 'finish releases metadata');
$statement_or->execute('replacement', 'two')->get();
is_deeply($calls[-1]{'params'}, [['text', 'replacement'], ['text', 'two']], 'execute replaces stored parameters');
my $row_ar=$statement_or->fetchrow_arrayref(); $row_ar->[0]='changed';
is($result_hr->{'rows'}[0][0], 1, 'caller cannot mutate buffered row through returned array');
is_deeply($db_or->selectrow_hashref('select 1', undef)->get(), { x => 'last' }, 'hash convenience');
is_deeply($db_or->selectall_arrayref('select 1', { Slice => {} })->get(), [{ x => 'last' }, { x => undef }], 'Slice convenience');
is_deeply($db_or->selectrow_arrayref('select 1', undef)->get(), [1, 'last'], 'array convenience');

is($statement_or->insert_id(), undef, 'PostgreSQL has no insert ID metadata');
my $saved_hr=$result_hr;
$result_hr={ columns => [], rows => [], count => 1, command => 'INSERT',
    insert_id => '9007199254740993', affected_rows => 1, warning_count => 0 };
$statement_or->execute()->get();
is($statement_or->insert_id(), '9007199254740993', 'large MySQL insert ID is exact');
is($statement_or->affected_rows(), 1, 'MySQL affected rows');
is($statement_or->warning_count(), 0, 'zero warnings preserved');
$statement_or->finish();
is($statement_or->insert_id(), undef, 'finish clears insert metadata');
$result_hr={ columns => [], rows => [], count => 0, command => 'UPDATE' };
is($db_or->do('update items', undef)->get(), '0E0', 'zero affected rows are true 0E0');
ok($db_or->do('update items', undef)->get(), 'zero result is boolean true');
is($db_or->selectrow_arrayref('select none', undef)->get(), undef, 'no row returns undef');
is($db_or->selectrow_hashref('select none', undef)->get(), undef, 'no hash row returns undef');
is_deeply($db_or->selectall_arrayref('select none', undef)->get(), [], 'no rows returns empty array');
$result_hr->{'count'}=undef;
is($db_or->do('create table example', undef)->get(), -1, 'unknown row count is -1');
$result_hr=$saved_hr;

$statement_or->bind_param(1, "\0\xff", 'bytea');
$statement_or->bind_param(2, 0, 'boolean');
$statement_or->execute()->get();
is_deeply($calls[-1]{'params'}, [['bytes', '00ff'], ['bool', JSON::PP::false]], 'explicit type hints');
$statement_or->execute("\x80", 1)->get();
is_deeply($calls[-1]{'params'}, [['bytes', '80'], ['bool', JSON::PP::true]], 'type hints persist for execute values');
my $sparse_or=$db_or->prepare('select $2'); $sparse_or->bind_param(2, 1);
eval { $sparse_or->execute()->get() }; like($@, qr/contiguous/, 'missing binding position rejected');
foreach my $position (0, -1, 1.5, 65536, '1x') {
    eval { $statement_or->bind_param($position, 1) }; like($@, qr/positions/, 'invalid binding position rejected');
}
foreach my $attr_hr ({ RaiseError => 1 }, { Slice => [] }, { Slice => { x => 1 } }) {
    eval { $db_or->selectall_arrayref('select 1', $attr_hr)->get() }; ok($@, 'unsupported attributes rejected');
}
eval { $db_or->prepare('select 1', { Slice => {} }) }; like($@, qr/Unsupported/, 'Slice only on applicable helper');
eval { $statement_or->bind_param(1, 'value', 12) }; like($@, qr/Unsupported/, 'unimplemented DBI numeric type constant rejected');
eval { $statement_or->fetchall_arrayref([]) }; like($@, qr/empty hash/, 'unsupported fetch slice rejected');

my $error_or=WebDyne::Cloudflare::Hyperdrive::Error->new(code => '23505', message => 'duplicate');
$fail{'query'}=$error_or;
eval { $statement_or->execute()->get() }; is(refaddr($@), refaddr($error_or), 'structured query error retains identity');
is($statement_or->fetchrow_arrayref(), undef, 'failed reexecution cannot expose stale rows');
delete($fail{'query'});
$statement_or->execute()->get();
eval { $statement_or->execute({ invalid => 'reference' }, 1) };
ok($@, 'invalid execute parameter rejected');
is($statement_or->fetchrow_arrayref(), undef, 'local execution failure also clears previous results');

my ($facade_or, $transaction_statement_or);
my $value=$db_or->transaction(async sub {
    ($facade_or)=@_;
    eval { await $db_or->selectrow_arrayref('select 1', undef) }; like($@, qr/belongs to/, 'parent calls blocked during callback');
    eval { await $facade_or->commit() }; like($@, qr/Explicit transaction control/, 'manual commit rejected in callback');
    eval { await $facade_or->transaction(async sub { return 1 }) }; like($@, qr/Explicit transaction control/, 'nested callback rejected');
    $transaction_statement_or=$facade_or->prepare('select 1');
    await $transaction_statement_or->execute();
    is($calls[-1]{'owner'}, 'transaction-owner', 'callback queries carry ownership');
    return 'callback value';
})->get();
is($value, 'callback value', 'transaction returns callback scalar');
is($calls[-1]{'operation'}, 'commit', 'successful callback committed');
eval { $facade_or->prepare('select 1') }; like($@, qr/expired/, 'callback handle expires');
eval { $transaction_statement_or->fetchrow_arrayref() }; like($@, qr/expired/, 'callback statements expire too');
is($db_or->transaction(async sub { return 0 })->get(), 0, 'false callback result preserved');
is($db_or->transaction(async sub { return undef })->get(), undef, 'undef callback result preserved');
eval { $db_or->transaction(async sub { die $error_or })->get() };
is(refaddr($@), refaddr($error_or), 'callback failure remains original after successful rollback');
is($calls[-1]{'operation'}, 'rollback', 'failed callback rolled back');
eval { $db_or->transaction(sub { return 1 })->get() }; like($@, qr/must return a Future/, 'plain callback return rejected');
is($calls[-1]{'operation'}, 'rollback', 'invalid callback return rolled back');
$fail{'rollback'}='rollback failed';
eval { $db_or->transaction(async sub { die $error_or })->get() };
is(refaddr($@), refaddr($error_or), 'rollback failure does not replace primary database error');
like($@->cleanup_errors()->[0], qr/rollback failed/, 'secondary cleanup failure retained');
delete($fail{'rollback'});
$db_or->disconnect()->get();
is($calls[-1]{'owner'}, 'transaction-owner', 'failed managed cleanup retains owner for disconnect');
$db_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr);
my $unknown_or=WebDyne::Cloudflare::Hyperdrive::Error->new(code => 'TIMEOUT', message => 'lost commit response', outcomeUnknown => 1);
$fail{'commit'}=$unknown_or;
eval { $db_or->transaction(async sub { return 1 })->get() };
ok($@->outcome_unknown(), 'ambiguous commit remains explicit');
is($calls[-1]{'operation'}, 'commit', 'ambiguous commit is not retried or presented as rolled back');
delete($fail{'commit'}); $db_or->disconnect()->get();
$db_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr);
$statement_or=$db_or->prepare('select 1');

$db_or->begin_work()->get();
eval { $db_or->transaction(async sub { return 1 })->get() }; like($@, qr/Nested/, 'callback cannot join explicit transaction');
$db_or->rollback()->get();
$gate_or=Future->new();
my $pending_or=$statement_or->execute();
eval { $statement_or->execute() }; like($@, qr/in progress/, 'overlapping statement execution rejected');
eval { $statement_or->fetchrow_arrayref() }; like($@, qr/in progress/, 'fetch during execution rejected');
$gate_or->done(); $pending_or->get(); $gate_or=undef;

my $unfinished_or;
$gate_or=Future->new();
eval {
    $db_or->transaction(async sub {
        my ($tx_or)=@_;
        $unfinished_or=$tx_or->selectrow_arrayref('select 1', undef);
        return 1;
    })->get();
};
like($@, qr/unfinished operations/, 'callback cannot silently commit unawaited work');
is($calls[-1]{'operation'}, 'rollback', 'unfinished work triggers rollback');
$gate_or->done(); $gate_or=undef;
eval { $unfinished_or->get() }; like($@, qr/expired/, 'late callback work cannot expose expired results');

my $cancel_tx_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr);
my $callback_gate_or=Future->new();
my $held_facade_or;
my $cancel_transaction_or=$cancel_tx_or->transaction(sub { ($held_facade_or)=@_; return $callback_gate_or });
$cancel_transaction_or->cancel();
eval { $held_facade_or->prepare('select 1') }; ok($@, 'cancelled callback facade is invalid');
$cancel_tx_or->disconnect()->get();
is($calls[-1]{'owner'}, 'transaction-owner', 'cancelled callback can disconnect with its retained owner');

my $text_error_db_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr);
$fail{'rollback'}="secondary failure\n";
eval { $text_error_db_or->transaction(async sub { die "primary failure\n" })->get() };
is($@->cause(), "primary failure\n", 'non-object callback error survives failed cleanup as cause');
is_deeply($@->cleanup_errors(), ["secondary failure\n"], 'secondary failure remains distinct');
delete($fail{'rollback'}); $text_error_db_or->disconnect()->get();

my $cancel_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr);
$gate_or=Future->new();
my $cancelled_or=$cancel_or->selectrow_arrayref('select 1', undef); $cancelled_or->cancel();
eval { $cancel_or->prepare('select 1') }; like($@, qr/cancelled/, 'Future cancellation invalidates database handle');
$gate_or=undef; $cancel_or->disconnect()->get();
my $disconnect_or=$db_or->disconnect();
is($disconnect_or->get(), 1, 'disconnect succeeds');
is(refaddr($db_or->disconnect()), refaddr($disconnect_or), 'disconnect completion is idempotent');
eval { $statement_or->fetchrow_arrayref() }; like($@, qr/disconnected/, 'disconnect invalidates old statements');
eval { $db_or->prepare('select 1') }; like($@, qr/disconnected/, 'disconnected object cannot reopen');
my $unused_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr); my $before=@calls;
$unused_or->disconnect()->get(); is(scalar(@calls), $before, 'unused disconnect does not create a connection');
done_testing();
