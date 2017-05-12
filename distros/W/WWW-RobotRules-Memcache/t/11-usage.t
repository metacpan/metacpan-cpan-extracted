#!perl

use strict;
use warnings;

use Test::More;

use English;
use Module::Build;

use Cache::Memcached;

my $build = Module::Build->current;

my $memcache = $build->args('memcache');

if (! $memcache) { plan skip_all => 'A memcache server was not set during build. Please do so: Build.PL --memcache="host:port"'; }

plan 'no_plan';

use_ok( 'WWW::RobotRules::Memcache' );

my $memd = Cache::Memcached->new({
    'servers' => [ $memcache ],
});

$memd->set('test-key', 'This is a test');
my $testvar = $memd->get('test-key');
is($testvar, 'This is a test');

my $robot = WWW::RobotRules::Memcache->new($memcache);
ok($robot);
isa_ok($robot, 'WWW::RobotRules::Memcache');

$robot->parse('http://www.w3.org/robots.txt', '');

$robot->visit('www.w3.org:80');

is($robot->no_visits('www.w3.org:80'), 1);

$robot->push_rules('www.w3.org:80', '/aas', '/per');
$robot->push_rules('www.w3.org:80', '/god', '/old');

my @rules = $robot->rules('www.w3.org:80');
is_deeply(\@rules, ['/aas', '/per', '/god', '/old']);

$robot->clear_rules('per');
$robot->clear_rules('www.w3.org:80');

@rules = $robot->rules('www.w3.org:80');
is_deeply(\@rules, []);

$robot->visit('www.w3.org:80', time + 10);
$robot->visit('www.w3.org:80');

is($robot->no_visits('www.w3.org:80'), 3);

ok(abs($robot->last_visit('www.w3.org:80') - time) > 2);

$robot = undef;

$robot = WWW::RobotRules::Memcache->new($memcache);
ok($robot);
isa_ok($robot, 'WWW::RobotRules::Memcache');

$robot->visit('www.w3.org:80');

is($robot->no_visits('www.w3.org:80'), 4);

