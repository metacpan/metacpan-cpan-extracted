use strict;
use warnings;

package MultBasic;
use parent 'Text::Parser';

sub new {
    my $pkg = shift;
    $pkg->SUPER::new( multiline_type => 'join_last' );
}

package main;

use Test::More;
use Test::Exception;
use Test::Output;

lives_ok {
    my $mpars = MultBasic->new();
    $mpars->read('t/data.txt');
    is $mpars->is_line_continued(''), 1, 'Is always continued';
    is_deeply(
        [ $mpars->get_records() ],
        ["1\n2 3\n 4\n five\nsix seven\n"],
        'Expected output'
    );
    is( $mpars->lines_parsed(), 5, 'Five lines parsed' );
}
'No errors in reading file';

lives_ok {
    my $mpars = MultBasic->new();
    is $mpars->multiline_type(undef), undef, 'Set to undef';
    is $mpars->is_line_continued(''), 0,     'Is never continued';
    $mpars->read('t/data.txt');
    is_deeply(
        [ $mpars->get_records() ],
        [ "1\n", "2 3\n", " 4\n", " five\n", "six seven\n" ],
        'Expected output'
    );
    is( $mpars->lines_parsed(), 5, 'Five lines parsed' );
}
'No errors in reading file';

done_testing;
