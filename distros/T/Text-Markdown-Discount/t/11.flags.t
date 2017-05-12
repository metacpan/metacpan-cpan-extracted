use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use Text::Markdown::Discount;

is(Text::Markdown::Discount::markdown("hey\nhttp://mixi.jp"), "<p>hey\nhttp://mixi.jp</p>\n");
is(Text::Markdown::Discount::markdown("hey\nhttp://mixi.jp", Text::Markdown::Discount::MKD_AUTOLINK), qq{<p>hey\n<a href="http://mixi.jp">http://mixi.jp</a></p>\n});
