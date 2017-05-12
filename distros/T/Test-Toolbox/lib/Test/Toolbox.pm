package Test::Toolbox;
use strict;
# use String::Util ':all';
use Carp 'croak';
use Test::Builder::Module;
use Cwd 'abs_path';

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# version
our $VERSION = '0.4';


#------------------------------------------------------------------------------
# opening pod
#

=head1 NAME

Test::Toolbox - tools for testing

=head1 SYNOPSIS

 # load module
 use Test::Toolbox;
 
 # plan tests
 rtplan 43;
 
 # or, plan tests, but die on the first failure
 rtplan 43, autodie=>1;
 
 # basic test
 rtok 'my test name', $success;

 # test for failure if you prefer
 rtok 'test name', $success, should=>0;

 # two values should equal each other
 rtcomp 'test name', $val, $other_val;
 
 # two values should not equal each other
 rtcomp 'test name', $val, $other_val, should=>0;
 
 # run some code which should succeed
 # note that the second param is undef
 rteval 'test name', undef, sub { mysub() };
 
 # run some code which should cause a specific error code
 rteval 'test name', 'file-open-failed', sub { mysub() };
 
 # check that $@ has a specific error code
 rtid 'test name', $@, 'missing-keys';
 
 # much more

=head1 OVERVIEW

Test::Toolbox provides (as you might guess) tools for automated testing.
Test::Toolbox is much like some other testing modules, such as Test::More
and Test::Simple. Test::Toolbox provides a different flavor of tests which
may or may not actually be to your preference.

The tools in Test::Toolbox have a standard format. Commands start with (the
command (of course), followed by the test name. Then there is usually the
value being tested, or values being compared, then other options. So, for
example, this command checks compares two values:

 rtcomp 'test name', $val, $other_val;

In some cases it's preferable to flip the logic of the test, so that, for
example, two values should B<not> be the same. In that case, you can add
the C<should> option:

 rtcomp 'test name', $val, $other_val, should=>0;

All test commands require a test name as the first param.

=head1 Meta commands

=cut

#
# opening pod
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# extend Test::Builder::Module
#
use base 'Test::Builder::Module';
#
# extend Test::Builder::Module
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# export
# KLUDGE: I don't like automatically exporting everything from a module. By
# default, nothing shoujld be exported. Exports should be explicit with
# something like :all. However, Test::Module throws an error if Test::Toolbox
# tries to use %EXPORT_OK. For now, I'm just going with the flow and exporting
# everything, but I'll see if I can correct the situation in later releases.
#
use base 'Exporter';
our (@EXPORT);

# @EXPORT
@EXPORT = qw[
	go_script_dir
	rtplan
	rtdiag
	rtcounts
	rtok
	rtcomp
	rtarr
	rtelcount
	rthash
	rtisa
	rtbool
	rtdef
	rtrx
	rtfile
	rtid
	rteval
];
#
# export
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# globals
#
our ($planned_test_count);
our $auto_die = 0;
our $verbose = 0;
our %counts = (success=>0, fail=>0, sofar=>0, planned=>0);
our $script_abs_path = abs_path($0);
#
# globals
#------------------------------------------------------------------------------



###############################################################################
# public methods
#


#------------------------------------------------------------------------------
# go_script_dir
#

=head2 go_script_dir()

C<go_script_dir()> changes to the directory that the script is running in. This
can be handy of your test script needs to read files that are part of your
tests. C<go_script_dir()> takes no params:

 go_script_dir();

=cut

sub go_script_dir {
	my ($script_dir);
	
	# TESTING
	# println subname(); ##i
	
	# load basename module
	require File::Basename;
	
	# get script's directory
	$script_dir = File::Basename::dirname($script_abs_path);
	
	# untaint directory path
	# KLUDGE: Normally unconditional untainting is a Very Bad Idea.
	# In this case I don't know a good way to untaint a path using a pattern.
	# The following code checks if the path actually exists as a directory,
	# then untaints the path
	if (-d $script_dir) {
		unless ($script_dir =~ m|^(.+)$|s)
			{ die 'somehow cannot untaint directory path' }
		$script_dir = $1;
	}
	
	# go to directory
	chdir($script_dir) or die 'go-script-dir-chdir-fail: unable to chdir to script directory';
}
#
# go_script_dir
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
# rtplan
#

=head2 rtplan()

rtplan() indicates how many tests you plan on running. Like with other test
modules, failing to run exactly that many tests is itself considered on error.
So, this command plans on running exactly 43 tests.

 rtplan 43;

You might prefer that your script dies on the first failure. In that case add
the C<autodie> option:

 rtplan 43, autodie=>1;

=cut

sub rtplan {
	my ($count, %opts) = @_;
	my ($tb);
	
	# TESTING
	# println subname(); ##i
	
	# set planned count
	$planned_test_count = $count;
	$counts{'planned'} = $count;
	
	# autodie
	if (exists $opts{'autodie'})
		{ $auto_die = $opts{'autodie'} }
	
	# verbose
	# if (exists $opts{'verbose'})
	#	{ $verbose = $opts{'verbose'} }
	
	# plan tests
	$tb = Test::Toolbox->builder;
	return $tb->plan(tests=>$count);
}
#
# rtplan
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rtdiag
#
sub rtdiag {
	my (@msgs) = @_;
	my $tb = Test::Toolbox->builder;
	return $tb->diag(@msgs);
}
#
# rtdiag
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rtcounts
#

=head2 rtcounts()

rtcounts() returns a hashref of the test counts so far. The hashref has the
following elements:

=over

=item * success: number of successful tests so far.

=item * fail: number of failed tests so far.

=item * sofar: total number of tests so far.

=item * planned: total number of planned tests.

=back

=cut

sub rtcounts {
	return {%counts};
}
#
# rtcounts
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# pod for test commands
#

=head1 Test commands

=cut

#
# pod for test commands
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# rtok
#

=head2 rtok()

rtok() is the basic command of Test::Toolbox. It requires two params, the name
of the test, and a scalar indicating success (true) or failure (false). So,
this simple command indicates a successful test:

 rtok 'my test', 1;

You might prefer to flip the logic, so that false indicates success. For that,
use the C<should> option:

 rtok 'my test', $val, should=>0;

All other test command call rtok().

=cut

sub rtok {
	my ($test_name, $ok, %opts) = @_;
	my ($indent);
	
	# TESTING
	# println subname(); ##i
	
	# default options
	%opts = (should=>1, %opts);
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# TESTING
	# unless ($test_name =~ m|^\(rt\)|si)
	#	{ croak 'during development, test name must start with (rt)' }
	
	# verbosify
	# if ($verbose) {
	#	println 'test: ', $test_name;
	#	$indent = indent();
	# }
	
	# reverse test if necessary
	$ok = should_flop($ok, %opts);
	
	# autodie if mecessary
	if ($auto_die) {
		if (! $ok) {
			croak("fail: $test_name");
		}
	}
	
	# regular ok
	ok_private($test_name, $ok);
	
	# set counts
	if ($ok)
		{ $counts{'success'}++ }
	else
		{ $counts{'fail'}++ }
	
	# increment sofar
	$counts{'sofar'}++;
}
#
# rtok
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rtcomp
#

=head2 rtcomp()

rtcomp() compares the string value of two values.  It sets success if they are
the same, failure if thet are different. Its simplest use would be like this:

 rtcomp 'my test', $first, $second;

As with other commands, you can flip the logic of the command so that success
is if they are not the same:

 rtcomp 'my test', $first, $second, should=>0;

rtcomp() interprets undef as matching undef, so the following test would would
be successful.

 rtcomp 'my test', undef, undef;

rtcomp() takes several options.

=over

=item * collapse

If this option is true, then the strings are collapsed before they are
compared. So, for example, the following test would succeed:

 rtcomp 'my test', ' Fred ', 'Fred', collapse=>1;

=item * nospace

nospace removes all spaces before comparing strings. So this test would
succeed:

 rtcomp 'my test', 'Fr   ed', 'Fred', nospace=>1;

=item * case_insensitive

The case_insensitive option indicates to compare the values case insensitively.
So, the following test would be successful.

=back

=cut

sub rtcomp {
	my ($name, $got, $should, %opts) = @_;
	my ($ok);
	
	# TESTING
	# println subname(); ##i
	
	# should have gotten at least three params
	unless ( @_ >= 3 )
		{ croak 'rtcomp requires at least 3 params' }
	
	# default options
	%opts = (should=>1, %opts);
	
	# collapse as necessary
	if ($opts{'collapse'}) {
		$got = collapse($got);
		$should = collapse($should);
	}
	
	# nospace as necessary
	elsif ($opts{'nospace'}) {
		$got = nospace($got);
		$should = nospace($should);
	}
	
	# remove trailing whitespace
	# elsif ($opts{'trim_end'} || $opts{'trim_ends'}) {
	#	$got =~ s|\s+$||s;
	#	$should =~ s|\s+$||s;
	#}
	
	# case insensitive
	if ($opts{'case_insensitive'}) {
		if (defined $should)
			{ $should = lc($should) }
		if (defined $got)
			{ $got = lc($got) }
	}
	
	# compare
	$ok = eqq($got, $should);
	
	# development environment
	if ( (! should_flop($ok, %opts)) && $auto_die) {
		print
			"--- rtcomp fail -------------------------------------------\n",
			$name, "\n";
		
		if (! $opts{'should'}) {
			print "should-flop: ", ($opts{'should'} ? 1 : 0), "\n";
		}
		
		print
			"got:         ", rtrim(define($got)), "\n",
			"should:      ", rtrim(define($should)), "\n",
			"----------------------------------------------------------\n";
	}
	
	# rtok
	return rtok($name, $ok, %opts);
}
#
# rtcomp
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# rtelcount
#

=head2 rtelcount

Checks if an array has the correct number of elements.  The first param is an
integer 0 or greater. The second param is an array reference. So, the following
test would pass:

 rtelcount 'my test', 3, \@arr;

=cut

sub rtelcount {
	my ($name, $arr, $count, %opts) = @_;
	return rtcomp $name, scalar(@$arr), $count, %opts;
}
#
# rtelcount
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rtarr
#

=head2 rtarr

rtarr compares two arrays. In its simplest use, the test passes if they are
identical:

 @first = qw{Larry Curly Moe};
 @second = qw{Larry Curly Moe};
 rtarr 'my test', \@first, \@second;

Like with rtcomp, two undefs are considered the same, so the following test
would pass.

 @first = ('Larry', 'Moe', 'Curly', undef);
 @second = ('Larry', 'Moe', 'Curly', undef);
 rtarr 'my test', \@first, \@second;

rtarr takes several options.

=over

=item * order_insensitive

If the order_insensitive option is true, then the arrays are considered the
same even if the elements are not in the same order. So the following test
would pass:

 @first = ('Curly', 'Larry', 'Moe');
 @second = ('Larry', 'Moe', 'Curly');
 rtarr 'my test', \@first, \@second, order_insensitive=>1;

=item * case_insensitive

If the case_insensitive option is true, then the elements are compared case
insensitively. So the following test would pass:

 @first = ('CURLY', 'LARRY', undef, 'MOE');
 @second = ('Curly', 'Larry', undef, 'Moe');
 rtarr 'my test', \@first, \@second, case_insensitive=>1;

=back

=cut

sub rtarr {
	my ($name, $got, $should, %opts) = @_;
	my ($ok);
	
	# TESTING
	# println subname(); ##i
	
	# default options
	%opts = (should=>1, %opts);
	
	# load Array::Comp
	# require Array::Comp;
	
	# default options
	%opts = (auto_die => 1, %opts);
	
	# get result
	$ok = arrs_same($got, $should, %opts);
	
	# test
	if ( (! should_flop($ok, %opts)) && $auto_die ) {
		# format for printing
		$got = [map({defined($_) ? $_ : '[undef]'} @$got)];
		$should = [map({defined($_) ? $_ : '[undef]'} @$should)];
		
		# top of section
		print "\n=== rtarr fail =============================================\n";
		
		# show should
		if (! $opts{'should'})
			{ print 'should: ', $opts{'should'}, "\n" }
		
		# show $got
		print "--- \$got ---------------------------------------------------\n";
		print join("\n", @$got);
		print "\n";
		
		# TESTING
		# commenting out next section for testing
		
		# show $should
		print "--- \$should ------------------------------------------------\n";
		print join("\n", @$should);
		print "\n";
		
		# bottom of section
		print "===========================================================\n\n\n";
	}
	
	# rtok
	return rtok($name, $ok, %opts);
}
#
# rtarr
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# rthash
#

=head2 rthash

rthash checks is two hashes contain the same keys and values. The following
test would pass. Keep in mind that hashes don't have the concept of order, so
it doesn't matter that the hashes are created with differently ordered keys.

 %first = ( Curly=>'big hair', Moe=>'flat hair', Schemp=>undef);
 %second = ( Moe=>'flat hair', Schemp=>undef, Curly=>'big hair');
 rthash 'my test', \%first, \%second;

rthash doesn't currently have a case_insensitive option. That will probably
be added in future releases.

=cut

sub rthash {
	my ($name, $have_sent, $should_sent, %opts) = @_;
	my (%have, %should, @wrong, $ok);
	
	# TESTING
	# println subname(); ##i
	
	# special case: if either is undef, return false
	unless (defined($have_sent) && defined($should_sent)) {
		if ($opts{'auto_die'}) {
			print 'got:    ', $have_sent, "\n";
			print 'should: ', $should_sent, "\n";
			croak 'at least one hash not defined';
		}
		
		return 0;
	}
	
	# get hashes we can play with
	%have = %$have_sent;
	%should = %$should_sent;
	
	# loop through values in %should
	foreach my $key (keys %should) {
		# if key doesn't exist
		if (exists $have{$key}) {
			if (neqq($have{$key}, $should{$key})) {
				push @wrong,
					'have:   ' . showval($have{$key}) . "\n" .
					'should: ' . showval($should{$key});
			}
			
			delete $have{$key};
		}
		
		else {
			push @wrong, "Do not have key: $key";
		}
	}
	
	# if anything left in %keys_have
	foreach my $key (keys %have)
		{ push @wrong, "Have unexpected key: $key" }
	
	# decide if anything wrong
	$ok = @wrong ? 0 : 1;
	
	# autodie if necessary
	if ( (! should_flop($ok, %opts)) && $auto_die ) {
		croak 'hashes are not identical';
	}
	
	# call rtok
	rtok($name, $ok, %opts);
}
#
# rthash
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# rtisa
#

=head2 rtisa

rtisa tests if a given value is of the given class. For example, the following
test would pass.

 $val = [];
 rtisa 'my test', $val, 'ARRAY';

The second value can be either the name of the class or an example of the
class, so the following test would also pass.

 $val = [];
 rtisa 'my test', $val, [];

If the class is undef or an empty string, then rtisa returns true if the given
object is not a reference.

 $val = 'whatever';
 rtisa 'my test', $val, '';

=cut

sub rtisa {
	my ($name, $have, $should, %opts) = @_;
	my ($ok, $not);
	
	# TESTING
	# println subname(); ##i
	
	# if $should is an object, get the class of the object
	if (ref $should)
		{ $should = ref($should) }
	
	# if defined $should, set $isa from UNIVERSAL::isa
	if ( defined($should) && length($should) ) {
		$ok = UNIVERSAL::isa($have, $should);
	}
	
	# else $have should not have a ref
	else {
		$ok = ref($have) ? 0 : 1;
	}
	
	# return rtok
	return rtok($name, $ok, %opts);
}
#
# rtisa
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rtbool
#

=head2 rtbool

rtbool checks if two values have the same boolean value, that is, if they are
both true or both false. Booleans are checked in the perlish sense, so the
values don't have to be the same, they just have to have the same perlish
boolean values. Here are some examples.

 rtbool 'my test', 'whatever', 'dude'; # passes
 rtbool 'my test', 'whatever', 1;      # passes
 rtbool 'my test', 'whatever', undef;  # fails
 rtbool 'my test', 0, undef;           # passes

=cut

sub rtbool {
	my ($name, $is, $should, %opts) = @_;
	
	# TESTING
	# println subname(); ##i
	# showvar $is;
	# showvar $should;
	
	# default options
	%opts = (auto_die=>1, %opts);
	
	# normalize
	$is = $is ? 'true' : 'false';
	$should = $should ? 'true' : 'false';
	
	# TESTING
	# showvar $is;
	# showvar $should;
	
	# compare
	return rtcomp($name, $is, $should, %opts);
}
#
# rtbool
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rtdef
#

=head2 rtdef

rtdef tests if the given value is defined. The second param is the value being
tested, the third param is if the value should be defined or not. So, the
following tests would pass.

 rtdef 'my test', 'hello', 1;
 rtdef 'my test', undef, 0;

The third param must be defined.

=cut

sub rtdef {
	my ($name, $is, $should, %opts) = @_;
	
	# TESTING
	# println subname(); ##i
	# showvar $is;
	# showvar $should;
	
	# $should must be defined
	if (! defined $should) {
		croak 'rtdef-should-not-defined: "should" should be defined in rtdef';
	}
	
	# compare
	return rtbool($name, defined($is), $should, %opts);
}
#
# rtdef
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# rtrx
#

=head2 rtrx

rtrx tests if the given value matches the given regular expression. The
following test would pass.

 rtrx 'my test', 'Fred', 'red';

If you want to get fancy with your regular expressions, use qr// to create the
regexes as you pass them in. The following test is an example.

 rtrx 'my test', 'Fred', qr/RED$/i;

=cut

sub rtrx {
	my ($name, $got, $rx, %opts) = @_;
	my ($ok);
	
	# TESTING
	# println subname(); ##i
	
	# default options
	%opts = (should=>1, %opts);
	
	# get result
	if (defined $got) {
		$ok = $got =~ m|$rx|s;
	}
	else {
		$ok = 0;
	}
	
	# test
	if ( (! should_flop($ok, %opts)) && $auto_die ) {
		
		# top of section
		print "\n=== rtrx fail ============================================\n";
		
		# show should
		if (! $opts{'should'})
			{ print 'should: ', $opts{'should'}, "\n" }
		
		# show $rx
		print "--- \$rx ----------------------------------------------------\n";
		print $rx;
		print "\n";
		
		# show $got
		print "--- \$should ------------------------------------------------\n";
		print $got;
		print "\n";
		
		# bottom of section
		print "===========================================================\n\n\n";
	}
	
	# rtok
	return rtok($name, $ok, %opts);
}
#
# rtrx
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# rtfile
#

=head2 rtfile

rtfile tests if the given file path exists. In its simplest use, rtfile takes
just the name of the file and the path:

 rtfile 'my test', '/tmp/log.txt';

You can use the C<should> option to test if the file B<doesn't> exist:

 rtfile 'my test', '/tmp/log.txt', should=>0;

=cut

sub rtfile {
	my ($name, $path, %opts) = @_;
	my ($ok);
	
	# TESTING
	# println subname(); ##i
	
	# default options
	%opts = (should=>1, %opts);
	
	# get existence of path
	$ok = -e($path);
	
	# throw error if not as should
	if ( (! should_flop($ok, %opts)) && $auto_die ) {
		croak
			'file ' . $path . ' should ' .
			($opts{'should'} ? '' : 'not ') . 'exist';
	}
	
	# return rtok
	return rtok($name, $ok, %opts);
}
#
# rtfile
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# message id tests
#

=head1 Message ID tests

The following tests checking for errors that begin with an error code, followed
by a colon, followed by plain language. For example:

 croak 'error-opening-log-file: error opening log file';

Note that the error ID must be followed by a colon.

=cut

#
# message id tests
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rtid
#

=head2 rtid()

rtid() checks if the given string starts with the given id. For example, to
test is $! starts with the id 'error-opening-log-file' you would use this command:

 rtid 'my test', $!, 'error-opening-log-file';

=cut

sub rtid {
	my ($name, $is, $should, %opts) = @_;
	
	# TESTING
	# println subname(); ##i
	# showvar $is;
	# showvar $should;
	
	# get id of $is
	if (defined $is)
		{ $is =~ s|\:.*||s }
	else
		{ $is = '' }
	
	# get id of $should or set it to empty string
	if (defined $should)
		{ $should =~ s|\:.*||s }
	else
		{ $should = '' }
	
	# TESTING
	# showvar $is;
	# showvar $should;
	
	# compare
	return rtcomp($name, $is, $should, %opts);
}
#
# rtid
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rteval
#

=head2 rteval()

rteval() allows you to test some code then check for an error id, all in one
easy command. rteval runs the given subroutine in an eval{} block, then tests
Here's an (admittedly contrived) example:

 rteval
   'my test',
   sub { die 'error-opening-log-file: whatever' },
   'error-opening-log-file';

If your subroutine is really long, you might prefer to put the id as the first
param, then the sub.  rteval() provides some forgivness in that regard: if the
second param is a sub, then the first param is assumed to be the id. So the
following example works the same as the above example:

 rteval
   'my test',
   'error-opening-log-file',
   sub { die 'error-opening-log-file: whatever' };

If the sub is supposed to work, you can put undef for the expected code:

 rteval
   'my test',
   sub { my $val = 1 },
   undef;

=cut

sub rteval {
	my ($name, $id_should, $code, %opts) = @_;
	my ($result);
	
	# TESTING
	# println subname(); ##i
	# println ref($id_should);
	
	# build in a little forgiveness
	if (UNIVERSAL::isa $id_should, 'CODE')
		{ ($id_should, $code) = ($code, $id_should) }
	
	# eval code
	eval { &$code() };
	
	# test results of eval
	return rtid($name, $@, $id_should, %opts);
}
#
# rteval
#------------------------------------------------------------------------------


#
# public methods
###############################################################################




###############################################################################
# private methods
#


#------------------------------------------------------------------------------
# showval
#
sub showval {
	my ($val) = @_;
	
	# if not defined, return [undef]
	if (! defined $val) {
		return '[undef]';
	}
	
	# else just return value
	return $val;
}
#
# showval
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# eqq, neqq
#
sub eqq {
	my ($str1, $str2) = @_;
	
	# if both defined
	if ( defined($str1) && defined($str2) )
		{ return $str1 eq $str2 }
	
	# if neither are defined 
	if ( (! defined($str1)) && (! defined($str2)) )
		{ return 1 }
	
	# only one is defined, so return false
	return 0;
}

sub neqq {
	return eqq(@_) ? 0 : 1;
}
#
# eqq, neqq
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ok_private
# private method
#
sub ok_private {
	my($name, $bool) = @_;
	
	# my $tb = Test::More->builder;
	my $tb = Test::Builder::Module->builder;
	
	return $tb->ok($bool, $name);
}
#
# ok_private
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# should_flop
#
sub should_flop {
	my ($ok, %opts) = @_;
	
	# TESTING
	# println subname; ##i
	
	# default %opts
	%opts = (should=>1, %opts);
	
	# reverse $ok if necessary
	if (! $opts{'should'})
		{ $ok = ! $ok }
	
	# set ok to strict boolean
	$ok = $ok ? 1 : 0;
}
#
# should_flop
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# arrs_same
#
sub arrs_same {
	my ($alpha_sent, $beta_sent, %opts) = @_;
	my (@alpha, @beta);
	
	# both must be array references
	unless (
		UNIVERSAL::isa($alpha_sent, 'ARRAY') &&
		UNIVERSAL::isa($beta_sent, 'ARRAY')
		)
		{ croak 'both params must be array references' }
	
	# if they have different lengths, they're different
	if (@$alpha_sent != @$beta_sent)
		{ return 0 }
	
	# get arrays to use for comparison
	@alpha = @$alpha_sent;
	@beta = @$beta_sent;
	
	# if case insensitive
	if ($opts{'case_insensitive'}) {
		grep {if (defined $_) {$_ = lc($_)}} @alpha;
		grep {if (defined $_) {$_ = lc($_)}} @beta;
	}
	
	# if order insensitive
	if ($opts{'order_insensitive'}) {
		@alpha = comp_sorter(@alpha);
		@beta = comp_sorter(@beta);
	}
	
	# loop through array elements
	for (my $i=0; $i<=$#alpha; $i++) {
		# if one is undef but other isn't
		if (
			( (  defined $alpha[$i]) && (! defined $beta[$i]) ) ||
			( (! defined $alpha[$i]) && (  defined $beta[$i]) )
			) {
			return 0;
		}
		
		# if $alpha[$i] is undef then both must be, so they're the same
		elsif (! defined $alpha[$i]) {
		}
		
		# both are defined
		else {
			unless ($alpha[$i] eq $beta[$i])
				{ return 0 }
		}
	}
	
	# if we get this far, they're the same
	return 1;
}
#
# arrs_same
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# comp_sorter
#
sub comp_sorter {
	return sort {
		# if both undefined, return 0
		if ( (! defined $a) && (! defined $b) )
			{ return 0 }
		
		# if just $a isn't defined, return -1
		elsif ( ! defined $a )
			{ return -1 }
		
		# if just $b isn't defined, return 1
		elsif ( ! defined $b )
			{ return 1 }
		
		# else return string comparison
		$a cmp $b;
	} @_;
}
#
# comp_sorter
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# ltrim, rtrim
#
sub ltrim {
	my ($rv) = @_;
	
	if (defined $rv)
		{ $rv =~ s|\s+$||s }
	
	return $rv;
}

sub rtrim {
	my ($rv) = @_;
	
	if (defined $rv)
		{ $rv =~ s|^\s+||s }
	
	return $rv;
}
#
# ltrim, rtrim
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# define
#
sub define {
	my ($val) = @_;
	
	# if defined, return it
	if (defined $val)
		{ return $val }
	
	# else return empty string
	return '';
}
#
# define
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# collapse
#
sub collapse {
	my ($val) = @_;
	
	if (defined $val) {
		$val =~ s|^\s+||s;
		$val =~ s|\s+$||s;
		$val =~ s|\s+| |sg;
	}
	
	return $val;
}
#
# collapse
#------------------------------------------------------------------------------


#
# private methods
###############################################################################


# return true
1;
__END__


#------------------------------------------------------------------------------
# closing pod
#

=head1 TERMS AND CONDITIONS

Copyright (c) 2016 by Miko O'Sullivan. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself. This software comes with NO WARRANTY of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

Version: 0.04

=head1 HISTORY

=over

=item * Version 0.01 Aug 21, 2016

Initial release.

=item * Version 0.02 Aug 23, 2016

Fixed dependency problem. Should not have been using String::Util.

=item * Version 0.03 Aug 25, 2016

Added private sub collapse() which should have been in there all along.

=item * Version 0.04 Aug 26, 2016

Added private subs define(), rtrim(), ltrim() which should have been there
all along.

Added rtdiag().  Not sure how to test rtdiag(), so for now no tests for that.

May have fixed test for rtfile().

=back

=cut

#
# closing pod
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# module info
# This info is used by a home-grown CPAN module builder. This info has no use
# in the wild.
#
{
	# include in CPAN distribution
	include : 1,
	
	# allow modules
	allow_modules : {
	},
	
	# test scripts
	test_scripts : {
		'Toolbox/tests/tests.pl' : 1,
		'Toolbox/tests/myfile.txt' : 1,
	},
}
#
# module info
#------------------------------------------------------------------------------
