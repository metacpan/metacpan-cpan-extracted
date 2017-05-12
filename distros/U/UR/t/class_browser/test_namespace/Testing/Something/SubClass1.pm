package Testing::Something::SubClass1;
use strict;
use warnings;

class Testing::Something::SubClass1 {
    is => 'Testing::Something',
    has => [
        age => { is => 'Integer' },
    ],
};

1;
