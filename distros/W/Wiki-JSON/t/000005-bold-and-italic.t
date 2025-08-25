use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Warnings;

use_ok 'Wiki::JSON';

{
    my $parsed_html = Wiki::JSON->new->pre_html(q/'''bold''': hola/);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('b'),
        'bold',
        Wiki::JSON::HTML->_close_html_element('b'),
        ': hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
      ],
      'Simple bold test html starting with bold';
}

{
    my $parsed_html = Wiki::JSON->new->pre_html(q/hola: '''bold''': hola/);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola: ',
        Wiki::JSON::HTML->_open_html_element('b'),
        'bold',
        Wiki::JSON::HTML->_close_html_element('b'),
        ': hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
      ],
      'Simple bold test html';
}

{
    my $parsed_html =
      Wiki::JSON->new->pre_html(q/hola: '''''bold and italic''': italic''/);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola: ',
        Wiki::JSON::HTML->_open_html_element('b'),
        Wiki::JSON::HTML->_open_html_element('i'),
        'bold and italic',
        Wiki::JSON::HTML->_close_html_element('i'),
        Wiki::JSON::HTML->_close_html_element('b'),
        Wiki::JSON::HTML->_open_html_element('i'),
        ': italic',
        Wiki::JSON::HTML->_close_html_element('i'),
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
      ],
      'Cursed bold and italic test html';
}
{
    my $parsed = Wiki::JSON->new->parse(q/hola: '''bold''': hola/);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [ 'hola: ', { type => 'bold', output => ['bold'] }, ': hola' ],
      'Simple bold test';
}

{
    my $parsed = Wiki::JSON->new->parse(q/hola: ''italic'': hola/);

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [ 'hola: ', { type => 'italic', output => ['italic'] }, ': hola' ],
      'Simple italic test';
}

### Things get weird from now on:
# This is supported by mediawiki: Bold and italic  '''''bold & italic'''''

{
    my $parsed = Wiki::JSON->new->parse(
        q/hola: ''' bold ''bold and italic''' italic'': hola/);

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        'hola: ',
        { type => 'bold',            output => [' bold '] },
        { type => 'bold_and_italic', output => ['bold and italic'] },
        { type => 'italic',          output => [' italic'] },
        ': hola'
      ],
      'Bold and italic weirdness';
}

{
    my $parsed = Wiki::JSON->new->parse(
        q/hola: ''' bold ''bold

and italic''' italic'': hola/
    );

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        'hola: ',
        { type => 'bold',            output => [' bold '] },
        { type => 'bold_and_italic', output => [ 'bold', 'and italic' ] },
        { type => 'italic',          output => [' italic'] },
        ': hola'
      ],
      'Bold and italic weirdness plus new line to make it even weirder';
}

{
    my $parsed =
      Wiki::JSON->new->parse(q/hola: '''''bold and italic''''': hola/);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        'hola: ', { type => 'bold_and_italic', output => ['bold and italic'] },
        ': hola'
      ],
      'Simple bold and italic test';
}

{
    my $parsed;
    Test::Warnings::warnings {
        $parsed = Wiki::JSON->new->parse(q/hola: '''''bold and italic/);
    };

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        'hola: ', { type => 'bold_and_italic', output => ['bold and italic'] },
      ],
      'Bold and italic gets never terminated';
}

{
    my $parsed;
    Test::Warnings::warnings {
        $parsed =
          Wiki::JSON->new->parse(q/hola: '''''bold and italic''' italic/);
    };

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'hola: ', { type => 'bold_and_italic', output => ['bold and italic'] },
        { type => 'italic', output => [' italic'] },

      ],
      'Bold and italic gets interrupted by bold end and italic never ends';
}

## It becomes unable to parse further titles, terminate your bolds and italic.
{
    my $parsed;
    Test::Warnings::warnings {
        $parsed =
          Wiki::JSON->new->parse(
            q/= hola: '''''bold and italic''' italic = hola/);
    };

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            'hx_level' => 1,
            'output'   => [
                'hola: ',
                {
                    'type'   => 'bold_and_italic',
                    'output' => ['bold and italic']
                },
                {
                    'type'   => 'italic',
                    'output' => [
                        ' italic ',
                        {
                            'output'   => ['hola'],
                            'hx_level' => 1,
                            'type'     => 'hx'
                        }
                    ]
                }
            ],
            'type' => 'hx'
        }
      ],
'Title Bold and italic gets interrupted by bold end and italic never ends and has a trailing end of title and some text';
}
done_testing();
