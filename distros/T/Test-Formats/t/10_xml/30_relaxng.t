#!/usr/bin/perl
# $Id: 30_relaxng.t 8 2008-10-22 07:16:55Z rjray $

# Exercise the RelaxNG tests

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
our($relaxng, $xmlcontent);

# Start with some simple static-string content
$relaxng = <<END_RELAXNG_001;
<?xml version="1.0"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
    <start>
        <choice>
            <ref name="container.elem" />
            <ref name="data.elem" />
        </choice>
    </start>
    <define name="data.elem">
        <element>
            <name ns="">data</name>
            <text />
        </element>
    </define>
    <define name="container.elem">
        <element>
            <name ns="">container</name>
            <oneOrMore>
                <ref name="data.elem" />
            </oneOrMore>
        </element>
    </define>
</grammar>
END_RELAXNG_001

test_out("ok 1 - string+string");
test_out("not ok 2 - string+string fail");
test_out("ok 3 - string+string nested content");
is_valid_against_relaxng(q{<?xml version="1.0"?>
<data>foo</data>
}, $relaxng, "string+string");
is_valid_against_relaxng(q{<?xml version="1.0"?>
<container></container>
}, $relaxng, "string+string fail");
is_valid_against_relaxng(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $relaxng, "string+string nested content");
test_test(name => 'basic string+string arguments', skip_err => 1);

test_out("ok 1 - is_valid_against_rng alias");
is_valid_against_rng(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $relaxng, "is_valid_against_rng alias");
test_test(name => 'string+string arguments, is_valid_against_rng alias',
          skip_err => 1);

test_out("ok 1 - relaxng_ok alias");
relaxng_ok(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $relaxng, "relaxng_ok alias");
test_test(name => 'string+string arguments, relaxng_ok alias', skip_err => 1);

exit 0;
