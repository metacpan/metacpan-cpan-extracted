
use v5.38;
use Test::More;
use Test::Warnings;

use WebService::Akeneo;
use WebService::Akeneo::Config;

pass('compiles');
ok(WebService::Akeneo->can('new'), 'constructor exists');

done_testing;
