use strict;
use warnings;

use Test2::V0;
use Test2::Require::Module 'IPC::Run3';

use IPC::Run3 qw( run3 );

my $code = <<'EOF';
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

my ($output);
run3(
    [ $^X, '-e', $code ],
    \undef,
    \$output,
    \$output,
);

like(
    $output,
    qr/\Qnot ok 2 - Unexpected warning: eek\E .+/,
    'warning event in subtest appears in TAP output'
);

done_testing();
