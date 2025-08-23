use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Warnings qw/warning/;

use_ok 'Wiki::JSON';

# I refuse to implement multiple levels of lists.
{
    my $parsed = Wiki::JSON->new->parse(
        q/hola:
* hola<br>hola
* adios
* hey
end of list/
    );

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'hola:',
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'hola', 'hola', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'adios', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'hey', ],
                },

            ],
        },
        'end of list',
      ],
      'Simple list test';
}

{
    my $parsed = Wiki::JSON->new->parse(
        q/hola:
* hola<br>hola
* adios
* hey '''bold'''
end of list/
    );

    #            print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'hola:',
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'hola', 'hola', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'adios', ],
                },
                {
                    type   => 'list_element',
                    output => [
                        'hey ',
                        {
                            type   => 'bold',
                            output => ['bold'],
                        }
                    ],
                },

            ],
        },
        'end of list',
      ],
      'List works fine with bold';
}

{
    like warning {
    my $parsed_html = Wiki::JSON->new->pre_html(
        q/'''
* hola<br>hola
* hey '''bold'''''italic''[[hola]]
* adios
* ''hola''
end of list '''/
    );

#    print Data::Dumper::Dumper($parsed_html);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('b'),
        Wiki::JSON::HTML->_open_html_element('ul'),
        Wiki::JSON::HTML->_open_html_element('li'),
        'hola',
        Wiki::JSON::HTML->_open_html_element( 'br', 1 ),
        'hola',
        Wiki::JSON::HTML->_close_html_element('li'),
        Wiki::JSON::HTML->_open_html_element('li'),
        'hey ',
        Wiki::JSON::HTML->_open_html_element('b'),
        'bold',
        Wiki::JSON::HTML->_close_html_element('b'),
        Wiki::JSON::HTML->_open_html_element('i'),
        'italic',
        Wiki::JSON::HTML->_close_html_element('i'),
        Wiki::JSON::HTML->_open_html_element('a', 0, {href=> '/hola'}),
        'hola',
        Wiki::JSON::HTML->_close_html_element('a'),
        Wiki::JSON::HTML->_close_html_element('li'),
        Wiki::JSON::HTML->_open_html_element('li'),
        'adios',
        Wiki::JSON::HTML->_close_html_element('li'),
        Wiki::JSON::HTML->_open_html_element('li'),
        Wiki::JSON::HTML->_open_html_element('i'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('i'),
        Wiki::JSON::HTML->_close_html_element('li'),

        Wiki::JSON::HTML->_close_html_element('ul'),
        Wiki::JSON::HTML->_open_html_element( 'br', 1 ),
        'end of list ',
        Wiki::JSON::HTML->_close_html_element('b'),
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
      ],
      'Test html list gen with warnings';
      }, qr/unordered list found when content is expected to be inline/, 'Catched warning inline';
}
{
    my $parsed = Wiki::JSON->new->parse(
        q/hola:
* hola<br>hola
* adios
* hey/
    );

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'hola:',
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'hola', 'hola', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'adios', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'hey', ],
                },

            ],
        },
      ],
      'A list can end being just a list';
}

{
    my $parsed = Wiki::JSON->new->parse(
        q/* one
* two
* three [[Xinadi Legend]] xd/
    );

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'one', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'two', ],
                },
                {
                    type   => 'list_element',
                    output => [
                        'three ',
                        {
                            type  => 'link',
                            title => 'Xinadi Legend',
                            link  => 'Xinadi Legend',
                        },
                        ' xd',
                    ],
                },

            ],
        },
      ],
      'Parsing embedded elements works fine with the embedded element being in the last list element';
}
{
    my $parsed = Wiki::JSON->new->parse(
        q/* one
* three [[Xinadi Legend]] xd
* two/
    );

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'one', ],
                },
                {
                    type   => 'list_element',
                    output => [
                        'three ',
                        {
                            type  => 'link',
                            title => 'Xinadi Legend',
                            link  => 'Xinadi Legend',
                        },
                        ' xd',
                    ],
                },
                {
                    type   => 'list_element',
                    output => [ 'two', ],
                },

            ],
        },
      ],
      'Parsing embedded elements works fine with the embedded element being in the middle';
}
{
    my $parsed = Wiki::JSON->new->parse(
        q/* one
* three [[Xinadi Legend]] xd<br>xd
* two/
    );

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'one', ],
                },
                {
                    type   => 'list_element',
                    output => [
                        'three ',
                        {
                            type  => 'link',
                            title => 'Xinadi Legend',
                            link  => 'Xinadi Legend',
                        },
                        ' xd', 'xd',
                    ],
                },
                {
                    type   => 'list_element',
                    output => [ 'two', ],
                },

            ],
        },
      ],
      'Parsing embedded elements with br works fine';
}
done_testing();
