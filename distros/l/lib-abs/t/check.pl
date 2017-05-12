use strict;

my $tests; BEGIN { $tests = 22; }

use Test::More;

use FindBin;
BEGIN {
	defined $FindBin::Bin and length $FindBin::Bin
		or plan skip_all => "\$FindBin::Bin (v$FindBin::VERSION) is ".(defined $FindBin::Bin ? 'empty' : 'undef').". Not my fault";
}

use Carp ();
use Carp::Heavy (); # lib::abs may require Carp in runtime. With modified INC it may fail
use overload ();    # Test::More uses overload in runtime. With modified INC it may fail

use lib '.',"$FindBin::Bin/../lib",;
BEGIN { eval { require Test::NoWarnings; Test::NoWarnings->import; 1 } and ++$tests }

my @ORIG; BEGIN { @ORIG = @INC }

sub ex { @INC[0..@INC-@ORIG-1] }
sub diaginc { 0 or return; diag +( @_ ? ($_[0].': ') : ( 'Add INC: ') ) . join ', ', map "'$_'", ex(); }

#BEGIN { *lib::abs::DEBUG = sub () { 2 } }
use lib::abs ();

diag( "Testing lib::abs $lib::abs::VERSION using Cwd $Cwd::VERSION with FindBin $FindBin::VERSION, Perl $], $^X" );
diaginc();

plan tests => $tests;

is( $INC[0], ".", "before import: $INC[0]" );
lib::abs->import( '.' );
diag "Bin = `$FindBin::Bin' ;. is `$INC[0]'";
is( $FindBin::Bin, $INC[0], '. => $FindBin::Bin' );

diaginc();

lib::abs->unimport( '.' );
ok(!ex, 'no ex inc');

diaginc();

# Next tests are derived from lib::tiny


my @dirs = qw(foo bar);
my @adirs = map "$FindBin::Bin/$_",@dirs;
#printf "%o\n", umask(0);
mkdir($_, 0755) or warn "mkdir $_: $!" for @adirs;
chmod 0755, @adirs or warn "chmod $_: $!"; # do chmod (on some versions mkdir with mode ignore mode)

-e $_ or warn "$_ absent" for @adirs;

lib::abs->import(@dirs);

diaginc();
is($INC[0],$adirs[0],'add 0');
is($INC[1],$adirs[1],'add 1');

lib::abs->unimport(@dirs);
diaginc();

ok(!ex, 'dels paths');

eval {
    require lib;
    'lib'->import(@adirs);
};

SKIP: {
    skip 'apparently too old to handle: Unquoted string "lib" may clash with future reserved word at t/00.load.t line 21.', 1 if $@;
	is($INC[0],$adirs[0],'order same as lib.pm 0');
	is($INC[1],$adirs[1],'order same as lib.pm 1');
};

eval {
    'lib'->unimport(@adirs);
};

lib::abs->import( '.' );

# Reflib

@INC = ();
lib::abs->import( sub {} );
my $chk = shift @INC; # When left bad sub in @INC Test::Builder fails
is(ref $chk, 'CODE', 'code in @INC');

# Abs ok
# Don't want to hit in  existing file
my $path = '/somewhere/in/space';
while (-e $path) { $path .= '/deep' }
@INC = ();
lib::abs->import(
	'//'.$path,
	'/'.$path,
	$path,
);
my @abs = @INC; @INC = ();
lib->import(
	'//'.$path,
	'/'.$path,
	$path,
);
my @need = @INC; @INC = ();
is_deeply \@abs,\@need, 'absolute is same as lib';

# Rel ok

@INC = ();
lib::abs->import(
	'.///',
	'.//',
	'./',
	'.',
);
my @chk = @INC; @INC = ();

SKIP: {
	is($chk[0], $FindBin::Bin,     './// => .');
	@chk > 1 or skip "Duplicates are collapsed",3;
	is($chk[1], $FindBin::Bin,     '.// => .');
	is($chk[2], $FindBin::Bin,     './ => .');
	is($chk[3], $FindBin::Bin,     '. => .');
}

# Glob test

lib::abs->import('glob/*/lib');
@chk = @INC; @INC = ();
my @have;
for (@chk) {
	my $i = m{/glob/t(\d)/lib$} ? $1 : 99;
	$have[$i] = 1;
	like($_, qr{/glob/t(\d)/lib$}, 'glob t'.$i);
	
	
}
is_deeply( \@have,[1,1,1], 'all items present' );

lib::abs->import('glob/x?x/inc');
@chk = @INC; @INC = ();
@have = ();
for (@chk) {
	my $i = m{/glob/x(.)x/inc$} ? $1 : 99;
	$have[$i] = 1;
	like($_, qr{/glob/x(.)x/inc$}, 'glob x'.$i.'x');
}
is_deeply( \@have,[1,1], 'all items present' );

is ( lib::abs::path('.'), $FindBin::Bin, 'lib::abs::path' );
diag "lib::abs::path('.')=".lib::abs::path('.');

exit 0;

END{
	rmdir $_ for @adirs; # clean up
}
