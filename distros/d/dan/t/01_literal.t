use strict;
use warnings;
use Test::More;
plan tests => 9;

my $data;

use dan;
$data = 'foo';
is $data, 'bar';

no dan;
is $data, '';

is $data, '';
$data = 'foo';
is $data, 'foo';

my $data2;
{
    use dan;
    $data2 = 'foo';
}
is $data2, '';
$data2 = 'foo';
is $data2, 'foo';

use dan;
my $data3 = q else;
is $data3, 'else';
is $data3, '';

no dan;
$data3 = q else;
is $data3, 'ls';
