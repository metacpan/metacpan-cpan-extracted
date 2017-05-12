package ZooKeeper::XT::Role::CheckSet;
use ZooKeeper::Test::Utils;
use Test::Class::Moose::Role;
use namespace::autoclean;

sub test_set_value_with_null_byte {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $path = "/_perl_zk_test_set_value_with_null_byte-$$";
    $handle->create($path, ephemeral => 1);

    my $value  = "$$-\0-$$";
    my $length = length($value);
    $handle->set($path, $value);

    my ($got, $stat) = $handle->get($path);
    is $stat->{dataLength}, $length, 'data with null bytes has expected length';
    cmp_ok $got, 'eq', $value, 'data with null bytes has is unchanged after set';
}

sub test_set_value_to_null {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $path = "/_perl_zk_test_set_value_to_null-$$";
    $handle->create($path, value => "defined", ephemeral => 1);
    $handle->set($path, undef);

    my ($got, $stat) = $handle->get($path);
    is $stat->{dataLength}, 0, 'null data has no length';
    ok !defined($got), 'null data returns undef';
}

1;
