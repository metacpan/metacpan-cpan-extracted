
use Test::More tests  => 5;
use Test::Builder::Tester;
BEGIN { use_ok( 'Test::XML::Valid' ); }


# Basic test for success
    test_out('ok 1 - ./t/simple_valid.xhtml is valid XHTML');
    xml_file_ok('./t/simple_valid.xhtml');
    test_test('Basic Test::XML::Valid test for success');

# Test setting a custom message
    test_out('ok 1 - Simple File is Valid');
    xml_file_ok('./t/simple_valid.xhtml', 'Simple File is Valid');
    test_test('Setting a custom error message');

open (XML, "<./t/simple_valid.xhtml");
my $xml_string;
while (<XML>) {
    $xml_string .= $_;
}
close(XML);

# Basic test for success
    test_out('ok 1 - valid XHTML');
    xml_string_ok($xml_string);
    test_test('xml_string_ok() success');

# Test setting a custom message
    test_out('ok 1 - String is Valid');
    xml_string_ok($xml_string, 'String is Valid');
    test_test('xml_string_ok() custom error message');

# Basic test for failure
# What's a good way to test the failure output, since it's going
# to include a Perl library path, which will vary by installation? -mls
#     test_out('not ok 1 - ./t/basic.t is valid XHTML');
#     xml_file_ok('./t/basic.t');
#     test_test('Basic failure teset');




