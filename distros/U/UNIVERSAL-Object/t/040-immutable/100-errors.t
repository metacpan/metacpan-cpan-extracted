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
    like($@, qr/^Invalid BLESS args for This\:\:Will\:\:Not\:\:Work\, unsupported REPR type \(REGEXP\)/, '... got the expected error');
}
