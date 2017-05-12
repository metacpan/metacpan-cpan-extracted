#!/usr/bin/env perl

# Copyright (C) 2005-2010, Sebastian Riedel.

use strict;
use warnings;

use Test::More tests => 6;

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
