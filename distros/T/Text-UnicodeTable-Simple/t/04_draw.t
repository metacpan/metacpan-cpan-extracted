use strict;
use warnings;

use Test::More;
use Text::UnicodeTable::Simple;
use Term::ANSIColor qw(:constants);

{
    my $t = Text::UnicodeTable::Simple->new();
    $t->set_header(qw/a/);

    my $expected =<<'TABLE';
.---.
| a |
+---+
'---'
TABLE
    is($t->draw, $expected, 'only header');
    is("$t", $expected, 'overload stringify');
}

{
    my $t = Text::UnicodeTable::Simple->new();
    $t->set_header(qw/a b/);
    $t->add_row(qw/aaa bbbb/);

    my $expected =<<'TABLE';
.-----+------.
| a   | b    |
+-----+------+
| aaa | bbbb |
'-----+------'
TABLE
    is($t->draw, $expected, 'header and row');
}

{
    my $t = Text::UnicodeTable::Simple->new();
    $t->set_header(qw/1 2/);
    $t->add_row(qw/aaa bbbb/);
    $t->add_row(qw/4 12345/);

    my $expected =<<'TABLE';
.-----+-------.
|   1 |     2 |
+-----+-------+
| aaa | bbbb  |
|   4 | 12345 |
'-----+-------'
TABLE
    is($t->draw, $expected, 'alignment');
}

{
    my $t = Text::UnicodeTable::Simple->new();
    $t->set_header(qw/1 2/);
    $t->add_row(qw/a b/);
    $t->add_row_line();
    $t->add_row(qw/c d/);

    my $expected =<<'TABLE';
.---+---.
| 1 | 2 |
+---+---+
| a | b |
+---+---+
| c | d |
'---+---'
TABLE
    is($t->draw, $expected, 'add_row_line');
}

{
    my $t = Text::UnicodeTable::Simple->new();
    $t->set_header(qw/1 2/);
    $t->add_row(qw/a b/);
    $t->add_row_line();

    my $expected =<<'TABLE';
.---+---.
| 1 | 2 |
+---+---+
| a | b |
'---+---'
TABLE
    is($t->draw, $expected, 'ignore row_line after last row');
}

{
    use utf8;

    my $t = Text::UnicodeTable::Simple->new();
    $t->set_header(qw/a b/);
    $t->add_row(qw/あいうえお やゆよ/);

    my $expected =<<'TABLE';
.------------+--------.
| a          | b      |
+------------+--------+
| あいうえお | やゆよ |
'------------+--------'
TABLE
    is($t->draw, $expected, 'full width font');
}

{
    my $t = Text::UnicodeTable::Simple->new();
    $t->set_header("a\n123\ncdefg", "12\nabcd\n5");
    $t->add_row("1234\nabc", "abcde\n56");

    my $expected =<<'TABLE';
.-------+-------.
| a     |    12 |
| 123   |  abcd |
| cdefg |     5 |
+-------+-------+
|  1234 | abcde |
|   abc | 56    |
'-------+-------'
TABLE
    is($t->draw, $expected, 'multiline');
}

{
    my $t = Text::UnicodeTable::Simple->new( ansi_color => 1 );
    $t->set_header(qw/a b/);
    $t->add_row(RED . "aaa" . RESET, GREEN . "bbbb" . RESET);

    my $expected =<<'TABLE';
.-----+------.
| a   | b    |
+-----+------+
| aaa | bbbb |
'-----+------'
TABLE
    is(Term::ANSIColor::colorstrip($t->draw), $expected,
       'contain ANSI color escape sequence');
}

{
    my $t = Text::UnicodeTable::Simple->new();

    eval {
        $t->draw;
    };
    like $@, qr{'set_header' method previously}, 'not set table header';
}

done_testing;
