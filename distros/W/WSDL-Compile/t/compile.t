
use strict;
use warnings;

use Test::More tests => 13;
use Test::NoWarnings;
use Test::Exception;

use lib qw( t/lib );

BEGIN {
    use_ok "WSDL::Compile";
};

my $compile;
my $wsdl;
my $xml_compile;
my $parser;

# Test
lives_ok {
    $compile = WSDL::Compile->new(
        namespace => 'WSDL::Compile::%s::Op::%s::%s',
        service => {
            name => 'Test',
            tns => 'http://localhost/Test',
            documentation => 'Test Web Service',
        },
        operations => [
            qw/
                Example
            /
        ],
    );
} "WSDL::Compile object created for Test service";
isa_ok $compile, "WSDL::Compile", '$compile';

lives_ok {
    $wsdl = $compile->generate_wsdl();
} "...and WSDL generated fine";

lives_ok {
    $parser = XML::LibXML->new;
    $parser->parse_string( $wsdl );
} "...and is a valid xml";

# Test2
lives_ok {
    $compile = WSDL::Compile->new(
        namespace => 'WSDL::Compile::%s::Op::%s::%s',
        service => {
            name => 'Test2',
            tns => 'http://localhost/Test2',
            documentation => 'Test2 Web Service',
        },
        operations => [
            qw/
                Example
            /
        ],
    );
} "WSDL::Compile object created for Test2 service";
isa_ok $compile, "WSDL::Compile", '$compile';

lives_ok {
    $wsdl = $compile->generate_wsdl();
} "...and WSDL generated fine";

lives_ok {
    $parser = XML::LibXML->new;
    $parser->parse_string( $wsdl );
} "...and is a valid xml";

# Test3
lives_ok {
    $compile = WSDL::Compile->new(
        namespace => 'WSDL::Compile::%s::Op::%s::%s',
        service => {
            name => 'Test3',
            tns => 'http://localhost/Test3',
            documentation => 'Test3 Web Service',
        },
        operations => [
            qw/
                Example
            /
        ],
    );
} "WSDL::Compile object created for Test3 service";
isa_ok $compile, "WSDL::Compile", '$compile';

dies_ok {
    $compile->generate_wsdl();
} "...and WSDL fails with redefined attr";

