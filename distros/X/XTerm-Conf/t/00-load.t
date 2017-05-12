#!perl

use FindBin;
use Test;

plan tests => 2;

eval qq{ require XTerm::Conf };
ok($@, "", "Error loading XTerm::Conf");

system($^X, "-c", "-Mblib=$FindBin::RealBin/..", "xterm-conf");
ok($?, 0, "No syntax error in xterm-conf");
