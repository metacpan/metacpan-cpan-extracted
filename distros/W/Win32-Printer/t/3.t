#------------------------------------------------------------------------------#
# Win32::Printer (GhostScript) test script                                     #
# Copyright (C) 2003 Edgars Binans                                             #
#------------------------------------------------------------------------------#

use strict;
use warnings;
use Test::More;

use Win32::Printer;

if (Win32::Printer::_Get3PLibs() & 0x00000002) {
  plan tests => 4;
} else {
  plan skip_all => "Ghostscript is not built in!";
}

#------------------------------------------------------------------------------#

my $dc = new Win32::Printer( file => "t/tmp/test.pdf", pdf => 0, dc=>1);

ok ( $dc->Start("Test 1") == 1, 'Start()' );
ok ( defined($dc->Next("Test 2")) == 1, 'Next()' );
ok ( defined($dc->End()), 'End()' );
ok ( defined($dc->Close()), 'Close()' );

#------------------------------------------------------------------------------#

unlink <t/tmp/*.*>;
