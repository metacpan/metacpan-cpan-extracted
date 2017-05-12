use strict;
use Test::More tests => 5;

BEGIN { use_ok 'WebService::Google::Suggest' }

my $suggest = WebService::Google::Suggest->new();

isa_ok($suggest->ua, "LWP::UserAgent", "ua() retuens LWP");

my @data = $suggest->complete("google");
is($data[0]->{query}, "google maps", "google completes to google maps");
is($data[0]->{rank}, 0, "google is first");
is_deeply( [ $suggest->complete("udfg67a") ], [ ], "empty list" );

