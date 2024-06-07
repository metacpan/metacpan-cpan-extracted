package Test::Module::Runnable::Base;
# Module test framework
# Copyright (c) 2015-2024, Duncan Ross Palmer (2E0EOL) and others,
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#     * Neither the name of the Daybo Logic nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

=head1 NAME

Test::Module::Runnable::Base - See L<Test::Module::Runnable>

=head1 DESCRIPTION

This is the base class for L<Test::Module::Runnable>, and all user-documentation
must be sought there.

A few internal-only methods are documented here for project maintainers.

=cut

use Data::Dumper;
use Moose;

BEGIN {
	our $VERSION = '0.6.1';
}

use POSIX qw/EXIT_SUCCESS/;
use Readonly;
use Test::MockModule;
use Test::More 0.96;

Readonly my @UNIQUE_STR_CHARS => ('a'..'z', 'A'..'Z', '0'..'9');
Readonly my @UNIQUE_STR_CI_CHARS => ('a'..'z', '0'..'9');
Readonly my @UNIQUE_LETTERS_CHARS => ('a'..'z');

Readonly my $DOMAIN_DEFAULT => 'db3eb5cf-a597-4038-aea8-fd06faea6eed';

# This hash tracks the numbers returned from C<unique>.
my %__unique;

# This counter used by the uniqueDomain() function
my $__domainCounter;

# nb. don't add any more static globals here; Construct the object where needed, on the fly, even if you
# have not subclassed it, in legacy tests

=head1 ATTRIBUTES

=over

=item C<sut>

See L<Test::Module::Runnable/sut>

=cut

has 'sut' => (is => 'rw', required => 0);

=item C<pattern>

See L<Test::Module::Runnable/pattern>

=cut

has 'pattern' => (is => 'ro', isa => 'Regexp', default => sub { qr/^test/ });

=item C<logger>

See L<Test::Module::Runnable/logger>

=cut

has 'logger' => (is => 'rw', required => 0);

=item C<mocker>

See L<Test::Module::Runnable/mocker>

=cut

has 'mocker' => (
	is => 'rw',
	isa => 'Maybe[Test::MockModule]',
	required => 0,
	default => undef,
);

=back

=head1 PRIVATE ATTRIBUTES

=over

=item C<__unique>

Tracks the counter returned by C<unique>.
Always contains the previous value returned, or zero before any calls.
A hash is used to support multiple domains.

=cut

has '__unique' => (
	is => 'ro',
	isa => 'HashRef[Int]',
	default => sub {
		{ }
	},
);

=item C<__random>

Hash of random numbers already given out.

=cut

has '__random' => (
	is => 'ro',
	isa => 'HashRef[Int]',
	default => sub {
		{ }
	},
);

=back

=head1 METHODS

=over

=item C<unique>

See L<Test::Module::Runnable/unique>

=cut

sub unique {
	my (@args) = @_;
	confess('Suspected incorrect call: Test::Module::Runnable->unique(...)') if ($args[0] && $args[0] eq __PACKAGE__);

	shift(@args) if ref($args[0]);
	my $domain = $args[0];

	if (!defined($domain) || length($domain) == 0) {
		$domain = $DOMAIN_DEFAULT;
	} elsif ($domain eq 'rand') {
		return $__unique{$domain} = int(rand(999_999_999));
	}

	if (!defined($__unique{$domain}) && $ENV{TEST_UNIQUE}) {
		$__unique{$domain} = int($ENV{TEST_UNIQUE}) - 1; # we add 1 to first return value below
	}

	return ++$__unique{$domain};
}

=item C<uniqueStr([$length])>

See L<Test::Module::Runnable/uniqueStr($length)>

=cut

sub uniqueStr {
	my (@args) = @_;
	return __uniqueStrHelper(\@UNIQUE_STR_CHARS, @args);
}

=item C<uniqueStrCI($length)>

See L<Test::Module::Runnable/uniqueStrCI($length)>

=cut

sub uniqueStrCI {
	my (@args) = @_;
	return __uniqueStrHelper(\@UNIQUE_STR_CI_CHARS, @args);
}

=item C<uniqueDomain([$options])>

See L<Test::Module::Runnable/uniqueDomain([$options])>

=cut

sub uniqueDomain {
	my (@args) = @_;

	shift @args if ref($args[0]); # Remove $self
	my ($options) = (@args);

	my $counter = ++$__domainCounter;
	my $extraParts = ($counter % 4);

	my $firstPart = __domainPart($counter, -1, $options);
	return lc join('.', $firstPart, (map { __domainPart($counter, $_, $options) } 0..$extraParts), 'test');
}

=item C<uniqueLetters($length)>

See L<Test::Module::Runnable/uniqueLetters($length)>

=cut

sub uniqueLetters {
	my (@args) = @_;
	return __uniqueStrHelper(\@UNIQUE_LETTERS_CHARS, @args);
}

=item C<methodNames>

See L<Test::Module::Runnable/methodNames>

=cut

sub methodNames {
	my ($self) = @_;
	my @ret = ( );
	my @methodList = $self->meta->get_all_methods();

	foreach my $method (@methodList) {
		$method = $method->name;
		next unless ($self->can($method)); # Skip stuff we cannot do
		next if ($method !~ $self->pattern); # Skip our own helpers
		push(@ret, $method);
	}

	return @ret;
}

=item C<methodCount>

See L<Test::Module::Runnable/methodCount>

=cut

sub methodCount {
	my ($self) = @_;
	return scalar($self->methodNames());
}

=item C<run>

See L<Test::Module::Runnable/run>

=cut

sub run {
	my ($self, %params) = @_;
	my ($fail, @tests) = (0);

	$params{n} = 1 unless ($params{n});

	if (ref($params{tests}) eq 'ARRAY') { # User specified
		@tests = @{ $params{tests} };
	} else {
		@tests = $self->methodNames();
		if (@ARGV) {
			my @userRunTests = ( );
			foreach my $testName (@tests) {
				foreach my $arg (@ARGV) {
					next if ($arg ne $testName);
					push(@userRunTests, $testName);
				}
			}

			if (scalar(@userRunTests) > 0) {
				@tests = @userRunTests;
			}
		}
	}

	plan tests => scalar(@tests) * $params{n};

	$fail = $self->setUpBeforeClass(); # Call any registered pre-suite routine
	$self->__wrapFail('setUpBeforeClass', undef, $fail);
	for (my $i = 0; $i < $params{n}; $i++) {
		foreach my $method (@tests) {
			my $printableMethodName;

			# Run correct test (or all)
			$printableMethodName = $self->__generateMethodName($method);

			$fail = 0;

			# Check if user specified just one test, and this isn't it
			confess(sprintf('Test \'%s\' does not exist', $method))
				unless $self->can($method);

			$fail = $self->setUp(method => $method); # Call any registered pre-test routine
			$self->__wrapFail('setUp', $method, $fail);

			subtest $printableMethodName => sub {
				$fail = $self->$method(
					method => $method,
					printableMethodName => $printableMethodName,
				);
			};

			$self->__wrapFail('method', $method, $fail);
			$self->mocker->unmock_all() if ($self->mocker);
			$fail = 0;
			$fail = $self->tearDown(method => $method); # Call any registered post-test routine
			$self->__wrapFail('tearDown', $method, $fail);
		}
		$fail = $self->modeSwitch($i);
		$self->__wrapFail('modeSwitch', $self->sut, $fail);
	}
	$fail = $self->tearDownAfterClass(); # Call any registered post-suite routine
	$self->__wrapFail('tearDownAfterClass', undef, $fail);

	return EXIT_SUCCESS;
}

=item C<debug>

See L<Test::Module::Runnable/debug>

=cut

sub debug {
	my (undef, $format, @params) = @_;
	return unless ($ENV{'TEST_VERBOSE'});
	diag(sprintf($format, @params));
	return;
}

=item C<mock($class, $method, $return)>

See L<mock($class, $method, $return)>

=cut

sub mock {
	my ($self, $class, $method, $return) = @_;

	unless ($class->can($method) || $class->can('AUTOLOAD')) {
		BAIL_OUT("Cannot mock $class->$method because it doesn't exist and $class has no AUTOLOAD")
	}

	die('$return must be CODE or ARRAY ref') if defined($return) && ref($return) ne 'CODE' && ref($return) ne 'ARRAY';

	unless ($self->{mock_module}->{$class}) {
		$self->{mock_module}->{$class} = Test::MockModule->new($class);
	}

	$self->{mock_module}->{$class}->mock($method, sub {
		my @ret;
		my @args = @_;

		push @{$self->{mock_args}->{$class}->{$method}}, [@args];

		if ($return) {
			my ($val, $empty);
			if (ref($return) eq 'ARRAY') {
				# $return is an array ref, so shift the next value
				if (@$return) {
					$val = shift @$return;
				} else {
					$empty = 1;
				}
			} else {
				# here $return must be a CODE ref, so just set $val
				# and carry on.
				$val = $return;
			}

			if (ref($val) eq 'CODE') {
				if (wantarray) {
					@ret = $val->(@_);
				} else {
					$ret[0] = scalar $val->(@_);
				}
			} else {
				# just return this value, unless we're in the case
				# where we exhausted the array, in which case we
				# don't set this - it would make us return (undef)
				# rather than empty list in list context.
				$ret[0] = $val unless $empty;
			}
		}

		# TODO: When running the CODE ref above, we should catch any fatal error,
		# log them here, and then re-throw the error.
		shift @args;
		$self->debug(sprintf('%s::%s(%s) returning (%s)',
				$class, $method, _mockdump(\@args), _mockdump(\@ret)));
		return (wantarray ? @ret : $ret[0]);
	});

	return;
}

=item unmock([class], [$method])

See L<Test::Module::Runnable/unmock([class], [$method])>

=cut

sub unmock {
	my ($self, $class, $method) = @_;

	if (!$class) {
		die('It is not legal to unmock a method in many or unspecified classes') if ($method);
		$self->clearMocks;
	} elsif (!$method) {
		delete($self->{mock_module}->{$class});
		delete($self->{mock_args}->{$class});
	} else {
		if ($self->{mock_module}->{$class}) {
			$self->{mock_module}->{$class}->unmock($method);
		}
		delete($self->{mock_args}->{$class}->{$method});
	}

	return $self;
}

=item C<mockCalls($class, $method)>

See L<Test::Module::Runnable/mockCalls($class, $method)>

=cut

sub mockCalls {
	my ($self, $class, $method) = @_;
	return $self->__mockCalls($class, $method);
}

=item C<mockCallsWithObject($class, $method)>

See L<Test::Module::Runnable/mockCallsWithObject($class, $method)>

=cut

sub mockCallsWithObject {
	my ($self, $class, $method) = @_;
	return $self->__mockCalls($class, $method, withObject => 1);
}

=item C<clearMocks>

See L<Test::Module::Runnable/clearMocks>

=cut

sub clearMocks {
	my ($self) = @_;

	$self->{mock_module} = {};
	$self->{mock_args} = {};
	return;
}

=back

=head1 USER DEFINED METHODS

=over

=item C<setUpBeforeClass>

See L<Test::Module::Runnable/setUpBeforeClass>

=item C<tearDownAfterClass>

See L<Test::Module::Runnable/tearDownAfterClass>

=back

=head1 PROTECTED METHODS

=over

=item C<_mockdump>

See L<Test::Module::Runnable/_mockdump>

=cut

sub _mockdump {
	my ($arg) = @_;
	my $dumper = Data::Dumper->new([$arg], ['arg']);
	$dumper->Indent(1);
	$dumper->Maxdepth(1);
	my $str = $dumper->Dump();
	$str =~ s/\n\s*/ /g;
	$str =~ s/^\$arg = \[\s*//;
	$str =~ s/\s*\];\s*$//s;
	return $str;
}

=back

=head1 PRIVATE METHODS

=over

=item C<__mockCalls>

Helper method used by L</mockCalls($class, $method)> and L</mockCallsWithObject($class, $method)>.

=cut

sub __mockCalls {
	my ($self, $class, $method, %args) = @_;

	my $calls = $self->{mock_args}->{$class}->{$method} || [];
	unless ($args{withObject}) {
		# This ugly code takes $calls, which is a an arrayref
		# of arrayrefs, and maps it into a new arrayref, where
		# each inner arrayref is a copy of the original, with the
		# first element removed (i.e. the object reference).
		#
		# i.e. given $calls = [
		#    [ $obj, $arg1, $arg2 ],
		#    [ $obj, $arg3, $arg4 ],
		# ]
		# this will set $calls = [
		#    [ $arg1, $arg2 ],
		#    [ $arg3, $arg4 ],
		# ]
		$calls = [ map { [ @{$_}[1..$#$_] ] } @$calls ];
	}

	return $calls;
}

=item __generateMethodName

This method returns the current mode of testing the C<sut> as defined
in a class derived from L<Test::Module::Runnable>, as a string including the
current test method, given to this function.

If the subclass has not defined C<modeName> as a method or attribute,
or it is C<undef>, we return the C<methodName> passed, unmodified.

=over

=item C<methodName>

The name of the method about to be executed.  Must be a valid string.

=back

=cut

sub __generateMethodName {
	my ($self, $methodName) = @_;
	my $modeName = $self->modeName;

	return $methodName unless (defined($modeName) && length($modeName)); # Simples
	return sprintf('[%s] %s', $self->modeName, $methodName);
}

=item C<__wrapFail>

Called within L</run> in order to call L<Test::Builder/BAIL_OUT> with an appropriate message -
it essentially a way to wrap failures from user-defined methods.

As soon as the user-defined method is called, call this method with the following arguments:

=over

=item C<$type>

The name of the user-defined method, for example, 'setUp'

=item C<$method>

The name of the user test method, for example, 'testMyTestMethod'

=item C<$fail>

The exit code from the user-defined method.  Not a boolean.  If not C<EXIT_SUCCESS>,
C<BAIL_OUT> will be called.

=back

There is no return value.

=cut

sub __wrapFail {
	my ($self, $type, $method, $returnValue) = @_;
	return if (defined($returnValue) && $returnValue eq '0');
	if (!defined($method)) { # Not method-specific
		BAIL_OUT('Must specify type when evaluating result from method hooks')
			if ('setUpBeforeClass' ne $type && 'tearDownAfterClass' ne $type);

		$method = 'N/A';
	}
	return BAIL_OUT($type . ' returned non-zero for ' . $method);
}

=item C<__uniqueStrHelper(@args)>

Helper method for L</uniqueStr([$length])>.

=cut

sub __uniqueStrHelper {
	my (@args) = @_;
	my $chars = shift(@args);
	my $len = scalar(@$chars);

	my $func = (caller(1))[3];
	$func =~ s/.*:://;
	confess("Suspected incorrect call: Test::Module::Runnable->$func") if ($args[0] && $args[0] eq __PACKAGE__);

	shift(@args) if ref($args[0]);
	my $length = $args[0];
	my $str = '';

	# default length 1
	$length = 1 unless(defined($length));

	my $num = unique();
	my $oddOrEven = ($num % 2);
	while ($num > 0 || length($str) < $length) {
		# This character will be the current number modulo the character set length
		my $modulo = $num % $len;

		# use any remainder next time through
		$num = int($num / $len);

		my $char = $chars->[$modulo];
		if ($chars == \@UNIQUE_STR_CI_CHARS && length($str) % 2 == $oddOrEven) {
			$char = uc($char);
		}

		$str = $char . $str;
	}

	$str = __uniqueStrHelper($chars, $length) if ($str eq '0'); # unacceptable

	return $str;
}

=item C<__domainPart>

Helper method used by L</uniqueDomain([$options])> to construct a single part of a domain name.

Returns a string.

=cut

sub __domainPart {
	my ($counter, $pos, $options) = @_;

	my $length;
	if ($pos < 0 && $options->{length}) {
		# Use specified length, if there is one, for the first part only.
		$length = $options->{length};
	}

	# arbitrary calculation to come up with varying but
	# predictable lengths for a given counter (n-th domain created)
	# and position $pos within the domain
	$length = 1 + (($counter * 7 ^ $pos) % 5) unless $length;

	my $str = $options->{lettersOnly} ? uniqueLetters($length) : uniqueStrCI($length);
	$str = uniqueLetters(1).$str unless $str =~ /^[a-z]/i;

	return $str;
}

=back

=cut

1;
