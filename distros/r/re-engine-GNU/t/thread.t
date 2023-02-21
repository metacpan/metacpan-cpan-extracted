use strict;
use warnings FATAL => 'all';

BEGIN {
    use Config;
    if (! $Config{usethreads}) {
        print("1..0 # Skip: No threads\n");
        exit(0);
    }
}

use Thread;
use Test::More tests => 1 + 15 * 5;
use Test::More::UTF8;

BEGIN {
    require_ok('re::engine::GNU')
};

sub thr_sub {
  my ($qr) = @_;

  my $t = "\x{1000}\x{103B}\x{103D}\x{1014}\x{103A}\x{102F}\x{1015}\x{103A}xy" =~ $qr;

  is ($1, "\x{103A}", "utf8 \$1");
  is ($2, "x", "utf8 \$2");
  is ($-[0], 7, "utf8 \$-[0]");
  is ($+[0], 9, "utf8 \$-[0]");
  is ($-[1], 7, "utf8 \$-[1]");
  is ($+[1], 8, "utf8 \$-[1]");
  is ($-[2], 8, "utf8 \$-[2]");
  is ($+[2], 9, "utf8 \$-[2]");
  is (${^PREMATCH}, "\x{1000}\x{103B}\x{103D}\x{1014}\x{103A}\x{102F}\x{1015}", "utf8 \${^PREMATCH}");
  is (${^MATCH}, "\x{103A}x", "utf8 \${^MATCH}");
  is (${^POSTMATCH}, "y", "utf8 \${^POSTMATCH}");
  is ($`, "\x{1000}\x{103B}\x{103D}\x{1014}\x{103A}\x{102F}\x{1015}", "utf8 \$\`");
  is ($&, "\x{103A}x", "utf8 \$&");
  is ($', "y", "utf8 \$'");
  ok ($t, "\"\\x{1000}\\x{103B}\\x{103D}\\x{1014}\\x{103A}\\x{102F}\\x{1015}\\x{103A}xy\" =~ qr/\\([^x]\\)\\(x\\)/p");
}

{
  use re::engine::GNU -debug => $ENV{AUTHOR_TEST} || 0;

  my $qr = qr/\([^x]\)\(x\)/p;
  my @t = map { Thread->new(\&thr_sub, $qr) } (1..5);
  map { $_->join() } @t;
  no re::engine::GNU;
}

1;
