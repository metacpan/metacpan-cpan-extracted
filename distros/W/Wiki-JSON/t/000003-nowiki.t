use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    my $text   = '<nowiki>=== hola ===</nowiki>';
    my $parsed = Wiki::JSON->new->parse($text);

    #        print STDERR Data::Dumper::Dumper $parsed;
    is_deeply $parsed, ['=== hola ==='],

      'Simple nowiki works';
    my $parsed_html = Wiki::JSON->new->pre_html($text);

    #        print STDERR Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        '=== hola ===',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
      ],
      'Simple nowiki works html';
}

{
    my $text = 'hola
This is how titles are made: <nowiki>=== hola ===</nowiki> Cool isn\'t it?
hola';

    my $parsed = Wiki::JSON->new->parse($text);

    #        print STDERR Data::Dumper::Dumper $parsed;
    is_deeply $parsed,
      [
        'hola', 'This is how titles are made: === hola === Cool isn\'t it?',
        'hola',
      ],

      'Embedding titles to not expand works';
    my $parsed_html = Wiki::JSON->new->pre_html($text);

    #          print STDERR Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'This is how titles are made: === hola === Cool isn\'t it?',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
      ],
      'Embedding titles to not expand works html';
}

{
    my $text = 'hola
=== This is how titles are made: <nowiki>=== hola ===</nowiki> Cool isn\'t it? ===
hola';

    my $parsed = Wiki::JSON->new->parse(
        $text
    );

    #        print STDERR Data::Dumper::Dumper $parsed;
    is_deeply $parsed,
      [
        'hola',
        {
            'output' =>
              ['This is how titles are made: === hola === Cool isn\'t it?'],
            'hx_level' => 3,
            'type'     => 'hx'
        },
        'hola'
      ],
      'Embedding titles to not expand inside titles work';

    my $parsed_html = Wiki::JSON->new->pre_html($text);
#            print STDERR Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('h3'),
        'This is how titles are made: === hola === Cool isn\'t it?',
        Wiki::JSON::HTML->_close_html_element('h3'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element(
        'article'),
    ], 'Embedding titles to not expand inside titles work html™';
}

{
    my $text = '<nowiki>=== hola ===';
    my $parsed = Wiki::JSON->new->parse($text);

    #        print STDERR Data::Dumper::Dumper $parsed;
    is_deeply $parsed, [ '=== hola ===', ], 'Unterminated nowiki works.';
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    #        print Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        '=== hola ===',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Unterminated nowiki works html™.';
}

done_testing();
