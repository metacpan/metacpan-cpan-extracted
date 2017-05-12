use Test::Modern;
use t::lib::Harness qw(alg skip_unless_has_keys);

skip_unless_has_keys;

subtest 'Index Management' => sub {
    my $name = 'foo_'. time;
    my $content = { bar => { baz => 'bat'}};
    my $index = alg->create_index_object($name, $content);
    cmp_deeply $index => TD->superhashof({
            createdAt => TD->ignore(),
            objectID  => TD->re('\d+'),
            taskID    => TD->re('\d+'),
        }), "Returned index '$name' with valid IDs"
        or diag explain $index;

    sleep 1;

    my $query = alg->query_index({ index => $name, query => 'bat' });
    cmp_deeply $query->{hits} => [ TD->superhashof($content) ],
        'Correctly matched index values from query'
        or diag explain $query;

    my $queries = alg->query_indexes([
        { index => $name, query => 'baz' },
        { index => $name, query => 'bat' },
    ]);
    is @{$queries->{results}} => 2,
        'Retrieved two sets of results from batch route'
        or diag explain $queries;

    my $indexes = alg->get_indexes();
    cmp_deeply $indexes->{items} => [ TD->superhashof({
            createdAt => TD->ignore(),
        })], "Returned index '$name' in listing"
        or diag explain $indexes;

    my $contents = alg->browse_index($name);
    cmp_deeply $contents->{hits} => [ TD->superhashof($content) ],
        "Matched contents of index '$name'"
        or diag explain $contents;

    ok alg->clear_index($name), "Cleared index '$name' content";

    sleep 1;

    $contents = alg->browse_index($name);
    cmp_deeply $contents->{hits} => [],
        "Successfully cleared index '$name'"
        or diag explain $contents;

    my $settings = alg->get_index_settings($name);
    cmp_deeply $settings->{attributesToIndex} => undef,
        "Correctly found no attributesToIndex for '$name'"
        or diag explain $settings;

    ok alg->update_index_settings($name, { attributesToIndex => ['bat']}),
        "Updated attributesToIndex for '$name'";

    sleep 1;

    $settings = alg->get_index_settings($name);
    cmp_deeply $settings->{attributesToIndex} => ['bat'],
        "Correctly found 'bat' in attributesToIndex for '$name'"
        or diag explain $settings;

    my $name2 = 'foo2_' . time;
    ok alg->copy_index($name => $name2), "Copied index '$name' to '$name2'";

    sleep 1;

    $indexes = alg->get_indexes();
    cmp_deeply $indexes->{items} => TD->superbagof(map { TD->superhashof({ name => $_ })}
        ($name, $name2)),
        "Found indexes '$name' and '$name2'"
        or diag explain $indexes;

    my $name3 = 'foo3_' . time;
    ok alg->move_index($name2 => $name3), "Moved index '$name2' to '$name3'";

    sleep 1;

    $indexes = alg->get_indexes();
    cmp_deeply $indexes->{items} => TD->superbagof(map { TD->superhashof({ name => $_ })}
        ($name, $name3)),
        "Found indexes '$name' and '$name3'"
        or diag explain $indexes;

    ok alg->delete_index($_), "Deleted index '$_' completely"
        for ($name, $name3);

    sleep 1;

    $indexes = alg->get_indexes();
    cmp_deeply $indexes->{items} => [],
        'Correctly retrieved no indexes again'
        or diag explain $indexes;
};

subtest 'Index Object Management' => sub {
    my $name = 'bourbon_' . time;
    my $content = { delicious => 'limoncello' };
    my $index = alg->create_index_object($name, $content);
    my $object_id = $index->{objectID};

    $content = { terrible => 'cabbage' };
    ok alg->replace_index_object($name, $object_id, $content),
        "Replacing contents of object '$object_id'";

    sleep 1;

    my $object = alg->get_index_object($name, $object_id);
    cmp_deeply $object => TD->superhashof($content),
        "Successfully replaced contents of object '$object_id'"
        or diag explain $object;

    my $object_id2 = 'a1b2c3';
    ok alg->replace_index_object($name, $object_id2, $content),
        "Creating new object with ID: '$object_id2'";

    sleep 1;

    my $objects = alg->get_index_objects([
        { index => $name, object => $object_id },
        { index => $name, object => $object_id2 },
    ]);

    $content = { another => 'pilsner?'};
    ok alg->update_index_object($name, $object_id, $content),
        "Updating contents of object '$object_id'";

    sleep 1;

    my $contents = alg->browse_index($name)->{hits};
    cmp_deeply $contents => [
        {
            objectID => $object_id2,
            terrible => 'cabbage',
        },
        {
            objectID => $object_id,
            terrible => 'cabbage',
            another  => 'pilsner?',
        }], "Successfully replaced contents of object '$object_id'"
        or diag explain $contents;

    my $task_id = alg->replace_index_object($name, $object_id, $content)->{taskID};

    sleep 1;

    my $task = alg->get_task_status($name, $task_id);
    like $task->{status} => qr/[Pp]ublished/,
        "Retrieved task '$task_id' with status: '$task->{status}'"
        or diag explain $task;

    cmp_deeply $objects->{results} => [ map { TD->superhashof({ objectID => $_ })}
        ($object_id, $object_id2)],
        "Found objects '$object_id' and '$object_id2'"
        or diag explain $objects;

    my $batch = alg->batch_index_objects($name, [
        sub { alg->create_index_object($name, { hello => 'world' })},
        sub { alg->create_index_object($name, { goodbye => 'world' })},
    ]);

    is @{$batch->{objectIDs}} => 2,
        "Succesfully batched two 'create_index_object' requests on '$name'"
        or diag explain $batch;

    $batch = alg->batch_index_objects($name, [
        sub { alg->update_index_object($name, $batch->{objectIDs}[0], { 1 => 2 })},
        sub { alg->update_index_object($name, $batch->{objectIDs}[1], { 3 => 4 })},
    ]);

    is @{$batch->{objectIDs}} => 2,
        "Succesfully batched two 'update_index_object' requests on '$name'"
        or diag explain $batch;

    $batch = alg->batch_index_objects($name, [
        sub { alg->replace_index_object($name, $batch->{objectIDs}[0], { bacon => 'tasty' })},
        sub { alg->replace_index_object($name, $batch->{objectIDs}[1], { chicken => 'delicious' })},
    ]);

    is @{$batch->{objectIDs}} => 2,
        "Succesfully batched two 'replace_index_object' requests on '$name'"
        or diag explain $batch;

    $batch = alg->batch_index_objects($name, [
        sub { alg->delete_index_object($name, $batch->{objectIDs}[0] )},
        sub { alg->delete_index_object($name, $batch->{objectIDs}[1] )},
    ]);

    is @{$batch->{objectIDs}} => 2,
        "Succesfully batched two 'delete_index_object' requests on '$name'"
        or diag explain $batch;

    ok alg->delete_index($name), "Deleted index '$name' completely";
};

subtest 'Index Key Management' => sub {
    my $name = 'pirouette_' . time;
    ok alg->create_index_object($name, { content => 'placeholder' }),
        "Created index object '$name'";

    my $key = alg->create_index_key($name, {})->{key};
    ok $key, "Successfully created key: '$key'";

    sleep 1;

    my $key_object = alg->get_index_key($name, $key);
    cmp_deeply $key_object => {
            acl      => [],
            validity => 0,
            value    => $key,
        }, "Successfully retrieved key '$key'"
        or diag explain $key_object;

    my $keys = alg->get_index_keys;
    cmp_deeply $keys->{keys} => TD->superbagof({
            acl      => [],
            index    => $name,
            validity => 0,
            value    => $key,
        }), "Retrieved key '$key' again"
        or diag explain $keys;

    $keys = alg->get_index_keys($name);
    cmp_deeply $keys->{keys} => TD->superbagof({
            acl      => [],
            validity => 0,
            value    => $key,
        }), "Retrieved key '$key' again"
        or diag explain $keys;

    ok alg->update_index_key($name, $key, { acl => ['search']}),
        "Successfully updated key '$key'";

    sleep 1;

    $key_object = alg->get_index_key($name, $key);
    cmp_deeply $key_object => {
            acl      => ['search'],
            validity => 0,
            value    => $key,
        }, 'Retrieved key matches with updated fields'
        or diag explain $key_object;

    ok alg->delete_index_key($name, $key), "Deleted key '$key' completely";

    sleep 1;

    $keys = alg->get_index_keys;
    cmp_deeply $keys->{keys} => [],
        "Correctly retrieved no keys on '$name'"
        or diag explain $keys;

    ok alg->delete_index($name), "Deleted index '$name' completely";
};

done_testing;
