#------------------------------------------------------------------------------#
# Win32::Printer (FreeImage) test script                                       #
# Copyright (C) 2003 Edgars Binans                                             #
#------------------------------------------------------------------------------#

use strict;
use warnings;
use Test::More;

use Win32::Printer;

if (Win32::Printer::_Get3PLibs() & 0x00000001) {
  plan tests => 3;
} else {
  plan skip_all => "FreeImage is not built in!";
}

#------------------------------------------------------------------------------#

my $dc = new Win32::Printer( file => "t/tmp/test.ps" );

my $bmp00 = $dc->Image('t/t.png');
ok ( $bmp00 != 0, 'Image() bmp' );
ok ( $dc->Image($bmp00, 5, 5, 2, 1) == $bmp00, 'Image() indirect' );
ok ( $dc->Close($bmp00) == 1, 'Close() Image indirect' );
$dc->Close();

#------------------------------------------------------------------------------#

unlink <t/tmp/*.*>;
