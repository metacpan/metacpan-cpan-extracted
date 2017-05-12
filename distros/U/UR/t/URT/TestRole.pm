package URT::TestRole;

use strict;
use warnings;

use constant ROLE_METHOD_RETVAL => 1;

role URT::TestRole {
    has => [ 'role_param' ],
    requires => [ 'required_class_param', 'required_class_method' ],
};

sub role_method { ROLE_METHOD_RETVAL }

1;
