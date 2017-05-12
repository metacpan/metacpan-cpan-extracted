# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { 
use_ok('WebSource::Envelope');
use_ok('WebSource::Logger');
use_ok('WebSource::Parser');
use_ok('WebSource') ;
use_ok('WebSource::Query');
use_ok('WebSource::Fetcher');
use_ok('WebSource::Extract');
use_ok('WebSource::Extract::xslt');
use_ok('WebSource::XMLParser');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

