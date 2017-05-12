use Test::More tests => 5;

BEGIN {
    require_ok('lib::findbin');
}

diag("Testing lib::findbin $lib::findbin::VERSION");

my @INC_ORIG = @INC;

# we do this to avoid the false positive when @INC already has the path, if that is not the problem then we dump @INC
my @FUNK_INC_ORIG = qw(bar baz wop);
@INC = @FUNK_INC_ORIG;

lib::findbin->import();
is_deeply( \@INC, [ "$FindBin::Bin/lib", "$FindBin::Bin/../lib", @FUNK_INC_ORIG ], 'No arg: Added OK' ) || diag explain( \@INC );

lib::findbin->unimport();
is_deeply( \@INC, \@FUNK_INC_ORIG, 'No arg: Removed OK' ) || diag explain( \@INC );

lib::findbin->import('foo');
is_deeply( \@INC, [ "$FindBin::Bin/foo", @FUNK_INC_ORIG ], 'Arg: Added OK' ) || diag explain( \@INC );

lib::findbin->unimport('foo');
is_deeply( \@INC, \@FUNK_INC_ORIG, 'Arg: Removed OK' ) || diag explain( \@INC );

@INC = @INC_ORIG;
