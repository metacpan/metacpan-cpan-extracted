use strict;
use warnings;
use Test::Base tests => 2;

use WebService::Yes24::Item;

my $item = WebService::Yes24::Item->new(
    title     => 'Learning Perl (Hardcover, 5, English)',
    cover     => 'http://image.yes24.com/momo/TopCate75/MidCate08/7479928.jpg',
    author    => 'Tom Phoenix, Randal L.  Schwartz, Brian d Foy',
    publisher => 'O\' Reilly ',
    date      => ' 2008 - 07 ',
    price     => ' 41800 ',
    mileage   => ' 2090 ',
    link      => 'http://www.yes24.com/24/goods/2884380',
);

ok $item;
isa_ok $item, 'WebService::Yes24::Item';
