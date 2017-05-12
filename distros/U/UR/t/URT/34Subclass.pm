
package URT::34Subclass;

use strict;
use warnings;
## dont "use URT::34Baseclass";
use URT;

class URT::34Subclass {
    isa => 'URT::34Baseclass',
    is_transactional => 0,
    has => [
        some_other_stuff => { is => 'SCALAR' },
        abcdefg => { }
    ]
};

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(
        thingy => URT::Thingy->create
    );

    return $self;
}

1;

