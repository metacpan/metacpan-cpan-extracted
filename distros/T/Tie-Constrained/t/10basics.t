use strict;

BEGIN {
    eval {
      require warnings;
      warnings->import;
      1;
    }
    or do {
      $^W = 1;
    };
} # for pre- warnings.pm perls, thanks, J ben Jore

use Test::Simple tests => 9;

use Tie::Constrained;

BEGIN {
    my $v = qr/[aeiouy]/;
    my $c = qr/[bcdfghjklmnpqrstvwxz]/;
    sub validate { shift() =~ /^$c$v$v$c$c$/o }
}

{

    my $value;
    tie $value, 'Tie::Constrained', \&validate;

    ok( eval { my $test = $value; 1 },
        'FETCH for undefined value' );

    ok( ! eval { $value = 'quasi'; 1 },
        'STORE for invalid value' );

    ok( eval { $value = 'quash'; 1 },
        'STORE for valid value' );

    ok( eval { $value =~ s/a/i/; 1; },
        'Valid modification' );

    ok( ! eval { $value =~ s/h/e/; 1; },
        'Invalid modification: substitution' );

    ok( ! eval { $value++; 1;},
        'Invalid modification: post-increment' );

    ok( ! eval { ++$value; 1; },
        'Invalid modification: pre-increment' );
}

{
    my $value;
    ok( ! eval {
                   tie $value, 'Tie::Constrained',
                       \&validate,
                       'suite';
                   1;
          },
        'Invalid initial value' );
}

{
    my $value;
    ok( eval {
                tie $value, 'Tie::Constrained',
                    \&validate,
                    'suits';
                1;
             },
        'Valid initial value' );
}

