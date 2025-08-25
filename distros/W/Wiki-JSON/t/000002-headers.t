use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    for ( my $i = 1 ; $i < 7 ; $i++ ) {
        my $text   = ( '=' x $i ) . ' hola ' . ( '=' x $i );
        my $parsed = Wiki::JSON->new->parse($text);

        #        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => $i,
                'type'     => 'hx'
            },
          ],

          'Single header well-formed';
        my $parsed_html = Wiki::JSON->new->pre_html($text);

        #          print STDERR Data::Dumper::Dumper $parsed_html;
        is_deeply $parsed_html,
          [
            Wiki::JSON::HTML->_open_html_element(
                'article', 0, { class => 'wiki-article' }
            ),
            Wiki::JSON::HTML->_open_html_element( 'h' . $i ),
            'hola',
            Wiki::JSON::HTML->_close_html_element( 'h' . $i ),
            Wiki::JSON::HTML->_close_html_element('article'),
          ],

          'Single header well-formed HTML';
    }
}
{
    for ( my $i = 1 ; $i < 7 ; $i++ ) {
        my $text   = ( '=' x $i ) . ' hola ';
        my $parsed = Wiki::JSON->new->parse($text);

        #        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => $i,
                'type'     => 'hx'
            },
          ],

          'Single header without equal signs in the end';
        my $parsed_html = Wiki::JSON->new->pre_html($text);

        #        print STDERR Data::Dumper::Dumper $parsed_html;
        is_deeply $parsed_html,
          [
            Wiki::JSON::HTML->_open_html_element(
                'article', 0, { class => 'wiki-article' }
            ),
            Wiki::JSON::HTML->_open_html_element( 'h' . $i ),
            'hola',
            Wiki::JSON::HTML->_close_html_element( 'h' . $i ),
            Wiki::JSON::HTML->_close_html_element('article'),
          ],
          'Single header without equal signs in the end html';
    }
}

{
    for ( my $i = 1 ; $i < 7 ; $i++ ) {
        my $text   = ( '=' x $i ) . ' hola =';
        my $parsed = Wiki::JSON->new->parse($text);

        #        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => $i,
                'type'     => 'hx'
            },
          ],

          'Single header unbalanced';
        my $parsed_html = Wiki::JSON->new->pre_html($text);

        #            print STDERR Data::Dumper::Dumper $parsed_html;
        is_deeply $parsed_html,
          [
            Wiki::JSON::HTML->_open_html_element(
                'article', 0, { class => 'wiki-article' }
            ),
            Wiki::JSON::HTML->_open_html_element( 'h' . $i ),
            'hola',
            Wiki::JSON::HTML->_close_html_element( 'h' . $i ),
            Wiki::JSON::HTML->_close_html_element('article'),
          ],
          'Single header unbalanced html';
    }
}
{
    for ( my $i = 1 ; $i < 7 ; $i++ ) {
        my $text = ( '=' x $i ) . ' hola 

hola

hola

hola';
        my $parsed = Wiki::JSON->new->parse($text);

        #        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => $i,
                'type'     => 'hx'
            },
            'hola', 'hola', 'hola',
          ],

          'Single header without equal signs in the end plus text';
        my $parsed_html = Wiki::JSON->new->pre_html($text);

        #        print Data::Dumper::Dumper $parsed_html;
        is_deeply $parsed_html,
          [
            Wiki::JSON::HTML->_open_html_element(
                'article', 0, { class => 'wiki-article' }
            ),
            Wiki::JSON::HTML->_open_html_element( 'h' . $i ),
            'hola',
            Wiki::JSON::HTML->_close_html_element( 'h' . $i ),
            Wiki::JSON::HTML->_open_html_element('p'),
            'hola',
            Wiki::JSON::HTML->_close_html_element('p'),
            Wiki::JSON::HTML->_open_html_element('p'),
            'hola',
            Wiki::JSON::HTML->_close_html_element('p'),
            Wiki::JSON::HTML->_open_html_element('p'),
            'hola',
            Wiki::JSON::HTML->_close_html_element('p'),
            Wiki::JSON::HTML->_close_html_element('article'),
          ],
          'Single header without equal signs in the end plus text html';
    }
}
{
    my $text = 'hola === hola === hola

hola

hola

hola';
    my $parsed = Wiki::JSON->new->parse($text);

    #        print STDERR Data::Dumper::Dumper $parsed;
    is_deeply $parsed,
      [
        'hola ',
        {
            'output'   => ['hola'],
            'hx_level' => 3,
            'type'     => 'hx'
        },
        ' hola', 'hola', 'hola', 'hola',
      ],

      'Cursed titles in the same line work too';
    my $parsed_html = Wiki::JSON->new->pre_html($text);

    #            print STDERR Data::Dumper::Dumper @$parsed_html;
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola ',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('h3'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('h3'),
        Wiki::JSON::HTML->_open_html_element('p'),
        ' hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
      ],
      'Cursed titles in the same line work too html';
}

{
    my $text = '=== hola = hola

hola

hola

hola';
    my $parsed = Wiki::JSON->new->parse($text);

    #        print STDERR Data::Dumper::Dumper $parsed;
    is_deeply $parsed,
      [
        {
            'output'   => ['hola'],
            'hx_level' => 3,
            'type'     => 'hx'
        },
        ' hola', 'hola', 'hola', 'hola',
      ],

      'Cursed titles in the same line work too unbalanced and without start';
    my $parsed_html = Wiki::JSON->new->pre_html($text);

    #        print STDERR Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('h3'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('h3'),
        Wiki::JSON::HTML->_open_html_element('p'),
        ' hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
      ],
      'Cursed titles in the same line work too unbalanced and without start html';
}

{
    my $text = 'hola = hola ===
hola

hola

hola';
    my $parsed = Wiki::JSON->new->parse($text);

    #        print STDERR Data::Dumper::Dumper $parsed;
    is_deeply $parsed,
      [
        'hola ',
        {
            'output'   => ['hola'],
            'hx_level' => 1,
            'type'     => 'hx'
        },
        'hola', 'hola', 'hola',
      ],

      'Cursed titles in the same line work too unbalanced and without end';
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' }),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola ',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('h1'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('h1'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 
    'Cursed titles in the same line work too unbalanced and without end html';
}

done_testing();
