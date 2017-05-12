use strict;
use warnings;

package InterpolationTest;
use self;


sub new {
    return bless {}, self;
}

sub hello {
    "hello";
}

sub test_1 {
    return "${\( self->hello )}";
};

sub test_2 {
    return "@{[ self->hello ]}";
};

1;
