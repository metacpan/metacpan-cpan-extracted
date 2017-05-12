use strict;

use Test;
use XML::SAX::Machines;
use XML::SAX::Machine;  ## Need to register the option names

my @tests = (
sub {
    ok(
        XML::SAX::Machines->processor_class_option(
            "XML::SAX::Machine",
            "ConstructWithHashedOptions"
        ) ? 1 : 0,
        1,
        "XML::SAX::Machine's ConstructWithHashedOptions",
    );
},
sub {
    ok(
        XML::SAX::Machines->processor_class_option(
            "XML::SAX::Pipeline",
            "ConstructWithHashedOptions"
        ) ? 1 : 0,
        1,
        "XML::SAX::Machine's ConstructWithHashedOptions",
    );
},

);

plan tests => scalar @tests ;

$_->() for @tests;
