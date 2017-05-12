# -*- Mode: CPerl -*-
# t/03_utf8.t: test utf8 subclass

use Test::More tests=>4;
use Tie::File::Indexed::Utf8;

my $TEST_DIR = ".";

##-- common variables
my $file = "$TEST_DIR/test_utf8.dat";
my @u = ("\x{f6}de", "Ha\x{364}u\x{17f}er", "\x{262e}\x{2665}\x{2615}", "\x{0372}\x{2107}\x{01a7}\x{a68c}");

##-- 1+3: utf8 data
ok(tie(my @a, 'Tie::File::Indexed::Utf8', $file, mode=>'rw'), "utf8: tie");
@a = @u;
is($#a, $#u, "utf8: size");
is_deeply(\@a,\@u, "utf8: content");

##-- 4+1: unlink
ok(tied(@a)->unlink, "utf8: unlink");

# end of t/03_utf8.t
