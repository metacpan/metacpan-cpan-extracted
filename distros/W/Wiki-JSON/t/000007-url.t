use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    my $parsed = Wiki::JSON->new->parse(q/[[Funny Article]]/);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type => 'link',
            link => 'Funny Article',
            title => 'Funny Article',
        }
    ], 'Simple url test';
}

{
    my $text = q/[[Funny Article|funny article]]/;
    my $parsed = Wiki::JSON->new->parse($text);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type => 'link',
            link => 'Funny Article',
            title => 'funny article',
        }
    ], 'Simple url test with title';
    my $parsed_html = Wiki::JSON->new->pre_html($text);
#    print Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        Wiki::JSON::HTML->_open_html_element(
        'a', 0, { href => '/Funny%20Article' },
        ),
        'funny article',
        Wiki::JSON::HTML->_close_html_element('a'),
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Simple url test with title html™',
}

{
    my $text = q/This is the funny article: [[Funny Article|funny article]]. It is cool./;
    my $parsed = Wiki::JSON->new->parse($text);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'This is the funny article: ',
        {
            type => 'link',
            link => 'Funny Article',
            title => 'funny article',
        },
        '. It is cool.',
    ], 'Simple url test with text wrapping it';
    my $parsed_html = Wiki::JSON->new->pre_html($text);
    is_deeply $parsed_html, [
        Wiki::JSON::HTML->_open_html_element(
        'article', 0, { class => 'wiki-article' },
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'This is the funny article: ',
        Wiki::JSON::HTML->_open_html_element(
        'a', 0, { href => '/Funny%20Article' },
        ),
        'funny article',
        Wiki::JSON::HTML->_close_html_element('a'),
        '. It is cool.',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element('article'),
    ], 'Simple url test with title html™',
}

{
    my $parsed = Wiki::JSON->new->parse(q/This is the funny article: [[Funny Article|funny article<nowiki>]]<\/nowiki>]]. It is cool./);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'This is the funny article: ',
        {
            type => 'link',
            link => 'Funny Article',
            title => 'funny article]]',
        },
        '. It is cool.',
    ], 'Simple url test with text wrapping it and a nowiki caption';
}
{
    my $parsed = Wiki::JSON->new->parse(q/[[Funny Article]] [[Not Funny Article]]/);

#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type => 'link',
            link => 'Funny Article',
            title => 'Funny Article',
        },
        ' ',
        {
            type => 'link',
            link => 'Not Funny Article',
            title => 'Not Funny Article',
        }
    ], 'URLs spaciated between them';
}
done_testing;
