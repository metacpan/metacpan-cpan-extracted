use strict;
use Test::More tests => 4;

use Cwd qw(getcwd);

use Xymon::Plugin::Server::Devmon;

my $cwd = getcwd;

#
# 4.2
#
local $ENV{BBHOME} = "$cwd/t/testhome42";
local $ENV{XYMONHOME};
{
    my $devmon = Xymon::Plugin::Server::Devmon
        ->new(x => 'GAUGE:600:0:U',
              y => 'ABSOLUTE:600:0:U');

    $devmon->add_data(device1 => { x => 0, y => 1 });
    $devmon->add_data(device2 => { x => 2, y => 3 });

    my $s = $devmon->format;

    my $expected = "<!--DEVMON RRD: \n"
      . "DS:ds0:GAUGE:600:0:U DS:ds1:ABSOLUTE:600:0:U DS:ds2:GAUGE:600:0:U DS:ds3:GAUGE:600:0:U DS:ds4:GAUGE:600:0:U DS:ds5:GAUGE:600:0:U DS:ds6:GAUGE:600:0:U DS:ds7:GAUGE:600:0:U DS:ds8:GAUGE:600:0:U DS:ds9:GAUGE:600:0:U DS:ds10:GAUGE:600:0:U DS:ds11:GAUGE:600:0:U DS:ds12:GAUGE:600:0:U DS:ds13:GAUGE:600:0:U DS:ds14:GAUGE:600:0:U DS:ds15:GAUGE:600:0:U DS:ds16:GAUGE:600:0:U DS:ds17:GAUGE:600:0:U DS:ds18:GAUGE:600:0:U DS:ds19:GAUGE:600:0:U\n"
      . "device1 0:1:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U\n"
      . "device2 2:3:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U\n"
      . "-->\n";

    is($s, $expected);
}

# undef
{
    my $devmon = Xymon::Plugin::Server::Devmon
        ->new(x => 'GAUGE:600:0:U',
              y => 'ABSOLUTE:600:0:U');

    $devmon->add_data(device1 => { x => 987,        });
    $devmon->add_data(device2 => {           y => 0 });

    my $s = $devmon->format;

    my $expected = "<!--DEVMON RRD: \n"
      . "DS:ds0:GAUGE:600:0:U DS:ds1:ABSOLUTE:600:0:U DS:ds2:GAUGE:600:0:U DS:ds3:GAUGE:600:0:U DS:ds4:GAUGE:600:0:U DS:ds5:GAUGE:600:0:U DS:ds6:GAUGE:600:0:U DS:ds7:GAUGE:600:0:U DS:ds8:GAUGE:600:0:U DS:ds9:GAUGE:600:0:U DS:ds10:GAUGE:600:0:U DS:ds11:GAUGE:600:0:U DS:ds12:GAUGE:600:0:U DS:ds13:GAUGE:600:0:U DS:ds14:GAUGE:600:0:U DS:ds15:GAUGE:600:0:U DS:ds16:GAUGE:600:0:U DS:ds17:GAUGE:600:0:U DS:ds18:GAUGE:600:0:U DS:ds19:GAUGE:600:0:U\n"
      . "device1 987:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U\n"
      . "device2 U:0:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U:U\n"
      . "-->\n";

    is($s, $expected);
}

#
# 4.3
#
local $ENV{BBHOME};
local $ENV{XYMONHOME} = "$cwd/t/testhome";
{
    my $devmon = Xymon::Plugin::Server::Devmon
        ->new(x => 'GAUGE:600:0:U',
              y => 'ABSOLUTE:600:0:U');

    $devmon->add_data(device1 => { x => 0, y => 1 });
    $devmon->add_data(device2 => { x => 2, y => 3 });

    my $s = $devmon->format;

    my $expected =
	"<!--DEVMON RRD: \n"
	. "DS:x:GAUGE:600:0:U DS:y:ABSOLUTE:600:0:U\n"
	. "device1 0:1\n"
	. "device2 2:3\n"
	. "-->\n";

    is($s, $expected);
}

# undef
{
    my $devmon = Xymon::Plugin::Server::Devmon
        ->new(x => 'GAUGE:600:0:U',
              y => 'ABSOLUTE:600:0:U');

    $devmon->add_data(device1 => {         y => 1 });
    $devmon->add_data(device2 => { x => 0,        });

    my $s = $devmon->format;

    my $expected =
	"<!--DEVMON RRD: \n"
	. "DS:x:GAUGE:600:0:U DS:y:ABSOLUTE:600:0:U\n"
	. "device1 U:1\n"
	. "device2 0:U\n"
	. "-->\n";

    is($s, $expected);
}
