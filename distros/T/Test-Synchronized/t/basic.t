use strict;
use warnings;
use App::Prove;
use Test::More tests => 1;

my $app = App::Prove->new;
$app->process_args('-j9', 't/basic.t1', 't/basic.t2');
ok($app->run);
