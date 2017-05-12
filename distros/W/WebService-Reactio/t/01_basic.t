use strict;
use Test::More 0.98;
use Test::Mock::Furl;
use Furl::Response;
use Path::Class qw(file);
use JSON;

use WebService::Reactio;

subtest 'new()' => sub {
    subtest 'error' => sub {
        eval { WebService::Reactio->new() };
        ok $@, "Dies when api_key and organization doesn't exist";

        eval { WebService::Reactio->new( organization => 'ORGANIZATION' ) };
        ok $@, "Dies when api_key doesn't exist";

        eval { WebService::Reactio->new( api_key => 'API_KEY' ) };
        ok $@, "Dies when organization doesn't exist";
    };

    subtest 'success' => sub {
        eval { WebService::Reactio->new( api_key => 'API_KEY', organization => 'ORGANIZATION' ) };
        ok !$@, "Success for instance creation";
    };
};

subtest 'create_incident()' => sub {
    my $rct = WebService::Reactio->new( api_key => 'API_KEY', organization => 'ORGANIZATION' );

    subtest 'error' => sub {
        eval { $rct->create_incident() };
        ok $@, "Incident name doesn't exist";
    };

    subtest 'success' => sub {
        my $data = file('t/data/create_incident.json')->slurp;
        $Mock_furl->mock(request => sub { Furl::Response->new } );
        $Mock_furl_res->mock(content => sub { $data });

        my $res = $rct->create_incident('サイト閲覧不可', {
            status            => "open",
            detection         => "msp",
            cause             => "overcapacity",
            cause_supplement  => "Webサーバがアクセス過多でダウン",
            point             => "middleware",
            scale             => "whole",
            pend_text         => "Webサーバの再起動を行う",
            close_text        => "Webサーバのスケールアウトを検討",
            topics            => ["原因調査", "復旧作業"],
            notification_text => "Webサーバで障害が発生。至急対応をお願い致します。",
            notification_call => JSON::true,
        });

        is_deeply $res, decode_json($data);
    };
};

subtest 'incident()' => sub {
    my $rct = WebService::Reactio->new( api_key => 'API_KEY', organization => 'ORGANIZATION' );
    subtest 'error' => sub {
        eval { $rct->incident() };
        ok $@, "Incident id doesn't exist";
    };

    subtest 'success' => sub {
        my $data = file('t/data/incident.json')->slurp;
        $Mock_furl->mock(request => sub { Furl::Response->new } );
        $Mock_furl_res->mock(content => sub { $data });

        my $res = $rct->incident(1);

        is_deeply $res, decode_json($data);
    };
};

subtest 'incidents()' => sub {
    my $rct = WebService::Reactio->new( api_key => 'API_KEY', organization => 'ORGANIZATION' );

    subtest 'success' => sub {
        my $data = file('t/data/incidents.json')->slurp;
        $Mock_furl->mock(request => sub { Furl::Response->new } );
        $Mock_furl_res->mock(content => sub { $data });

        my $res = $rct->incidents({
            from     => 1430208000,
            to       => 1440210000,
            status   => 'open',
            page     => 2,
            per_page => 15,
        });

        is_deeply $res, decode_json($data);
    };
};

subtest 'notify_incident()' => sub {
    my $rct = WebService::Reactio->new( api_key => 'API_KEY', organization => 'ORGANIZATION' );

    subtest 'error' => sub {
        eval { $rct->notify_incident() };
        ok $@, "Incident id and notification message doesn't exist";

        eval { $rct->notify_incident(1) };
        ok $@, "Notification message doesn't exist";
    };

    subtest 'success' => sub {
        my $data = file('t/data/notify.json')->slurp;
        $Mock_furl->mock(request => sub { Furl::Response->new } );
        $Mock_furl_res->mock(content => sub { $data });

        my $res = $rct->notify_incident(1, "Webサーバで障害が発生しました。至急対応をお願い致します。", {
            notification_call => JSON::true
        });

        is_deeply $res, decode_json($data);
    };
};

subtest 'send_message()' => sub {
    my $rct = WebService::Reactio->new( api_key => 'API_KEY', organization => 'ORGANIZATION' );

    subtest 'error' => sub {
        eval { $rct->notify_incident() };
        ok $@, "Incident id and message doesn't exist";

        eval { $rct->notify_incident(1) };
        ok $@, "Message doesn't exist";
    };

    subtest 'success' => sub {
        my $data = file('t/data/send_message.json')->slurp;
        $Mock_furl->mock(request => sub { Furl::Response->new } );
        $Mock_furl_res->mock(content => sub { $data });

        my $res = $rct->notify_incident(1, "LoadAverageが50に上昇しました。", {
            notification_call => JSON::true
        });

        is_deeply $res, decode_json($data);
    };
};

done_testing;
