#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object::Immutable');
}

{
    {
        package This::Will::Not::Work;

        use strict;
        use warnings;

        our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object::Immutable') }

        sub REPR   { qr// }
        sub CREATE { $_[0]->REPR }
    }

    eval { This::Will::Not::Work->new };
    like($@, qr/^Unsupported REPR type:\ \(\?\^\:\)/, '... got the expected error');
}
