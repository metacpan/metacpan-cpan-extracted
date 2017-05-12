#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl warnings-DynamicScope.t'

# Revision: $Id: warnings-DynamicScope.t,v 1.10 2005/08/10 08:12:27 kay Exp $

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
use Test::Warn;
use Test::Exception;

# --------------------------------------------------------------------------
# Utilities
# --------------------------------------------------------------------------
package Handle::String;
use Tie::Handle;
use base "Tie::Handle";
sub TIEHANDLE {	my $self = ""; bless \$self }
sub PRINT     { ${$_[0]} = join('', @_[1..$#_]) }
sub PRINTF    {	${$_[0]} = sprintf($_[1], @_[2..$#_])}
sub READLINE  { ${$_[0]} };

package main;
sub lex_warnif { warnings::warnif($_[0], "WARNING ON FOR $_[0]") }

# --------------------------------------------------------------------------
# Start tests
# --------------------------------------------------------------------------
my $init_value;
BEGIN {
	$init_value = $^W;
}

BEGIN { use_ok('warnings::DynamicScope') };
BEGIN { use_ok('warnings::register') };

# --------------------------------------------------------------------------
# Test die on bad category

dies_ok { $^W{unknown_cat} = 1 } 'Bad category(die)';

ok($@ =~ /^Unknown warning category 'unknown_cat'/,
   'Bad category(error message)');

# --------------------------------------------------------------------------
# Test all and $^W

ok($^W{all} == $init_value, 'initial value: $^W{all}');
ok($^W      == $init_value, 'initial value: $^W');

$^W = 1;

ok($^W == 1,      'set: $^W = 1');
ok($^W{all} == 1, 'set: transition $^W => $^W{all}, 1');

$^W = 0;

ok($^W == 0,      'set: $^W = 0');
ok($^W{all} == 0, 'set: transition $^W => $^W{all}, 0');

$^W{all} = 1;

ok($^W{all} == 1, 'set: $^W{all} = 1');
ok($^W == 1,      'set: transition $^W{all} => $^W, 1');

$^W{all} = 0;

ok($^W{all} == 0, 'set: $^W{all} = 0');
ok($^W == 0,      'set: transition $^W{all} => $^W, 0');

# --------------------------------------------------------------------------
# Test lexical warnings for all


$^W = 0;
ok($^W == 0,      'lexical: initalizae');
ok($^W{all} == 0, 'lexical: initalizae');

# use warnings 'all';
my $val;
BEGIN {
	BEGIN {
		$^W = 1;
	}

	$val = $^W;
	ok($val == 1, 'lexical: lexical set: $^W = 1');

	$val = $^W{all};
	ok($val == 1, 'lexical: lexical set: transfer $^W => $^W{all}, 1');

	$^W = 1;
}
BEGIN {
	ok(${$warnings::DynamicScope::WARNINGS_HASH::r_WARNINGS} == 1,
	   'lexical: lexical set: transfer $^W => original $^W, 1');
}

tie *{main::stderr}, 'Handle::String';
lex_warnif('all');
my $warn = <STDERR>;
untie *{main::stderr};
ok($warn =~ /WARNING ON FOR all/, 'lexical: lexical enabled(all) == 1');

ok($^W == 0,      'lexical: dynamic $^W == 0');
ok($^W{all} == 0, 'lexical: dynamic $^W == 1');

# no warnings 'all';
BEGIN {
	BEGIN {
		$^W = 0;
	}
	
	$val = $^W;
	ok($val == 0, 'lexical: lexical set: $^W = 0');

	$val = $^W{all};
	ok($val == 0, 'lexical: lexical set: transfer $^W => $^W{all}, 0');

	$^W = 0;
}
BEGIN {
	ok(${$warnings::DynamicScope::WARNINGS_HASH::r_WARNINGS} == 0,
	   'lexical: lexical set: transfer $^W => original $^W, 0');
}

tie *{main::stderr}, 'Handle::String';
lex_warnif('all');
$warn = <STDERR>;
untie *{main::stderr};
ok($warn eq "", 'lexical: lexical enabled(all) == 0');

# use wanings FATAL => 'all';
BEGIN {
	BEGIN {
		$^W{all} = 'FATAL';
	}

	$val = $^W{all};
	ok($val == 2, 'lexical: lexical set: $^W{all} = FATAL');

	$val = $^W;
	ok($val == 2, 'lexical: lexical set: transfer $^W{all} => oritigal $^W, FATAL => 1');

	$^W{all} = 'FATAL';
}
BEGIN {
	ok(${$warnings::DynamicScope::WARNINGS_HASH::r_WARNINGS} == 1,
	   'lexical: lexical set: transfer $^W{all} => $^W, FATAL => 1');
}

eval { lex_warnif('all') };
ok($@ =~ /WARNING ON FOR all/, 'lexical: lexical enabled(all) == FATAL');

# use wanings 'all'; unsets DeadBets
BEGIN {
	BEGIN {
		$^W{all} = 1;
	}

	$val = $^W{all};
	ok($val == 1, 'lexical: lexical set: $^W{all} = 1, unset DeadBits');

	$val = $^W;
	ok($val == 1, 'lexical: lexical set: transfer $^W{all} => $^W, 1');

	$^W{all} = 1;
}
BEGIN {
	ok(${$warnings::DynamicScope::WARNINGS_HASH::r_WARNINGS} == 1,
	   'lexical: lexical set: transfer $^W{all} => original $^W, 1');
}
tie *{main::stderr}, 'Handle::String';
lex_warnif('all');
$warn = <STDERR>;
untie *{main::stderr};
ok($warn =~ /WARNING ON FOR all/, 'lexical: lexical enabled(all) == 1');

# no wanings 'all';
BEGIN {
	BEGIN {
		$^W{all} = 0;
	}

	$val = $^W{all};
	ok($val == 0, 'lexical: lexical set: $^W{all} = 0');

	$val = $^W;
	ok($val == 0, 'lexical: lexical set: transfer $^W{all} => $^W, 0');

	$^W{all} = 0;
}
BEGIN {
	ok(${$warnings::DynamicScope::WARNINGS_HASH::r_WARNINGS} == 0,
	   'lexical: lexical set: transfer $^W{all} => original $^W, 0');
}
tie *{main::stderr}, 'Handle::String';
lex_warnif('all');
$warn = <STDERR>;
untie *{main::stderr};
ok($warn eq "", 'lexical: lexical enabled(all) == 0');


# --------------------------------------------------------------------------
# Test register;

package Test1;
use warnings::register;
package Test2;
use warnings::register;
package main;

$^W{all} = 1;

lives_ok { $^W{Test1} } "register: Test1";
lives_ok { $^W{Test2} } "register: Test2";

# --------------------------------------------------------------------------
# Test setting values.
ok($^W{Test1} == 1, '$^W{Test1}: initial value');
ok($^W{Test2} == 1, '$^W{Test2}: initial value');

ok($^W{all}  == 1,  'check: $^W{all} == 1');
ok($^W == 1,        'check: $^W == 1');

$^W{Test1} = 0;

ok($^W{Test1} == 0, "set: Test1 = 0");
ok($^W{all}  == 1,  'set: transition($^W{all} == 0)');
ok($^W  == 1,       'set: no transition($^W == 1)');

$^W{Test2} = 0;

ok($^W{Test2} == 0, "set: Test2 = 0");
ok($^W{all}  == 1,  'set: no effect($^W{all} == 1)');
ok($^W == 1,        'set: no effect($^W == 1)');

$^W{Test1} = 1;
$^W{Test2} = 1;

ok($^W{Test1} == 1, "set: Test1 = 1");
ok($^W{Test2} == 1, "set: Test2 = 1");
ok($^W{all}  == 1,  'set: no transition($^W{all} == 1)');
ok($^W  == 1,       'set: no transition($^W == 1)');

$^W = 0;

ok($^W{Test1} == 0, 'set: transition $^W => Test1, 0');
ok($^W{Test2} == 0, 'set: transition $^W => Test2, 0');
ok($^W == 0,        'set: transition $^W => $^W,   0');
ok($^W{all} == 0,   'set: transition $^W => all,   0');

$^W = 1;

ok($^W{Test1} == 1, 'set: transition $^W => Test1, 1');
ok($^W{Test2} == 1, 'set: transition $^W => Test2, 1');
ok($^W == 1,        'set: transition $^W => $^W,   1');
ok($^W{all} == 1,   'set: transition $^W => all,   1');

$^W{all} = 0;

ok($^W{Test1} == 0, "set: transition all => Test1, 0");
ok($^W{Test2} == 0, "set: transition all => Test2, 0");
ok($^W == 0,        'set: transition all => $^W,   0');
ok($^W{all} == 0,   'set: transition all => all,   0');

$^W{all} = 1;

ok($^W{Test1} == 1, "set: transition all => Test1, 1");
ok($^W{Test2} == 1, "set: transition all => Test2, 1");
ok($^W == 1,        'set: transition all => $^W,   1');
ok($^W{all} == 1,   'set: transition all => all,   1');

$^W = 0;

$^W{Test1} = 1;

ok($^W{Test1} == 1, "set: Test1 = 1");
ok($^W{all}  == 0,  'set: no effect($^W{all} == 0)');
ok($^W{all}  == 0,  'set: no effect($^W == 0)');

$^W{Test2} = 1;

ok($^W{Test2} == 1, "set: Test2 = 1");
ok($^W{all}  == 0,  'set: no effect($^W{all} == 0)');
ok($^W{all}  == 0,  'set: no effect($^W == 0)');

# --------------------------------------------------------------------------
# Test scope

$^W = 0;
{
	$^W = 1;

	ok($^W{Test1} == 1, 'scope in:  $^W => Test1, 1');
	ok($^W{Test2} == 1, 'scope in:  $^W => Test2, 1');
	ok($^W == 1,        'scope in:  $^W => $^W,   1');
	ok($^W{all} == 1,   'scope in:  $^W => all,   1');
}

ok($^W{Test1} == 1, 'scope out: $^W => Test1, 1');
ok($^W{Test2} == 1, 'scope out: $^W => Test2, 1');
ok($^W == 1,        'scope out: $^W => $^W,   1');
ok($^W{all} == 1,   'scope out: $^W => all,   1');

# --------------------------------------------------------------------------

$^W{all} = 0;
{
	$^W{all} = 1;

	ok($^W{Test1} == 1, 'scope in:  all => Test1, 1');
	ok($^W{Test2} == 1, 'scope in:  all => Test2, 1');
	ok($^W == 1,        'scope in:  all => $^W,   1');
	ok($^W{all} == 1,   'scope in:  all => all,   1');
}

ok($^W{Test1} == 1, 'scope out: all => Test1, 1');
ok($^W{Test2} == 1, 'scope out: all => Test2, 1');
ok($^W == 1,        'scope out: all => $^W,   1');
ok($^W{all} == 1,   'scope out: all => all,   1');

# --------------------------------------------------------------------------

$^W = 0;
$^W{Test1} = 0;
$^W{Test2} = 0;
{
	$^W{Test1} = 1;
	$^W{Test2} = 1;
	
	ok($^W{Test1} == 1, 'scope in:  Test1 = 1');
	ok($^W{Test2} == 1, 'scope in:  Test2 = 1');
	ok($^W == 0,        'scope in:  $^W  == 0');
	ok($^W{all} == 0,   'scope in:  all  == 0');
}

ok($^W{Test1} == 1, 'scope out: Test1 = 1');
ok($^W{Test2} == 1, 'scope out: Test2 = 1');
ok($^W == 0,        'scope out: $^W  == 0');
ok($^W{all} == 0,   'scope out: all  == 0');

# --------------------------------------------------------------------------
# Test simple dynamic scope

$^W = 1;
$^W{all} = 1;
${Test1} = 1;
${Test2} = 1;

{
	local $^W;
	local $^W{all};
	local ${Test1};
	local ${Test2};

	ok($^W{Test1} == 0, 'dscope in:  default == 0');
	ok($^W{Test2} == 0, 'dscope in:  default == 0');
	ok($^W == 0,        'dscope in:  default == 0');
	ok($^W{all} == 0,   'dscope in:  default == 0');
}

ok($^W{Test1} == 1, 'dscope out: Test1 == 1');
ok($^W{Test2} == 1, 'dscope out: Test2 == 1');
ok($^W == 1,        'dscope out: $^W   == 1');
ok($^W{all} == 1,   'dscope out: all   == 1');

# --------------------------------------------------------------------------

$^W = 1;
$^W{all} = 1;
${Test1} = 1;
${Test2} = 1;

{
	local $^W;

	ok($^W{Test1} == 0, 'dscope in:  Test1 initialized to 0 by local $^W');
	ok($^W{Test2} == 0, 'dscope in:  Test2 initialized to 0 by local $^W');
	ok($^W == 0,        'dscope in:  $^W   initialized to 0 by local $^W');
	ok($^W{all} == 0,   'dscope in:  all   initialized to 0 by local $^W');
}

ok($^W{Test1} == 1, 'dscope out: Test1 == 1');
ok($^W{Test2} == 1, 'dscope out: Test2 == 1');
ok($^W == 1,        'dscope out: $^W   == 1');
ok($^W{all} == 1,   'dscope out: all   == 1');

# --------------------------------------------------------------------------

$^W = 0;
$^W{all} = 0;
${Test1} = 0;
${Test2} = 0;

{
	local $^W = 1;

	ok($^W{Test1} == 1, 'dscope in:  Test1 set to 1 by local $^W');
	ok($^W{Test2} == 1, 'dscope in:  Test2 set to 1 by local $^W');
	ok($^W == 1,        'dscope in:  $^W   set to 1 by local $^W');
	ok($^W{all} == 1,   'dscope in:  all   set to 1 by local $^W');
}

ok($^W{Test1} == 0, 'dscope out: Test1 == 0');
ok($^W{Test2} == 0, 'dscope out: Test2 == 0');
ok($^W == 0,        'dscope out: $^W   == 0');
ok($^W{all} == 0,   'dscope out: all   == 0');

# --------------------------------------------------------------------------

$^W = 0;
{
	local $^W = 1;

	ok($^W{Test1} == 1, 'dscope in:  transition $^W => Test1, 1');
	ok($^W{Test2} == 1, 'dscope in:  transition $^W => Test2, 1');
	ok($^W == 1,        'dscope in:  transition $^W => $^W,   1');
	ok($^W{all} == 1,   'dscope in:  transition $^W => all,   1');
}

ok($^W{Test1} == 0, 'dscope out: transition $^W => Test1, 0');
ok($^W{Test2} == 0, 'dscope out: transition $^W => Test2, 0');
ok($^W == 0,        'dscope out: transition $^W => $^W,   0');
ok($^W{all} == 0,   'dscope out: transition $^W => all,   0');

# --------------------------------------------------------------------------

$^W{all} = 0;
{
	local $^W{all} = 1;

	ok($^W{Test1} == 1, 'dscope  in: transition all => Test1, 1');
	ok($^W{Test2} == 1, 'dscope  in: transition all => Test2, 1');
	ok($^W == 1,        'dscope  in: transition all => $^W,   1');
	ok($^W{all} == 1,   'dscope  in: transition all => all,   1');
}

ok($^W{Test1} == 0, 'dscope out: transition all => Test1, 0');
ok($^W{Test2} == 0, 'dscope out: transition all => Test2, 0');
ok($^W == 0,        'dscope out: transition all => $^W,   0');
ok($^W{all} == 0,   'dscope out: transition all => all,   0');

# --------------------------------------------------------------------------

$^W = 0;
$^W{Test1} = 0;
$^W{Test2} = 0;
{
	local $^W{Test1} = 1;
	local $^W{Test2} = 1;
	
	ok($^W{Test1} == 1, 'scope in:  Test1 = 1');
	ok($^W{Test2} == 1, 'scope in:  Test2 = 1');
	ok($^W == 0,        'scope in:  $^W  == 0');
	ok($^W{all} == 0,   'scope in:  all  == 0');
}

ok($^W{Test1} == 0, 'scope out: Test1 = 0');
ok($^W{Test2} == 0, 'scope out: Test2 = 0');
ok($^W == 0,        'scope out: $^W  == 0');
ok($^W{all} == 0,   'scope out: all  == 0');

# --------------------------------------------------------------------------
# Test recursive call - 1

$cnt = 10;
$^W{Test1} = 0;
$^W{Test2} = 0;
sub recursive1 {
	if (--$cnt == 0) {
		ok($^W{Test1} == 1, 'recursive1 in: Test1 == 1');
		ok($^W{Test2} == 1, 'recursive1 in: Test2 == 1');
	} else {
		recursive1();
	}
}
$^W{Test1} = 1;
$^W{Test2} = 1;

ok($^W{Test1} == 1, 'recursive1 before: Test1 == 1');
ok($^W{Test2} == 1, 'recursive1 before: Test2 == 1');

recursive1();

ok($^W{Test1} == 1, 'recursive1 before: Test1 == 1');
ok($^W{Test2} == 1, 'recursive1 before: Test2 == 1');

# --------------------------------------------------------------------------
# Test recursive call - 2

$cnt = 10;
$^W{Test1} = 0;
$^W{Test2} = 0;
sub recursive2 {
	if (--$cnt == 0) {
		ok($^W{Test1} == 0, 'recursive2 in: Test1 == 1');
		ok($^W{Test2} == 0, 'recursive2 in: Test2 == 1');
	} else {
		recursive2();
	}
}
$^W{Test1} = 0;
$^W{Test2} = 0;

ok($^W{Test1} == 0, 'recursive2 before: Test1 == 0');
ok($^W{Test2} == 0, 'recursive2 before: Test2 == 0');

recursive2();

ok($^W{Test1} == 0, 'recursive2 before: Test1 == 0');
ok($^W{Test2} == 0, 'recursive2 before: Test2 == 0');

# --------------------------------------------------------------------------
# Test recursive call - 3

$cnt = 10;
$^W{Test1} = 0;
$^W{Test2} = 0;
sub recursive3 {
	if (--$cnt == 0) {
		ok($^W{Test1} == 0, 'recursive3 in: Test1 == 0');
		ok($^W{Test2} == 0, 'recursive3 in: Test2 == 0');
	} else {
		local $^W{Test1} = 0;
		local $^W{Test2} = 0;
		recursive3();
	}
}
$^W{Test1} = 1;
$^W{Test2} = 1;

ok($^W{Test1} == 1, 'recursive3 before: Test1 == 1');
ok($^W{Test2} == 1, 'recursive3 before: Test2 == 1');

recursive3();

ok($^W{Test1} == 1, 'recursive3 before: Test1 == 1');
ok($^W{Test2} == 1, 'recursive3 before: Test2 == 1');

# --------------------------------------------------------------------------
# Test recursive call - 4

$cnt = 10;
$^W{Test1} = 0;
$^W{Test2} = 0;
sub recursive4 {
	if (--$cnt == 0) {
		ok($^W{Test1} == 1, 'recursive4 in: Test1 == 1');
		ok($^W{Test2} == 1, 'recursive4 in: Test2 == 1');
	} else {
		local $^W{Test1} = 1;
		local $^W{Test2} = 1;
		recursive4();
	}
}
$^W{Test1} = 0;
$^W{Test2} = 0;

ok($^W{Test1} == 0, 'recursive4 before: Test1 == 0');
ok($^W{Test2} == 0, 'recursive4 before: Test2 == 0');

recursive4();

ok($^W{Test1} == 0, 'recursive4 before: Test1 == 0');
ok($^W{Test2} == 0, 'recursive4 before: Test2 == 0');

# --------------------------------------------------------------------------
# Test class hierarchy

package Test1;
sub new {
	die "In Test1" if $^W{Test1};
}

package Test2;
our @ISA = 'Test1';
sub new {
	die "In Test2" if $^W{Test2};
	$_[0]->SUPER::new;
}

package main;

$^W{Test1} = 0;
$^W{Test2} = 0;
lives_ok { Test2->new() } "heirarchey 1";

$^W{Test1} = 1;
$^W{Test2} = 0;
dies_ok { Test2->new() } "heirarchey 2";
ok($@ =~ /^In Test1/, "heirarchey 2");

$^W{Test1} = 1;
$^W{Test2} = 1;
dies_ok { Test2->new() } "heirarchey 2";
ok($@ =~ /^In Test2/, "heirarchey 2");


# --------------------------------------------------------------------------
# Test as pragma

my $dummy;
my $uninit1;

use warnings FATAL => 'uninitialized';

use warnings;

dies_ok { $dummy = $uninit1 . "" } "pragma";

BEGIN {
	$^W{uninitialized} = 0;
}

my $uninit2;
warning_is { $dummy = $uninit2 . "" } "", "pragma";

BEGIN {
	$^W{uninitialized} = 1;
}

my $uninit3;
warning_like { $dummy = $uninit3 . "" } qr/^Use of uninitialized value in concatenation/, "pragma";

BEGIN {
	$^W{uninitialized} = 'FATAL';
}

my $uninit4;
dies_ok { $dummy = $uninit4 . "" } "pragma";

no warnings FATAL => 'uninitialized';

# --------------------------------------------------------------------------
# Test foreach keys(first key and next key)

package z;
use warnings::register;

package A;
use warnings::register;

use warnings::register;

package main;

$^W = 1;
my $t = 1;
my $first_one;
my $last_one;
my $cnt = 0;
foreach my $key (sort keys(%^W)) {
	$t &= $^W{$key};
	$first_one = $key if ++$cnt == 1;
	$last_one = $key;
}

ok($t, "foreach keys");
ok($first_one eq "A", "foreach keys, first");
ok($last_one eq 'z', "foreach keys, last");

$^W = 0;
$t = 0;
foreach my $key (keys(%^W)) {
	$t |= $^W{$key};
}
ok(!$t, "foreach keys");

# --------------------------------------------------------------------------
# Test "-X" command line switch

BEGIN {
	$warnings::DynamicScope::WARNINGS_HASH::X_FLAG = 1;
	BEGIN {
		$^W = 1;
	}
	ok($^W      == 0, '"-X" command line switch');
	ok($^W{all} == 0, '"-X" command line switch');
	$warnings::DynamicScope::WARNINGS_HASH::X_FLAG = 0;
}

BEGIN {
	$warnings::DynamicScope::WARNINGS_HASH::W_FLAG = 1;
	BEGIN {
		$^W = 0;
	}
	ok($^W      == 1, '"-W" command line switch');
	ok($^W{all} == 1, '"-W" command line switch');
	$warnings::DynamicScope::WARNINGS_HASH::W_FLAG = 0;
}

$warnings::DynamicScope::WARNINGS_HASH::X_FLAG = 1;
$^W = 1;
ok($^W      == 0, '"-X" command line switch');
ok($^W{all} == 0, '"-X" command line switch');

$warnings::DynamicScope::WARNINGS_HASH::W_FLAG = 1;
$^W = 0;
ok($^W      == 1, '"-W" command line switch');
ok($^W{all} == 1, '"-W" command line switch');
$warnings::DynamicScope::WARNINGS_HASH::W_FLAG = 0;
