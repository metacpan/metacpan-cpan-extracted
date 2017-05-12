use strict;
use warnings;
use utf8;
use Test::More tests => 12;
use Text::Markdown::Discount;

{
    my $perl_string = '# あ';
    my $html = Text::Markdown::Discount::markdown($perl_string);
    like $html, qr!<h1>あ</h1>!;
    ok utf8::is_utf8($html);
}

{
    no utf8;
    my $byte = '# あ';
    my $html = Text::Markdown::Discount::markdown($byte);
    like $html, qr!<h1>あ</h1>!;
    ok !utf8::is_utf8($html);
}

{
    my $perl_string = '*イーエム*';
    my $html = Text::Markdown::Discount::markdown($perl_string);
    like $html, qr!<em>イーエム</em>!;
    ok utf8::is_utf8($html);
}

{
    no utf8;
    my $byte = '*イーエム*';
    my $html = Text::Markdown::Discount::markdown($byte);
    like $html, qr!<em>イーエム</em>!;
    ok !utf8::is_utf8($html);
}

{
    my $perl_string = '_イーエム_';
    my $html = Text::Markdown::Discount::markdown($perl_string);
    like $html, qr!<em>イーエム</em>!;
    ok utf8::is_utf8($html);
}

{
    no utf8;
    my $byte = '_イーエム_';
    my $html = Text::Markdown::Discount::markdown($byte);
    like $html, qr!<em>イーエム</em>!;
    ok !utf8::is_utf8($html);
}
