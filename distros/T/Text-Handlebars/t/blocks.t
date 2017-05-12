#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

render_ok(
    'This is {{#shown}}shown{{/shown}}',
    { shown => 1 },
    'This is shown',
    "true block variable"
);

render_ok(
    'This is {{#shown}}shown{{/shown}}',
    { shown => 0 },
    'This is ',
    "false block variable"
);

render_ok(
    'This is {{#shown}}shown{{/shown}}',
    { shown => [({}) x 3] },
    'This is shownshownshown',
    "array block variable"
);

render_ok(
    'This is {{#shown}}{{content}}{{/shown}}',
    { shown => { content => 'SHOWN' } },
    'This is SHOWN',
    "nested hash block variable"
);

render_ok(
    'This is {{#shown}}{{content}}{{/shown}}',
    {
        shown => [
            { content => '3' },
            { content => '2' },
            { content => '1' },
            { content => 'Shown' },
        ],
    },
    'This is 321Shown',
    "nested array of hashes block variable"
);

render_ok(
    '{{#goodbyes}}{{@index}}. {{text}}! {{/goodbyes}}cruel {{world}}!',
    {
        goodbyes => [
            { text => 'goodbye' },
            { text => 'Goodbye' },
            { text => 'GOODBYE' },
        ],
        world => 'world',
    },
    '0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!',
    "\@index variable"
);

render_ok(
    '{{#foo}}{{/foo}}bar',
    {
        foo => [ 1, 2, 3 ],
    },
    'bar',
    "empty block"
);

render_ok(
    '{{#people}}{{name}}{{^}}{{none}}{{/people}}',
    {
        none => 'No people',
    },
    'No people',
    "inverted block shorthand"
);

render_ok(
    '{{#people}}{{name}}{{^}}{{none}}{{/people}}',
    {
        none   => 'No people',
        people => [],
    },
    'No people',
    "inverted block shorthand (empty array)"
);

render_ok(
    <<'TEMPLATE',
{{#people}}
{{.}}
{{^}}
{{none}}
{{/people}}
TEMPLATE
    {
        none   => 'No people',
        people => [
            'Jesse Luehrs',
            'Shawn Moore',
            'Stevan Little',
        ],
    },
    <<'RENDERED',
Jesse Luehrs
Shawn Moore
Stevan Little
RENDERED
    "inverted block shorthand (non-empty array)"
);

done_testing;
