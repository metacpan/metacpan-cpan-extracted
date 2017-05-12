#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More qw(no_plan);
use XML::Filter::ExceptionLocator;
use XML::SAX::ParserFactory;
require 't/Chucker.pm';

# XML::SAX::ExpatXS is the only one with a working document locator
$XML::SAX::ParserPackage = 'XML::SAX::ExpatXS';

my $chucker = XML::Filter::Chucker->new('ok');
my $filter = XML::Filter::ExceptionLocator->new(Handler => $chucker);
isa_ok($filter, 'XML::Filter::ExceptionLocator');
my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);
ok($parser);

# should chuck on ok, line 2, column >= 1
eval { $parser->parse_uri('t/ok.xml') };
my $err = $@;
isa_ok($err, 'XML::SAX::Exception');
like($err, qr/Found a <ok>!/);
is($err->{LineNumber},   2);
ok($err->{ColumnNumber} >= 1);
like($err, qr/Found a <ok>!\s+\[Ln:\s+2/);

# should chuck on line 5, column >= 6
eval { $parser->parse_uri('t/bigger.xml') };
$err = $@;
isa_ok($err, 'XML::SAX::Exception');
like($err, qr/Found a <ok>!/);
is($err->{LineNumber},   5);
ok($err->{ColumnNumber} >= 6);
like($err, qr/Found a <ok>!\s+\[Ln:\s+5/);
