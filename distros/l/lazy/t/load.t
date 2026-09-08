use strict;
use warnings;

use lazy;

use Capture::Tiny qw( capture );
use Test::More import => [qw( diag done_testing is_deeply like )];

# t/load.t is the fast, offline smoke test for lazy's @INC hook.
#
# It must NOT hit the network or install anything (GH#39). Driving the real
# App::cpm::CLI->run for a deliberately-missing module forces an HTTPS resolve
# against cpanmetadb; on a box without IO::Socket::SSL et al. that resolve
# re-enters lazy's own @INC hook and silently installs a cascade of TLS
# modules into the user's global perl as a side effect of `make test`.
#
# So we stub run() the same way t/pass-through-args.t does (a plain glob
# redefine — no extra prereq) and keep `use lazy;` with its default -g so the
# global-install code path is still exercised. The stub makes an install
# impossible regardless of -g, which is why -L is not needed here. The real
# darkpan install path is covered by t/local-install-via-args.t.
my @called;
{
    require App::cpm::CLI;
    no warnings 'redefine';
    *App::cpm::CLI::run = sub {
        shift;
        push @called, [@_];

        # Emulate cpm's behaviour for an unresolvable module: print a FAIL
        # line to stderr and return non-zero rather than dying.
        print STDERR "FAIL install Local::404\n";
        return 1;
    };
}

my ($cb) = grep { ref $_ eq 'CODE' } @INC;
my ( $stdout, $stderr, @result ) = capture { $cb->( undef, 'Local::404' ) };

my $args_ok = is_deeply(
    \@called,
    [ [ 'install', '-g', 'Local::404' ] ],
    'hook forwards the -g default install to App::cpm::CLI->run'
);
my $like_ok
    = like( $stderr, qr{FAIL}, 'failed install surfaces cpm FAIL output' );
my $is_ok
    = is_deeply( \@result, [], 'returns empty list after install attempt' );

unless ( $args_ok && $like_ok && $is_ok ) {
    diag 'STDOUT: ' . $stdout;
    diag 'STDERR: ' . $stderr;
}

done_testing();
