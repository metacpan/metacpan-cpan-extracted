#!/usr/bin/perl
# $Id: 05_xml_parsing.t 4 2008-10-21 10:59:44Z rjray $

# Test the parsing-only tests of Test::Formats::XML

use strict;
use warnings;
use vars qw($dir);

use File::Spec;
use XML::LibXML;
use Test::Builder::Tester tests => 1;

# Testing this:
use Test::Formats::XML;

# $dir gets used with File::Spec->catfile() to get O/S-agnostic paths to the
# files used by the tests.
$dir = (File::Spec->splitpath(File::Spec->rel2abs($0)))[1];

# Used and re-used
our ($xmlcontent);

test_out("ok 1 - string");
test_out("not ok 2 - string fail");
is_well_formed_xml(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, "string");
is_well_formed_xml(q{<?xml version="1.0"?>
<container><data>foo<data></container>
}, "string fail");
test_test(name => 'basic string argument', skip_err => 1);

exit 0;
