use strict;
use warnings;
use Test::More tests => 2;
use Test::TCP;
use Plack::Runner;
use Plack::Request;
use LWP::UserAgent;
use List::MoreUtils qw(any);
use AnyEvent;
use AnyEvent::HTTP qw(http_get);
use HTTP::Headers;

my $max_workers = 1;
my $max_reqs_per_child = 5;

my $reqs = 60;

my $reqs_per_child = 0;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $params = $req->parameters;
    $reqs_per_child++;

    return sub {
        my ($write, $sock) = @_;
        my $w; $w = AE::timer 3, 0, sub {
            $write->([
                200,
                [
                    'Content-Type' => 'text/plain',
                    'X-Requests-Per-Child' => $reqs_per_child,
                ],
                [ $$ ],
            ]);
            undef $w;
        };
    };
};


test_tcp
    client => sub {
        my $port = shift;

        my $cv = AE::cv;
        $cv->begin;

        local $AnyEvent::HTTP::MAX_PER_HOST = $reqs;

        my %res;
        my @code;
        my @pids;
        for ( 1..$reqs ) {
            my $url = "http://127.0.0.1:$port/";
            my $status = "http://127.0.0.1:$port/status";

            $cv->begin;
            http_get $url, sub {
                my ($body, $headers) = @_;
                $headers = HTTP::Headers->new(%$headers);

                $res{$body} ||= 1;
                my $reqs_per_child = $headers->header('x-requests-per-child');
                if ($res{$body} < $reqs_per_child) {
                    $res{$body} = $reqs_per_child;
                }
                my $status = $headers->header('status');
                push @code, $status if $status == 200;

                $cv->end;
            };
        }

        $cv->end;
        $cv->recv;

        is scalar @code, $reqs;
        ok any { $res{$_} > $max_reqs_per_child } keys %res;
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
