use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok 'Test::SetupTeardown';

{ # bare: no setup, no teardown

    my $environment = Test::SetupTeardown->new;
    my $did_i_run = 0;

    $environment->run_test('this is the description',
                           sub { $did_i_run = 1 });

    is($did_i_run, 1,
       q{... and a bare environment runs the test fine});

    throws_ok(sub { $environment->run_test('this is the description',
                                           sub { die 'supercalifragilistiexpialidocious' }) },
              qr/supercalifragilistiexpialidocious/,
              q{... and exceptions thrown from within the test are forwarded});

}

{ # setup, no teardown

    my $setup_count = 0;
    my $environment = Test::SetupTeardown->new(setup => sub { $setup_count++ });
    my $did_i_run = 0;

    $environment->run_test('this is the description',
                           sub { $did_i_run = 1 });

    is($did_i_run, 1,
       q{... and an environment with setup runs the test fine});

    is($setup_count, 1,
       q{... and the setup closure has run});

    throws_ok(sub { $environment->run_test('this is the description',
                                           sub { die 'supercalifragilistiexpialidocious' }) },
              qr/supercalifragilistiexpialidocious/,
              q{... and exceptions thrown from within the test are forwarded});

    is($setup_count, 2,
       q{... and the setup closure has still run});

}

{ # teardown, no setup

    my $teardown_count = 0;
    my $environment = Test::SetupTeardown->new(teardown => sub { $teardown_count++ });
    my $did_i_run = 0;

    $environment->run_test('this is the description',
                           sub { $did_i_run = 1 });

    is($did_i_run, 1,
       q{... and an environment with setup runs the test fine});

    is($teardown_count, 1,
       q{... and the teardown closure has run});

    throws_ok(sub { $environment->run_test('this is the description',
                                           sub { die 'supercalifragilistiexpialidocious' }) },
              qr/supercalifragilistiexpialidocious/,
              q{... and exceptions thrown from within the test are forwarded});

    is($teardown_count, 2,
       q{... and the teardown closure has still run});

}

done_testing;
