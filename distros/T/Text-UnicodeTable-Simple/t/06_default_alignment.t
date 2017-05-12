use strict;
use warnings;

use Test::More;
use Text::UnicodeTable::Simple;

{
    my $t = Text::UnicodeTable::Simple->new(
        alignment => 'right',
    );
    $t->set_header(qw/1 2/);
    $t->add_row(qw/aaa bbbb/);
    $t->add_row(qw/4 12345/);

    my $expected =<<'TABLE';
.-----+-------.
|   1 |     2 |
+-----+-------+
| aaa |  bbbb |
|   4 | 12345 |
'-----+-------'
TABLE
    is($t->draw, $expected, 'alignment');
}

{
    my $t = Text::UnicodeTable::Simple->new(
        alignment => 'left',
    );
    $t->set_header(qw/1 2/);
    $t->add_row(qw/aaa bbbb/);
    $t->add_row(qw/4 12345/);

    my $expected =<<'TABLE';
.-----+-------.
| 1   | 2     |
+-----+-------+
| aaa | bbbb  |
| 4   | 12345 |
'-----+-------'
TABLE
    is($t->draw, $expected, 'alignment');
}

{
    eval {
        Text::UnicodeTable::Simple->new(alignment => -1234);
    };
    like $@, qr/should be 'left' or 'right'/, 'invalud alignment param';
}

done_testing;
