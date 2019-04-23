use strict;
use warnings;

use Capture::Tiny qw( capture );

use Test2::V0;

my $output = capture {

    # We expect this to exit non-zero since the test will fail.

    ## no critic (InputOutput::RequireCheckedSyscalls)
    system( $^X, '-e', <<'EOF' );
use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

ok(1);

subtest 'subt' => sub {
    ok(1);
    warn "eek";
    ok(2);
};

done_testing();
EOF

};

like(
    $output,
    qr/\Qnot ok 2 - Unexpected warning: eek\E .+/,
    'warning event in subtest appears in TAP output'
);

done_testing();
