use strict;
use warnings;
use lib 'lib';
use lib 't/lib';
use Test::More;
use Text::Xatena;
use Text::Xatena::Util;
use Encode;
use Text::Xatena::Test;
use Text::Xatena::Test::MyInline;
use Test::HTML::Differences;

plan tests => 3;

sub u8 ($) {
    decode_utf8(shift);
}

sub is_u8 ($;$) {
    ok utf8::is_utf8(shift), shift;
}

subtest "basic" => sub {
    my $thx = Text::Xatena->new;
    isa_ok $thx, "Text::Xatena";
    ok $thx->format('foobar');
    is_u8 $thx->format(u8 'あああ'), 'format takes utf8 strings';

    is $thx->format(""), '', 'empty string';
    is $thx->format("\n"), '', 'empty string';
    done_testing;
};

subtest "replace inline" => sub {
    my $thx = Text::Xatena->new;
    is $thx->format('TEST'), "<p>TEST</p>\n";
    {
        my $thx = Text::Xatena->new(inline => Text::Xatena::Test::MyInline->new);
        is $thx->format('TEST'), "<p>XXXX</p>\n";
    };
    is $thx->format('TEST'), "<p>TEST</p>\n";
    {
        my $thx = Text::Xatena->new;
        is $thx->format('TEST', inline => Text::Xatena::Test::MyInline->new), "<p>XXXX</p>\n";
    };
    is $thx->format('TEST'), "<p>TEST</p>\n";

    done_testing;
};

subtest "replace block" => sub {
    {
        my $thx = Text::Xatena->new(syntaxes => [
        ]);
        eq_or_diff_html $thx->format(">>\nquote\n<<"), "<p>>><br />quote<br /><<</p>";
    };

    {
        my $thx = Text::Xatena->new(syntaxes => [qw/List/]);
        eq_or_diff_html $thx->format(unindent q{
            * foobar

            - 1111
            - 2222
            - 3333
        }), q{
            <p>* foobar</p>
            <ul>
                <li>1111</li>
                <li>2222</li>
                <li>3333</li>
            </ul>
        };
    };

    done_testing;
};


