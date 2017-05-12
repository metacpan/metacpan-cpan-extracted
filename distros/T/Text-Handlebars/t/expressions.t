#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

render_ok(
    '<h1>{{title}}</h1>',
    { title => 'Xslate rocks' },
    '<h1>Xslate rocks</h1>',
    "basic variables"
);

render_ok(
    '<h1>{{article.title}}</h1>',
    { article => { title => 'Hash references rock' } },
    '<h1>Hash references rock</h1>',
    ". separator"
);

render_ok(
    '<h1>{{article/title}}</h1>',
    { article => { title => 'Deprecated syntax does not' } },
    '<h1>Deprecated syntax does not</h1>',
    "/ separator"
);

render_ok(
    '<h1>{{page.article.title}}</h1> - {{date}}',
    {
        page => {
            article => { title => 'Multilevel field access' },
        },
        date => '2012-10-01',
    },
    '<h1>Multilevel field access</h1> - 2012-10-01',
    "multilevel field access with ."
);

render_ok(
    '{{#article}}<h1>{{title}}</h1> - {{../date}}{{/article}}',
    { article => { title => 'Backtracking' }, date => '2012-10-01' },
    '<h1>Backtracking</h1> - 2012-10-01',
    "backtracking with ../"
);

render_ok(
    <<'TEMPLATE',
{{#page}}
{{#article}}<h1>{{title}}</h1> - {{../../date}}{{/article}}
{{/page}}
TEMPLATE
    {
        page => {
            article => { title => 'Multilevel Backtracking' },
        },
        date => '2012-10-01',
    },
    <<'RENDERED',
<h1>Multilevel Backtracking</h1> - 2012-10-01
RENDERED
    "multilevel backtracking with ../"
);

render_ok(
    '{{#article}}<h1>{{title}}</h1> - {{../metadata.date}}{{/article}}',
    {
        article  => { title => 'Backtracking' },
        metadata => { date  => '2012-10-01' },
    },
    '<h1>Backtracking</h1> - 2012-10-01',
    "backtracking into other hash variables with ../ and ."
);

render_ok(
    '{{articles.[10].comments}}',
    {
        articles => {
            10 => { comments => "First post!" },
        },
    },
    'First post!',
    "field access with non-identifiers"
);

render_ok(
    '{{articles.[.foo\som#th"ing].comments}}',
    {
        articles => {
            '.foo\som#th"ing' => { comments => "First post!" },
        },
    },
    'First post!',
    "field access with non-identifiers"
);

render_ok(
    '{{articles.[10].comments}}',
    {
        articles => [
            (({}) x 10),
            { comments => "First post!" },
        ],
    },
    'First post!',
    "array dereferencing"
);

render_ok(
    '{{.}} {{this}}',
    "foo",
    "foo foo",
    "top level current context"
);

render_ok(
    '{{#thing}}{{.}} {{this}}{{/thing}}',
    {
        thing => [ "foo" ],
    },
    "foo foo",
    "nested current context"
);

render_ok(
    '{{#hellos}}{{this/text}}{{/hellos}}',
    {
        hellos => [
            { text => 'hello' },
            { text => 'Hello' },
            { text => 'HELLO' },
        ],
    },
    'helloHelloHELLO',
    "'this' with paths"
);

render_ok(
    '{{#thing}}{{{.}}} {{{this}}}{{/thing}}',
    {
        thing => [ "<foo>" ],
    },
    "<foo> <foo>",
    "{{{.}}}"
);

render_ok(
    '{{foo-bar}}',
    {
        'foo-bar' => "FOOBAR",
    },
    'FOOBAR',
    "- is a valid character"
);

render_ok(
    '{{foo.foo-bar}}',
    {
        foo => {
            'foo-bar' => "FOOBAR",
        },
    },
    'FOOBAR',
    "- is a valid character"
);

done_testing;
