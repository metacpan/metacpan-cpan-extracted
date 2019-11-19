#!/usr/bin/env perl

use Test::MockTime 'set_fixed_time';

BEGIN {
    set_fixed_time('1325422800');
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
