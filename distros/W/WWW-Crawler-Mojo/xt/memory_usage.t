use strict;
use warnings;
use utf8;
use Data::Dumper;
use Mojo::IOLoop;
use WWW::Crawler::Mojo;
use Devel::Size qw(total_size);

my $page = 1;
my $max = 50;

my $daemon = Mojo::Server::Daemon->new(
    ioloop => Mojo::IOLoop->singleton,
    silent => 1,
    listen => ['http://127.0.0.1'],
);

$daemon->on(request => sub {
    my ($daemon, $tx) = @_;
    my $method = $tx->req->method;
    my $path   = $tx->req->url->path;
    $tx->res->code(200);
    $tx->res->headers->content_type('text/html');
    $tx->res->body(<<"EOF") if $page < $max;
<html>
    <body>
        <a href="/@{[ ++$page ]}">$page</a>
        <a href="/@{[ ++$page ]}">$page</a>
        <a href="/@{[ ++$page ]}">$page</a>
        <a href="/@{[ ++$page ]}">$page</a>
        <a href="/@{[ ++$page ]}">$page</a>
    <body>
</html>
EOF
    $tx->res->body(<<"EOF") if $page >= $max;
<html>
    <body>
    <body>
</html>
EOF
    $tx->resume;
});
$daemon->start;

my $port = Mojo::IOLoop->acceptor($daemon->acceptors->[0])->handle->sockport;
my $base = Mojo::URL->new("http://127.0.0.1:$port");
my $bot = WWW::Crawler::Mojo->new;
$bot->enqueue(WWW::Crawler::Mojo::resolve_href($base, '/'));

my $last_job;

$bot->on('res' => sub {
    my ($bot, $scrape, $job, $res) = @_;
    $job->url($job->url->to_string);
    $bot->enqueue($_) for $scrape->();
    $last_job = $job;
});
$bot->init;

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

warn total_size($last_job);
warn Dumper($last_job);
