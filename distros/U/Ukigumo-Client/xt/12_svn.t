use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'LWP::Protocol::PSGI';

plan skip_all => 'There is no svn' if system('svn --version')!=0;

use Ukigumo::Client;
use Ukigumo::Client::VC::SVN;
use Ukigumo::Client::Executor::Perl;
use Ukigumo::Constants;
use JSON;

LWP::Protocol::PSGI->register(sub{
    ok 1;
    [200, ['Content-Type' => 'text/json'], [
        encode_json(+{
            report => {
                url => 'http://...',
            },
        })
    ]];
});

my $client = Ukigumo::Client->new(
    vc => Ukigumo::Client::VC::SVN->new(
        branch     => 'trunk',
        repository => 'http://svn.coderepos.org/share/dan/perl/PL_check/trunk/',
    ),
    server_url => 'http://localhost/',
    executor   => Ukigumo::Client::Executor::Perl->new(),
    quiet      => 1,
);
$client->run();

done_testing;

