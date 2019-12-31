package XS::STL::ErrorCategory;
use strict;
use XS::Framework;

use overload
    '""'     => \&_op_string,
    '=='     => \&_op_eq,
    'eq'     => \&_op_eq,
;

1;
