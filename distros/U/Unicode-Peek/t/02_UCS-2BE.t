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
  'Check encoding formats hexDumperOutput UCS-2BE',
);

like(
  exception { hexDumperInput('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats hexDumperInput UCS-2BE',
);

like(
  exception { ascii2hexEncode('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats ascii2hexEncode UCS-2BE',
);

like(
  exception { hex2ascciiDecode('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats hex2ascciiDecode UCS-2BE',
);

ok( ascii2hexEncode('UCS-2BE', '這是一個測試') eq
    '9019662f4e00500b6e2c8a66',
    'Ascii too Hex UCS-2BE' );

ok( hex2ascciiDecode('UCS-2BE', '9019662f4e00500b6e2c8a66') eq
    '這是一個測試',
    'Hex to Ascii UCS-2BE' );

my @hexOutput = ( '90 19 66 2f 4e 00 50 0b 6e 2c',
		  '8a 66' );

is_deeply( hexDumperOutput('UCS-2BE', '這是一個測試' ), \@hexOutput );

ok( hexDumperInput('UCS-2BE', \@hexOutput ) eq
    '這是一個測試',
    'Hex to Ascii UCS-2BE hexDumperInput');
