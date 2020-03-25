package XS::STL::ErrorCode;
use strict;
use XS::Framework;

use overload
    '""'     => \&_op_string,
    'bool'   => \&_op_bool,
    '=='     => \&_op_eq,
    'eq'     => \&_op_eq,
    '&'      => \&_op_and,
;

1;
