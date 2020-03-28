use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier "minify";

my %opt = ();
$opt{version} = "0";


my $maxi = << "EOM";
<foo/>
EOM

# Not really mini :)
my $mini = << "EOM";
<?xml version="0" encoding="UTF-8"?><foo/>
EOM

chomp $mini;

is(minify($maxi, %opt), $mini, "Version is 0" );
$opt{version} = "version";

done_testing;

