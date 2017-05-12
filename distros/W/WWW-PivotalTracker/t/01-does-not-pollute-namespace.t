#!perl -T

use strict;
use warnings;

use Test::Most;

use WWW::PivotalTracker;

my $num_tests = @WWW::PivotalTracker::EXPORT_OK;
$num_tests += @WWW::PivotalTracker::EXPORT;

plan tests => $num_tests;

foreach (@WWW::PivotalTracker::EXPORT, @WWW::PivotalTracker::EXPORT_OK) {
    ok(!__PACKAGE__->can($_), "WWW::PivotalTracker doesn't leak: $_");
}
