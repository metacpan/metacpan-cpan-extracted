use strict;
use warnings;

use Test::More tests => 2;
use YottaDB qw/:all/;


my @subs;

push @subs, $_ for (0..30); # we check the maximum subscripts (31)

eval { y_get "Variable", @subs; };
ok(!$@);

eval { y_get "Variable", @subs, 1; };
ok($@ =~ /too\s+many\s+subscripts/);


