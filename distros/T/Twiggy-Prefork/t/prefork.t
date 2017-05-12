use strict;
use warnings;
use Test::More qw(no_diag);
use Test::TCP;
use Plack::Loader;
use Plack::Request;
use LWP::UserAgent;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $params = $req->parameters;

    return [
        200,
        [ 'Content-Type' => 'text/plain', ],
        [ $$ ],
    ];
};

test_tcp(
    client => sub {
        my $port = shift;

        # XXX LWP is implied by plack
        my $ua = LWP::UserAgent->new();
        my %res;
        my @code;
        my $req = 60;
        for ( 1..$req ) {
            my $res = $ua->get("http://127.0.0.1:$port/");
            $res{$res->content}++;
            push @code, $res->code if $res->code == 200;
        }
        is scalar @code, $req;
        ok scalar keys %res > 4;
    },
    server => sub {
        my $port = shift;
        my $server = Plack::Loader->load(
            'Twiggy::Prefork', 
            port => $port, 
            host => '127.0.0.1',
            'max_workers' => 3,
            'max_reqs_per_child' => 10,
        );
        $server->run($app);
        exit;
    },
);

done_testing();
