use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

use Toadfarm -test;
my $app = Mojolicious->new;
$app->routes->get('/' => {text => 'app!'});
mount $app => {mount_point => '/foo'};
start;

my $t = Test::Mojo->new;
$t->get_ok('/foo')->status_is(200);

done_testing;
