#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('WWW::DME');
    use_ok('WWW::DNSMadeEasy');
    use_ok('WWW::DNSMadeEasy::Domain');
    use_ok('WWW::DNSMadeEasy::Domain::Record');
}

done_testing;
