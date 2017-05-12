#!/use/bin/perl
use warnings;
use strict;
use lib 'lib';
use Test::More;
use Test::Exception;
use WebService::VaultPress::Partner::Request::Usage;

# Expected Defaults

ok my $vp = WebService::VaultPress::Partner::Request::Usage->new();

is $vp->api, "https://partner-api.vaultpress.com/gtm/1.0/summary";

# Constructure assigns accessors as expected.

ok $vp = WebService::VaultPress::Partner::Request::Usage->new(
    api => "Daily, I am amazed at your inexhaustible ability to just live.",
);

is $vp->api, "Daily, I am amazed at your inexhaustible ability to just live.",
    "Api method expected.";

isnt $vp->api, "Only if I plead guilty which is, of course, unacceptable." .
    "I have to worry about a three strikes law since I plan to commit future" . 
    " crimes.",
    "Api method is consistent.";

done_testing;
