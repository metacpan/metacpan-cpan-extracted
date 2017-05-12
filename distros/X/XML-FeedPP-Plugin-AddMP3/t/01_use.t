# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-FeedPP-Plugin-AddMP3.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
use XML::FeedPP;
BEGIN { use_ok('XML::FeedPP::Plugin::AddMP3') };
