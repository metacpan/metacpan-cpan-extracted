#!/usr/bin/perl 

use strict;
use warnings;

use WSDL::Compile;

my $gen = WSDL::Compile->new(
    service => {
        name => 'Example',
        tns => 'http://localhost/Example',
        documentation => 'Example Web Service',
    },
    operations => [
        qw/
            CreateCustomer
        /
    ],
);

my $wsdl = $gen->generate_wsdl();

print $wsdl;

