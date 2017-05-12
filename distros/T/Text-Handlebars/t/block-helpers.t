#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

render_ok(
    {
        helpers => {
            noop => sub {
                my ($context, $options) = @_;
                return $options->{fn}->($context);
            },
        },
    },
    <<'TEMPLATE',
<div class="entry">
  <h1>{{title}}</h1>
  <div class="body">
    {{#noop}}{{body}}{{/noop}}
  </div>
</div>
TEMPLATE
    { title => 'A', body => 'the first letter' },
    <<'RENDERED',
<div class="entry">
  <h1>A</h1>
  <div class="body">
    the first letter
  </div>
</div>
RENDERED
    "noop helper"
);

render_ok(
    {
        helpers => {
            with => sub {
                my ($context, $new_context, $options) = @_;
                return $options->{fn}->($new_context);
            },
        },
    },
    <<'TEMPLATE',
<div class="entry">
  <h1>{{title}}</h1>
  {{#with story}}
    <div class="intro">{{{intro}}}</div>
    <div class="body">{{{body}}}</div>
  {{/with}}
</div>
TEMPLATE
    {
        title => 'First Post',
        story => {
            intro => 'Before the jump',
            body  => 'After the jump',
        },
    },
    <<'RENDERED',
<div class="entry">
  <h1>First Post</h1>
    <div class="intro">Before the jump</div>
    <div class="body">After the jump</div>
</div>
RENDERED
    "with helper"
);

render_ok(
    {
        helpers => {
            with => sub {
                my ($context, $new_context, $options) = @_;
                return $options->{fn}->($new_context);
            },
            each => sub {
                my ($context, $list, $options) = @_;

                my $ret = '';
                for my $new_context (@$list) {
                    $ret .= $options->{fn}->($new_context);
                }

                return $ret;
            },
        },
    },
    <<'TEMPLATE',
<div class="entry">
  <h1>{{title}}</h1>
  {{#with story}}
    <div class="intro">{{{intro}}}</div>
    <div class="body">{{{body}}}</div>
  {{/with}}
</div>
<div class="comments">
  {{#each comments}}
    <div class="comment">
      <h2>{{subject}}</h2>
      {{{body}}}
    </div>
  {{/each}}
</div>
TEMPLATE
    {
        title => 'First Post',
        story => {
            intro => 'Before the jump',
            body  => 'After the jump',
        },
        comments => [
            { subject => "Subject A", body => "Body A" },
            { subject => "Subject B", body => "Body B" },
        ],
    },
    <<'RENDERED',
<div class="entry">
  <h1>First Post</h1>
    <div class="intro">Before the jump</div>
    <div class="body">After the jump</div>
</div>
<div class="comments">
    <div class="comment">
      <h2>Subject A</h2>
      Body A
    </div>
    <div class="comment">
      <h2>Subject B</h2>
      Body B
    </div>
</div>
RENDERED
    "each helper"
);

render_ok(
    {
        helpers => {
            list => sub {
                my ($context, $items, $options) = @_;
                my $out = "<ul>";

                for my $item (@$items) {
                    $out .= "<li>" . $options->{fn}->($item) . "</li>";
                }

                return $out . "</ul>\n";
            },
        },
    },
    <<'TEMPLATE',
{{#list nav}}
  <a href="{{url}}">{{title}}</a>
{{/list}}
TEMPLATE
    {
        nav => [
            {
                url   => 'http://www.yehudakatz.com',
                title => 'Katz Got Your Tongue',
            },
            {
                url   => 'http://www.sproutcore.com/block',
                title => 'SproutCore Blog',
            },
        ],
    },
    <<'RENDERED',
<ul><li>  <a href="http://www.yehudakatz.com">Katz Got Your Tongue</a>
</li><li>  <a href="http://www.sproutcore.com/block">SproutCore Blog</a>
</li></ul>
RENDERED
    "list helper"
);

render_ok(
    {
        helpers => {
            if => sub {
                my ($context, $conditional, $options) = @_;
                if ($conditional) {
                    return $options->{fn}->($context);
                }
                return '';
            },
        },
    },
    <<'TEMPLATE',
{{#if isActive}}
  <img src="star.gif" alt="Active">
{{/if}}
TEMPLATE
    {
        isActive => 1,
    },
    <<'RENDERED',
  <img src="star.gif" alt="Active">
RENDERED
    "if helper (true)"
);

render_ok(
    {
        helpers => {
            if => sub {
                my ($context, $conditional, $options) = @_;
                if ($conditional) {
                    return $options->{fn}->($context);
                }
                return '';
            },
        },
    },
    <<'TEMPLATE',
{{#if isActive}}
  <img src="star.gif" alt="Active">
{{/if}}
TEMPLATE
    {
        isActive => 0,
    },
    <<'RENDERED',
RENDERED
    "if helper (false)"
);

render_ok(
    {
        helpers => {
            if => sub {
                my ($context, $conditional, $options) = @_;
                if ($conditional) {
                    return $options->{fn}->($context);
                }
                else {
                    return $options->{inverse}->($context);
                }
            },
        },
    },
    <<'TEMPLATE',
{{#if isActive}}
  <img src="star.gif" alt="Active">
{{else}}
  <img src="cry.gif" alt="Inactive">
{{/if}}
TEMPLATE
    {
        isActive => 1,
    },
    <<'RENDERED',
  <img src="star.gif" alt="Active">
RENDERED
    "if/else helper (true)"
);

render_ok(
    {
        helpers => {
            if => sub {
                my ($context, $conditional, $options) = @_;
                if ($conditional) {
                    return $options->{fn}->($context);
                }
                else {
                    return $options->{inverse}->($context);
                }
            },
        },
    },
    <<'TEMPLATE',
{{#if isActive}}
  <img src="star.gif" alt="Active">
{{else}}
  <img src="cry.gif" alt="Inactive">
{{/if}}
TEMPLATE
    {
        isActive => 0,
    },
    <<'RENDERED',
  <img src="cry.gif" alt="Inactive">
RENDERED
    "if/else helper (false)"
);

render_ok(
    {
        helpers => {
            list => sub {
                my ($context, $items, $options) = @_;

                my $attrs = join ' ', map { "$_=\"$options->{hash}{$_}\"" }
                                          sort keys %{ $options->{hash} };

                return "<ul $attrs>"
                     . join("\n", map {
                           "<li>" . $options->{fn}->($_) . "</li>"
                       } @$items)
                     . "</ul>\n";
            },
        },
    },
    <<'TEMPLATE',
{{#list nav id="nav-bar" class="top"}}
  <a href="{{url}}">{{title}}</a>
{{/list}}
TEMPLATE
    {
        nav => [
            {
                url   => 'http://www.yehudakatz.com',
                title => 'Katz Got Your Tongue',
            },
            {
                url   => 'http://www.sproutcore.com/block',
                title => 'SproutCore Blog',
            },
        ],
    },
    <<'RENDERED',
<ul class="top" id="nav-bar"><li>  <a href="http://www.yehudakatz.com">Katz Got Your Tongue</a>
</li>
<li>  <a href="http://www.sproutcore.com/block">SproutCore Blog</a>
</li></ul>
RENDERED
    "helper arguments"
);

{ local $TODO = "unimplemented"; local $SIG{__WARN__} = sub { };
# XXX this is almost certainly not what the api should be like, but i don't
# understand the purpose for this feature well enough to come up with anything
# more reasonable. feedback welcome!
render_ok(
    {
        helpers => {
            list => sub {
                my ($context, $items, $options) = @_;

                my $out = "<ul>";
                for my $item (@$items) {
                    my $data;
                    if ($options->{data}) {
                        $data = $options->{create_frame}->($options->{data});
                    }
                    $out .= "<li>"
                          . $options->{fn}->($item, {data => $data})
                          . "</li>";
                }

                $out .= "</ul>";
                return $out;
            },
        },
    },
    <<'TEMPLATE',
{{#list array}}
  {{@index}}. {{title}}
{{/list}}
TEMPLATE
    {
        array => [
            "Foo",
            "Bar",
            "Baz",
        ],
    },
    <<'RENDERED',
<ul><li>  1. Foo
</li><li>  2. Bar
</li><li>  3. Baz
</li></ul>
RENDERED
    "helper private variables"
);
}

render_ok(
    {
        helpers => {
            list => sub {
                my ($context, $items, $options) = @_;

                if (@$items) {
                    my $out = '<ul>';
                    for my $item (@$items) {
                        $out .= '<li>';
                        $out .= $options->{fn}->($item);
                        $out .= '</li>';
                    }
                    $out .= '</ul>';
                    return $out;
                }
                else {
                    return '<p>' . $options->{inverse}->($context) . '</p>';
                }
            },
        },
    },
    q[{{#list people}}{{name}}{{^}}<em>Nobody's here</em>{{/list}}],
    {
        people => [
            { name => 'Alan' },
            { name => 'Yehuda' },
        ],
    },
    q[<ul><li>Alan</li><li>Yehuda</li></ul>],
    "helper with inverse"
);

render_ok(
    {
        helpers => {
            list => sub {
                my ($context, $items, $options) = @_;

                if (@$items) {
                    my $out = '<ul>';
                    for my $item (@$items) {
                        $out .= '<li>';
                        $out .= $options->{fn}->($item);
                        $out .= '</li>';
                    }
                    $out .= '</ul>';
                    return $out;
                }
                else {
                    return '<p>' . $options->{inverse}->($context) . '</p>';
                }
            },
        },
    },
    q[{{#list people}}{{name}}{{^}}<em>Nobody's here</em>{{/list}}],
    {
        people => [],
    },
    q[<p><em>Nobody's here</em></p>],
    "helper with inverse (empty)"
);

render_ok(
    {
        helpers => {
            list => sub {
                my ($context, $items, $options) = @_;

                if (@$items) {
                    my $out = '<ul>';
                    for my $item (@$items) {
                        $out .= '<li>';
                        $out .= $options->{fn}->($item);
                        $out .= '</li>';
                    }
                    $out .= '</ul>';
                    return $out;
                }
                else {
                    return '<p>' . $options->{inverse}->($context) . '</p>';
                }
            },
        },
    },
    q[{{#list people}}Hello{{^}}{{message}}{{/list}}],
    {
        people  => [],
        message => "Nobody's here",
    },
    q[<p>Nobody&#39;s here</p>],
    "helper with inverse (inverse has variables)"
);

render_ok(
    <<TEMPLATE,
{{#each list}}
<li>
{{#each doc}}
<div>{{this}}</div>
<span>{{../../info}}</span>
{{/each}}
</li>
{{/each}}
TEMPLATE
    {
        info => "hello world",
        list => [ { "doc" => [ "a", "b", "c" ] } ],
    },
    <<RENDERED,
<li>
<div>a</div>
<span>hello world</span>
<div>b</div>
<span>hello world</span>
<div>c</div>
<span>hello world</span>
</li>
RENDERED
    "object hierarchy access (RT#94792)"
);

render_ok(
    <<TEMPLATE,
{{#each list}}
<li>
{{#each doc}}
<div>{{this}}</div>
{{#each ../../info}}<span>{{this}}</span>{{/each}}
{{/each}}
</li>
{{/each}}
TEMPLATE
    {
        info => [ "hello", "world" ],
        list => [ { "doc" => [ "a", "b", "c" ] } ],
    },
    <<RENDERED,
<li>
<div>a</div>
<span>hello</span><span>world</span>
<div>b</div>
<span>hello</span><span>world</span>
<div>c</div>
<span>hello</span><span>world</span>
</li>
RENDERED
    "object hierarchy access (RT#94792)"
);

render_ok(
    <<TEMPLATE,
{{{outer}}}
{{#each elements}}
{{{inner}}}
{{/each}}
TEMPLATE
    {
        outer => '<em>example</em>',
        elements => [
            { inner => '<em>text</em>' },
            { inner => '<h1>text</h1>' },
        ]
    },
    <<RENDERED,
<em>example</em>
<em>text</em>
<h1>text</h1>
RENDERED
    "raw variable access inside block helpers (#6)"
);

done_testing;
