use strict;
use warnings;
use Test::More tests => 1;

{
    package CustomSignature;

    use base qw/signatures/;

    use signatures;

    sub proto_unwrap ($class, $prototype) {
        return "my (\$prototype) = '$prototype';";
    }
}

BEGIN { CustomSignature->import }

sub foo (affe tiger) { $prototype }

is(foo(), 'affe tiger', 'overriding proto_unwrap');
