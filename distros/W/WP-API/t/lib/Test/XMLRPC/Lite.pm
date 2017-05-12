package Test::XMLRPC::Lite;

use strict;
use warnings;

use parent 'XMLRPC::Lite';

our $CallTest;
our $ResponseXML;

sub call {
    shift;
    $CallTest->(@_) if $CallTest;

    die 'No response XML defined' unless $ResponseXML;
    return XMLRPC::Deserializer->deserialize($ResponseXML);
}

1;
