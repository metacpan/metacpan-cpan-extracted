#!/pro/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::NoWarnings;

use_ok "Text::OutputFilter";

my $lm = 4;
@ARGV and $ARGV[0] =~ m/^\d+$/ && ! -f $ARGV[0] and $lm = 0 + shift;

my $buf = "";
my $expect;

# Test printf ()
tie *STDOUT, "Text::OutputFilter", 1, \$buf, sub { "[$_[0]]" };
$expect  = " [000042]\n";
printf "%06d\n", 42;
untie *STDOUT;
is ($buf, $expect, "printf ()");

# test binmode, tell, fileno, and eof
$buf = "";
local $\ = "";
tie *STDOUT, "Text::OutputFilter", 1, \$buf, sub { "[$_[0]]" };
is (binmode (STDOUT, ":crlf"), 1, "binmode :crlf");
$expect  = " [000042]\r\n";
printf "%06d\n", 42;
#           ----+----1+
is (tell     STDOUT, 11,	"tell ()");
# Tied to a scalar: should return -1
is (fileno   STDOUT, -1,	"fileno ()");
is (eof      STDOUT,  0,	"eof ()");
is (binmode (STDOUT), 1,	"binmode ()");
is ($buf, $expect,		"printf ()");
is (close    STDOUT,  1,	"close ()");
untie *STDOUT;

# test forbidden and NYI
tie *STDOUT, "Text::OutputFilter", 1, \$buf, sub { "[$_[0]]" };
eval { my $in = <STDOUT> };
like ($@, qr{No support for \S+ method},  "output only");
eval { seek STDOUT, 5, 0 };
like ($@, qr{Support for \S+ method NYI}, "NYI");
untie *STDOUT;
