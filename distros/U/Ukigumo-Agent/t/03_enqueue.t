use strict;
use warnings;
use utf8;
use t::Util;
use LWP::UserAgent;
use JSON qw/encode_json/;
use Ukigumo::Agent::Manager;
use Test::More;

undef *Ukigumo::Agent::Manager::register_job;
*Ukigumo::Agent::Manager::register_job = sub {};

my $agent       = t::Util::build_ukigumo_agent();
my $ua          = LWP::UserAgent->new(timeout => 3);
my $enqueue_url = "http://127.0.0.1:@{[ $agent->port ]}/api/v0/enqueue";

subtest 'normal' => sub {
    my $res = $ua->post(
        $enqueue_url,
        +{
            repository => '127.0.0.1/repos',
            branch     => 'master',
        },
    );
    is $res->code, 200;
};

subtest 'validation error' => sub {
    subtest 'branch is missing' => sub {
        my $res = $ua->post(
            "http://127.0.0.1:@{[ $agent->port ]}/api/v0/enqueue",
            +{
                repository => '127.0.0.1/repos',
            },
        );
        is $res->code, 400;
    };

    subtest 'repository is missing' => sub {
        my $res = $ua->post(
            "http://127.0.0.1:@{[ $agent->port ]}/api/v0/enqueue",
            +{
                branch => 'master',
            },
        );
        is $res->code, 400;
    };
};

done_testing;

