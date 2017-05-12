package WebService::TeamCity::Types;

use strict;
use warnings;

our $VERSION = '0.03';

use Type::Library
    -base,
    -declare => qw( BuildStatus DateTimeObject TestStatus );
use Type::Utils qw( class_type enum );

enum BuildStatus, [qw( SUCCESS FAILURE ERROR UNKNOWN )];

enum TestStatus, [qw( SUCCESS FAILURE UNKNOWN )];

class_type DateTimeObject, { class => 'DateTime' };

1;
