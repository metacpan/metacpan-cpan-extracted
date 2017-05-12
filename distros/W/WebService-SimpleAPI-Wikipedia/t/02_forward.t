use strict;
use utf8;
use Test::Base;

use WebService::SimpleAPI::Wikipedia;

plan tests => 2 * blocks;

filters { opt => 'yaml', id => 'chomp', title => 'chomp' };

run {
    my $block = shift;
    my $api = WebService::SimpleAPI::Wikipedia->new;
    my $res = $api->api($block->opt);
    my @val = grep { $_->id eq $block->id } @{ $res };

    if (@val) {
        is $val[0]->title, $block->title;
        like $val[0]->datetime->year, qr/^20/;
    } else {
        fail("disagreement of id: " . $block->id);
        fail;
    }
}

__END__

===
--- opt
keyword: Perl
lang: ja
search: 1
--- id
1063
--- title
Perl

===
--- opt
keyword: TCP/IP
lang: ja
search: 1
--- id
1438
--- title
TCP/IP

===
--- opt
keyword: Google
lang: ja
search: 1
--- id
668439
--- title
Google

===
--- opt
keyword: Yahoo
lang: ja
search: 1
--- id
63513
--- title
Yahoo

===
--- opt
keyword: 日本
lang: ja
search: 1
--- id
14383
--- title
日本酒

