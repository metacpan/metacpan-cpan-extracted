#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

use Text::Xslate 'mark_raw';

render_ok(
    '<h1>{{title}}</h1><p>{{{body}}}</p>',
    { title => 'My New Post', body => 'This is my first post!' },
    '<h1>My New Post</h1><p>This is my first post!</p>',
    "raw body",
);

render_ok(
    '<h1>{{title}}</h1><p>{{{body}}}</p>',
    {
        title => 'All About <p> Tags',
        body  => '<i>This is a post about &lt;p&gt; tags</i>'
    },
    '<h1>All About &lt;p&gt; Tags</h1><p><i>This is a post about &lt;p&gt; tags</i></p>',
    "raw body with html"
);

render_ok(
    '<h1>{{title}}</h1><p>{{{body}}}</p>',
    {
        title => mark_raw('All About &lt;p&gt; Tags'),
        body  => '<i>This is a post about &lt;p&gt; tags</i>'
    },
    '<h1>All About &lt;p&gt; Tags</h1><p><i>This is a post about &lt;p&gt; tags</i></p>',
    "raw title with manual mark_raw() call"
);

render_ok(
    <<'TEMPLATE',
* {{name}}
* {{age}}
* {{company}}
* {{& company}}
TEMPLATE
    {
        name    => 'Chris',
        company => '<b>GitHub</b>',
    },
    <<'RENDERED',
* Chris
* 
* &lt;b&gt;GitHub&lt;/b&gt;
* <b>GitHub</b>
RENDERED
    "mark_raw via &"
);

done_testing;
