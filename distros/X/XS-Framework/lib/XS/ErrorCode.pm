package XS::ErrorCode;
use strict;
use XS::Framework;

use overload
    '""'     => \&_op_string,
    'bool'   => \&_op_bool,
    '=='     => \&_op_eq,
    'eq'     => \&_op_eq,
;

1;
