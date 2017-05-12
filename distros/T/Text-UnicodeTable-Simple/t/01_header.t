use strict;
use warnings;

use Test::More;
use Text::UnicodeTable::Simple;

{
    my $t = Text::UnicodeTable::Simple->new();
    ok(defined($t), "constructor");
    isa_ok($t, "Text::UnicodeTable::Simple");

    can_ok($t, 'set_header');
    can_ok($t, 'setCols'); # alias
    $t->set_header('apple', 'orange', 'melon');

    my @rows;
    push @rows, $_->text for @{$t->{header}->[0]};
    is_deeply(\@rows, ['apple', 'orange', 'melon'], 'use array');
}

{
    my $t = Text::UnicodeTable::Simple->new(
        header => [qw/apple orange melon/],
    );

    my @rows;
    push @rows, $_->text for @{$t->{header}->[0]};
    is_deeply(\@rows, ['apple', 'orange', 'melon'],
              "constructor with 'header' param");
}

{
    my $t = Text::UnicodeTable::Simple->new();
    $t->set_header(['apple', 'orange', 'melon']);

    my @rows;
    push @rows, $_->text for @{$t->{header}->[0]};
    is_deeply(\@rows, ['apple', 'orange', 'melon'], 'use ArrayRef');
}

{
    my $t = Text::UnicodeTable::Simple->new();

    eval {
        $t->set_header();
    };
    like($@, qr{Input array has no element}, 'no element');

    eval {
        $t->set_header(['apple'], ['orange']);
    };
    like($@, qr{Multiple ArrayRef arguments}, 'multiple ArrayRef');

    eval {
        my $t = Text::UnicodeTable::Simple->new(
            header => "not ArrayRef",
        );
    };
    like($@, qr{param should be ArrayRef}, 'header should be ArrayRef');
}

done_testing;
