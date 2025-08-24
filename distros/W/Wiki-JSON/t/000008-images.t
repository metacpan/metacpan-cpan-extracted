use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    my $text = q/Look this image: [[File:Image.png|caption]]. I like it./;
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'Look this image: ',
        Wiki::JSON::HTML->_open_html_element('img', 1, { src => 'Image.png', alt => 'caption'}),
        '. I like it.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Testing html image inline';
}

{
    my $text = q/Look this image: [[File:Image.png|caption|alt=Better caption]]. I like it./;
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'Look this image: ',
        Wiki::JSON::HTML->_open_html_element('img', 1, { src => 'Image.png', alt => 'Better caption'}),
        '. I like it.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Testing html image inline';
}

{
    my $text = q/Look this image: [[File:Video.mp4|caption|alt=Better caption]]. I like it./;
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'Look this image: ',
        Wiki::JSON::HTML->_open_html_element('video', 1, { src => 'Video.mp4', }),
        '. I like it.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Testing html image inline';
}
{
    my $text = q/Look this image: [[File:Image.png|frame|caption]]. I like it./;
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'Look this image: ',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('figure', 0, { typeof => 'mw:File/Frame' }),
        Wiki::JSON::HTML->_open_html_element('img', 1, { src => 'Image.png'}),
        Wiki::JSON::HTML->_open_html_element('figcaption'),
        'caption',
        Wiki::JSON::HTML->_close_html_element('figcaption'),
        Wiki::JSON::HTML->_close_html_element('figure'),
        Wiki::JSON::HTML->_open_html_element('p'),
        '. I like it.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Testing html image inline';
}
{
    my $text = q/Look this image: [[File:corporate.pdf|frame|caption]]. I like it./;
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'Look this image: ',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('figure', 0, { typeof => 'mw:File/Frame' }),
        Wiki::JSON::HTML->_open_html_element('iframe', 0, { src => 'corporate.pdf', }),
        Wiki::JSON::HTML->_close_html_element('iframe'),
        Wiki::JSON::HTML->_open_html_element('figcaption'),
        'caption',
        Wiki::JSON::HTML->_close_html_element('figcaption'),
        Wiki::JSON::HTML->_close_html_element('figure'),
        Wiki::JSON::HTML->_open_html_element('p'),
        '. I like it.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Testing html image inline';
}

{
    my $text = q/Look this image: [[File:corporate.pdf|page=3|frame|caption]]. I like it./;
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'Look this image: ',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('figure', 0, { typeof => 'mw:File/Frame' }),
        Wiki::JSON::HTML->_open_html_element('iframe', 0, { src => 'corporate.pdf#page=3', }),
        Wiki::JSON::HTML->_close_html_element('iframe'),
        Wiki::JSON::HTML->_open_html_element('figcaption'),
        'caption',
        Wiki::JSON::HTML->_close_html_element('figcaption'),
        Wiki::JSON::HTML->_close_html_element('figure'),
        Wiki::JSON::HTML->_open_html_element('p'),
        '. I like it.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Testing html image inline';
}
{
    my $text = q/Look this image: [[File:Video.mp4|frame|caption]]. I like it./;
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'Look this image: ',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('figure', 0, { typeof => 'mw:File/Frame' }),
        Wiki::JSON::HTML->_open_html_element('video', 1, { src => 'Video.mp4', }),
        Wiki::JSON::HTML->_open_html_element('figcaption'),
        'caption',
        Wiki::JSON::HTML->_close_html_element('figcaption'),
        Wiki::JSON::HTML->_close_html_element('figure'),
        Wiki::JSON::HTML->_open_html_element('p'),
        '. I like it.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Testing html image inline';
}

{
    my $text = q/Look this image: [[File:Image.png|thumb|caption|alt=Better caption]]. I like it./;
    my $parsed_html = Wiki::JSON->new->pre_html($text);
#    print Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'Look this image: ',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('figure', 0, { typeof => 'mw:File/Thumb' }),
        Wiki::JSON::HTML->_open_html_element('img', 1, { src => 'Image.png', alt => 'Better caption'}),
        Wiki::JSON::HTML->_open_html_element('figcaption'),
        'caption',
        Wiki::JSON::HTML->_close_html_element('figcaption'),
        Wiki::JSON::HTML->_close_html_element('figure'),
        Wiki::JSON::HTML->_open_html_element('p'),
        '. I like it.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Testing html image inline';
}

{
    my $parsed = Wiki::JSON->new->parse(q/[[File:Image.png]]/);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type    => 'image',
            link    => 'Image.png',
            options => {},
            caption => '',
        }
      ],
      'Simple image test';
}

{
    my $parsed =
      Wiki::JSON->new->parse(q/[[File:Image.png|A cool image showing a test]]/);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type    => 'image',
            link    => 'Image.png',
            options => {},
            caption => 'A cool image showing a test',
        }
      ],
      'Simple image test with caption';
}

{
    my $parsed = Wiki::JSON->new->parse(
q/[[File:Image.png|A cool image showing a test|Not showed caption|50 px|60px|x60 px|x50px|upright 2.0|upright=2.0|upright|left|right|center|none|border|framed|frame|frameless|thumb|thumbnail|baseline|sub|super|top|text-top|middle|bottom|text-bottom|link=Help:Example Images|alt=Nothing to read here|page=3|thumbtime=3:20:30|thumbtime=20:00|thumbtime=30|start=3:30:30|start=30:30|start=30|muted|loop|loosy=false|class=cool image]]/
    );

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type    => 'image',
            link    => 'Image.png',
            options => {
                resize => {
                    width => 50,
                },
                format => {
                    border => 1,
                    frame  => 1,
                },
                halign    => 'left',
                valign    => 'baseline',
                link      => 'Help:Example Images',
                alt       => 'Nothing to read here',
                page      => 3,
                thumbtime => '3:20:30',
                start     => '3:30:30',
                muted     => 1,
                loop      => 1,
                not_loosy => 1,
                classes   => [qw/cool image/],
            },
            caption => 'A cool image showing a test',
        }
      ],
      'Simple image with all options selected and multiple captions.';
}

{
    my $parsed =
      Wiki::JSON->new->parse(q/[[File:Image.png|A cool image showing a test]]/);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type    => 'image',
            link    => 'Image.png',
            options => {},
            caption => 'A cool image showing a test',
        }
      ],
      'Simple image test with caption';
}

for my $sep (' ', '') {
    my $parsed = Wiki::JSON->new->parse(
qq/[[File:Image.png|A cool image showing a test|Not showed caption|x50${sep}px]]/
    );

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type    => 'image',
            link    => 'Image.png',
            options => {
                resize => {
                    height => 50,
                },
            },
            caption => 'A cool image showing a test',
        }
      ],
      "Simple image with height and sep='$sep'.";
}
{
    my $parsed = Wiki::JSON->new->parse(
q/[[File:Image.png|A cool image showing a test|Not showed caption|upright 3.0]]/
    );

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type    => 'image',
            link    => 'Image.png',
            options => {
                resize => {
                    upright => '3.0',
                },
            },
            caption => 'A cool image showing a test',
        }
      ],
      'Simple image with upright';
}

for my $sep (' ', '=') {
    my $parsed = Wiki::JSON->new->parse(
qq/[[File:Image.png|A cool image showing a test|Not showed caption|upright${sep}3.0]]/
    );

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type    => 'image',
            link    => 'Image.png',
            options => {
                resize => {
                    upright => '3.0',
                },
            },
            caption => 'A cool image showing a test',
        }
      ],
      "Simple image with upright and sep='$sep'.";
}
done_testing;
