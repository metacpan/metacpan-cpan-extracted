use strict;
use Test::More;
use Test::Double;
use Test::Fatal;
use JSON qw/encode_json decode_json/;

use WebService::Mackerel;

subtest 'all args' => sub {
    is exception {
        WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    }, undef, "create ok";
};

subtest 'no api_key' => sub {
    like(
        exception {
            WebService::Mackerel->new( service_name  => 'test' );
        },
        qr/api key is required/,
        "no api_key args died as expected",
    );
};

subtest 'no service_name' => sub {
    like(
        exception {
            WebService::Mackerel->new( api_key  => 'testapikey' );
        },
        qr/service name is required/,
        "no service_name args died as expected",
    );
};

subtest 'post_service_metrics' => sub {
    my $fake_res = encode_json({ "success" => "true" });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('post_service_metrics')->times(1)->returns($fake_res);

    my $res = $mackerel->post_service_metrics([ {"name" => "custom.name_metrics", "time" => "1415609260", "value" => 200} ]);

    is_deeply $res, $fake_res, 'post_service_metrics : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'create_host' => sub {
    my $fake_res = encode_json({ "id" => "test_host_id" });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('create_host')->times(1)->returns($fake_res);

    my $res = $mackerel->create_host({
            "name"          => "test_hostname",
            "meta"          => { "status" => "maintenance" },
            "interfaces"    => [ { "name" => "eth0", "ipAddress" => "192.168.128.1", "macAddress" => "AA:BB::CC::DD::11::22" } ],
            "roleFullnames" => [ "test:test-role" ],
        });

    is_deeply $res, $fake_res, 'create_host : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'get_host' => sub {
    my $fake_res = encode_json({
            "createdAt" => 1416151310,
            "id"        => "test_host_id",
            "memo"      => "test memo",
            "role"      => { [ "test-role" ] },
        });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('get_host')->times(1)->returns($fake_res);

    my $res = $mackerel->get_host("test_host_id");

    is_deeply $res, $fake_res, 'get_host : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'update_host' => sub {
    my $fake_res = encode_json({ "id" => "test_host_id" });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('update_host')->times(1)->returns($fake_res);

    my $res = $mackerel->update_host({
            "hostId"        => "test_host_id",
            "data"          => {
                "name"          => "test_hostname",
                "meta"          => { "status" => "maintenance" },
                "interfaces"    => [ { "name" => "eth0", "ipAddress" => "192.168.128.1", "macAddress" => "AA:BB::CC::DD::11::22" } ],
                "roleFullnames" => [ "test:test-role" ],
            },
        });

    is_deeply $res, $fake_res, 'update_host : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'update_host_status' => sub {
    my $fake_res = encode_json({ "success" => "true" });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('update_host_status')->times(1)->returns($fake_res);

    my $res = $mackerel->update_host_status({
            "hostId" => "test_host_id",
            "data"   => { "status" => "maintenance" },
        });

    is_deeply $res, $fake_res, 'update_host_status : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'host_retire' => sub {
    my $fake_res = encode_json({ "success" => "true" });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('host_retire')->times(1)->returns($fake_res);

    my $res = $mackerel->host_retire("test_host_id");

    is_deeply $res, $fake_res, 'host_retire : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'post_host_metrics' => sub {
    my $fake_res = encode_json({ "success" => "true" });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('post_host_metrics')->times(1)->returns($fake_res);

    my $res = $mackerel->post_host_metrics([ {"hostId" => "fake_host_id", "name" => "metric_name", "time" => "1415609260", "value" => 200} ]);

    is_deeply $res, $fake_res, 'post_service_metrics : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'get_latest_host_metrics' => sub {
    my $fake_res = encode_json({ "tsdbLatest" => { "fake_host_id" => { "metric_name" => 200, } } });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('get_latest_host_metrics')->times(1)->returns($fake_res);

    my $res = $mackerel->get_latest_host_metrics([ {"hostId" => "fake_host_id", "name" => "metric_name"} ]);

    is_deeply $res, $fake_res, 'get_latest_host_metrics : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'create_monitor' => sub {
    my $fake_res = encode_json({
        "id"            => "test_monitor_id",
        "type"          => "host",
        "name"          => "disk.aa-00.writes.delta",
        "duration"      => 3,
        "metric"        => "disk.aa-00.writes.delta",
        "operator"      => ">",
        "warning"       => 20000,
        "critical"      => 400000,
        "scopes"        => [ "Test"],
        "excludeScopes" => [ "Test: staging" ],
    });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('create_monitor')->times(1)->returns($fake_res);

    my $res = $mackerel->create_monitor({
        "type"          => "host",
        "name"          => "disk.aa-00.writes.delta",
        "duration"      => 3,
        "metric"        => "disk.aa-00.writes.delta",
        "operator"      => ">",
        "warning"       => 20000,
        "critical"      => 400000,
        "scopes"        => [ "Test"],
        "excludeScopes" => [ "Test: staging" ],
    });

    is_deeply $res, $fake_res, 'create_monitor : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'get_monitor' => sub {
    my $fake_res = encode_json({
        "monitors" => [ {
            "id"            => "test_monitor_id",
            "type"          => "host",
            "name"          => "disk.aa-00.writes.delta",
            "duration"      => 3,
            "metric"        => "disk.aa-00.writes.delta",
            "operator"      => ">",
            "warning"       => 20000,
            "critical"      => 400000,
            "scopes"        => [ "Test"],
            "excludeScopes" => [ "Test: staging" ],
        },]
    });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('get_monitor')->times(1)->returns($fake_res);

    my $res = $mackerel->get_monitor();

    is_deeply $res, $fake_res, 'get_monitor : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'update_monitor' => sub {
    my $fake_res = encode_json({
        "id" => "test_monitor_id",
    });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('update_monitor')->times(1)->returns($fake_res);

    my $res = $mackerel->update_monitor("test_monitor_id", {
        "type"          => "host",
        "name"          => "disk.aa-00.writes.delta",
        "duration"      => 3,
        "metric"        => "disk.aa-00.writes.delta",
        "operator"      => ">",
        "warning"       => 20000,
        "critical"      => 400000,
        "scopes"        => [ "Test"],
        "excludeScopes" => [ "Test: staging" ],
    });

    is_deeply $res, $fake_res, 'update_monitor : response success';

    Test::Double->verify;
    Test::Double->reset;
};

subtest 'delete_monitor' => sub {
    my $fake_res = encode_json({
        "id"            => "test_monitor_id",
        "type"          => "host",
        "name"          => "disk.aa-00.writes.delta",
        "duration"      => 3,
        "metric"        => "disk.aa-00.writes.delta",
        "operator"      => ">",
        "warning"       => 20000,
        "critical"      => 400000,
        "scopes"        => [ "Test"],
        "excludeScopes" => [ "Test: staging" ],
    });
    my $mackerel = WebService::Mackerel->new( api_key  => 'testapikey', service_name => 'test' );
    mock($mackerel)->expects('delete_monitor')->times(1)->returns($fake_res);

    my $res = $mackerel->delete_monitor("test_monitor_id", {
    });

    is_deeply $res, $fake_res, 'delete_monitor : response success';

    Test::Double->verify;
    Test::Double->reset;
};

done_testing;
