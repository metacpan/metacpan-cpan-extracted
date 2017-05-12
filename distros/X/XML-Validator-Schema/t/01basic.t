#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw(no_plan);
use_ok('XML::Validator::Schema') or exit;

# specifying a non-existent schema file should fail
use XML::SAX::ParserFactory;

eval {
    my $parser = XML::SAX::ParserFactory->parser(
     Handler => XML::Validator::Schema->new(file => 'nonexistent.xsd'));
};
like($@, qr/does not exist/);

