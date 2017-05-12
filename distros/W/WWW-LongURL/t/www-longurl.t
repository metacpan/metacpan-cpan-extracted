#!perl
use strict;
use warnings;
use LWP::Online ':skip_all';

# Skip online tests if we can't contact the LongURL API..
BEGIN {
    require Test::More;
    unless ( LWP::Online::online() ) {
        Test::More->import(
            skip_all => 'Test requires a working internet connection'
        );
    }
}

use Test::More;

use_ok('WWW::LongURL') or die;
done_testing();
