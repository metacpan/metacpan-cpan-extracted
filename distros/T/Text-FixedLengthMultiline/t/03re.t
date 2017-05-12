#!perl
use strict;
use warnings;
use Test::More tests => 52;
use Test::NoWarnings;

BEGIN { use_ok('Text::FixedLengthMultiline'); }

my $fmt;

foreach my $continue_style ('first', 'last', 'any') {
    $fmt = Text::FixedLengthMultiline->new(format => [ ], continue_style => $continue_style);
    is($fmt->get_first_line_re(), undef, "Empty format ($continue_style)");
    is($fmt->get_continue_line_re(), undef);
}

foreach my $continue_style ('first', 'last', 'any') {
    $fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col' => 4 ], continue_style => $continue_style);
    is($fmt->get_first_line_re(), qr{^ {3}\S.{0,3} *$}, "Left aligned mandatory column ($continue_style)");
    is($fmt->get_continue_line_re(), undef);
}

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col' => -4 ]);
is($fmt->get_first_line_re(), qr{^ {3}.{3}\S *$}, 'Right aligned mandatory column');
is($fmt->get_continue_line_re(), undef);

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1' => 4, 1, '!col2' => 5 ]);
is($fmt->get_first_line_re(), qr{^ {3}\S.{3} \S.{0,4} *$}, 'Left aligned mandatory column');
is($fmt->get_continue_line_re(), undef);

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1' => -4, 1, '!col2' => 5 ]);
is($fmt->get_first_line_re(), qr{^ {3}.{3}\S \S.{0,4} *$}, 'Right aligned mandatory column');
is($fmt->get_continue_line_re(), undef);

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1' => 4, 1, 'col2' => 5 ]);
is($fmt->get_first_line_re(), qr{^ {3}\S(?:.{0,3}|.{3}(?: .{0,5})?) *$}, 'Left aligned mandatory column');
is($fmt->get_continue_line_re(), undef);

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1' => -4, 1, 'col2' => 5 ]);
is($fmt->get_first_line_re(), qr{^ {3}.{3}\S(?: .{0,5})? *$}, 'Right aligned mandatory column');
is($fmt->get_continue_line_re(), undef);

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1' => -4, 1, 'col2' => 5, 2, 'col3' => 6 ]);
is($fmt->get_first_line_re(), qr{^ {3}.{3}\S(?:(?: .{0,5})?| .{5}(?: {2}.{0,6})?) *$}, 'Left aligned mandatory column');
is($fmt->get_continue_line_re(), undef);

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1' => -4, 1, 'col2' => 5, 2, '!col3' => 6 ]);
is($fmt->get_first_line_re(), qr{^ {3}.{3}\S .{5} {2}\S.{0,5} *$}, 'Left aligned mandatory column');
is($fmt->get_continue_line_re(), undef);

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4 ]);
is($fmt->get_first_line_re(), qr{^ {3}\S.{0,3} *$}, '!col1~');
is($fmt->get_continue_line_re(), qr{^ {3}\S.{0,3} *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => -4 ]);
is($fmt->get_first_line_re(), qr{^ {3}.{3}\S *$}, 'Right aligned multi');
is($fmt->get_continue_line_re(), qr{^ {3}.{3}\S *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => -4, 2, 'col2' => 8 ], continue_style => 'first');
is($fmt->get_first_line_re(), qr{^ {3}.{3}\S(?: {2}.{0,8})? *$}, '!col1~ col2');
is($fmt->get_continue_line_re(), qr{^ {3}.{3}\S *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => -4, 2, 'col2' => 8 ], continue_style => 'last');
is($fmt->get_first_line_re(), qr{^ {3}.{3}\S(?: {2}.{0,8})? *$}, '!col1~ col2');
is($fmt->get_continue_line_re(), qr{^ {3}.{3}\S(?: {2}.{0,8})? *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4, 2, '!col2' => 8 ], continue_style => 'first');
is($fmt->get_first_line_re(), qr{^ {3}\S.{3} {2}\S.{0,7} *$}, '!col1~ !col2');
is($fmt->get_continue_line_re(), qr{^ {3}\S.{0,3} *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4, 2, '!col2' => 8 ], continue_style => 'last');
is($fmt->get_first_line_re(), qr{^ {3}\S(?:.{0,3}|.{3} {2}\S.{0,7}) *$}, '!col1~ !col2');
is($fmt->get_continue_line_re(), qr{^ {3}\S(?:.{0,3}|.{3} {2}\S.{0,7}) *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4, 2, 'col2' => 9, 5, '!col3' => 8 ], continue_style => 'any');
is($fmt->get_first_line_re(), qr{^ {3}\S(?:.{0,3}|.{3} {2}.{9} {5}\S.{0,7}) *$}, '!col1~ col2 !col3');
is($fmt->get_continue_line_re(), qr{^ {3}\S(?:.{0,3}|.{3} {2}.{9} {5}\S.{0,7}) *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4, 2, 'col2' => 9, 5, '!col3' => 8 ], continue_style => 'first');
is($fmt->get_first_line_re(), qr{^ {3}\S.{3} {2}.{9} {5}\S.{0,7} *$}, '!col1~ col2 !col3');
is($fmt->get_continue_line_re(), qr{^ {3}\S.{0,3} *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4, 2, 'col2' => 9, 5, '!col3' => 8 ], continue_style => 'last');
is($fmt->get_first_line_re(), qr{^ {3}\S(?:.{0,3}|.{3} {2}.{9} {5}\S.{0,7}) *$}, '!col1~ col2 !col3');
is($fmt->get_continue_line_re(), qr{^ {3}\S(?:.{0,3}|.{3} {2}.{9} {5}\S.{0,7}) *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4, 2, 'col2~' => 9, 5, '!col3~' => 8 ], continue_style => 'first');
is($fmt->get_first_line_re(), qr{^ {3}\S.{3} {2}.{9} {5}\S.{0,7} *$}, '!col1~ col2~ !col3~');
is($fmt->get_continue_line_re(), qr{^ {3}(?:\S.{0,3}|.{4} {2}(?:\S.{0,8}|.{9} {5}\S.{0,7})) *$});

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4, 2, 'col2~' => 9, 5, '!col3~' => 8 ], continue_style => 'any');
is($fmt->get_first_line_re(), qr{^ {3}\S(?:.{0,3}|.{3}(?:(?: {2}.{0,9})?| {2}.{9} {5}\S.{0,7})) *$}, '!col1~ col2~ !col3~');
TODO: {
  local $TODO = 'Fix get_continue_re_line()  (working but not optimized)';
  is($fmt->get_continue_line_re(), qr{^ {3}(?:\S.{0,3}|.{4} {2}(?:\S.{0,8}|.{9} {5}\S.{0,7})) *$});
}

$fmt = Text::FixedLengthMultiline->new(format => [ 3, '!col1~' => 4, 2, 'col2~' => 9, 5, '!col3~' => 8 ], continue_style => 'last');
is($fmt->get_first_line_re(), qr{^ {3}\S(?:.{0,3}|.{3}(?:(?: {2}.{0,9})?| {2}.{9} {5}\S.{0,7})) *$}, '!col1~ col2~ !col3~');
TODO: {
  local $TODO = 'Fix get_continue_re_line()  (working but not optimized)';
  is($fmt->get_continue_line_re(), qr{^ {3}(?:\S.{0,3}|.{4} {2}(?:\S.{0,8}|.{9} {5}\S.{0,7})) *$});
}
# TODO more tests
