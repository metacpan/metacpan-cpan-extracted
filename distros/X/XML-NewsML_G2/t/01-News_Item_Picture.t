#!/usr/bin/env perl

use Test::MockTime 'set_fixed_time';

BEGIN {
    set_fixed_time('2012-01-01T13:00:00Z');
}

use utf8;
use Test::More;
use DateTime::Format::XSD;
use XML::LibXML;

use version;

use lib 't';
use NewsML_G2_Test_Helpers qw(create_ni_picture test_ni_picture :vars);

use warnings;
use strict;

use XML::NewsML_G2;

test_ni_picture( create_ni_picture(), 'NewsItemPicture' );

done_testing;
