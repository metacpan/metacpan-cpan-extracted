use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WWW/Salesforce.pm',
    'lib/WWW/Salesforce/Constants.pm',
    'lib/WWW/Salesforce/Deserializer.pm',
    'lib/WWW/Salesforce/Serializer.pm',
    'lib/WWW/Salesforce/Simple.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-load-salesforce-simple.t',
    't/01-load-salesforce.t',
    't/WWW-Salesforce-oauth.t',
    't/WWW-Salesforce.t',
    't/www_sf_utils.t'
);

notabs_ok($_) foreach @files;
done_testing;
