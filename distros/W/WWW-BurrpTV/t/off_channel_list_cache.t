use Test::More;
use warnings;
use strict;

plan tests => 3;


use_ok('WWW::BurrpTV');
my $tv = WWW::BurrpTV->new(cache => 't/files');
isa_ok($tv, 'WWW::BurrpTV');

my $list = $tv->channel_list;
is($list->{'Star Movies'}, 'http://tv.burrp.com/channel/star-movies/59/', 'Channel list retrieval');
