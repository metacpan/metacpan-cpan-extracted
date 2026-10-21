use Modern::Perl;
use Test::More;
use Test::HexDifferences; 

BEGIN { use_ok 'ZX81::Tokenize', 'tokenize_basic' }

eq_or_dump_diff(tokenize_basic(""), "");
eq_or_dump_diff(tokenize_basic(" 10 run "), 
				pack("C*", 0,10, 2,0, 0xF7,0x76));
eq_or_dump_diff(tokenize_basic(" 10 \\\n run "), 
				pack("C*", 0,10, 2,0, 0xF7,0x76));
eq_or_dump_diff(tokenize_basic(" # comment \n \n \n 10 run "), 
				pack("C*", 0,10, 2,0, 0xF7,0x76));
eq_or_dump_diff(tokenize_basic(" 10 print \"Hello\" \n \n 20 goto 10 "), 
				pack("C*", 
					0,10, 9,0,  0xF5,0x0B,0x2D,0x2A,0x31,0x31,0x34,0x0B,0x76,
					0,20, 10,0, 0xEC,0x1D,0x1C,0x7E,0x84,0x20,0x00,0x00,0x00,0x76));
eq_or_dump_diff(tokenize_basic(" 10 print \"\\\"A\\\"\""), 
				pack("C*", 
					0,10, 7,0,  0xF5,0x0B,0xC0,0x26,0xC0,0x0B,0x76));
eq_or_dump_diff(tokenize_basic(" 10 rem \\01\\01\\00\\C9"), 
				pack("C*", 
					0,10, 6,0,  0xEA,0x01,0x01,0x00,0xC9,0x76));
eq_or_dump_diff( tokenize_basic(" 10 PRINT 0"),
    pack( "C*", 0, 10, 9, 0, 0xF5, 0x1C, 0x7E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x76 ) );
eq_or_dump_diff( tokenize_basic(" 10 REM 0"),
    pack( "C*", 0, 10, 3, 0, 0xEA, 0x1C, 0x76 ) );
eq_or_dump_diff( tokenize_basic(" 10 LET C1=1"),
    pack( "C*", 0, 10, 12, 0, 0xF1, 0x28, 0x1D, 0x14, 
							  0x1D, 0x7E, 0x81, 0x00, 0x00, 0x00, 0x00, 0x76 ) );

done_testing;
