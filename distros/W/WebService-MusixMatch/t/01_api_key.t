use strict;
use Test::More 0.98;
use WebService::MusixMatch;


SKIP: {
    skip q|Not exists $ENV{'MUSIXMATCH_API_KEY'}|, 2 unless exists $ENV{MUSIXMATCH_API_KEY};

    my $musixmatch = new WebService::MusixMatch;
    ok $musixmatch->api_key, '$ENV{MUSIXMATCH_API_KEY}';
    is $musixmatch->api_key, $ENV{MUSIXMATCH_API_KEY};

}

my $musixmatch = new WebService::MusixMatch(
    'api_key' => 'DUMMY_API_KEY',
);
is $musixmatch->api_key, 'DUMMY_API_KEY';


done_testing;

