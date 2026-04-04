#!/usr/bin/env perl
use v5.20;
use Text::Stencil;

# chaining transforms: trim, then truncate, then html-escape
my $chain = Text::Stencil->new(row => '{0:trim|trunc:30|html}', separator => "\n");
say "=== chained ===";
say $chain->render([
    ['  <script>alert("long text that will be truncated")</script>  '],
    ['  Short & safe  '],
]);

# conditional output
my $cond = Text::Stencil->new(row => '{name:raw}{active:if: (active)}{role:wrap: [:]}', separator => "\n");
say "\n=== conditional ===";
say $cond->render([
    { name => 'Alice', active => 1, role => 'admin' },
    { name => 'Bob',   active => 0, role => '' },
    { name => 'Eve',   active => 1, role => 'user' },
]);

# map transform
my $status = Text::Stencil->new(row => '{name:raw}: {code:map:0=OK:1=WARN:2=ERROR:*=UNKNOWN}', separator => "\n");
say "\n=== map ===";
say $status->render([
    { name => 'server1', code => '0' },
    { name => 'server2', code => '2' },
    { name => 'server3', code => '9' },
]);

# coalesce: fallback fields
my $coal = Text::Stencil->new(row => '{display:coalesce:nickname:name:Anonymous}', separator => "\n");
say "\n=== coalesce ===";
say $coal->render([
    { name => 'Alice', nickname => 'Al',  display => 'Alice A.' },
    { name => 'Bob',   nickname => '',    display => '' },
    { name => '',      nickname => '',    display => '' },
]);

# formatting: numbers, dates, masks
my $fmt = Text::Stencil->new(
    row       => '{0:int_comma} | {1:bytes_si} | {2:elapsed} | {3:mask:4}',
    separator => "\n",
);
say "\n=== formatting ===";
say $fmt->render([
    [1234567, 1073741824, 90061, '4111222233334444'],
    [42,      1536,       45,    'secret'],
]);
