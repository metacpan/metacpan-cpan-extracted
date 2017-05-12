package ZooKeeper::XT::Role::CheckTransactions;
use ZooKeeper;
use ZooKeeper::Constants;
use ZooKeeper::Test::Utils;
use Test::Class::Moose::Role;
use namespace::clean;

sub test_create {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $node = "/_perl_zk_test_txn_create-$$";

    my $txn = $handle->transaction
                     ->create("${node}-1", ephemeral => 1)
                     ->create("${node}-2", ephemeral => 1);

    my @results = $txn->commit;
    is_deeply \@results, [
        {
            path => "${node}-1",
            type => 'create',
        },
        {
            path => "${node}-2",
            type => 'create',
        },
    ], 'returned path and types for nodes created in transaction';

    ok $handle->exists("${node}-1");
    ok $handle->exists("${node}-2");
}

sub test_bad_transaction {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $node = "/_perl_zk_test_txn_create-$$";

    my $txn = $handle->transaction
                     ->create("${node}-1", ephemeral => 1)
                     ->create("${node}-2/bad-parent", ephemeral => 1);

    my @results = $txn->commit;

    is $results[0]->{type}, 'error', 'good op returned with type error';
    is $results[0]->{code}, ZOK,     'good op returned error code ZOK';
    is $results[1]->{type}, 'error', 'bad op returned with type error';
    is $results[1]->{code}, ZNONODE, 'bad op returned ZNONODE on bad create';

    ok !$handle->exists("${node}-1"), 'node from good op code not created';
    ok !$handle->exists("${node}-2/bad-parent"), 'node from bad op code not created';
}

sub test_check {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $node = "/_perl_zk_test_txn_check-$$";
    $handle->create($node, ephemeral => 1);
    my $stat = $handle->exists($node);

    my ($happy_result) = $handle->transaction
                                ->check($node, $stat->{version})
                                ->commit;
    is $happy_result->{type}, 'check', 'successful check returns result with type check';

    my ($sad_result) = $handle->transaction
                              ->check($node, $stat->{version} + 1)
                              ->commit;
    is $sad_result->{type}, 'error', 'bad check returns type error';
    is $sad_result->{code}, ZBADVERSION, 'bad check returns bad version error code';
}

sub test_set {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $node = "/_perl_zk_test_txn_set-$$";
    $handle->create($node, ephemeral => 1);
    my $stat = $handle->exists($node);

    my ($happy_result) = $handle->transaction
                                ->set($node, 'happy', version => $stat->{version})
                                ->commit;
    my $happy_data = $handle->get($node);
    is $happy_result->{type}, 'set', 'successful set op returns result with type set';
    is $happy_data, 'happy', 'successful set op set new data';
    is_deeply $happy_result->{stat}, $handle->exists($node), 'successful set op has stat set to current node stat';

    my ($sad_result) = $handle->transaction
                               ->set($node, 'sad', version => $stat->{version})
                               ->commit;
    my $sad_data = $handle->get($node);
    is $sad_result->{type}, 'error', 'bad set op returned type error';
    is $sad_result->{code}, ZBADVERSION, 'bad set op has bad version error code';
    is $sad_data, 'happy', 'bad set op did not change data in node';
}

sub test_delete {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $node = "/_perl_zk_test_txn_check-$$";
    $handle->create($node, ephemeral => 1);
    my $stat = $handle->exists($node);

    my ($sad_result) = $handle->transaction
                              ->delete($node, version => $stat->{version} + 1)
                              ->commit;
    is $sad_result->{type}, 'error', 'bad delete op returned type error';
    is $sad_result->{code}, ZBADVERSION, 'bad delete op has error code for bad version';
    ok !!$handle->exists($node), 'bad delete op didnt delete node';

    my ($happy_result) = $handle->transaction
                                ->delete($node, version => $stat->{version})
                                ->commit;
    is $happy_result->{type}, 'delete', 'successful delete op returned type delete';
    ok !$handle->exists($node), 'successful delete op deleted node';
}

sub test_txn_creates_data_with_null_bytes {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $path   = "/_perl_zk_test_txn_creates_data_with_null_bytes-$$";
    my $value  = "$$-\0-$$";
    my $length = length($value);

    $handle->transaction->create($path, value => $value, ephemeral => 1)->commit;

    my ($got, $stat) = $handle->get($path);
    is $stat->{dataLength}, $length, 'data with null byte has same expected length';
    cmp_ok $got, 'eq', $value, 'data with null bytes has is unchanged after set';
}

sub test_txn_sets_data_with_null_bytes {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $path = "/_perl_zk_test_txn_sets_data_with_null_bytes-$$";
    $handle->create($path, ephemeral => 1);

    my $value  = "$$-\0-$$";
    my $length = length($value);
    $handle->transaction->set($path, $value)->commit;

    my ($got, $stat) = $handle->get($path);
    is $stat->{dataLength}, $length, 'data with null bytes has expected length';
    cmp_ok $got, 'eq', $value, 'data with null bytes has is unchanged after set';
}

sub test_txn_creates_null_data {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $path = "/_perl_zk_test_txn_creates_null_data-$$";
    $handle->transaction->create($path, ephemeral => 1)->commit;

    my ($got, $stat) = $handle->get($path);
    is $stat->{dataLength}, 0, 'null data has no length';
    ok !defined($got), 'returned undef for null data';
}

sub test_txn_sets_null_data {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $path = "/_perl_zk_test_txn_sets_null_data-$$";
    $handle->create($path, value => "defined", ephemeral => 1);
    $handle->transaction->set($path, undef)->commit;

    my ($got, $stat) = $handle->get($path);
    is $stat->{dataLength}, 0, 'null data has no length';
    ok !defined($got), 'null data returns undef';
}

1;
