#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use Text::FindLinks 'markup_links';

is markup_links(text => 'www.foo.com'),
    '<a href="http://www.foo.com">www.foo.com</a>',
    'Convert relative links to absolute';
is markup_links(text => '<a href="www.foo.com">foo</a>'),
    '<a href="www.foo.com">foo</a>',
    'Do not change URLs in the href attribute';
is markup_links(text => '<a href="...">www.foo.com</a>'),
    '<a href="...">www.foo.com</a>',
    'Do not change URLs inside the <a> tag';
