use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

BEGIN { use_ok('XUL::Image'); }

dies_ok {
    XUL::Image->new;
} 'count is required';

dies_ok {
    XUL::Image->new(count => 'foo');
} 'count should be Int';

dies_ok {
    XUL::Image->new(count => '3.2');
} 'count should be Int';

lives_ok {
    XUL::Image->new(count => '32');
} 'num-like string is okay';

my $conv = XUL::Image->new(count => 180);
ok $conv;
isa_ok $conv, 'XUL::Image';

is $conv->count, 180, 'count read ok';
dies_ok {
    $conv->count(32);
} 'count cannot be written';

is $conv->delay, 1, 'delay defaults to 1';
lives_ok {
    $conv->delay(2);
} 'delay is writable';
is $conv->delay, 2, 'delay updated';

is $conv->outdir, 'xul_img', 'outdir defaults to xul_img';
lives_ok {
    $conv->outdir('tmp');
} 'outdir is writable';
is $conv->outdir, 'tmp', 'outdir updated';

is $conv->title, 'Mozilla', 'title defaults to Mozilla';

$conv = XUL::Image->new(count => 12, outdir => 'tmp', delay => undef);
ok $conv;
isa_ok $conv, 'XUL::Image';
is $conv->count, 12, 'count ok';
is $conv->outdir, 'tmp', 'outdir ok';
is $conv->delay, 1, 'undef delay defaults to 1 (sec)';
