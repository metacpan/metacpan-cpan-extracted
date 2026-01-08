use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    is_deeply Wiki::JSON->new->parse(''), [], 'Empty string is empty mediawiki';
    my $parsed_html = Wiki::JSON->new->pre_html('');

    #    print Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html,
      [
        {
            'status' => 'open',
            'tag'    => 'article',
            'attrs'  => {
                'class' => 'wiki-article'
            }
        },
        {
            'tag'    => 'article',
            'status' => 'close'
        }
      ],
      'Empty string is empty mediawiki HTML';
}
{
    is_deeply Wiki::JSON->new->parse( '
' ),
      [], 'Empty lines do not parsed';
}
{
    my $text = 'hola

adios';

    my $parsed = Wiki::JSON->new->parse($text);

    #    print STDERR Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [ 'hola', 'adios' ], 'Text parsing works';
    my $parsed_html = Wiki::JSON->new->pre_html($text);
#    print Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html,
      [
        {
            'status' => 'open',
            'attrs'  => {
                'class' => 'wiki-article'
            },
            'tag' => 'article'
        },
        {
            'tag'    => 'p',
            'status' => 'open',
            attrs    => {},
        },
        'hola',
        {
            'tag'    => 'p',
            'status' => 'close'
        },
        {
            'status' => 'open',
            'tag'    => 'p',
            attrs    => {},
        },
        'adios',
        {
            'status' => 'close',
            'tag'    => 'p'
        },
        {
            'tag'    => 'article',
            'status' => 'close'
        }
      ],
      'Text parsing works';
}
{
    my $text = "hola\n\r\n\radios";

    my $parsed = Wiki::JSON->new->parse($text);

    #    print STDERR Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [ 'hola', 'adios' ], 'Text parsing works';
    my $parsed_html = Wiki::JSON->new->pre_html($text);
#    print Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html,
      [
        {
            'status' => 'open',
            'attrs'  => {
                'class' => 'wiki-article'
            },
            'tag' => 'article'
        },
        {
            'tag'    => 'p',
            'status' => 'open',
            attrs    => {},
        },
        'hola',
        {
            'tag'    => 'p',
            'status' => 'close'
        },
        {
            'status' => 'open',
            'tag'    => 'p',
            attrs    => {},
        },
        'adios',
        {
            'status' => 'close',
            'tag'    => 'p'
        },
        {
            'tag'    => 'article',
            'status' => 'close'
        }
      ],
      'Text parsing works';
}
done_testing();
