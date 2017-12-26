use strict;
use warnings;

use Test::Deep;
use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => { 'moz:firefoxOptions' => { args => ['-headless'] } },
    host         => 'geckodriver',
    port         => 4444,
);

cmp_deeply $drv->status,
    { message => 'Session already started', ready => bool(0) }, 'status';

done_testing;
