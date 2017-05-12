#!/usr/bin/env perl

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

test_ni_picture(create_ni_picture());

done_testing;
