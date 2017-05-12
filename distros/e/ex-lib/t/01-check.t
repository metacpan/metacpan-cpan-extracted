#!/usr/bin/perl -w

use strict;
my $tests;
BEGIN { $tests = 16+7+1; }
use FindBin;
use overload (); # Test::More uses overload in runtime. With modified INC it may fail
use lib '.',"$FindBin::Bin/../lib",;
BEGIN { eval { require Test::NoWarnings; Test::NoWarnings->import; 1 } and ++$tests }
use Test::More tests => $tests;

my @ORIG;
BEGIN { @ORIG = @INC }
our $DIAG = 0;

sub ex { @INC[0..@INC-@ORIG-1] }

sub diaginc {
	$DIAG or return;
	diag +( @_ ? ($_[0].': ') : ( 'Add INC: ') ) . join ', ', map "'$_'", ex();
}

use ex::lib ();

diag( "Testing ex::lib $ex::lib::VERSION using Cwd $Cwd::VERSION, Perl $], $^X" );


diaginc();

is( $INC[0], ".", "before import: $INC[0]" );
ex::lib->import( '.' );
diag "Bin = `$FindBin::Bin' ;. is `$INC[0]'";
is( $FindBin::Bin, $INC[0], '. => $FindBin::Bin' );

diaginc();

ex::lib->unimport( '.' );
ok(!ex, 'no ex inc');

diaginc();

# Next tests are derived from lib::tiny


my @dirs = qw(foo bar);
my @adirs = map "$FindBin::Bin/$_",@dirs;
#printf "%o\n", umask(0);
mkdir($_, 0755) or warn "mkdir $_: $!" for @adirs;
chmod 0755, @adirs or warn "chmod $_: $!"; # do chmod (on some versions mkdir with mode ignore mode)

-e $_ or warn "$_ absent" for @adirs;

ex::lib->import(@dirs);

diaginc();
is($INC[0],$adirs[0],'add 0');
is($INC[1],$adirs[1],'add 1');

ex::lib->unimport(@dirs);
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

ex::lib->import( '.' );

# Reflib

@INC = ();
ex::lib->import( sub {} );
my $chk = shift @INC; # When left bad sub in @INC Test::Builder fails
is(ref $chk, 'CODE', 'code in @INC');

# Abs ok

@INC = ();
ex::lib->import(
	'///opt/perl/lib',
	'//opt/perl/lib',
	'/opt/perl/lib',
	'.///',
	'.//',
	'./',
	'.',
);
my @chk = @INC; @INC = ();

is($chk[0], '///opt/perl/lib', 'absolute path stay unchanged');
is($chk[1], '//opt/perl/lib',  'absolute path stay unchanged');
is($chk[2], '/opt/perl/lib',   'absolute path stay unchanged');
SKIP: {
    is($chk[3], $FindBin::Bin,     './// => .');
    @chk > 4 or skip "Duplicates are collapsed",3;
    is($chk[4], $FindBin::Bin,     '.// => .');
    is($chk[5], $FindBin::Bin,     './ => .');
    is($chk[6], $FindBin::Bin,     '. => .');
}

ex::lib->import('glob/*/lib');
@chk = @INC; @INC = ();
my @have;
for (@chk) {
	my $i = m{/glob/t(\d)/lib$} ? $1 : 99;
	$have[$i] = 1;
	like($_, qr{/glob/t(\d)/lib$}, 'glob t'.$i);
	
	
}
is_deeply( \@have,[1,1,1], 'all items present' );

ex::lib->import('glob/x?x/inc');
@chk = @INC; @INC = ();
@have = ();
for (@chk) {
	my $i = m{/glob/x(.)x/inc$} ? $1 : 99;
	$have[$i] = 1;
	like($_, qr{/glob/x(.)x/inc$}, 'glob x'.$i.'x');
}
is_deeply( \@have,[1,1], 'all items present' );

is ( ex::lib::path('.'), $FindBin::Bin, 'ex::lib::path' );
diag "ex::lib::path('.')=".ex::lib::path('.');


exit 0;

END{
	rmdir $_ for @adirs; # clean up
}
