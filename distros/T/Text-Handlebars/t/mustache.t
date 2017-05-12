#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

# from the mustache(5) man page
# http://mustache.github.com/mustache.5.html

render_ok(
    <<'TEMPLATE',
Hello {{name}}
You have just won ${{value}}!
{{#in_ca}}
Well, ${{taxed_value}}, after taxes.
{{/in_ca}}
TEMPLATE
    {
        name        => 'Chris',
        value       => 10000,
        taxed_value => 10000 - (10000 * 0.4),
        in_ca       => 1,
    },
    <<'RENDERED',
Hello Chris
You have just won $10000!
Well, $6000, after taxes.
RENDERED
    "synopsis"
);

render_ok(
    <<'TEMPLATE',
* {{name}}
* {{age}}
* {{company}}
* {{{company}}}
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
    "basic test"
);

render_ok(
    <<'TEMPLATE',
Shown.
{{#nothin}}
Never shown!
{{/nothin}}
TEMPLATE
    {
        person => 1,
    },
    <<'RENDERED',
Shown.
RENDERED
    "section with no value"
);

render_ok(
    <<'TEMPLATE',
{{#repo}}
<b>{{name}}</b>
{{/repo}}
TEMPLATE
    {
        repo => [
            { name => 'resque' },
            { name => 'hub' },
            { name => 'rip' },
        ],
    },
    <<'RENDERED',
<b>resque</b>
<b>hub</b>
<b>rip</b>
RENDERED
    "section with non-empty list"
);

render_ok(
    <<'TEMPLATE',
{{#wrapped}}
{{name}} is awesome.
{{/wrapped}}
TEMPLATE
    {
        name    => 'Willy',
        wrapped => sub {
            my ($text) = @_;
            chomp($text);
            return "<b>$text</b>\n";
        },
    },
    <<'RENDERED',
<b>Willy is awesome.</b>
RENDERED
    "lambdas"
);

render_ok(
    <<'TEMPLATE',
{{#person?}}
Hi {{name}}!
{{/person?}}
TEMPLATE
    {
        'person?' => { 'name' => 'Jon' },
    },
    <<'RENDERED',
Hi Jon!
RENDERED
    "non-false values"
);

render_ok(
    <<'TEMPLATE',
{{#repo}}
<b>{{name}}</b>
{{/repo}}
{{^repo}}
No repos :(
{{/repo}}
TEMPLATE
    {
        repo => [],
    },
    <<'RENDERED',
No repos :(
RENDERED
    "inverted sections"
);

render_ok(
    <<'TEMPLATE',
<h1>Today{{! ignore me }}.</h1>
TEMPLATE
    {
    },
    <<'RENDERED',
<h1>Today.</h1>
RENDERED
    "comments"
);

render_file_ok(
    { path => ['t/mustache/partials'], suffix => '.mustache' },
    'base.mustache',
    {
        names => [
            { name => 'Chris' },
            { name => 'Willy' },
            { name => 'Jon'   },
        ],
    },
    <<'EXPECTED',
<h2>Names</h2>
<strong>Chris</strong>
<strong>Willy</strong>
<strong>Jon</strong>
EXPECTED
    "partials"
);

render_ok(
    <<'TEMPLATE',
* {{default_tags}}
{{=<% %>=}}
* <% erb_style_tags %>
<%={{ }}=%>
* {{ default_tags_again }}
TEMPLATE
    {
        default_tags       => 'foo',
        erb_style_tags     => 'bar',
        default_tags_again => 'baz',
    },
    <<'RENDERED',
* foo
* bar
* baz
RENDERED
    "set delimiter"
);

done_testing;
