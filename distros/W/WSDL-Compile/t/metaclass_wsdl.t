
use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;

BEGIN {
    use_ok "WSDL::Compile::Meta::Attribute::WSDL";
};

{
    package WSDL::Compile::Example::Class;
    use Moose;

    has 'wsdl_attr_1' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'Str',
    );

    no Moose;
}

lives_ok {
    my $obj = WSDL::Compile::Example::Class->new(
        wsdl_attr_1 => 'example',
    );
} "object with metaclass attribute created";
