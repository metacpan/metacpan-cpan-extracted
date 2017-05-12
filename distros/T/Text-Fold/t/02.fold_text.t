use Test::More tests => 32;

BEGIN {
use_ok( 'Text::Fold' );
}

diag( "Testing Text::Fold $Text::Fold::VERSION" );

ok( fold_text('Hello World') eq 'Hello World', 'Simple string, no modification' );

my $nine_x = 'X' x 9;
my $eighty_x = 'X' x 80;
my $seventy_seven_x = 'X' x 77;
my $one_hundred_x = 'X' x 100;

ok( fold_text($eighty_x) eq "$seventy_seven_x\-\nXXX", 'Default width and default EOL' );
ok( fold_text("X$one_hundred_x",10) eq ("$nine_x\-\n" x 11) . "XX", 'Specified width and default EOL' );
ok( fold_text("X$one_hundred_x",10,"Y") eq ("${nine_x}\-Y" x 11) . "XX", 'Specified width and specified EOL' );
ok( fold_text("X$eighty_x",undef,"Z") eq "${seventy_seven_x}\-ZXXXX", 'default width and specified EOL' );

ok( 
    fold_text( "disparate\ndispara-te", 8 )
    eq
    "dispara-\nte\ndispara-\n-te",
    'Proper hyphenating'
);

ok(fold_text("\n\na b cd",3) eq "\n\na b\n cd", 'Beginning newlines preserved');
ok(fold_text("a b cd\n\n",3) eq "a b\n cd\n\n", 'Trailing newlines preserved');
ok(fold_text("\n\n\na b cd\n\n\n\n",3) eq "\n\n\na b\n cd\n\n\n\n", 'Beginning and Trailing newlines preserved');

ok(fold_text("123 567 ",4) eq "123 \n567 ", 'Trailing space in chunks preserved');

ok(fold_text('') eq '', 'empty is fine');
ok(fold_text("\n") eq "\n", 'Single EOL');
ok(fold_text("\r\n") eq "\n", 'Single MS EOL');
ok(fold_text("\n\n\n") eq "\n\n\n", 'Multi EOL');
ok(fold_text("\r\n\r\n\r\n") eq "\n\n\n", 'Multi MS EOL');

# hashref configuration 
ok(fold_text($eighty_x,{}) eq "$seventy_seven_x\-\nXXX",'hashref as 2nd arg w/ out join');
ok(fold_text($eighty_x,undef,{}) eq "$seventy_seven_x\-\nXXX",'hashref as 3nd arg w/ out join - default width');
ok(fold_text("X$one_hundred_x",10,{}) eq ("$nine_x\-\n" x 11) . "XX",'hashref as 3rd arg w/ out join - given width');

ok(fold_text("X$eighty_x",{ 'join' => "Z"}) eq "${seventy_seven_x}\-ZXXXX",'hashref as 2nd arg w/ join');
ok(fold_text("X$eighty_x",undef,{ 'join' => "Z"}) eq "${seventy_seven_x}\-ZXXXX",'hashref as 3nd arg w/ join - default width');
ok(fold_text("X$one_hundred_x",10,{ 'join' => "Y"}) eq ("${nine_x}\-Y" x 11) . "XX",'hashref as 3rd arg w/ join - given width');

# soft_hyphen_threshold

ok(fold_text("1 3 5 7 9 1 3 5 7 9XYD abc10 howdyhowdyhowdy",20,{ 'soft_hyphen_threshold' => '0E0' }) eq "1 3 5 7 9 1 3 5 7 \n9XYD abc10 howdyhow-\ndyhowdy",'defalut (E0E) value');
ok(fold_text("1 3 5 7 9 1 3 5 7 9XYD abc 10howdy hh XYZ",20,{ 'soft_hyphen_threshold' => '3' }) eq "1 3 5 7 9 1 3 5 7 9-\nXYD abc 10howdy hh \nXYZ",'valid given value');

ok(fold_text("123456 789012345678901234567890712",7) eq "123456 \n789012-\n345678-\n901234-\n567890-\n712", 'token larger than chunk soft hyphen default');
ok(fold_text("123456 78901234567 911 01234567890",7,{ 'soft_hyphen_threshold' => '3' }) eq "123456 \n789012-\n34567 \n911 01-\n234567-\n890", 'token larger than chunk soft hyphen threshold');

ok(
    fold_text("1 3 5 7 9 1 3 5 78901234567890123456 2 4 6 8 01234567890123456789012345678007 hi",20,{ 'soft_hyphen_threshold' => '2' }) 
   eq 
   "1 3 5 7 9 1 3 5 \n78901234567890123456\n 2 4 6 8 0123456789-\n0123456789012345678-\n007 hi",
   'given value to small'
);

ok(
    fold_text("1 3 5 7 9 1 3 5 78901234567890123456 2 4 6 8 01234567890123456789012345678007 hi",20,{ 'soft_hyphen_threshold' => '21' }) 
   eq 
   "1 3 5 7 9 1 3 5 \n78901234567890123456\n 2 4 6 8 0123456789-\n0123456789012345678-\n007 hi",
   'given value to big'
);

ok(
    fold_text("1 3 5 7 9 1 3 5 78901234567890123456 2 4 6 8 01234567890123456789012345678007 hi",20,{ 'soft_hyphen_threshold' => '20' }) 
   eq 
   "1 3 5 7 9 1 3 5 \n78901234567890123456\n 2 4 6 8 0123456789-\n0123456789012345678-\n007 hi",
   'given value just right'
);

# TODO break these out into more specific tests instead of multi things via one giant blob

my $output_debug = 0;

ok(
fold_text('abcdefgh10XYZ
1234567
12345678
123456789
1234567890
12345678901

i am ten a
i am ten an
i am ten a z
i am tenab
i am tenabn
i am tenab z


123456“abcdef
1234567“abcdef
12345678“abcdef
123456789“abcdef
1234567890“abcdef',10)
eq 
'abcdefgh1-
0XYZ
1234567
12345678
123456789
1234567890
123456789-
01

i am ten a
i am ten  
an
i am ten a
 z
i am tenab
i am tena-
bn
i am tenab
 z


123456“ab-
cdef
1234567“a-
bcdef
12345678“-
abcdef
123456789-
“abcdef
123456789-
0“abcdef',
'Byte string (via char)'
) || $output_debug++;

ok(
fold_text("abcdefgh10XYZ
1234567
12345678
123456789
1234567890
12345678901

i am ten a
i am ten an
i am ten a z
i am tenab
i am tenabn
i am tenab z


123456\xE2\x80\x9Cabcdef
1234567\xE2\x80\x9Cabcdef
12345678\xE2\x80\x9Cabcdef
123456789\xE2\x80\x9Cabcdef
1234567890\xE2\x80\x9Cabcdef",10)
eq 
"abcdefgh1-
0XYZ
1234567
12345678
123456789
1234567890
123456789-
01

i am ten a
i am ten  
an
i am ten a
 z
i am tenab
i am tena-
bn
i am tenab
 z


123456\xE2\x80\x9Cab-
cdef
1234567\xE2\x80\x9Ca-
bcdef
12345678\xE2\x80\x9C-
abcdef
123456789-
\xE2\x80\x9Cabcdef
123456789-
0\xE2\x80\x9Cabcdef",
'Byte string (via grapheme cluster)'
) || $output_debug++;

ok(
fold_text("abcdefgh10XYZ
1234567
12345678
123456789
1234567890
12345678901

i am ten a
i am ten an
i am ten a z
i am tenab
i am tenabn
i am tenab z


123456\x{201c}abcdef
1234567\x{201c}abcdef
12345678\x{201c}abcdef
123456789\x{201c}abcdef
1234567890\x{201c}abcdef",10)
eq 
"abcdefgh1-
0XYZ
1234567
12345678
123456789
1234567890
123456789-
01

i am ten a
i am ten  
an
i am ten a
 z
i am tenab
i am tena-
bn
i am tenab
 z


123456\x{201c}ab-
cdef
1234567\x{201c}a-
bcdef
12345678\x{201c}-
abcdef
123456789-
\x{201c}abcdef
123456789-
0\x{201c}abcdef",
'Unicode string'
) || $output_debug++;

if ($output_debug) {
    diag("--- Byte string (via char) ---\n(" . fold_text('abcdefgh10XYZ
1234567
12345678
123456789
1234567890
12345678901

i am ten a
i am ten an
i am ten a z
i am tenab
i am tenabn
i am tenab z


123456“abcdef
1234567“abcdef
12345678“abcdef
123456789“abcdef
1234567890“abcdef',10) . ")\n\n"
    );

    diag("--- Byte string (via grapheme cluster) ---\n(" . fold_text("abcdefgh10XYZ
1234567
12345678
123456789
1234567890
12345678901

i am ten a
i am ten an
i am ten a z
i am tenab
i am tenabn
i am tenab z


123456\xE2\x80\x9Cabcdef
1234567\xE2\x80\x9Cabcdef
12345678\xE2\x80\x9Cabcdef
123456789\xE2\x80\x9Cabcdef
1234567890\xE2\x80\x9Cabcdef",10) . ")\n\n"
    );

    diag("--- Unicode string ---\n(" . fold_text("abcdefgh10XYZ
1234567
12345678
123456789
1234567890
12345678901

i am ten a
i am ten an
i am ten a z
i am tenab
i am tenabn
i am tenab z


123456\x{201c}abcdef
1234567\x{201c}abcdef
12345678\x{201c}abcdef
123456789\x{201c}abcdef
1234567890\x{201c}abcdef",10) . ")\n\n"
    );
}