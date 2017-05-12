use strict;
use warnings;

use Test::More;
use Text::UnicodeTable::Simple;

{
    my $t = Text::UnicodeTable::Simple->new();

    can_ok($t, 'add_row');
    can_ok($t, 'addRow'); # alias

    $t->set_header(qw/1 2 3 4/);
    $t->add_row(qw/a b c d/);

    my @first_row = map { $_->text } @{$t->{rows}->[0]};
    is_deeply(\@first_row, [qw/a b c d/], 'set row');

    $t->add_row([ qw/e f g h/ ]);
    my @second_row = map { $_->text } @{$t->{rows}->[1]};
    is_deeply(\@second_row, [qw/e f g h/], 'set row with ArrayRef');
}

{
    my $t = Text::UnicodeTable::Simple->new();

    $t->set_header(qw/1 2 3 4/);
    $t->add_row(qw/a b c/);

    my @first_row = map { $_->text } @{$t->{rows}->[0]};
    is_deeply(\@first_row, [qw/a b c/, ''], 'set row shorter than header');

    $t->add_row();
    my @second_row = map { $_->text } @{$t->{rows}->[1]};
    is_deeply(\@second_row, ['', '', '', ''], 'set row with no element');
}

{
    my $t = Text::UnicodeTable::Simple->new();

    can_ok($t, 'add_rows');
    $t->set_header(qw/1 2 3 4/);
    $t->add_rows(
        [qw/a b c d/],
        [qw/e f g/],
    );

    my @first_row = map { $_->text } @{$t->{rows}->[0]};
    is_deeply(\@first_row, [qw/a b c d/], 'add row with add_rows method 1');

    my @second_row = map { $_->text } @{$t->{rows}->[1]};
    is_deeply(\@second_row, [qw/e f g/, ''], 'add row with add_rows method 2');
}

{
    my $t = Text::UnicodeTable::Simple->new();

    can_ok($t, 'add_row_line');
    can_ok($t, 'addRowLine'); # alias

    $t->set_header('a');

    $t->add_row_line;
    isa_ok($t->{rows}->[0], 'Text::UnicodeTable::Simple::Line');
}

{
    my $t = Text::UnicodeTable::Simple->new();

    eval {
        $t->add_row(qw/a b c d e/);
    };
    like $@, qr{'set_header' method previously}, 'not call set_header(add_row)';

    eval {
        $t->add_row_line();
    };
    like $@, qr{'set_header' method previously},
        'not call set_header(add_row_line)';

    $t->set_header(qw/aaa bbb ccc/);

    eval {
        $t->add_row(qw/a b c d e/);
    };
    like $@, qr{Too many elements}, 'too long argument';

    eval {
        $t->add_row(['a'], ['b']);
    };
    like $@, qr{Multiple ArrayRef arguments}, 'set multiple ArrayRef';
}

done_testing;
