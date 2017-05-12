#!/usr/bin/perl
# $Id: 05_api_baseclass.t 37 2006-10-13 04:10:47Z  $

use strict;

use File::Basename 'dirname';
use Test::More tests => 15;

use WebService::ISBNDB::API;

do (dirname $0) . '/util.pl';

for (qw(Authors Books Categories Publishers Subjects))
{
    is(WebService::ISBNDB::API->class_for_type($_),
       "WebService::ISBNDB::API::$_",
       "Class for $_ type");
}

my $obj = WebService::ISBNDB::API->new();
isa_ok($obj, 'WebService::ISBNDB::API');

# Check type
is($obj->get_type(), 'API', 'Object type');
# Check the default protocol, which is set by the Class::Std configuration
is($obj->get_protocol(), 'REST', 'Class-default protocol is REST');
undef $obj;

my $key = api_key();
WebService::ISBNDB::API->set_default_api_key($key);
WebService::ISBNDB::API->set_default_protocol('soap');

$obj = WebService::ISBNDB::API->new();
is($obj->get_default_api_key, $key, 'Default API key');
is($obj->get_default_protocol, 'SOAP', 'Default protocol');
is($obj->get_api_key, $key, 'Object got default API key');

$obj = WebService::ISBNDB::API->new({ api_key => 'XXX' });
is($obj->get_api_key, 'XXX', 'Object got user-specified API key');

# Test adding and removing types
$obj->add_type('NewType', 'ISBNDB::NewType');
is($obj->class_for_type('NewType'), 'ISBNDB::NewType', 'Adding a new type');
$obj->remove_type('NewType');
is($obj->class_for_type('NewType'), undef, 'Removing user-defined type');

# Test attempting to remove a core type
eval { $obj->remove_type('Books'); };
like($@, '/Cannot remove a core type/i', 'Try to remove core types');

exit;
