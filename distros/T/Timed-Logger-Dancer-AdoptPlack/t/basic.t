use strict;
use warnings;

use Test::More tests => 4;
use Dancer qw();
use Dancer::SharedData;

my $module = 'Timed::Logger::Dancer::AdoptPlack';
use_ok($module);
isa_ok($module->logger, 'Timed::Logger', 'got an time logger object even if there is no Dancer request');

my $request = Dancer::Request->new_for_request('GET', '/', {}, '', '');
Dancer::SharedData->request($request);
isa_ok($module->logger, 'Timed::Logger', 'got an time logger object');

my $env = { Plack::Middleware::Timed::Logger::PSGI_KEY() => 'test log' };
$request->env($env);
is($module->logger, 'test log', 'got log from env');
