use Test::More tests => 9;

BEGIN {
    require_ok('lib::tiny');
}

diag("Testing lib::tiny $lib::tiny::VERSION");

my @dirs = qw(tiny_foo tiny_bar);
mkdir( $_, umask() ) for @dirs;    # set up, umask() is for old perl's

my @ORIG = @INC;

lib::tiny->import(@dirs);
ok( $INC[0] eq $dirs[0] && $INC[1] eq $dirs[1], 'adds paths' );

lib::tiny->unimport(@dirs);
ok( $INC[0] eq $ORIG[0] && $INC[1] eq $ORIG[1], 'dels paths' );

# eval because at least one
eval {
    require lib;
    lib->import(@dirs);
};

SKIP: {
    skip 'apparently too old to handle: Unquoted string "lib" may clash with future reserved word at t/00.load.t line 21.', 1 if $@;
    ok( $INC[0] eq $dirs[0] && $INC[1] eq $dirs[1], 'adds paths ordered same as lib.pm' );
}

rmdir $_ for @dirs;    # clean up

# mostly from lib::findlib t/00.load.t
BEGIN {
    require_ok('lib::tiny::findbin');
}

diag("Testing lib::tiny::findbin $lib::findbin::VERSION");

my @INC_ORIG = @INC;
my %made;
for my $path ( "$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/foo" ) {
    if ( !-d $path ) {
        $made{$path}++;
        mkdir $path || die "Could not create test path $path: $!";

    }
}

lib::tiny::findbin->import();
is_deeply( \@INC, [ "$FindBin::Bin/lib", "$FindBin::Bin/../lib", @INC_ORIG ], 'No arg: Added OK' );

lib::tiny::findbin->unimport();
is_deeply( \@INC, \@INC_ORIG, 'No arg: Removed OK' );

lib::tiny::findbin->import('foo');
is_deeply( \@INC, [ "$FindBin::Bin/foo", @INC_ORIG ], 'Arg: Added OK' );

lib::tiny::findbin->unimport('foo');
is_deeply( \@INC, \@INC_ORIG, 'Arg: Removed OK' );

for my $dir ( keys %made ) {
    rmdir $dir || die "Could not remove test path $dir: $!";
}
