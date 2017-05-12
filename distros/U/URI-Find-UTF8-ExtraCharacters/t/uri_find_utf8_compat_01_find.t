use strict;
use warnings;
use utf8;
use Test::Base;
use URI::Find::UTF8::ExtraCharacters;

#adapted from URI::Find::UTF8 0.03
sub URI::Find::UTF8 {
    'URI::Find::UTF8::ExtraCharacters'
}

filters { raw => 'chomp', uri => 'chomp' };

plan tests => 2 * blocks;

run {
    my $block = shift;

    my $f = URI::Find::UTF8->new(
        sub {
            my($uri, $orig) = @_;
            is $uri->as_string, $block->uri, "$uri";
            is $orig, $block->raw, "raw path";
        },
    );
    $f->find(\$block->input);
}

__DATA__

===
--- input
アンサイクロペディアのホームページはhttp://ja.uncyclopedia.info/wiki/メインページ foo bar
--- raw
http://ja.uncyclopedia.info/wiki/メインページ
--- uri
http://ja.uncyclopedia.info/wiki/%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8

===
--- input
Home page <URL:http://www.google.com> Google
--- raw
http://www.google.com
--- uri
http://www.google.com
