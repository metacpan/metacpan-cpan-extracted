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

use Test::More tests => 24;

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
is ( scalar @warnings, 1, 'and emits exactly one warning' );
like ( $warnings[0], qr/Check source subroutine for key no_source/,
    'and is reported as a problem with that key' );

# Before perl 5.14, an eval run by a destructor while the source is dying
# clears $@. The failure must still be noticed - not cached as an empty result.
{
    package Local::Guard;
    sub new     { bless {}, shift }
    sub DESTROY { eval { 1 } }
}

my $guarded = 0;
$cache{guarded} = {
    timeout => 60,
    source  => sub { $guarded++; my $guard = Local::Guard->new; die "db down\n" }
};

is ( read_key('guarded'), undef, 'a source dying past a destructor that runs eval reads as undef' );
is ( scalar @warnings, 1, 'and emits exactly one warning' );
like ( $warnings[0], qr/Check source subroutine for key guarded/,
    'and is reported as a problem with that key' );
read_key('guarded');
is ( $guarded, 2, 'and is retried on the next read instead of being cached' );

# An exception object that is false and stringifies to nothing is still an
# exception.
{
    package Local::FalseError;
    use overload 'bool' => sub { 0 }, '""' => sub { '' }, fallback => 1;
}

my $false_errors = 0;
$cache{false_error} = {
    timeout => 60,
    source  => sub { $false_errors++; die bless {}, 'Local::FalseError' }
};

is ( read_key('false_error'), undef, 'a source dying with a false exception object reads as undef' );
is ( scalar @warnings, 1, 'and emits exactly one warning' );
like ( $warnings[0], qr/Check source subroutine for key false_error/,
    'and is reported as a problem with that key' );
like ( $warnings[0], qr/unknown error/, 'with "unknown error" in place of the empty message' );
read_key('false_error');
is ( $false_errors, 2, 'and is retried on the next read instead of being cached' );
is ( scalar @warnings, 1, 'and warns again' );

1;

