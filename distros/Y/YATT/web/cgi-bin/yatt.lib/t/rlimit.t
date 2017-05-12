#!/usr/bin/perl -w
use strict;
use warnings qw(FATAL all NONFATAL misc);

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More;

unless (eval {require BSD::Resource}) {
  plan skip_all => 'BSD::Resource is not installed'; exit;
}
if ($^O eq "darwin") {
  plan skip_all => 'rlimit_vmem may not work on this platform';
}

plan tests => 4;

ok(chdir "$FindBin::Bin/..", 'chdir to lib dir');

require_ok('YATT::Util::RLimit');
require_ok('Config');

my $script = q{
  my $limit = $Config::Config{ptrsize} >= 8 ? 200 : 100;
  rlimit_vmem($limit) or die $@; eval q{print "p03" .. "p05_1"}
};

like qx($^X -I. -MYATT::Util::RLimit -e '$script' 2>&1), qr{^Out of memory}
  , "Memory hog should be detected.";
