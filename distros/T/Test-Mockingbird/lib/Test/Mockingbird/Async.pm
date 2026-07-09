package Test::Mockingbird::Async;

use strict;
use warnings;

use Carp qw(croak);
use Exporter 'import';
use Test::Mockingbird ();

our @EXPORT_OK = qw(
	mock_future_return
	mock_future_fail
	mock_future_sequence
	mock_future_once
	async_spy
);

=head1 NAME

Test::Mockingbird::Async - Future-based async mocking for Test::Mockingbird

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Test::Mockingbird;
    use Test::Mockingbird::Async qw(
        mock_future_return
        mock_future_fail
        mock_future_sequence
        mock_future_once
        async_spy
    );

    # Mock a method to return a pre-resolved Future
    mock_future_return 'My::DB::fetch' => { id => 1 };
    my $result = My::DB::fetch()->get;   # { id => 1 }

    # Mock a method to return a pre-failed Future
    mock_future_fail 'My::DB::fetch' => 'not found';
    my ($msg) = My::DB::fetch()->failure;   # 'not found'

    # Return different values over successive calls
    mock_future_sequence 'My::DB::fetch' => (10, 20, 30);
    My::DB::fetch()->get;   # 10
    My::DB::fetch()->get;   # 20
    My::DB::fetch()->get;   # 30 (repeated from here)

    # Return a Future exactly once, then restore the previous implementation
    mock_future_once 'My::DB::ping' => 'ok';
    My::DB::ping()->get;   # 'ok', then original restored

    # Spy on a method that returns a Future
    my $spy = async_spy 'My::DB::fetch';
    My::DB::fetch('key');
    my @calls = $spy->();
    my $call = $calls[0];
    # $call->{args}   is [ 'My::DB::fetch', 'key' ]
    # $call->{future} is the Future returned by the original

    restore_all();

=head1 DESCRIPTION

C<Test::Mockingbird::Async> extends L<Test::Mockingbird> with helpers for
testing code that uses L<Future>-based asynchronous APIs.

All mocks and spies installed by this module use the same underlying stack
as the core engine. C<restore_all()>, C<unmock()>, and C<diagnose_mocks()>
work identically to their core counterparts. Every installed layer is
recorded in C<diagnose_mocks()> with a type of C<mock_future_return>,
C<mock_future_fail>, C<mock_future_sequence>, C<mock_future_once>, or
C<async_spy>.

C<async_spy> also writes to the call-order log, so
C<assert_call_order()> works across a mix of plain spies and async spies.

=head2 Dependency

This module requires the L<Future> distribution (available from CPAN).
It is not a mandatory dependency of L<Test::Mockingbird> itself; the
module loads C<Future> on first use and croaks with a helpful message if
it is not installed.

=head1 METHODS

=head2 mock_future_return

Mock a method so that it always returns a pre-resolved C<Future>.

    mock_future_return 'My::DB::fetch' => $value;
    mock_future_return 'My::DB::fetch' => ($val1, $val2);   # multi-value

The method is replaced with a stub that returns C<Future->done(@values)>.
Restore with C<restore_all()> or C<unmock()>.

=head3 API specification

=head4 Input (Params::Validate::Strict schema)

- C<target>: required, scalar string; shorthand C<'Pkg::method'> form
- C<@values>: zero or more values passed to C<Future->done>

=head4 Output (Returns::Set schema)

- C<return>: undef

=cut

sub mock_future_return {
	my ($target, @values) = @_;

	croak 'mock_future_return requires a target' unless defined $target;

	_require_future();

	local $Test::Mockingbird::TYPE = 'mock_future_return';
	Test::Mockingbird::mock($target, sub { Future->done(@values) });

	return;
}

=head2 mock_future_fail

Mock a method so that it always returns a pre-failed C<Future>.

    mock_future_fail 'My::DB::fetch' => 'not found';
    mock_future_fail 'My::DB::fetch' => ('db error', 'db', { code => 500 });

The method is replaced with a stub that returns
C<Future->fail($message, @details)>. The caller receives a rejected Future;
no exception is thrown at the call site.

=head3 API specification

=head4 Input (Params::Validate::Strict schema)

- C<target>: required, scalar string
- C<$message>: required, scalar string; the failure message
- C<@details>: optional; additional failure metadata passed to C<Future->fail>

=head4 Output (Returns::Set schema)

- C<return>: undef

=cut

sub mock_future_fail {
	my ($target, $message, @details) = @_;

	croak 'mock_future_fail requires a target and a failure message'
		unless defined $target && defined $message;

	_require_future();

	local $Test::Mockingbird::TYPE = 'mock_future_fail';
	Test::Mockingbird::mock($target, sub { Future->fail($message, @details) });

	return;
}

=head2 mock_future_sequence

Mock a method so that it returns a sequence of C<Future> values over
successive calls. When the sequence is exhausted, the last item is repeated.

    mock_future_sequence 'My::DB::fetch' => (10, 20, 30);
    My::DB::fetch()->get;   # 10
    My::DB::fetch()->get;   # 20
    My::DB::fetch()->get;   # 30 (repeats)

Each item in the sequence may be either a plain value (wrapped automatically
in C<Future->done>) or a pre-built C<Future> object (passed through as-is,
allowing a mix of resolved and failed Futures in the sequence):

    mock_future_sequence 'My::DB::fetch' =>
        42,
        Future->fail('oops');

=head3 API specification

=head4 Input (Params::Validate::Strict schema)

- C<target>: required, scalar string
- C<@items>: required; one or more plain values or C<Future> objects

=head4 Output (Returns::Set schema)

- C<return>: undef

=cut

sub mock_future_sequence {
	my ($target, @items) = @_;

	croak 'mock_future_sequence requires a target and at least one item'
		unless defined $target && @items;

	_require_future();

	my @queue = @items;

	local $Test::Mockingbird::TYPE = 'mock_future_sequence';
	Test::Mockingbird::mock($target, sub {
		my $item = @queue == 1 ? $queue[0] : shift @queue;
		# Pass pre-built Futures through unchanged; wrap plain values
		return (ref $item && $item->isa('Future')) ? $item : Future->done($item);
	});

	return;
}

=head2 mock_future_once

Install a mock that returns a pre-resolved C<Future> exactly once. After the
first call the previous implementation is automatically restored.

    mock_future_return 'My::DB::ping' => 'baseline';
    mock_future_once   'My::DB::ping' => 'temporary';

    My::DB::ping()->get;   # 'temporary'
    My::DB::ping()->get;   # 'baseline' (previous mock restored)

This is useful for simulating transient failures, one-time responses, or
state transitions in async code.

=head3 API specification

=head4 Input (Params::Validate::Strict schema)

- C<target>: required, scalar string
- C<@values>: zero or more values passed to C<Future->done>

=head4 Output (Returns::Set schema)

- C<return>: undef

=cut

sub mock_future_once {
	my ($target, @values) = @_;

	croak 'mock_future_once requires a target' unless defined $target;

	_require_future();

	my ($package, $method) = Test::Mockingbird::_parse_target($target);

	my $wrapper = sub {
		my $future = Future->done(@values);
		Test::Mockingbird::unmock($package, $method);
		return $future;
	};

	local $Test::Mockingbird::TYPE = 'mock_future_once';
	Test::Mockingbird::mock($target, $wrapper);

	return;
}

=head2 async_spy

Wrap a method so that every call is recorded along with the C<Future> it
returned. The original method is still called and its return value is
passed back to the caller unchanged.

    my $spy = async_spy 'My::DB::fetch';
    My::DB->fetch(id => 1);

    my @calls = $spy->();

    my $call = $calls[0];
    # $call->{args}   is [ 'My::DB::fetch', $invocant, id => 1 ]
    # $call->{future} is whatever Future the original returned

    my $result = $call->{future}->get;   # inspect resolved value

Unlike the plain C<spy()> coderef (which returns arrayrefs), C<async_spy>
returns hashrefs so the C<future> field is unambiguous.

C<async_spy> writes to the call-order log, so C<assert_call_order()> works
across a mix of plain and async spies.

=head3 Limitations

C<async_spy> assumes the spied method returns a C<Future>. If the method
returns a plain value the C<future> field in each call record will hold that
value rather than a C<Future>, and calling C<< ->get >> on it will fail.

=head3 API specification

=head4 Input (Params::Validate::Strict schema)

- C<target>: required; C<'Pkg::method'> shorthand or C<('Pkg', 'method')> longhand

=head4 Output (Returns::Set schema)

- C<return>: coderef; when called, returns the list of call records

=cut

sub async_spy {
	_require_future();

	my ($package, $method) = Test::Mockingbird::_parse_target(@_);

	croak 'Package and method are required for async_spy'
		unless $package && $method;

	my $full_method = "${package}::${method}";

	# Capture current implementation so the wrapper can delegate to it.
	# mock() will also capture it independently for stack bookkeeping;
	# both captures see the same coderef at this point.
	my $orig;
	{
		## no critic (ProhibitNoStrict)
		no strict 'refs';
		$orig = \&{$full_method};
	}

	my @calls;

	my $wrapper = sub {
		my @call_args = @_;
		my $future    = $orig->(@call_args);
		push @calls, { args => [$full_method, @call_args], future => $future };
		Test::Mockingbird::_record_call($full_method);
		return $future;
	};

	local $Test::Mockingbird::TYPE = 'async_spy';
	Test::Mockingbird::mock($full_method, $wrapper);

	return sub { @calls };
}

# ----------------------------------------------------------------------
# Private helpers
# ----------------------------------------------------------------------

sub _require_future {
	eval { require Future; 1 }
		or croak "Test::Mockingbird::Async requires the Future module.\n"
			. "Install it with: cpanm Future\n";
}

=head1 SUPPORT

Please report bugs at L<https://github.com/nigelhorne/Test-Mockingbird/issues>.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<Test::Mockingbird>

=item * L<Test::Mockingbird::DeepMock>

=item * L<Future>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.

=cut

1;
