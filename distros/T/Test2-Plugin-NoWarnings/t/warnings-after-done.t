use strict;
use warnings;

use Test2::Require::Module 'IPC::Run3';
use Test2::V0;
use Test2::Plugin::NoWarnings;

use IPC::Run3 qw( run3 );

my $code = <<'EOF';
use Test2::V0;
use Test2::Plugin::NoWarnings;

ok( 1, 'this is fine' );

done_testing();

warn "This should not cause a failure but should be visible\n";
EOF

my ( $stdout, $stderr );
run3(
    [ $^X, '-e', $code ],
    \undef,
    \$stdout,
    \$stderr,
);

unlike(
    $stdout, 'not ok',
    'all tests pass when test warns after done_testing()'
);

is( $?, 0, 'no error from test that warns after done_testing()' );

like(
    $stderr,
    qr/This should not cause a failure but should be visible\n/,
    'warning after done_testing() is seen on stderr output',
);

done_testing();
