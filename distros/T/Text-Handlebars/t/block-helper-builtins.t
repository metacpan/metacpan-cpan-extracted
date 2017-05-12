#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

render_ok(
    <<'TEMPLATE',
<div class="entry">
  <h1>{{title}}</h1>

  {{#with author}}
  <h2>By {{firstName}} {{lastName}}</h2>
  {{/with}}
</div>
TEMPLATE
    {
        title  => 'My first post!',
        author => {
            firstName => 'Charles',
            lastName  => 'Jolley',
        },
    },
    <<'RENDERED',
<div class="entry">
  <h1>My first post!</h1>

  <h2>By Charles Jolley</h2>
</div>
RENDERED
    "with helper"
);

render_ok(
    <<'TEMPLATE',
<ul class="people_list">
  {{#each people}}
  <li>{{this}}</li>
  {{/each}}
</ul>
TEMPLATE
    {
        people => [
            "Yehuda Katz",
            "Alan Johnson",
            "Charles Jolley",
        ],
    },
    <<'RENDERED',
<ul class="people_list">
  <li>Yehuda Katz</li>
  <li>Alan Johnson</li>
  <li>Charles Jolley</li>
</ul>
RENDERED
    "each helper"
);

render_ok(
    <<'TEMPLATE',
<ul class="people_list">
  {{#each people}}
  <li>{{last}}, {{first}}</li>
  {{/each}}
</ul>
TEMPLATE
    {
        people => [
            { first => "Yehuda", last => "Katz" },
            { first => "Alan", last => "Johnson" },
            { first => "Charles", last => "Jolley" },
        ],
    },
    <<'RENDERED',
<ul class="people_list">
  <li>Katz, Yehuda</li>
  <li>Johnson, Alan</li>
  <li>Jolley, Charles</li>
</ul>
RENDERED
    "each helper"
);

render_ok(
    <<'TEMPLATE',
<div class="entry">
  {{#if author}}
  <h1>{{firstName}} {{lastName}}</h1>
  {{/if}}
</div>
TEMPLATE
    {},
    <<'RENDERED',
<div class="entry">
</div>
RENDERED
    "if helper (false)"
);

render_ok(
    <<'TEMPLATE',
<div class="entry">
  {{#if author}}
  <h1>{{firstName}} {{lastName}}</h1>
  {{/if}}
</div>
TEMPLATE
    {
        author    => 1,
        firstName => "Yehuda",
        lastName  => "Katz",
    },
    <<'RENDERED',
<div class="entry">
  <h1>Yehuda Katz</h1>
</div>
RENDERED
    "if helper (true)"
);

render_ok(
    <<'TEMPLATE',
<div class="entry">
  {{#if author}}
    <h1>{{firstName}} {{lastName}}</h1>
  {{else}}
    <h1>Unknown Author</h1>
  {{/if}}
</div>
TEMPLATE
    {},
    <<'RENDERED',
<div class="entry">
    <h1>Unknown Author</h1>
</div>
RENDERED
    "if/else helper (false)"
);

render_ok(
    <<'TEMPLATE',
<div class="entry">
  {{#if author}}
    <h1>{{firstName}} {{lastName}}</h1>
  {{else}}
    <h1>Unknown Author</h1>
  {{/if}}
</div>
TEMPLATE
    {
        author    => 1,
        firstName => "Yehuda",
        lastName  => "Katz",
    },
    <<'RENDERED',
<div class="entry">
    <h1>Yehuda Katz</h1>
</div>
RENDERED
    "if/else helper (true)"
);

render_ok(
    <<'TEMPLATE',
<div class="entry">
  {{#unless license}}
  <h3 class="warning">WARNING: This entry does not have a license!</h3>
  {{/unless}}
</div>
TEMPLATE
    {},
    <<'RENDERED',
<div class="entry">
  <h3 class="warning">WARNING: This entry does not have a license!</h3>
</div>
RENDERED
    "unless helper (false)"
);

render_ok(
    <<'TEMPLATE',
<div class="entry">
  {{#unless license}}
  <h3 class="warning">WARNING: This entry does not have a license!</h3>
  {{/unless}}
</div>
TEMPLATE
    {
        license => 1,
    },
    <<'RENDERED',
<div class="entry">
</div>
RENDERED
    "unless helper (true)"
);

render_ok(
    <<'TEMPLATE',
<ul class="people_list">
  {{#each people}}
  <li>{{../description}} {{this}}</li>
  {{/each}}
</ul>
TEMPLATE
    {
        description => "The Wonderful",
        people => [
            "Yehuda Katz",
            "Alan Johnson",
            "Charles Jolley",
        ],
    },
    <<'RENDERED',
<ul class="people_list">
  <li>The Wonderful Yehuda Katz</li>
  <li>The Wonderful Alan Johnson</li>
  <li>The Wonderful Charles Jolley</li>
</ul>
RENDERED
    "each helper with ../"
);

done_testing;
