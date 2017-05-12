use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;
use Mojo::UserAgent;

use_ok('Test::RestAPI'); 

my $api = Test::RestAPI->new();

lives_ok {
    $api->start();
    } 'start don\'t died';

my $uri = $api->uri;

my $ua = Mojo::UserAgent->new();
is($ua->get($uri)->res->body(), 'Hello', 'response ok');

#system 'cat '.$api->mojo_home.'/log/production.log';

undef $api;
sleep 1;

ok($ua->get($uri)->res->error(), 'after destroy Test object API is dead');