package Testing::Something;
use strict;
use warnings;

class Testing::Something {
    id_by => [
        prop1 => { is => 'String' },
        prop2 => { is => 'Integer' },
    ],
    has => [
        color => { is => 'Testing::Color', id_by => 'color_id' },
    ],
    is_abstract => 1,
    doc => 'A class with some properties',
};

sub a_method {
    1;
}

sub another_method {
    2;
}

1;
   
