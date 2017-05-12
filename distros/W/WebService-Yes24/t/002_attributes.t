use strict;
use warnings;
use Test::Base tests => 8;

use WebService::Yes24::Item;

my $yes24 = WebService::Yes24::Item->new(
    title     => 'Learning Perl (Hardcover, 5, English)',
    cover     => 'http://image.yes24.com/momo/TopCate75/MidCate08/7479928.jpg',
    author    => 'Tom Phoenix, Randal L. Schwartz, Brian d Foy',
    publisher => 'O\'Reilly',
    date      => '2008-07',
    price     => '41800',
    mileage   => '2090',
    link      => 'http://www.yes24.com/24/goods/2884380?scode=032&srank=1',
);

#
# get attributes
#
is(
    $yes24->title,
    'Learning Perl (Hardcover, 5, English)',
    'attributes get: title',
);
is(
    $yes24->cover,
    'http://image.yes24.com/momo/TopCate75/MidCate08/7479928.jpg',
    'attributes get: cover'
);
is(
    $yes24->author,
    'Tom Phoenix, Randal L. Schwartz, Brian d Foy',
    'attributes get: author',
);
is( $yes24->publisher, 'O\'Reilly', 'attributes get: publisher', );
is( $yes24->date,      '2008-07',   'attributes get: date', );
is( $yes24->price,     '41800',     'attributes get: price', );
is( $yes24->mileage,   '2090',      'attributes get: mileage', );
is(
    $yes24->link,
    'http://www.yes24.com/24/goods/2884380?scode=032&srank=1',
    'attributes get: link',
);
