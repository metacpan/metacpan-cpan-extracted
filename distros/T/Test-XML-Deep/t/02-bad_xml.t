#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;

BEGIN {
	use_ok( 'Test::XML::Deep' );
}


{
    my $xml = <<EOXML;
<?xml version="1.0" encoding="UTF-8"?>
<example>
    <sometag>
</example>
EOXML

    test_out("not ok 1");
    test_fail(+8);
    test_diag(qq{Failed to parse 
# <?xml version="1.0" encoding="UTF-8"?>
# <example>
#     <sometag>
# </example>
# 
# XML::Parser error was: mismatched tag at line 4, column 2, byte 65\n# });
    cmp_xml_deeply($xml, { });
    test_test("fail works");
}

{
    my $xml = <<EOXML;
<?xml version="1.0" encoding="UTF-8"?>
<example>
    <som
</example>
EOXML

    test_out("not ok 1 - half a tag");
    test_fail(+8);
    test_diag(qq{Failed to parse 
# <?xml version="1.0" encoding="UTF-8"?>
# <example>
#     <som
# </example>
# 
# XML::Parser error was: not well-formed (invalid token) at line 4, column 0, byte 58\n# });
    cmp_xml_deeply($xml, { }, 'half a tag');
    test_test("fail works");
}

