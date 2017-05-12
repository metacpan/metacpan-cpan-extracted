#!/usr/bin/perl -w
use strict;
use Test::Simple tests => 2;

use Text::WrapI18N qw(:all);
$columns = 9;
ok(wrap("", "", "abcdefg") eq "abcdefg");
ok(wrap("# ", "! ", "abcdefg hijklmn") eq "# abcdefg\n! hijklmn");
exit;
__END__

