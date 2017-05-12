#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    for my $test (keys %regex) {
        ok !$violated{$test}, $test or diag "$test appears on lines @{$violated{$test}}";
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    subtest $module => sub {
        not_in_file_ok($module =>
            'the great new $MODULENAME' => qr/ - The great new /,
            'boilerplate description'   => qr/Quick summary of what the module/,
            'stub function definition'  => qr/function[12]/,
            'module description'        => qr/One-line description of module/,
            'description'               => qr/A full description of the module/,
            'subs / methods'            => qr/section listing the public components/,
            'diagnostics'               => qr/A list of every error and warning message/,
            'config and environment'    => qr/A full explanation of any configuration/,
            'dependencies'              => qr/A list of all of the other modules that this module relies upon/,
            'incompatible'              => qr/any modules that this module cannot be used/,
            'bugs and limitations'      => qr/A list of known problems/,
            'contact details'           => qr/<contact address>/,
        );
    };
}

subtest 'README' => sub {
    not_in_file_ok((-f 'README' ? 'README' : 'README.pod') =>
        "The README is used..."       => qr/The README is used/,
        "'version information here'"  => qr/to provide version information/,
    );
};

subtest 'Changes' => sub {
    not_in_file_ok(Changes =>
        "placeholder date/time"       => qr(Date/time)
    );
};

module_boilerplate_ok('lib/W3C/SOAP.pm');
module_boilerplate_ok('lib/W3C/SOAP/Base.pm');
module_boilerplate_ok('lib/W3C/SOAP/Client.pm');
module_boilerplate_ok('lib/W3C/SOAP/Document.pm');
module_boilerplate_ok('lib/W3C/SOAP/Document/Node.pm');
module_boilerplate_ok('lib/W3C/SOAP/Exception.pm');
module_boilerplate_ok('lib/W3C/SOAP/Header.pm');
module_boilerplate_ok('lib/W3C/SOAP/Header/Security.pm');
module_boilerplate_ok('lib/W3C/SOAP/Header/Security/Username.pm');
module_boilerplate_ok('lib/W3C/SOAP/Manual/XSD.pod');
module_boilerplate_ok('lib/W3C/SOAP/Parser.pm');
module_boilerplate_ok('lib/W3C/SOAP/Utils.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/Binding.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/InOutPuts.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/Message.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/Node.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/Operation.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/Policy.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/Port.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/PortType.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Document/Service.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Meta/Method.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Parser.pm');
module_boilerplate_ok('lib/W3C/SOAP/WSDL/Utils.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Document.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Document/ComplexType.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Document/Element.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Document/List.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Document/Node.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Document/SimpleType.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Document/Type.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Parser.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Traits.pm');
module_boilerplate_ok('lib/W3C/SOAP/XSD/Types.pm');
module_boilerplate_ok('bin/get-wsdl-resources');
module_boilerplate_ok('bin/wsdl-parser');
module_boilerplate_ok('bin/xsd-parser');
done_testing();
