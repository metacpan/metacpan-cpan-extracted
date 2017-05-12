#!/usr/bin/perl -w
use strict;
use Test::Simple tests => 5;

use Text::CharWidth qw(:all);
ok(mbwidth("A") == 1);
ok(mbswidth("A") == 1);
ok(mbwidth("AA") == 1);
ok(mbswidth("AA") == 2);
ok(mblen("AA") == 1);
exit;
__END__

