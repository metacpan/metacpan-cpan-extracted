
package URT::34Baseclass;

use strict;
use warnings;
use URT;

class URT::34Baseclass {
    is_transactional => 0,
    has => [
        parent => { is => 'URT::34Subclass', id_by => 'parent_id' },
        thingy => { is => 'URT::Thingy', id_by => 'thingy_id' }
    ]
};

1;

