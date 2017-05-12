use strict;

use lib qw(./t/lib ./lib ./cgi-bin/lib ../cgi-bin/lib /var/www/modules2);

use Test::XHTML;

my $tests = "t/100-external-simple.csv";
Test::XHTML::runtests($tests);

1;
