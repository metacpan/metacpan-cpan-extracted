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
            link => sub {
                my ($context, $object) = @_;
                return mark_raw(
                    "<a href='" . $object->{url} . "'>"
                  . $object->{text}
                  . "</a>"
                );
            },
        },
    },
    <<'TEMPLATE',
{{{link story}}}
TEMPLATE
    {
        story => {
            url  => 'http://example.com/',
            text => "<h1>It's an example!</h1>",
        },
    },
    <<'RENDERED',
<a href='http://example.com/'><h1>It's an example!</h1></a>
RENDERED
    "basic helpers"
);

render_ok(
    {
        helpers => {
            link => sub {
                my ($context, $text, $url) = @_;
                return mark_raw(
                    "<a href='" . $url . "'>" . $text . "</a>"
                );
            },
        },
    },
    <<'TEMPLATE',
{{{link "See more..." story.url}}}
TEMPLATE
    {
        story => {
            url  => 'http://example.com/',
        },
    },
    <<'RENDERED',
<a href='http://example.com/'>See more...</a>
RENDERED
    "helpers with literal args"
);

render_ok(
    {
        helpers => {
            link => sub {
                my ($context, $text, $options) = @_;

                my @attrs;
                for my $key (sort keys %$options) {
                    push @attrs, $key . '="' . $options->{$key} . '"';
                }

                return mark_raw(
                    "<a " . join(' ', @attrs) . ">" . $text . "</a>"
                );
            },
        },
    },
    <<'TEMPLATE',
{{{link "See more..." href=story.url class="story"}}}
TEMPLATE
    {
        story => {
            url  => 'http://example.com/',
        },
    },
    <<'RENDERED',
<a class="story" href="http://example.com/">See more...</a>
RENDERED
    "helpers with literal args"
);

done_testing;
