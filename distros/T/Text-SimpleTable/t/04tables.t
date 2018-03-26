#!/usr/bin/env perl

# Copyright (C) 2005-2010, Sebastian Riedel.

use strict;
use warnings;
use utf8;

use Test::More tests => 9;

binmode STDERR, ":utf8";
binmode STDOUT, ":utf8";

use_ok('Text::SimpleTable');

# No titles and multiple rows
my $t1 = Text::SimpleTable->new(5, 10);
$t1->row('Catalyst',          'rockz!');
$t1->row('DBIx::Class',       'suckz!');
$t1->row('Template::Toolkit', 'rockz!');
is($t1->draw, <<EOF, 'right table');
.-------+------------.
| Cata- | rockz!     |
| lyst  |            |
| DBIx- | suckz!     |
| ::Cl- |            |
| ass   |            |
| Temp- | rockz!     |
| late- |            |
| ::To- |            |
| olkit |            |
'-------+------------'
EOF

# Titles and multiple cols
my $t2 = Text::SimpleTable->new([5, 'ROCKZ!'], [10, 'Suckz!'], [7, 'rockz!']);
$t2->row('Catalyst', 'DBIx::Class', 'Template::Toolkit', 'HTML::Mason');
is($t2->draw, <<EOF, 'right table');
.-------+------------+---------.
| ROCK- | Suckz!     | rockz!  |
| Z!    |            |         |
+-------+------------+---------+
| Cata- | DBIx::Cla- | Templa- |
| lyst  | ss         | te::To- |
|       |            | olkit   |
'-------+------------+---------'
EOF

# Minimal
my $t3 = Text::SimpleTable->new(5);
$t3->row('Everything works!');
is($t3->draw, <<EOF, 'right table');
.-------.
| Ever- |
| ythi- |
| ng w- |
| orks! |
'-------'
EOF

# Horizontal rule
my $t4 = Text::SimpleTable->new(5);
$t4->row('Everything works!');
$t4->hr;
$t4->row('Everything works!');
is($t4->draw, <<EOF, 'right table');
.-------.
| Ever- |
| ythi- |
| ng w- |
| orks! |
+-------+
| Ever- |
| ythi- |
| ng w- |
| orks! |
'-------'
EOF

# Bad width
my $t5 = Text::SimpleTable->new(1);
$t5->row('Works!');
$t5->hr;
$t5->row('Works!');
is($t5->draw, <<EOF, 'right table');
.----.
| W- |
| o- |
| r- |
| k- |
| s! |
+----+
| W- |
| o- |
| r- |
| k- |
| s! |
'----'
EOF

# UTF-8 Titles and multiple cols
my $t6 = Text::SimpleTable->new([5, "\x{A9}ROCKZ!"], [10, "Suckz!"], [7, "r\x{1A0}ckz!"]);
$t6->row('Catalyst', 'DBIx::Class', 'Template::Toolkit', 'HTML::Mason');
is($t6->draw, <<EOF, 'right table');
.-------+------------+---------.
| \x{A9}ROC- | Suckz!     | r\x{1A0}ckz!  |
| KZ!   |            |         |
+-------+------------+---------+
| Cata- | DBIx::Cla- | Templa- |
| lyst  | ss         | te::To- |
|       |            | olkit   |
'-------+------------+---------'
EOF

# UTF-8 Titles and multiple cols with boxes
is($t6->boxes->draw, <<EOF, 'right table');
┌───────┬────────────┬─────────┐
│ ©ROC- │ Suckz!     │ rƠckz!  │
│ KZ!   │            │         │
├───────┼────────────┼─────────┤
│ Cata- │ DBIx::Cla- │ Templa- │
│ lyst  │ ss         │ te::To- │
│       │            │ olkit   │
└───────┴────────────┴─────────┘
EOF

my $t7 = Text::SimpleTable->new([5, 'Foo'], [10, 'Bar']);
$t7->row('foobarbaz', 'yadayadayada');
$t7->hr;
$t7->row('barbarbarbarbar', 'yada');
is($t7->boxes->draw, <<EOF, 'right table');
┌───────┬────────────┐
│ Foo   │ Bar        │
├───────┼────────────┤
│ foob- │ yadayaday- │
│ arbaz │ ada        │
├───────┼────────────┤
│ barb- │ yada       │
│ arba- │            │
│ rbar- │            │
│ bar   │            │
└───────┴────────────┘
EOF

