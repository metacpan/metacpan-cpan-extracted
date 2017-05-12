#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

render_ok(
    <<'TEMPLATE',
Shown.
{{#nothin}}
Never shown!
{{/nothin}}
TEMPLATE
    {
        person => 1,
        nothin => 0,
    },
    <<'RENDERED',
Shown.
RENDERED
    "section with no value"
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
        nothin => [],
    },
    <<'RENDERED',
Shown.
RENDERED
    "section with no value"
);

render_ok(
    <<'TEMPLATE',
<h1>Today{{!
ignore me
}}.</h1>
TEMPLATE
    {
    },
    <<'RENDERED',
<h1>Today.</h1>
RENDERED
    "comments"
);

render_ok(
    '{{#l1}}{{#l2}}{{#l3}}{{l4}}{{/l3}}{{/l2}}{{/l1}}',
    { l1 => { l2 => { l3 => { l4 => 'FOO' } } } },
    'FOO',
    "multi-level nesting"
);

render_ok(
    <<'TEMPLATE',
l1:
{{#l1}}
  l2:
{{#l2}}
    l3:
{{#l3}}
      l4: {{l4}}
{{/l3}}
{{/l2}}
{{/l1}}
TEMPLATE
    {
        l1 => [
            {
                l2 => {
                    l3 => [
                        { l4 => 'FOO' },
                        { l4 => 'BAR' },
                        { l4 => 'BAZ' },
                    ],
                },
            },
            {
                l2 => {
                    l3 => [
                        { l4 => 'foo' },
                        { l4 => 'bar' },
                        { l4 => 'baz' },
                    ],
                },
            },
        ],
    },
    <<'RENDERED',
l1:
  l2:
    l3:
      l4: FOO
      l4: BAR
      l4: BAZ
  l2:
    l3:
      l4: foo
      l4: bar
      l4: baz
RENDERED
    "multi-level nesting"
);

render_ok(
    <<'TEMPLATE',
{{#name}}
Name: {{name}}
{{/name}}
TEMPLATE
    {
        name => [
            { name => 'foo' },
            { name => 'bar' },
            { name => 'baz' },
        ],
    },
    <<'RENDERED',
Name: foo
Name: bar
Name: baz
RENDERED
    "reusing variable names while nesting"
);

done_testing;
