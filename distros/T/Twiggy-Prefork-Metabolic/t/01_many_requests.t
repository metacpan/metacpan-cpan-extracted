use strict;
use warnings;
use Test::More;
use Test::TCP;
use Plack::Runner;
use Plack::Request;
use LWP::UserAgent;

my $max_workers = 3;
my $max_reqs_per_child = 5;

my $reqs = 60;

my $reqs_per_child = 0;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $params = $req->parameters;
    $reqs_per_child++;
    return [
        200,
        [
            'Content-Type' => 'text/plain',
            'X-Requests-Per-Child' => $reqs_per_child,
        ],
        [ $$ ],
    ];
};

test_tcp
    client => sub {
        my $port = shift;

        my $ua = LWP::UserAgent->new();
        my %res;
        my @code;
        for ( 1..$reqs ) {
            my $res = $ua->get("http://127.0.0.1:$port/");
            $res{$res->content}++;
            push @code, $res->code if $res->code == 200;
            # Note: the worker will be restarted just exactly at the
            # time when $max_reqs_per_child is reached since we are
            # requesting sequentially
            cmp_ok scalar $res->header('X-Requests-Per-Child'), '<=', 5;
        }
        is scalar @code, $reqs;

        my $childs = $max_reqs_per_child;
        my $workers = int(($reqs + $childs - 1) / $childs);

        # The estimated minimum number of worker consumption
        # (when the requests distributed to all workers equally)
        cmp_ok scalar keys %res, '>=', $workers;
        # The estimated minimum number of worker consumption
        # (when the requests went to a single worker)
        cmp_ok scalar keys %res, '<', $workers + $max_workers;
    },
    server => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options(split(/\s+/, qq(
            --server Twiggy::Prefork::Metabolic
            --host 127.0.0.1
            --max_workers $max_workers
            --max-reqs-per-child $max_reqs_per_child
            --env test
            --port $port
        )));
        $runner->run($app);
        exit;
    };

done_testing();
