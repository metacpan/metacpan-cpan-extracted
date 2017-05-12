use strict;
use warnings;
use Test::More;
plan tests => 6;

use utf8;
use dan;
my $data = 'foo';
isnt $data, '';
is $data, 'foo';

no utf8;
$data = 'foo';
is $data, 'foo';
is $data, '';

use utf8;
use dan force => 1;
my $data2 = 'foo';
is $data2, '';
is $data2, 'foo';
