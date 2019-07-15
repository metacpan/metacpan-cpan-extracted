use 5.012;
use warnings;
use lib 't';
use MyTest;

# signed integer
is(MyTest::i8(10), 10);
is(MyTest::i8(-100), -100);
is(MyTest::i8(128), -128);
is(MyTest::i16(30000), 30000);
is(MyTest::i16(-10000), -10000);
is(MyTest::i16(33000), -32536);
is(MyTest::i32(2000000000), 2000000000);
is(MyTest::i32(-100000000), -100000000);
is(MyTest::i32(3000000000), -1294967296);
is(MyTest::i64(9223372036854775807), 9223372036854775807);
is(MyTest::i64(-5223372036854775807), -5223372036854775807);
is(MyTest::i64(9223372036854775808), -9223372036854775808);

# unsigned integers
is(MyTest::u8(10), 10);
is(MyTest::u8(255), 255);
is(MyTest::u8(256), 0);
is(MyTest::u8(-10), 246);
is(MyTest::u16(10000), 10000);
is(MyTest::u16(65535), 65535);
is(MyTest::u16(65536), 0);
is(MyTest::u16(-10), 65526);
is(MyTest::u32(1000000000), 1000000000);
is(MyTest::u32(4294967295), 4294967295);
is(MyTest::u32(4294967296), 0);
is(MyTest::u32(-10), 4294967286);
is(MyTest::u64(1000000000000000), 1000000000000000);
is(MyTest::u64(18446744073709551615), 18446744073709551615);
is(MyTest::u64(-10), 18446744073709551606);

# time_t
if ($Config{ivsize} == 8) {
    is(MyTest::time_t(9223372036854775807), 9223372036854775807);
    is(MyTest::time_t(9223372036854775808), -9223372036854775808);
} else {
    is(MyTest::time_t(2000000000), 2000000000);
    is(MyTest::time_t(-100000000), -100000000);
    is(MyTest::time_t(3000000000), -1294967296);
}

done_testing();
