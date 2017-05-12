#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;
use Time::Piece ();

my $now = time();

my $tc = Text::Clevery->new(verbose => 2);

my @set = (
    [<<'T', {value => "next x-men film, x3, delayed."}, <<'X', 'filter'],
<em>{$value|capitalize}</em>
<em>{$value|capitalize:false}</em>
<em>{$value|capitalize:true}</em>
T
<em>Next X-Men Film, x3, Delayed.</em>
<em>Next X-Men Film, x3, Delayed.</em>
<em>Next X-Men Film, X3, Delayed.</em>
X

    [<<'T', {value => "foo"}, <<'X'],
    <em>{$value|cat:"bar"}</em>
    {$value|cat: "<br />"}
T
    <em>foobar</em>
    foo<br />
X

    [<<'T', {value => "Cold Wave Linked to Temperatures."}, <<'X'],
    {$value|count_characters}
    {$value|count_characters:true}
T
    29
    33
X

    [<<'T', {value => <<'V'}, <<'X'],
    {$value|count_paragraphs}
    {$value|count_sentences}
    {$value|count_words}
T
War Dims Hope for Peace. Child's Death Ruins Couple's Holiday.

Man is Fatally Slain. Death Causes Loneliness, Feeling of Isolation.
V
    2
    4
    20
X

    [<<'T', {value => q{'Stiff Opposition Expected to Casketless Funeral Plan'} }, <<'X'],
    {$value|escape}
    {$value|escape:'html'}
    {$value|escape:'htmlall'}
    {$value|escape:'url'}
    {$value|escape:'quotes'}
T
    &apos;Stiff Opposition Expected to Casketless Funeral Plan&apos;
    &apos;Stiff Opposition Expected to Casketless Funeral Plan&apos;
    &#39;Stiff Opposition Expected to Casketless Funeral Plan&#39;
    %27Stiff%20Opposition%20Expected%20to%20Casketless%20Funeral%20Plan%27
    \'Stiff Opposition Expected to Casketless Funeral Plan\'
X
# ' <- this apos is for poor editors

    [<<'T', {value => q{foo bar/baz} }, <<'X'],
    {$value|escape:'url'}
    {$value|escape:'urlpathinfo'}
T
    foo%20bar%2Fbaz
    foo%20bar/baz
X

    [<<'T', {value => q{smarty@example.com} }, <<'X'],
    { $value | escape:"hex" }
    { $value | escape:"hexentity" }
    { $value | escape:"mail" }
T
    %73%6d%61%72%74%79%40%65%78%61%6d%70%6c%65%2e%63%6f%6d
    &#x73;&#x6d;&#x61;&#x72;&#x74;&#x79;&#x40;&#x65;&#x78;&#x61;&#x6d;&#x70;&#x6c;&#x65;&#x2e;&#x63;&#x6f;&#x6d;
    smarty [AT] example [DOT] com
X

    [<<'T', {now => $now}, sprintf <<'X', Time::Piece->new($now)->year],
    {$now|date_format:"[%Y]"}
T
    [%s]
X

    [<<'T', {value => qq{"foo", </script>\r\n} }, <<'X'],
    { $value | escape:"javascript" }
T
    \"foo\", <\/script>\r\n
X

    [<<'T', {value => qq{foo\nbar\nbaz\n} }, <<'X'],
{ $value | indent -}
{ $value | indent: 8 -}
{ $value | indent: 12: '.' -}
T
    foo
    bar
    baz
        foo
        bar
        baz
............foo
............bar
............baz
X

    [<<'T', {now => $now}, sprintf <<'X', Time::Piece->new($now)->year],
    {$now|date_format:"[%Y]"}
T
    [%s]
X

    [<<'T', {a => undef, b => "", c => "0"}, <<'X'],
    {$a|default: "aaa"}
    {$b|default: "bbb"}
    {$c|default: "ccc"}
T
    aaa
    bbb
    0
X

    [<<'T', {a => "foo", b => "FOO" }, <<'X'],
    {$a|lower}
    {$b|lower}
T
    foo
    foo
X

    [<<'T', {value => "foo\n" . "bar\n"}, <<'X'],
{$value|nl2br}
T
foo<br />bar<br />
X


    [<<'T', {value => qq{foo  bar  baz} }, <<'X'],
    { $value | regex_replace: "[\r\n\ t]+": " " }
    { $value | replace: "bar": "BAR" }
    { $value | replace: "[ ]bar[ ]": "BAR" }
T
    foo bar baz
    foo  BAR  baz
    foo  bar  baz
X

    [<<'T', {value => qq{foo bar baz} }, <<'X'],
    { $value | spacify}
    { $value | spacify: "." }
T
    f o o   b a r   b a z
    f.o.o. .b.a.r. .b.a.z
X

    [<<'T', {value => 3.14}, <<'X'],
    {$value|string_format: '[%d]'}
T
    [3]
X

    [<<'T', {value => qq{foo  bar  baz} }, <<'X'],
    { $value | strip}
    { $value | strip: "." }
T
    foo bar baz
    foo.bar.baz
X

    [<<'T', {value => q{Blind Woman Gets <font face="helvetica">New Kidney</font> from Dad she Hasn't Seen in <b>years</b>.} }, <<'X'],
    { $value | strip_tags}
    { $value | strip_tags:true}
    { $value | strip_tags:false}
T
    Blind Woman Gets  New Kidney  from Dad she Hasn&apos;t Seen in  years .
    Blind Woman Gets  New Kidney  from Dad she Hasn&apos;t Seen in  years .
    Blind Woman Gets New Kidney from Dad she Hasn&apos;t Seen in years.
X

    [<<'T', {value => q{Two Sisters Reunite after Eighteen Years at Checkout Counter.} }, <<'X'],
    {$value}
    {$value|truncate}
    {$value|truncate:30}
    {$value|truncate:30:""}
    {$value|truncate:30:"---"}
    {$value|truncate:30:"":true}
    {$value|truncate:30:"...":true}
    {$value|truncate:30:'..':true:true}
T
    Two Sisters Reunite after Eighteen Years at Checkout Counter.
    Two Sisters Reunite after Eighteen Years at Checkout Counter.
    Two Sisters Reunite after...
    Two Sisters Reunite after
    Two Sisters Reunite after---
    Two Sisters Reunite after Eigh
    Two Sisters Reunite after E...
    Two Sisters Re..ckout Counter.
X

    [<<'T', {value => q{Blind woman gets new kidney from dad she hasn't seen in years.} }, <<'X'],
{$value}

{$value|wordwrap:30}

{$value|wordwrap:20}

{$value|wordwrap:30:"<br />\n"}

{$value|wordwrap:26:"\n":true}
T
Blind woman gets new kidney from dad she hasn&apos;t seen in years.

Blind woman gets new kidney
from dad she hasn&apos;t seen in
years.

Blind woman gets new
kidney from dad she
hasn&apos;t seen in
years.

Blind woman gets new kidney<br />
from dad she hasn&apos;t seen in<br />
years.

Blind woman gets new kidn
ey from dad she hasn&apos;t se
en in years.
X


    [<<'T', {a => "foo", b => "FOO" }, <<'X'],
    {$a|upper}
    {$b|upper}
T
    FOO
    FOO
X

    [<<'T', {a => "foo"}, <<'X', 'with statement'],
{if $a -}
    [{$a|upper}]
{/if -}
T
    [FOO]
X

    [<<'T', {a => "foo"}, <<'X', 'operator precedence'],
    {$a | cat: " bar" | cat: " baz"}
T
    foo bar baz
X

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
