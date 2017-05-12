use strict;
use warnings;
use Test::Base tests => 12;

use WebService::Yes24;

my $yes24 = WebService::Yes24->new;

#
# get default
#
is $yes24->category,   'all',      'attributes get: category';
is $yes24->page_size,  20,         'attributes get: page_size';
is $yes24->page,       1,          'attributes get: page';
is $yes24->sort,       'accuracy', 'attributes get: sort';
is $yes24->sold_out,   1,          'attributes get: sold_out';
is $yes24->query_type, 'normal',   'attributes get: query_type';

#
# set & get
#
$yes24->category('korean-book');
is $yes24->category, 'korean-book', 'attributes set: category';

$yes24->page_size(40);
is $yes24->page_size, 40, 'attributes set: page_size';

$yes24->page(10);
is $yes24->page, 10, 'attributes set: page';

$yes24->sort('low-price');
is $yes24->sort, 'low-price', 'attributes set: sort';

$yes24->sold_out(0);
is $yes24->sold_out, 0, 'attributes set: sold_out';

$yes24->query_type('author');
is $yes24->query_type, 'author', 'attributes set: query_type';

#
# set invalid attributes
#
# TODO:
