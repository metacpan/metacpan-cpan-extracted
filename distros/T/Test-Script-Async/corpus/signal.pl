use strict;
use warnings;

my $sig = $ARGV[0];
die "no sig given" unless defined $sig;
kill $sig, $$;
