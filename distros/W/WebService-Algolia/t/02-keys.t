use Test::Modern;
use t::lib::Harness qw(alg skip_unless_has_keys);

skip_unless_has_keys;

subtest 'Global Key Management' => sub {
    my $keys = alg->get_keys;
    cmp_deeply $keys->{keys} => [],
        'Correctly retrieved no keys'
        or diag explain $keys;

    my $key = alg->create_key({})->{key};
    ok $key, "Successfully created key: '$key'";

    sleep 1;

    my $key_object = alg->get_key($key);
    cmp_deeply $key_object => {
            acl      => [],
            validity => 0,
            value    => $key,
        }, "Successfully retrieved key '$key'"
        or diag explain $key_object;

    $keys = alg->get_keys;
    cmp_deeply $keys->{keys} => [{
            acl      => [],
            validity => 0,
            value    => $key,
        }], "Retrieved key '$key' again"
        or diag explain $keys;

    ok alg->update_key($key, { acl => ['search']}),
        "Successfully updated key '$key'";

    sleep 1;

    $key_object = alg->get_key($key);
    cmp_deeply $key_object => {
            acl      => ['search'],
            validity => 0,
            value    => $key,
        }, 'Retrieved key matches with updated fields'
        or diag explain $key_object;

    ok alg->delete_key($key), "Deleted key '$key' completely";

    sleep 1;

    $keys = alg->get_keys;
    cmp_deeply $keys->{keys} => [],
        'Correctly retrieved no keys'
        or diag explain $keys;
};

done_testing;
