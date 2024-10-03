use strict;
use warnings;

use Test::More;
my @builtins;
BEGIN {
  if (eval { require builtin; 1 }) {
    @builtins = grep {
      no strict 'refs';
      !/::$|^(?:un)?import$/ && defined &{"builtin::$_"}
    } sort keys %builtin::;
  }
  else {
    plan skip_all => "No core builtin on perl $] to check against";
  }
}

use builtin::compat ();

plan tests => scalar @builtins;

my @excluded = qw(
  export_lexically
);
my %excluded = map +($_ => 1), @excluded;

for my $builtin (@builtins) {
  my $exists = do {
    no strict 'refs';
    defined &{"builtin::compat::$builtin"};
  };

  if (!$excluded{$builtin}) {
    ok $exists, "builtin::compat::$builtin exists";
  }
  else {
    ok !$exists, "builtin::compat::$builtin does not exist";
  }
}

done_testing;
