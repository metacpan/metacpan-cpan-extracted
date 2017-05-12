#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;
use Text::Clevery::Util qw(ceil floor);
use Time::Piece ();

my $now = Time::Piece->new();

my $tc = Text::Clevery->new(verbose => 2);

my @set = (
    [<<'T', {lang => 'Clevery'}, <<'X'],
Hello, {$lang} world!
T
Hello, Clevery world!
X

    [<<'T', {h => { lang => 'Clevery' }}, <<'X'],
Hello, {$h.lang} world!
T
Hello, Clevery world!
X

    [<<'T', {h => { lang => 'Clevery' }, f => 'lang' }, <<'X'],
Hello, {$h.$f} world!
T
Hello, Clevery world!
X

    [<<'T', {a => ['Clevery'] }, <<'X'],
Hello, {$a[0]} world!
T
Hello, Clevery world!
X

    [<<'T', { x => 32 }, <<'X'],
    {$x + 10}
T
    42
X

    [<<'T', {now => $now}, $now->year, 'dot field'],
{ $now.year -}
T

    [<<'T', {now => $now}, $now->year, 'dot method'],
{ $now.year() -}
T

    [<<'T', {now => $now}, $now->year, 'arrow field'],
{ $now->year -}
T

    [<<'T', {now => $now}, $now->year, 'arrow method'],
{ $now->year() -}
T

    [<<'T', {lang => 'Clevery' }, <<'X'],
Hello, {ldelim}{$lang}{rdelim} world!
T
Hello, {Clevery} world!
X

    [<<'T', {lang => 'Clevery'}, <<'X'],
Hello, {* this is a comment *}{$lang}{* this is another comment *} world!
T
Hello, Clevery world!
X

    [<<'T', {lang => 'Clevery'}, <<'X'],
Hello, {$lang} world!{* comment
 comment
 comment *}
T
Hello, Clevery world!
X

    [<<'T', {lang => 'Clevery'}, <<'X'],
    ---
{if $lang}
    ok
{/if}
    ---
T
    ---

    ok

    ---
X

    [<<'T', {lang => 'Clevery'}, <<'X'],
    ---
{if $lang}
    ok
{else}
    unlikely
{/if}
    ---
T
    ---

    ok

    ---
X

    [<<'T', {}, <<'X'],
    ---
{if $lang}
    unlikely
{else}
    ok
{/if}
    ---
T
    ---

    ok

    ---
X

    [<<'T', {foobar => 1}, <<'X'],
    ---
{if $lang}
    unlikely
{elseif $foobar}
    ok
{else}
    unlikely
{/if}
    ---
T
    ---

    ok

    ---
X

    [<<'T', { a => [qw(foo bar baz)] }, <<'X'],
{foreach from=$a item=it -}
    [{$it}]
{/foreach -}
T
    [foo]
    [bar]
    [baz]
X

    [<<'T', { a => { b => [qw(foo bar baz)] }}, <<'X'],
{foreach from=`$a.b` item=it -}
    [{$it}]
{/foreach -}
T
    [foo]
    [bar]
    [baz]
X

    [<<'T', { value => 'foo' }, <<'X'],
{literal}[{$value}]{/literal}
T
[{$value}]
X


    [<<'T', { a => [] }, <<'X'],
{literal}
{foreach from=$a item=it -}
    [{$it}]
{/foreach -}
{/literal}
T

{foreach from=$a item=it -}
    [{$it}]
{/foreach -}

X

    [<<'T', { a => [] }, <<'X', 'parse'],
foo{foreach
    from=$a
    item=it
  }{/foreach}bar
T
foobar
X

    [<<'T', { a => [] }, <<'X', 'parse'],
foo{foreach
    from=$a
    item=it
  }{/foreach}bar
T
foobar
X
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

# utils
is ceil(0.1), 1;
is ceil(0.8), 1;
is ceil(5.1), 6;
is ceil(5.8), 6;

is floor(0.1), 0;
is floor(0.8), 0;
is floor(5.1), 5;
is floor(5.8), 5;

done_testing;
