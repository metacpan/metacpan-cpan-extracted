#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

use Text::Xslate 'mark_raw';

render_ok(
    {
        helpers => {
            fullName => sub {
                my ($context, $person) = @_;
                return $person->{firstName} . ' ' . $person->{lastName};
            },
        },
    },
    <<'TEMPLATE',
<div class="post">
  <h1>By {{fullName author}}</h1>
  <div class="body">{{body}}</div>

  <h1>Comments</h1>

  {{#each comments}}
  <h2>By {{fullName author}}</h2>
  <div class="body">{{body}}</div>
  {{/each}}
</div>
TEMPLATE
    {
        author   => { firstName => "Alan", lastName => "Johnson" },
        body     => "I Love Handlebars",
        comments => [
            {
                author => { firstName => "Yehuda", lastName => "Katz" },
                body   => "Me too!"
            },
        ],
    },
    <<'RENDERED',
<div class="post">
  <h1>By Alan Johnson</h1>
  <div class="body">I Love Handlebars</div>

  <h1>Comments</h1>

  <h2>By Yehuda Katz</h2>
  <div class="body">Me too!</div>
</div>
RENDERED
    "example"
);

render_ok(
    {
        helpers => {
            agree_button => sub {
                my ($context) = @_;
                return mark_raw(
                    "<button>I agree. I "
                  . $context->{emotion}
                  . ' '
                  . $context->{name}
                  . "</button>"
                );
            },
        },
    },
    <<'TEMPLATE',
<ul>
  {{#each items}}
  <li>{{agree_button}}</li>
  {{/each}}
</ul>
TEMPLATE
    {
        items => [
            { name => "Handlebars", emotion => "love" },
            { name => "Mustache",   emotion => "enjoy" },
            { name => "Ember",      emotion => "want to learn" },
        ],
    },
    <<'RENDERED',
<ul>
  <li><button>I agree. I love Handlebars</button></li>
  <li><button>I agree. I enjoy Mustache</button></li>
  <li><button>I agree. I want to learn Ember</button></li>
</ul>
RENDERED
    "example"
);

done_testing;
