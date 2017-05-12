#!/usr/bin/perl
# $Id: 10_sgmldtd.t 8 2008-10-22 07:16:55Z rjray $

# Exercise the SGML/XML DTD tests

use strict;
use warnings;
use vars qw($dir);

use File::Spec;
use XML::LibXML;
use Test::Builder::Tester tests => 3;

# Testing this:
use Test::Formats::XML;

# $dir gets used with File::Spec->catfile() to get O/S-agnostic paths to the
# files used by the tests.
$dir = (File::Spec->splitpath(File::Spec->rel2abs($0)))[1];

# Used and re-used
our($dtd, $xmlcontent);

# Start with some simple static-string content
$dtd = <<END_DTD_001;
<!ELEMENT data (#PCDATA)>
<!ELEMENT container (data+)>
END_DTD_001

test_out("ok 1 - string+string");
test_out("not ok 2 - string+string fail");
test_out("ok 3 - string+string nested content");
is_valid_against_sgmldtd(q{<?xml version="1.0"?>
<data>foo</data>
}, $dtd, "string+string");
is_valid_against_sgmldtd(q{<?xml version="1.0"?>
<container></container>
}, $dtd, "string+string fail");
is_valid_against_sgmldtd(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $dtd, "string+string nested content");
test_test(name => 'basic string+string arguments', skip_err => 1);

# Test the aliases with the same simple data
test_out("ok 1 - is_valid_against_dtd alias");
is_valid_against_dtd(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $dtd, "is_valid_against_dtd alias");
test_test(name => 'string+string arguments, is_valid_against_dtd alias',
          skip_err => 1);

test_out("ok 1 - sgmldtd_ok alias");
sgmldtd_ok(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $dtd, "sgmldtd_ok alias");
test_test(name => 'string+string arguments, sgmldtd_ok alias', skip_err => 1);

exit 0;
