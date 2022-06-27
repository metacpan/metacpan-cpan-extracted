use strict;
use warnings;

use lib 'meia/lib', 'meia/var/lib';
use UniEvent;
use Panda::W;
#use Panda::X::Server;
use UniEvent::HTTP::Client;

$SIG{PIPE} = 'IGNORE';
use UniEvent::HTTP qw/http_request/;

use XLog;
use XLog::File;
#XLog::set_logger(XLog::Console->new);
XLog::set_logger(XLog::File->new({file => "ebanarot.log"}));
XLog::set_level(XLog::DEBUG, "UniEvent::HTTP");

my @clients;

my $pool = UniEvent::HTTP::Pool::instance();

my $i = 0;
my $t = UE::Timer->new;
$t->start(0.01);

$t->callback(sub {
    $pool->request({
        uri => 'http://dev.crazypanda.ru:42027/',
        body => '{}',
        method => Protocol::HTTP::Request::METHOD_POST(),
        timeout => 1,
        response_callback => sub {
            my ($request, $response, $err) = @_;
            $i++;
            warn "#$i ".$response->code." - $err" if $err;
        },
    });
});

UE::Loop->default_loop->run;
