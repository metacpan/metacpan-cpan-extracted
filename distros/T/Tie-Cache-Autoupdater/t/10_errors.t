#
#===============================================================================
#
#  DESCRIPTION:  A source subroutine that dies, or that was never given,
#                produces a warning and an undef read - and the failed key
#                is retried on the next read instead of waiting out the
#                timeout.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 13;

use_ok('Tie::Cache::Autoupdater');

tie my %cache, 'Tie::Cache::Autoupdater';

my @warnings;

sub read_key {
    my $key = shift;

    @warnings = ();
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    return $cache{ $key };
}

my $attempts = 0;
my $broken   = 1;

$cache{flaky} = {
    timeout => 60,
    source  => sub { $attempts++; die "boom\n" if $broken; return 'good' }
};

is ( read_key('flaky'), undef, 'a read whose source dies returns undef' );
is ( scalar @warnings, 1, 'and emits exactly one warning' );
like ( $warnings[0], qr/Check source subroutine for key flaky/,
    'the warning names the failing key' );
like ( $warnings[0], qr/boom/, 'and quotes the error raised by the source' );

is ( read_key('flaky'), undef, 'the failure is not cached as a value' );
is ( $attempts, 2, 'the next read retries at once, without waiting for the timeout' );

$broken = 0;

is ( read_key('flaky'), 'good', 'a later successful call provides a value' );
is ( $attempts, 3, 'which took one more call to the source' );
is ( read_key('flaky'), 'good', 'and that value is cached from then on' );
is ( $attempts, 3, 'without calling the source again' );

# A key registered without a source has nothing to call, which is reported
# the same way as a source that dies.
$cache{no_source} = { timeout => 60 };

is ( read_key('no_source'), undef, 'a key registered without a source reads as undef' );
like ( $warnings[0], qr/Check source subroutine for key no_source/,
    'and is reported as a problem with that key' );

1;

