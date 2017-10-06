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
  'Check encoding formats hexDumperOutput UCS-4',
);

like(
  exception { hexDumperInput('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats hexDumperInput UCS-4',
);

like(
  exception { ascii2hexEncode('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats ascii2hexEncode UCS-4',
);

like(
  exception { hex2ascciiDecode('Test', '這是一個測試'); },
  qr/Unknown encoding format 'Test'/,
  'Check encoding formats hex2ascciiDecode UCS-4',
);

ok( ascii2hexEncode('UCS-4', '這是一個測試') eq
    '0000feff000090190000662f00004e000000500b00006e2c00008a66',
    'Ascii too Hex UCS-4' );

ok( hex2ascciiDecode('UCS-4', '0000feff000090190000662f00004e000000500b00006e2c00008a66') eq
    '這是一個測試',
    'Hex to Ascii UCS-4' );

my @hexOutput = ( '00 00 fe ff 00 00 90 19 00 00',
		  '66 2f 00 00 4e 00 00 00 50 0b',
		  '00 00 6e 2c 00 00 8a 66' );

is_deeply( hexDumperOutput('UCS-4', '這是一個測試' ), \@hexOutput );

ok( hexDumperInput('UCS-4', \@hexOutput ) eq
    '這是一個測試',
    'Hex to Ascii UCS-4 hexDumperInput');