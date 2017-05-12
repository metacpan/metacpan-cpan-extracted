#!/usr/bin/env perl

use Test::More;
use uni::perl;
diag "@INC";
=for rem
    use warnings qw(FATAL closed threads internal debugging pack substr malloc
                    unopened portable prototype inplace io pipe unpack regexp
                    deprecated exiting glob digit printf utf8 layer
                    reserved parenthesis taint closure semicolon);
    no warnings qw(exec newline);
=cut

sub DIAG () { 0 }

my $unopened = 10;
open my $closed, '>', \(my $o = "");close $closed;
open my $raw, '>:raw', \(my $x = "");

sub test_warn_die(&;@) {
	my $code = shift;
	my $name = shift;
	my $warn = 0;
	my $die = 0;
	local $SIG{__WARN__} = sub {
		$warn = 1;
		DIAG and diag "$name should not: @_"
	};
	local $SIG{__DIE__}  = sub { $die = 1; };
	my $rc = eval {
		$code->();
	1};
	my $e = $@;
	ok !$warn, "$name - no warn";
	ok $die,   "$name - died";
	ok !$rc,   "$name - eval failed";
	ok $e,     "$name - have error" and DIAG and diag $e;
	
}

sub test_no_warn(&;@) {
	my $code = shift;
	my $name = shift;
	my $warn = 0;
	local $SIG{__WARN__} = sub {
		$warn = 1;
		diag "$name: @_";
	};
	$code->();
	ok !$warn, "$name - no warn";
}

test_warn_die {
	print $closed "test";
} "closed";

# threads ?
# internal ?
# debugging ?

test_warn_die {
	pack 'C', 256;
} "pack";

test_warn_die {
	my $o = \("x");
	substr( $o,0 ) = "x";
} 'substr';

# malloc ?
test_warn_die {
	binmode $unopened, ':raw';
} 'unopened';

test_warn_die {
	eval "0xfffffffff" or die;
} 'portable';

test_warn_die {
	eval q{
		testme( "1" );
		sub testme($) {}
	1} or die;
} 'prototype';

# inplace ?

test_warn_die {
	telldir $unopened;
} 'io';

test_warn_die {
	open(my $x, '|echo|');
} 'pipe';

test_warn_die {
	unpack 'H', "\x{1234}";
} "unpack";

test_warn_die {
	eval q! m{[a-[:alpha:]]}; 1! or die;
} 'regexp';

test_warn_die {
	eval q{
		my $x if 0;
	1} or die;
} 'deprecated';

test_warn_die {
	sub { last }->();
} 'exiting';

# glob ?
test_warn_die {
	eval q{ 0b010102 } or die;
} 'digit';

test_warn_die {
	printf '%$';
} 'printf';

test_warn_die {
	print { $raw } "\x{1234}";
} 'utf8';

test_warn_die {
	open my $x, '<:encoding(', "/dev/null";
} 'layer';

test_warn_die {
	eval q{
		no strict;
		my $x = reserved;
	1} or die;
} 'reserved';

test_warn_die {
	eval q{
		no strict;
		my $foo, $bar = @_;
	1} or die;
} 'parenthesis';

# taint ?

test_warn_die {
	eval q{
		f();
		sub { my $x; sub f { $x } }
	1} or die;
} 'closure';

# semicolon ?

SKIP: {
	skip "Can't make this test on Windows", 4+1 if $^O eq 'MSWin32';

test_warn_die {
	use warnings FATAL => 'exec';
	exec("/some/not/present/program");
} 'exec + fail';

test_no_warn {
	exec("/some/not/present/program");
} 'exec';

}

# can't test newline on unix

=for rem

test_warn_die {
	use warnings FATAL => 'newline';
	open my $f, '>', "newlinefile\0\0" or warn "$!";
} 'newline + fail';

test_no_warn {
	open my $f, '>', "newlinefile\n";
} 'newline';
=cut

done_testing();

exit 0;
require Test::NoWarnings;
