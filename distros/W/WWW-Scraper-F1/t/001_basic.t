use v5.12;
use strict;
use warnings;
use warnings   qw(FATAL utf8);
use open       qw(:std :utf8);
use charnames  qw(:full :short);

use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Scraper::F1;
use URI::file;

use Test::More;

BEGIN { use_ok('WWW::Scraper::F1') }
my $default_uri = URI::file->new_abs('t/assets/default.html');
my $driver_uri = URI::file->new_abs('t/assets/2012.html');
my $test_hash = {upcoming => $default_uri, championship => $driver_uri };

ok(ref(get_upcoming_race( { test =>  $test_hash} ))      eq "HASH" , 'get_upcoming_race returned hash_ref');
ok(ref(get_top_championship({ test => $test_hash }))   eq "ARRAY", 'get_top_championship return array_ref');

my $top  = get_top_championship( {test => $test_hash});
my $race = get_upcoming_race({test => $test_hash});

is(scalar @$top, 5, 'top_championsip without arguments returned 5 elements');
is(scalar @{ get_top_championship( { test => $test_hash, length => 10 } ) }, 10 , 'top_championship with length option 10, returns 10 elements');

like($top->[0]{points} , qr/\d{0,3}/ , 'get_top_championship returns points in its hash');

like($race->{countdown} ,  qr/^(\d{1,3} days)?(\d{1,2} hours)?.*$/ , 'upcoming race countdown pattern match');


done_testing();

#for tomorow me,
#  lets make dist::zille make a Build.pl file so it will hopefully run its tests on windows
