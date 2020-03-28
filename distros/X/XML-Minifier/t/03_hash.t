use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier "minify";

my %opt = ();
$opt{version} = "42.0";


my $maxi = << "EOM";
<foo/>
EOM

my $mini = << "EOM";
<?xml version="42.0" encoding="UTF-8"?><foo/>
EOM

my $mini16 = << "EOM";
<?xml version="42.0" encoding="UTF-16"?><foo/>
EOM

chomp $mini;
chomp $mini16;

is(minify($maxi, %opt), $mini, "Give entire hash like this : %opt" );
$opt{encoding} = "UTF-16";
is(minify($maxi, %opt), $mini16, "Give entire hash like this : %opt (multiple keys/values)" );
is(minify($maxi, version => "42.0"), $mini, "Give hash like this : key => value" );
is(minify($maxi, version => "42.0", encoding => "UTF-16"), $mini16, "Give hash like this : key => value (multiple keys/values) (1)" );
is(minify($maxi, version => "0", version => "42.0", encoding => "UTF-16"), $mini16, "Give hash like this : key => value (multiple keys/values) (2 duplicate key)" );
is(minify($maxi, encoding => "UTF-16", version => "42.0"), $mini16, "Give hash like this : key => value (multiple keys/values) (3 change order)" );
is(minify($maxi, a => "", b => "", encoding => "UTF-16", version => "42.0"), $mini16, "Give exotic keys with empty content" );
is(minify($maxi, "encoding", "UTF-16", "version", "42.0"), $mini16, "Give hash with non-fat comma" );
is(minify($maxi, "", "", encoding => "UTF-16", version => "42.0"), $mini16, "Weird but will work" );

done_testing;

