#!perl

use strict;
use warnings;
use Test::More;

#	use Log::Any::Adapter;
#	use Log::Log4perl;
#	Log::Any::Adapter->set('Log4perl');
#	Log::Log4perl::init('./log4perl.conf');

BEGIN {
    use_ok 'Web::Solid::Auth';
}

require_ok 'Web::Solid::Auth';

done_testing;
