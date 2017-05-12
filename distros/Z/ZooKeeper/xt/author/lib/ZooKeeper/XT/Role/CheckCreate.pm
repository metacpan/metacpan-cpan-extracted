package ZooKeeper::XT::Role::CheckCreate;
use ZooKeeper::Test::Utils;
use Test::Class::Moose::Role;
use namespace::autoclean;

sub test_create_value_with_null_byte {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $path   = "/_perl_zk_test_create_value_with_null_byte-$$";
    my $value  = "$$-\0-$$";
    my $length = length($value);

    $handle->create($path, value => $value, ephemeral => 1);

    my ($got, $stat) = $handle->get($path);
    is $stat->{dataLength}, $length, 'data with null byte has same expected length';
    cmp_ok $got, 'eq', $value, 'data with null bytes has is unchanged after set';
}

sub test_create_value_as_null {
    my ($test) = @_;
    my $handle = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
    );

    my $path = "/_perl_zk_test_create_value_as_null-$$";
    $handle->create($path, ephemeral => 1);

    my ($got, $stat) = $handle->get($path);
    is $stat->{dataLength}, 0, 'null data has no length';
    ok !defined($got), 'returned undef for null data';
}


1;
