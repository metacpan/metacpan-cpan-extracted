use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;

plan skip_all => "set TEST_FULL to test requests to live servers" unless $ENV{TEST_FULL};

variate_catch('[client-live]', 'ssl');

subtest "default loop" => sub {
    my $loop = new UE::Loop->default_loop;
    my $test = new UE::Test::Async(1, 1, $loop);
    UE::HTTP::http_request({
        uri => 'http://ya.ru',
        response_callback => sub {
            my ($request, $response) = @_;
            is $response->code, 200;
            $test->happens;
            $loop->stop;
        },
    });
    $loop->run;
};

subtest "separate loop" => sub {
    my $loop = new UE::Loop->new;
    my $test = new UE::Test::Async(1, 1, $loop);
    UE::HTTP::http_request({
        uri => 'http://ya.ru',
        response_callback => sub {
            my ($request, $response) = @_;
            is $response->code, 200;
            $test->happens;
            $loop->stop;
        },
    }, $loop);
    $loop->run;
};

subtest "https" => sub {
    my $loop = new UE::Loop->default_loop;
    my $test = new UE::Test::Async(1, 1, $loop);
    UE::HTTP::http_request({
        uri => 'https://ya.ru',
        response_callback => sub {
            my ($request, $response) = @_;
            is $response->code, 200;
            $test->happens;
            $loop->stop;
        },
    });
    $loop->run;
};

subtest "sync simple get" => sub {
    my ($res, $err) = UE::HTTP::http_get("https://ya.ru");
    is $err, undef;
    cmp_ok length($res->body), '>', 0, "body length = ".length($res->body);
};

subtest "async simple get" => sub {
    my $body;
    UE::HTTP::http_get("https://ya.ru", sub {
        my ($req, $res, $err) = @_;
        is $err, undef;
        $body = $res->body;
    });
    UE::Loop::default->run;
    cmp_ok length($body), '>', 0, "body length = ".length($body);
};

done_testing();
