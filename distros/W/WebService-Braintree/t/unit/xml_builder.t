# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree::Xml qw(hash_to_xml xml_to_hash);
use WebService::Braintree::TestHelper;

sub check_round_trip {
    my ($data, $print_xml) = @_;

    my $xml = hash_to_xml($data);
    note($xml) if $print_xml;

    is_deeply xml_to_hash($xml), $data
}

subtest "generated simple xml" => sub {
    TODO: {
        local $TODO = "undef doesn't flip back properly";
        check_round_trip({key => undef}, 1);
    }
    check_round_trip({key => "value"});
    check_round_trip({key => {subkey => "value2", subkey2 => "value3"}});
    check_round_trip({key => {subkey => {subsubkey => "value3"}}});
    check_round_trip({keys => [{subkey => "value"}]}, 1);
    check_round_trip({root => {keys => [{subkey => "value"}, {subkey2 => "value2"}]}}, 1);
};

subtest "generate arrays correctly" => sub {
    my $actual = hash_to_xml({search => {ids => [1, 2, 3]}});
    my $expected = '<?xml version="1.0" encoding="UTF-8"?>
<search>
  <ids type="array">
    <item>1</item>
    <item>2</item>
    <item>3</item>
  </ids>
</search>
';
    is $actual, $expected;
};

done_testing();
