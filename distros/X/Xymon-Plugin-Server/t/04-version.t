use strict;
use Test::More tests => 2;

use Cwd qw(getcwd);

use Xymon::Plugin::Server;

my $cwd = getcwd;

#
# 4.2
#
local $ENV{BBHOME} = "$cwd/t/testhome42";
local $ENV{XYMONHOME};
my $v42 = Xymon::Plugin::Server->version;
ok($v42->[0] == 4 && $v42->[1] == 2);

#
# 4.3
#
local $ENV{BBHOME};
local $ENV{XYMONHOME} = "$cwd/t/testhome";
my $v43 = Xymon::Plugin::Server->version;
ok($v43->[0] == 4 && $v43->[1] == 3);
