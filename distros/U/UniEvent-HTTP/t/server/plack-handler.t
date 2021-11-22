use 5.020;
use warnings;
use Test::More;
use UniEvent;

plan skip_all => 'Plack required to test Plack handler' unless eval {require Plack::Test::Suite; 1};
Plack::Test::Suite->run_server_tests('UniEvent::HTTP::Simple');

use Protocol::HTTP::Error;
use Plack::Handler::UniEvent::HTTP::Simple;
require Plack::Util;

subtest "request is dropped unpon buggy app (MEIACORE-1754)" => sub {
    my $class = 'Plack::Handler::UniEvent::HTTP::Simple';

    my $buggy_app = sub {
        note "invoking app";
        return sub {
            my $responder = shift;
            note "delayed responder $responder has bee invoked";
        };
    };

    my $invoked;
    my $srv = $class->new(host => '127.0.0.1', port => 0);
    $srv->{server}->run_event->add(sub{
        my $base_addr = $srv->{server}->sockaddr . "";
        my $uri = "http://$base_addr/";
        note "going to make a request on $uri";
        my $ua = UniEvent::HTTP::UserAgent->new;
        $ua->request({
            uri               => $uri,
            response_callback => sub {
                my (undef, $res, $err) = @_;
                note "response_callback";
                is $err, Protocol::HTTP::Error::unexpected_eof;
                undef $ua;
                $invoked = 1;
                $srv->{server}->stop;
            },
        });
    });
    $srv->run($buggy_app);
    ok $invoked;
};

done_testing();
