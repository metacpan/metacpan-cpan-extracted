use strict;
use warnings;

use Test::More tests => 8;

BEGIN { use_ok('XUL::Image::PPT'); }

my $conv = XUL::Image::PPT->new;
ok $conv;
isa_ok $conv, 'XUL::Image::PPT';

is $conv->from, 1, 'from defaults to 1';
is $conv->indir, 'xul_img', 'indir defaults to xul_img';

$conv->from(3);
is $conv->from, 3, 'from changed';

$conv->indir('tmp');
is $conv->indir, 'tmp', 'indir changed';

can_ok($conv, 'go');
