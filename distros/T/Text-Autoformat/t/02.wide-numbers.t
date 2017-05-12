use utf8;
use strict;
use Test::More tests => 1;
use Text::Autoformat;

my $str = <<'END';
１. Analyze problem
２. Design algorithm
６. Code solution
４. Test
２. Ship
END

my $after = autoformat $str, {
  lists => 'number',
  all   => 1, # rjbs thinks this should not be needed -- rjbs, 2015-04-24
};

unlike(
  $after,
  qr/2/,
  "we do not mangle lists numbered with non-ASCII numbers",
);

