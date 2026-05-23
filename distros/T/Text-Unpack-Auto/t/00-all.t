use strict;
use warnings;
use Test::More;
use Text::Unpack::Auto;

# ---------------------------------------------------------------------------
# guess_unpack
# ---------------------------------------------------------------------------

subtest 'guess_unpack: basic column detection' => sub {
    my @lines = (
        'foo bar baz',
        'aaa bbb ccc',
        'xxx yyy zzz',
    );
    my $fmt = guess_unpack(@lines);
    is $fmt, 'a3x1a3x1a3', 'three space-separated columns';
};

subtest 'guess_unpack: single line' => sub {
    is guess_unpack('foo bar'), 'a3x1a3', 'works with one line';
};

subtest 'guess_unpack: ragged lines — longer line controls template' => sub {
    my $fmt = guess_unpack(
        'foo bar',
        'foo bar baz',
    );
    is $fmt, 'a3x1a3x1a3', 'longer line extends template';
};

subtest 'guess_unpack: empty column cells' => sub {
    my $fmt = guess_unpack(
        'foo bar baz',
        'aaa     ccc',   # middle cell empty
    );
    is $fmt, 'a3x1a3x1a3', 'empty cell does not destroy column';
};

subtest 'guess_unpack: minimum_gap bridges small gaps' => sub {
    my @lines = (
        'foo bar baz',
        'aaa bbb ccc',
    );
    my $fmt_no_gap  = guess_unpack(@lines);
    my $fmt_with_gap = guess_unpack({ minimum_gap => 2 }, @lines);
    is $fmt_no_gap,   'a3x1a3x1a3', 'without minimum_gap';
    is $fmt_with_gap, 'a11',         'minimum_gap=>2 bridges single spaces';
};

subtest 'guess_unpack: minimum_gap preserves wide separators' => sub {
    my @lines = (
        'foo   bar   baz',
        'aaa   bbb   ccc',
    );
    is guess_unpack({ minimum_gap => 2 }, @lines), 'a3x3a3x3a3',
        'gaps of 3 survive minimum_gap=>2';
};

subtest 'guess_unpack: minimum_gap=>1 is same as no option' => sub {
    my @lines = ('foo bar', 'aaa bbb');
    is guess_unpack({ minimum_gap => 1 }, @lines), guess_unpack(@lines),
        'minimum_gap=>1 is a no-op';
};

# ---------------------------------------------------------------------------
# auto_unpack
# ---------------------------------------------------------------------------

subtest 'auto_unpack: basic round-trip' => sub {
    my @lines = (
        'foo bar baz',
        'aaa bbb ccc',
        'xxx yyy zzz',
    );
    my @rows = auto_unpack(@lines);
    is_deeply $rows[0], ['foo', 'bar', 'baz'], 'first row';
    is_deeply $rows[1], ['aaa', 'bbb', 'ccc'], 'second row';
    is_deeply $rows[2], ['xxx', 'yyy', 'zzz'], 'third row';
};

subtest 'auto_unpack: trims whitespace from cells' => sub {
    my @rows = auto_unpack(
        'foo bar baz',
        'a   b   c  ',
    );
    is_deeply $rows[1], ['a', 'b', 'c'], 'cells trimmed';
};

subtest 'auto_unpack: empty cell comes back as empty string' => sub {
    my @rows = auto_unpack(
        'foo bar baz',
        'aaa     ccc',
    );
    is_deeply $rows[1], ['aaa', '', 'ccc'], 'empty cell is empty string not undef';
};

subtest 'auto_unpack: returns correct number of rows' => sub {
    my @lines = ('a b c', 'd e f', 'g h i');
    my @rows = auto_unpack(@lines);
    is scalar @rows, 3, 'one arrayref per input line';
};

subtest 'auto_unpack: with minimum_gap option' => sub {
    my @rows = auto_unpack(
        { minimum_gap => 3 },
        'foo   bar   baz',
        'aaa   bbb   ccc',
    );
    is_deeply $rows[0], ['foo', 'bar', 'baz'], 'columns split correctly with minimum_gap';
    is_deeply $rows[1], ['aaa', 'bbb', 'ccc'], 'second row';
};

subtest 'auto_unpack: realistic ls -l style input' => sub {
    my @lines = (
        '-rw-r--r-- 1 user group  1234 Jan  1 12:00 file.txt',
        '-rwxr-xr-x 2 user group 56789 Feb 28 09:15 script.pl',
    );
    my @rows = auto_unpack(@lines);
    is scalar @{$rows[0]}, scalar @{$rows[1]}, 'same number of fields per row';
    is $rows[0][0], '-rw-r--r--', 'permissions field';
};

done_testing;