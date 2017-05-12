use strict;
use utf8;
use Test::Base;

use WebService::SimpleAPI::Wikipedia;

plan tests => 1 * blocks;

filters { opt => 'yaml', id => 'chomp', title => 'chomp' };

run {
    my $block = shift;
    my $api = WebService::SimpleAPI::Wikipedia->new({ quiet => 1 });
    my $res = $api->api($block->opt);
    is $res->nums, 0;
}

__END__

===
--- opt
keyword: Perls
lang: ja
search: 1

===
--- opt
keyword: Yappon
lang: ja
search: 1

===
--- opt
keyword: Boofy
lang: ja
search: 1
