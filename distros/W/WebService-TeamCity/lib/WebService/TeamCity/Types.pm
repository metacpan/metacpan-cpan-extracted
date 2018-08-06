package WebService::TeamCity::Types;

use strict;
use warnings;

our $VERSION = '0.04';

use Type::Library
    -base,
    -declare => qw( BuildStatus DateTimeObject JSONBool TestStatus );
use Type::Utils qw( class_type enum union );

enum BuildStatus, [qw( SUCCESS FAILURE ERROR UNKNOWN )];

enum TestStatus, [qw( SUCCESS FAILURE UNKNOWN )];

class_type DateTimeObject, { class => 'DateTime' };

union JSONBool, [
    class_type('JSON::PP::Boolean'),
    class_type('JSON::XS::Boolean'),
];

1;
