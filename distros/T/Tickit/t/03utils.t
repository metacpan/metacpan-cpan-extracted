#!/usr/bin/perl

use strict;
use warnings;

# These tests depend on a locale that knows about Unicode
BEGIN {
   use POSIX qw( setlocale LC_CTYPE );

   my $CAN_UNICODE = 0;

   foreach (qw( en_US.UTF-8 en_GB.UTF-8 )) {
      setlocale LC_CTYPE, $_ and $CAN_UNICODE = 1 and last;
   }

   require constant;
   import constant CAN_UNICODE => $CAN_UNICODE;
}

use Test::More;

# An invalid UTF-8 string
my $BAD_UTF8 = do { no utf8; "foo\xA9bar" };

my $CJK_UTF8 = do { use utf8; "(ノಠ益ಠ)ノ彡┻━┻" };

use Tickit::Utils qw(
   string_count
   string_countmore

   textwidth
   chars2cols
   cols2chars
   substrwidth
   align
   bound
   distribute
);
use Tickit::StringPos;

{
   my $pos = Tickit::StringPos->zero;

   ok( ref $pos, '$pos isa ref' );

   is( $pos->bytes,      0, '$pos->bytes is 0' );
   is( $pos->codepoints, 0, '$pos->codepoints is 0' );
   is( $pos->graphemes,  0, '$pos->graphemes is 0' );
   is( $pos->columns,    0, '$pos->columns is 0' );

   is( string_count( "", $pos ), 0, 'string_count("") is 0' );

   is( string_count( "ABC", $pos ), 3, 'string_count("ABC") is 3' );

   is( $pos->bytes,      3, '$pos->bytes is 3 after count "ABC"' );
   is( $pos->codepoints, 3, '$pos->codepoints is 3 after count "ABC"' );
   is( $pos->graphemes,  3, '$pos->graphemes is 3 after count "ABC"' );
   is( $pos->columns,    3, '$pos->columns is 3 after count "ABC"' );

   is( string_countmore( "ABCDEF", $pos ), 3, 'string_countmore("ABCDEF") is 3' );

   is( $pos->bytes,      6, '$pos->bytes is 6 after countmore "DEF"' );
   is( $pos->codepoints, 6, '$pos->codepoints is 6 after countmore "DEF"' );
   is( $pos->graphemes,  6, '$pos->graphemes is 6 after countmore "DEF"' );
   is( $pos->columns,    6, '$pos->columns is 6 after countmore "DEF"' );

   my $limit = Tickit::StringPos->limit_bytes( 5 );

   is( $limit->bytes,       5, '$limit->bytes is 5' );
   is( $limit->codepoints, -1, '$limit->codepoints is -1' );
   is( $limit->graphemes,  -1, '$limit->graphemes is -1' );
   is( $limit->columns,    -1, '$limit->columns is -1' );
}

is( textwidth( "" ),            0, 'textwidth empty' );
is( textwidth( "ABC" ),         3, 'textwidth ASCII' );
SKIP: {
   skip "No Unicode", 6 unless CAN_UNICODE;

   is( textwidth( "cafe\x{301}" ), 4, 'textwidth combining' );

   is( textwidth( "caf\x{fffd}" ), 4, 'U+FFFD counts as width 1' );

   is( textwidth( $BAD_UTF8 ), 7, 'Invalid UTF-8 counts as width 1' );

   is( textwidth( $CJK_UTF8 ), 15, 'CKJ UTF-8 counts as width 15');

   is( textwidth( "\x1b" ), undef, 'C0 control is invalid for textwidth' );
   is( textwidth( "\x9b" ), undef, 'C1 control is invalid for textwidth' );
   is( textwidth( "\x7f" ), undef, 'DEL is invalid for textwidth' );
}

is_deeply( [ chars2cols "ABC", 0, 1, 3, 4 ],
           [ 0, 1, 3, 3 ],
           'chars2cols ASCII' );
SKIP: {
   skip "No Unicode", 5 unless CAN_UNICODE;

   is_deeply( [ chars2cols "cafe\x{301}", 3, 4, 5, 6 ],
              [ 3, 3, 4, 4 ],
              'chars2cols combining' );

   is_deeply( [ chars2cols "caf\x{fffd}", 3, 4, 5 ],
              [ 3, 4, 4 ],
              'U+FFFD counts as width 1 for chars2cols' );

   is_deeply( [ chars2cols $BAD_UTF8, 3, 5, 7 ],
              [ 3, 5, 7 ],
              'Invalid UTF-8 counts as width 1 for chars2cols' );

   is( chars2cols( "\x1b", 1 ), undef, 'C0 control is invalid for chars2cols' );
   is( chars2cols( "\x9b", 1 ), undef, 'C1 control is invalid for chars2cols' );
}

is( scalar chars2cols( "ABC", 2 ), 2, 'scalar chars2cols' );
is( scalar chars2cols( "ABC", 3 ), 3, 'scalar chars2cols EOS' );
is( scalar chars2cols( "ABC", 4 ), 3, 'scalar chars2cols past EOS' );

is_deeply( [ cols2chars "ABC", 0, 1, 3, 4 ],
           [ 0, 1, 3, 3 ],
           'cols2chars ASCII' );
SKIP: {
   skip "No Unicode", 5 unless CAN_UNICODE;

   is_deeply( [ cols2chars "cafe\x{301}", 3, 4, 5 ],
              [ 3, 5, 5 ],
              'cols2chars combining' );

   is_deeply( [ cols2chars "caf\x{fffd}", 3, 4, 5 ],
              [ 3, 4, 4 ],
              'U+FFFD counts as width 1 for cols2chars' );

   is_deeply( [ cols2chars $BAD_UTF8, 3, 5, 7 ],
              [ 3, 5, 7 ],
              'Invalid UTF-8 counts as width 1 for cols2chars' );

   is( cols2chars( "\x1b", 1 ), undef, 'C0 control is invalid for cols2chars' );
   is( cols2chars( "\x9b", 1 ), undef, 'C1 control is invalid for cols2chars' );
}

is( scalar cols2chars( "ABC", 2 ), 2, 'scalar cols2chars' );
is( scalar cols2chars( "ABC", 3 ), 3, 'scalar cols2chars EOS' );
is( scalar cols2chars( "ABC", 4 ), 3, 'scalar cols2chars past EOS' );

is( substrwidth( "ABC", 0, 1 ), "A", 'substrwidth ASCII' );
is( substrwidth( "ABC", 2 ),    "C", 'substrwidth ASCII trail' );
SKIP: {
   skip "No Unicode", 2 unless CAN_UNICODE;

   is( substrwidth( "cafe\x{301} table", 0, 4 ), "cafe\x{301}", 'substrwidth combining within' );
   is( substrwidth( "cafe\x{301} table", 5, 5 ), "table", 'substrwidth combining after' );
}

is_deeply( [ align 10, 30, 0.0 ], [  0, 10, 20 ], 'align 10 in 30 by 0.0' );
is_deeply( [ align 10, 30, 0.5 ], [ 10, 10, 10 ], 'align 10 in 30 by 0.5' );
is_deeply( [ align 10, 30, 1.0 ], [ 20, 10,  0 ], 'align 10 in 30 by 1.0' );

is_deeply( [ align 30, 30, 0.0 ], [  0, 30,  0 ], 'align 30 in 30 by 0.0' );
is_deeply( [ align 40, 30, 0.0 ], [  0, 30,  0 ], 'align 40 in 30 by 0.0' );

is( bound( undef, 20, undef ), 20, 'bound with no limits' );
is( bound(    10, 20, undef ), 20, 'bound with minimum' );
is( bound(    10,  5, undef ), 10, 'bound at minimum' );
is( bound( undef, 20,    40 ), 20, 'bound with maximum' );
is( bound( undef, 50,    40 ), 40, 'bound at maximum' );

{
   my @buckets = (
      { base => 10, expand => 1 },
      { base => 10, expand => 2 },
      { base => 20 },
   );

   distribute( 40, @buckets );
   is_deeply( \@buckets,
              [ { base => 10, expand => 1, value => 10, start =>  0, },
                { base => 10, expand => 2, value => 10, start => 10, },
                { base => 20,              value => 20, start => 20, } ],
              'distribute exact' );

   distribute( 50, @buckets );
   is_deeply( \@buckets,
              [ { base => 10, expand => 1, value => 13, start =>  0, },
                { base => 10, expand => 2, value => 17, start => 13, },
                { base => 20,              value => 20, start => 30, } ],
              'distribute spare' );

   distribute( 30, @buckets );
   is_deeply( \@buckets,
              [ { base => 10, expand => 1, value =>  7, start =>  0, },
                { base => 10, expand => 2, value =>  8, start =>  7, },
                { base => 20,              value => 15, start => 15, } ],
              'distribute short' );

   push @buckets, { fixed => 3 };

   distribute( 30, @buckets );
   is_deeply( \@buckets,
              [ { base => 10, expand => 1, value =>  6, start =>  0, },
                { base => 10, expand => 2, value =>  7, start =>  6, },
                { base => 20,              value => 14, start => 13, },
                { fixed => 3,              value =>  3, start => 27, } ],
              'distribute short with fixed' );
}

done_testing;
