#########################

use utf8;
use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Unicode::Peek', qw( :all )) };
BEGIN { use_ok('Test::Fatal', qw( exception ))};

#########################

like(
  exception { hexDumperOutput('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats hexDumperOutput UTF-32LE',
);

like(
  exception { hexDumperInput('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats hexDumperInput UTF-32LE',
);

like(
  exception { ascii2hexEncode('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats ascii2hexEncode UTF-32LE',
);

like(
  exception { hex2ascciiDecode('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats hex2ascciiDecode UTF-32LE',
);

ok( ascii2hexEncode('UTF-32LE', '這是一個測試') eq
    '199000002f660000004e00000b5000002c6e0000668a0000',
    'Ascii too Hex UTF-32LE' );

ok( hex2ascciiDecode('UTF-32LE',
		     '199000002f660000004e00000b5000002c6e0000668a0000') eq
    '這是一個測試',
    'Hex to Ascii UTF-32LE' );

my @hexOutput = ( '19 90 00 00 2f 66 00 00 00 4e',
		  '00 00 0b 50 00 00 2c 6e 00 00',
		  '66 8a 00 00' );

is_deeply( hexDumperOutput('UTF-32LE', '這是一個測試' ), \@hexOutput );

ok( hexDumperInput('UTF-32LE', \@hexOutput ) eq
    '這是一個測試',
    'Hex to Ascii UTF-32LE hexDumperInput');