use strict;

use Test::More qw(no_plan);

use Vcdiff::OpenVcdiff;

pipe my $p1, my $p2;

print $p2 "junk";
close $p2;

eval {
  Vcdiff::diff($p1, "junk2");
};

my $err = $@;

like($err, qr/mmap call failed/, 'threw mmap error');
