# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More 'no_plan'; #skip_all => "Turn off for development"; # See perldoc Test::More for details
use strict;
use Data::Dumper;

#Is the client-code even installed?
BEGIN { 
    use_ok('XML::SemanticCompare');
};


END {
  
};

my $C = XML::SemanticCompare->new();

isa_ok( $C, 'XML::SemanticCompare',"isa XML::SemanticCompare") 
  or die("is not a XML::SemanticCompare ... cannot continue");

############           compare XML with attributes      ###############

my $control = 'xmls/getDragonAlleleLocus-control.xml';
my $test    = 'xmls/getDragonAlleleLocus-control.xml';

# compare the same document
ok($C->compare($control, $test), "Same document considered the same!");

# compare XML document with one that contains loads of whitespace in it, but are semantically similar
$test    = 'xmls/getDragonAlleleLocus-lots-whitespace.xml';
ok($C->compare($control, $test), "Rightfully ignored whitespace when comparing 2 semantically similar docs");

# compare control to test file that has extra child
$test    = 'xmls/getDragonAlleleLocus-extra-child.xml';
ok(!$C->compare($control, $test), "XML with extra child rightfully considered different!");

# compare control to test file that has renamed root
$test    = 'xmls/getDragonAlleleLocus-root-renamed.xml';
ok(!$C->compare($control, $test), "XML with different root elements rightfully considered different!");

# compare control to test file that has root with different nsuri
$test    = 'xmls/getDragonAlleleLocus-root-nsuri-different.xml';
ok(!$C->compare($control, $test), "compare control to test file that has root with different nsuri!");

# compare XML document with one that defines a default ns and uses no prefix
$test    = 'xmls/getDragonAlleleLocus-no_prefix-test.xml';
ok($C->compare($control, $test), "Compare XML document with one that defines a default ns and uses no prefix");

# compare XML document with one that is missing some of the prefixes but uses a default one
$test    = 'xmls/getDragonAlleleLocus-missing-prefixes.xml';
ok($C->compare($control, $test), "compare XML document with one that is missing some of the prefixes but defines a default one");

# compare XML document with one that is missing some of the prefixes and does not define a default one
$test    = 'xmls/getDragonAlleleLocus-missing-prefixes-no-default.xml';
ok(!$C->compare($control, $test), "compare XML document with one that is missing some of the prefixes and does not defines a default one");

# compare XML document with one that has different attribute values
$test    = 'xmls/getDragonAlleleLocus-different-attribute-values.xml';
ok(!$C->compare($control, $test), "compare XML document with one that has different attribute values");

# compare XML document with one that has different attribute names
$test    = 'xmls/getDragonAlleleLocus-different-attribute-names.xml';
ok(!$C->compare($control, $test), "compare XML document with one that has different attribute names");

# set use_attr to false and compare docs that have different attribute names and values
$C->use_attr(undef);
ok(!$C->use_attr, "use_attr successfully set");

# compare XML document with one that has different attribute values
$test    = 'xmls/getDragonAlleleLocus-different-attribute-values.xml';
ok($C->compare($control, $test), "compare XML document with one that has different attribute values while use_attr is false");

# compare XML document with one that has different attribute names
$test    = 'xmls/getDragonAlleleLocus-different-attribute-names.xml';
ok($C->compare($control, $test), "compare XML document with one that has different attribute names while use_attr is false");

# set use_attr to true
$C->use_attr(1);
ok($C->use_attr, "use_attr successfully set");

# set trim to false
$C->trim(undef);
ok(!$C->trim, "trim successfully set");

# set trim to true
$C->trim(1);
ok($C->trim, "trim successfully set");

# test xml with unordered children
# the control doc
$control = 'xmls/getUnitprotDescriptorsByKeyword-control-output.xml';

# compare the same document
ok($C->compare($control, $control), "Same document considered the same!");

# ordering of children are different
$test = 'xmls/getUnitprotDescriptorsByKeyword-test-output.xml';
ok($C->compare($control, $test), "compare XML document when the ordering of children are different");

# ordering of children are different and lots of whitespace
$test = 'xmls/getUnitprotDescriptorsByKeyword-extra-whitespace.xml';
ok($C->compare($control, $test), "compare XML document when the ordering of children are different and lots of whitespace");

# ordering of children are different and lots of whitespace and trim set to false
$C->trim(undef);
$test = 'xmls/getUnitprotDescriptorsByKeyword-extra-whitespace.xml';
ok(!$C->compare($control, $test), "compare XML document when the ordering of children are different and lots of whitespace and trim set to false");$C->trim(undef);

# set trim back to true
$C->trim(1);
ok($C->trim, "Set trim back to true");

# compare same document that has different prefix
$test = 'xmls/getUnitprotDescriptorsByKeyword-test-output-foo-prefix.xml';
ok($C->compare($control, $test), "compare same document that has different prefix");

# compare same document that has no prefix
$test = 'xmls/getUnitprotDescriptorsByKeyword-test-output-no-prefix.xml';
ok($C->compare($control, $test), "compare same document that has no prefix");

# test xpath
my $xpath = '/moby:MOBY/moby:mobyContent/moby:mobyData/moby:Collection/moby:Simple';
ok($C->test_xpath($xpath, $control), "XPATH test: are there any moby:Simple elements?");

$xpath = '/moby:MOBY/moby:mobyContent/moby:mobyData/moby:Collection/Simple';
ok(!$C->test_xpath($xpath, $control), "XPATH test: are there any Simple elements?");

$xpath = '/moby:MOBY/moby:mobyContent/moby:mobyData/moby:Collection[@moby:articleName]';
ok($C->test_xpath($xpath, $control), "XPATH test: are there any moby:Collection elements with a moby:articleName attribute?");
