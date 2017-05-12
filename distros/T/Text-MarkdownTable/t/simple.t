use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Text::MarkdownTable'; }
require_ok 'Text::MarkdownTable';

sub is_table(@) {
    my ($message, $expect,$data) = (pop,pop,shift);
    my $out = "";
    my $table = Text::MarkdownTable->new(@_, file => \$out);
    $table->add($_) for @$data;
    $table->done;
    is $out, $expect, $message;
}

is_table [ ], columns => "foo,bar", '', "empty table";

is_table [{a => 'moose', b => '1'},
          {a => "p\nony", b => '2'},
          {a => 'shr|mp', b => '3'}],
<<TABLE, "MultiMarkdown format ok";
| a      | b |
|--------|---|
| moose  | 1 |
| p ony  | 2 |
| shr mp | 3 |
TABLE

is_table [{ a => 'Hello', b => 'World' }],
         fields => { a => 'Longname', x => 'X', y => undef }, 
<<TABLE, "custom column names as HASH";
| Longname | X | y |
|----------|---|---|
| Hello    |   |   |
TABLE

is_table [{ a => 'Hello', b => 'happy', c => 'World', d => '!' }],
          columns => ['greet',undef,'greet',''],
<<TABLE, "custom column names as ARRAY";
| greet |       | greet |   |
|-------|-------|-------|---|
| Hello | happy | World | ! |
TABLE

is_table [{ aa => 'Hi', b => 'World', c => 'long value' }],
         widths => '5,3,6',
<<TABLE, "custom column width / truncation";
| aa    | b   | c      |
|-------|-----|--------|
| Hi    | Wor | lon... |
TABLE

is_table [{ aa => 'Hi', b => 'World', c => 'long value' }],
          widths => '5,3,6', condense => 1,
<<TABLE, "condense with truncation";
aa|b|c
--|-|-
Hi|Wor|lon...
TABLE

ok !Text::MarkdownTable->new->streaming, "no streaming by default";

my $out = "";
my $table = Text::MarkdownTable->new( condense => 1, file => \$out );
$table->add({ foo => 1, bar => 1024 });
ok $table->streaming, "streaming mode";
is $out, <<TABLE, "streaming mode";
bar|foo
---|---
1024|1
TABLE

$table->add({ doz => 7, bar => 0, doz => 'ignored' });
is $out, <<TABLE, "streaming mode";
bar|foo
---|---
1024|1
0|
TABLE

is_table [{a => 7},{a => 8}], 
    header => 0,
    "| 7 |\n| 8 |\n", "disable header";

is_table [{a => 7, b=> 1},{a => 8}], 
    header => 0, condense => 1,
    "7|1\n8|\n", "vbar delimited values";

is_table([{foo => 1, bar => 2}], edges => 0, <<TABLE, "edges disabled");
bar | foo
----|----
2   | 1  
TABLE

is_table([{a => 1, b => 2, c => 3}], edges => 0, <<TABLE, "edges disabled");
a | b | c
--|---|--
1 | 2 | 3
TABLE

done_testing;
