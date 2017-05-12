package ZooKeeper::XUnit::Constants;
use ZooKeeper::Constants;
use Test::LeakTrace;
use Test::Class::Moose;

sub test_leaks {
    my %acl_constants = (
        'ZOO_OPEN_ACL_UNSAFE' => \&ZOO_OPEN_ACL_UNSAFE,
        'ZOO_READ_ACL_UNSAFE' => \&ZOO_READ_ACL_UNSAFE,
        'ZOO_CREATOR_ALL_ACL' => \&ZOO_CREATOR_ALL_ACL,
    );

    while (my ($name, $sub) = each %acl_constants) {
        no_leaks_ok {
            $sub->();
        } "no leaks returning acl $name";
    }
}

sub test_standard_acls {
    is_deeply(
        ZOO_OPEN_ACL_UNSAFE,
        [{id => 'anyone', perms => ZOO_PERM_ALL, scheme => 'world'}],
        'reconstructed ZOO_OPEN_ACL_UNSAFE in perl',
    );

    is_deeply(
        ZOO_READ_ACL_UNSAFE,
        [{id => 'anyone', perms => ZOO_PERM_READ, scheme => 'world'}],
        'reconstructed ZOO_READ_ACL_UNSAFE in perl',
    );

    is_deeply(
        ZOO_CREATOR_ALL_ACL,
        [{id => '', perms => ZOO_PERM_ALL, scheme => 'auth'}],
        'reconstructed ZOO_CREATOR_ALL_ACL in perl',
    );
}

sub test_zperm {
    is zperm(ZOO_PERM_ALL), "all";
    is zperm(ZOO_PERM_READ), "read";
    is zperm(ZOO_PERM_READ|ZOO_PERM_WRITE), "read|write";
    is zperm(ZOO_PERM_READ|ZOO_PERM_WRITE|ZOO_PERM_CREATE), "create|read|write";
}

sub test_zevent {
    is zevent(ZOO_CREATED_EVENT), "created";
    is zevent(ZOO_NOTWATCHING_EVENT), "not watching";
}

sub test_zstate {
    is zstate(ZOO_EXPIRED_SESSION_STATE), "expired session";
    is zstate(ZOO_CONNECTING_STATE), "connecting";
}

1;
