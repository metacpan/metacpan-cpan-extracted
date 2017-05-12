use strict;

use Test::More qw(no_plan);

use Vcdiff::Xdelta3;

pipe my $p1, my $p2;

print $p2 "junk";
close $p2;

eval {
  Vcdiff::diff($p1, "junk2");
};

my $err = $@;

like($err, qr/lseek/, 'threw non-lseekable error');
