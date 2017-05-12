#!perl -T

use strict;
use warnings;
use Test::More tests => 2;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;

BEGIN {
	use_ok( 'Test::XML::Deep' );
}


{
    my $xml = <<EOXML;
<?xml version="1.0" encoding="UTF-8"?>
<example>
    <sometag attribute="value">some data</sometag>
    <sometag attribute="other">more data</sometag>
</example>
EOXML

    my $expected = { sometag => [ { attribute => 'value',
                                    content   => 'some data'
                                 },
                               ]
                   };

    test_out("not ok 1");
    test_fail(+4);
    test_diag('Compared array length of $data->{"sometag"}
#    got : array with 2 element(s)
# expect : array with 1 element(s)');
    cmp_xml_deeply($xml, $expected);
    test_test("fail works");
}


