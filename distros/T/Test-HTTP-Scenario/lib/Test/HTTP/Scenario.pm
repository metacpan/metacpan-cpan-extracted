package Test::HTTP::Scenario;

use strict;
use warnings;
use Carp qw(croak carp);
use Exporter qw(import);
use Scalar::Util qw(blessed);
use File::Slurper qw(read_text write_text);

our @EXPORT_OK = qw(with_http_scenario);
our $VERSION = '0.01';

=head1 NAME

Test::HTTP::Scenario - Deterministic record/replay of HTTP interactions for test suites

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Test::Most;
  use Test::HTTP::Scenario qw(with_http_scenario);

  with_http_scenario(
      name    => 'get_user_basic',
      file    => 't/fixtures/get_user_basic.yaml',
      mode    => 'replay',
      adapter => 'LWP',
      sub {
          my $user = $client->get_user(42);
          cmp_deeply($user, superhashof({ id => 42 }));
      },
  );

=head1 DESCRIPTION

Test::HTTP::Scenario lets you test HTTP-based code without ever hitting the real network,
by recording real interactions once and replaying them forever.
It provides a deterministic record/replay mechanism
for HTTP-based test suites. It allows you to capture real HTTP
interactions once (record mode) and replay them later without network
access (replay mode). This makes API client tests fast, hermetic, and
fully deterministic.

Adapters provide the glue to specific HTTP client libraries such as
LWP. Serializers control how fixtures are stored
on disk.

=head1 MODES

=head2 record

Real HTTP requests are executed. Each request/response pair is
normalized and appended to the fixture. The fixture file is written at
the end of C<run()>.

=head2 replay

No real HTTP requests are made. Requests are matched against the
fixture in order, and responses are reconstructed from stored data.

=head1 STRICT MODE

If C<strict =E<gt> 1> is enabled, replay mode requires that all
recorded interactions are consumed. If the callback returns early,
C<run()> croaks with a strict-mode error.

=head1 DIFFING

If C<diffing =E<gt> 1> (default), mismatched requests produce a
detailed diff showing expected and actual method, URI, and normalized
request structures.

=head1 ADAPTERS

Adapters implement:

=over 4

=item * request/response normalization

=item * response reconstruction

=item * temporary monkey-patching of the HTTP client library

=back

Available adapters:

=over 4

=item * LWP

=back

You may also supply a custom adapter object.

=head1 SERIALIZERS

Serializers implement encoding and decoding of fixture files.

Available serializers:

=over 4

=item * YAML (default)

=item * JSON

=back

=head1 USING RECORD AND REPLAY IN REAL-WORLD APPLICATIONS

This section describes the recommended workflow for using
C<Test::HTTP::Scenario> in a real-world test suite. The goal is to
capture real HTTP traffic once (record mode) and then replay it
deterministically in all subsequent test runs (replay mode).

=head2 Overview

Record/replay is designed for API client libraries that normally make
live HTTP requests. In record mode, the module performs real network
calls and stores normalized request/response pairs in a fixture file.
In replay mode, the module prevents all network access and returns
synthetic responses reconstructed from the fixture.

This allows your test suite to:

=over 4

=item * run without network access

=item * avoid flakiness caused by external services

=item * run quickly and deterministically in CI

=item * capture complex multi-step API flows once and reuse them

=back

=head2 Typical Workflow

=head3 Step 1: Write your test using C<with_http_scenario>

  use Test::Most;
  use Test::HTTP::Scenario qw(with_http_scenario);

  with_http_scenario(
      name    => 'get_user_flow',
      file    => 't/fixtures/get_user_flow.yaml',
      mode    => $ENV{SCENARIO_MODE} || 'replay',
      adapter => 'LWP',
      sub {
          my $user = MyAPI->new->get_user(42);
          is $user->{id}, 42, 'user id matches';
      },
  );

=head3 Step 2: Run the test suite in record mode

  $ SCENARIO_MODE=record prove -l t/get_user_flow.t

This performs real HTTP requests and writes the fixture file:

  t/fixtures/get_user_flow.yaml

=head3 Step 3: Commit the fixture file to version control

The fixture becomes part of your test assets. It should be treated like
any other test data file.

=head3 Step 4: Run the test suite normally (replay mode)

  $ prove -l t

Replay mode:

=over 4

=item * loads the fixture

=item * intercepts all HTTP requests

=item * matches them against the recorded interactions

=item * returns synthetic responses

=back

No network access is required.

=head2 Updating Fixtures

If the API changes or you need to refresh the recorded data, simply
delete the fixture file and re-run the test in record mode:

  $ rm t/fixtures/get_user_flow.yaml
  $ SCENARIO_MODE=record prove -l t/get_user_flow.t

=head2 Example: Multi-Step API Flow

Record mode captures each request in order:

  with_http_scenario(
      name    => 'create_and_fetch',
      file    => 't/fixtures/create_and_fetch.yaml',
      mode    => $ENV{SCENARIO_MODE} || 'replay',
      adapter => 'LWP',
      sub {
          my $api = MyAPI->new;

          my $id = $api->create_user({ name => 'Alice' });
          my $user = $api->get_user($id);

          is $user->{name}, 'Alice';
      },
  );

Replay mode enforces the same sequence, ensuring your client behaves
correctly across multiple calls.

=head2 Notes

=over 4

=item * Replay mode never performs real HTTP requests.

=item * Strict mode can be enabled to ensure all interactions are consumed.

=item * Diffing mode provides detailed diagnostics when a request does not match.

=item * Fixtures are stable across platforms and Perl versions.

=back

=head1 METHODS

=head2 new

Construct a new scenario object.

=head3 Purpose

Initializes a scenario with a name, fixture file, mode, adapter, and
serializer. Loads adapter and serializer classes and binds the adapter
to the scenario.

=head3 Arguments

=over 4

=item * name (Str, required)

Scenario name.

=item * file (Str, required)

Path to the fixture file.

=item * mode (Str, required)

Either C<record> or C<replay>.

=item * adapter (Str|Object, required)

Adapter name such as C<LWP> or an adapter object.

=item * serializer (Str, optional)

Serializer name, default C<YAML>.

=item * diffing (Bool, optional)

Enable or disable diffing, default true.

=item * strict (Bool, optional)

Enable or disable strict behaviour, default false.

=back

=head3 Returns

A new L<Test::HTTP::Scenario> object.

=head3 Side Effects

Loads adapter and serializer classes dynamically. Binds the adapter to
the scenario.

=head3 Notes

The adapter object persists across calls to C<run()>.

=cut

#----------------------------------------------------------------------#
# Constructor
#----------------------------------------------------------------------#

sub new {
	my ($class, %args) = @_;

	# Entry: class name and argument hash
	# Exit:  new Test::HTTP::Scenario object
	# Side effects: loads adapter and serializer classes
	# Notes: mode must be explicit and valid

	for my $k (qw(name file mode adapter)) {
		croak "Missing required argument '$k'" unless exists $args{$k};
	}

	croak "Invalid mode '$args{mode}'" unless $args{mode} =~ /\A(?:record|replay)\z/;

	my $adapter = _build_adapter($args{adapter});
	my $serializer = _build_serializer($args{serializer} || 'YAML');

	my $self = bless {
		name		 => $args{name},
		file		 => $args{file},
		mode		 => $args{mode},
		adapter	=> $adapter,
		serializer => $serializer,
		interactions => [],
		loaded	 => 0,
		diffing	=> $args{diffing} // 1,
		strict	 => $args{strict}  // 0,
		_cursor => 0
	}, $class;

	$adapter->set_scenario($self);

	return $self;
}

=head2 run

Execute a coderef under scenario control.

=head3 Purpose

Installs adapter hooks, loads fixtures in replay mode, executes the
callback, and saves fixtures in record mode. Ensures uninstall and
save always occur.

=head3 Arguments

=over 4

=item * CODE (Coderef, required)

The code to execute while the adapter hooks are active.

=back

=head3 Returns

Whatever the coderef returns, preserving list, scalar, or void context.

=head3 Side Effects

=over 4

=item * Installs adapter hooks.

=item * Loads fixtures in replay mode.

=item * Saves fixtures in record mode.

=item * Uninstalls adapter hooks at scope exit.

=back

=head3 Notes

Exceptions propagate naturally. Strict mode enforces full consumption
of recorded interactions.

=cut


sub run {
	my ($self, $code) = @_;

	my $adapter = $self->{adapter};
	$adapter->set_scenario($self);

	$self->_load_if_needed;
	$adapter->install;

	# ensure uninstall + save ALWAYS run
	my $guard = Test::HTTP::Scenario::Guard->new(sub {
		$adapter->uninstall;
		$self->_save_if_needed;
	});

	my $wantarray = wantarray;

	my (@ret, $ret);

	# *** NO eval here ***
	if (!defined $wantarray) {
		$code->();
	}
	elsif ($wantarray) {
		@ret = $code->();
	}
	else {
		$ret = $code->();
	}

	# strict mode AFTER callback, BEFORE returning
	if ($self->{mode} eq 'replay' && $self->{strict}) {
		my $total = @{ $self->{interactions} || [] };
		my $cursor = $self->{_cursor} // 0;

		if ($cursor < $total) {
			croak "Strict mode: $total interactions recorded, "
				. "but only $cursor were used";
		}
	}

	return if !defined $wantarray;
	return @ret	   if $wantarray;
	return $ret;
}

=head2 with_http_scenario

Convenience wrapper for constructing and running a scenario.

=head3 Purpose

Creates a scenario object from key/value arguments and immediately
executes C<run()> with the supplied coderef.

=head3 Arguments

Key/value pairs identical to C<new>, followed by a coderef.

=head3 Returns

Whatever the coderef returns.

=head3 Side Effects

Constructs a scenario and installs adapter hooks during execution.

=head3 Notes

The final argument must be a coderef.

=cut

sub with_http_scenario {
	my @args = @_;

	# Entry: key/value arguments followed by coderef
	# Exit:  returns whatever the coderef returns
	# Side effects: constructs a scenario and runs it
	# Notes: convenience wrapper for tests

	my $code = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

	croak 'with_http_scenario() requires a coderef as last argument'
		unless $code;

	my %args = @args;

	my $self = __PACKAGE__->new(%args);

	return $self->run($code);
}

=head2 handle_request

Handle a single HTTP request in record or replay mode.

=head3 Purpose

In record mode, performs the real HTTP request and stores the
normalized request and response. In replay mode, matches the incoming
request against stored interactions and returns a synthetic response.

=head3 Arguments

=over 4

=item * req (Object)

Adapter-specific request object.

=item * do_real (Coderef)

Coderef that performs the real HTTP request.

=back

=head3 Returns

=over 4

=item * In record mode: the real HTTP::Response.

=item * In replay mode: a reconstructed HTTP::Response.

=back

=head3 Side Effects

=over 4

=item * Appends interactions in record mode.

=item * Advances the internal cursor in replay mode.

=back

=head3 Notes

Matching is currently based on method and URI only. Diffing mode
produces detailed mismatch diagnostics.

=cut

sub handle_request {
	my ($self, $req, $do_real) = @_;

	croak 'handle_request() requires a coderef for real request'
		unless ref $do_real eq 'CODE';

	if ($self->{mode} eq 'record') {
		my $res = $do_real->();

		my $record = {
			request  => $self->_normalize_request($req),
			response => $self->_normalize_response($res),
		};

		push @{ $self->{interactions} }, $record;

		return $res;
	}

	# replay mode
	$self->_load_if_needed;

	my $idx = $self->{_cursor} // 0;
	my $interactions = $self->{interactions} || [];

	if ($idx > $#$interactions) {
		croak 'No more recorded HTTP interactions available in scenario';
	}

	my $expected = $interactions->[$idx]{request}  || {};
	my $stored   = $interactions->[$idx]{response} || {};

	my $got = $self->_normalize_request($req);

	my $match = $self->_requests_match($expected, $got);

	if (!$match) {
		my $msg = 'No matching HTTP interaction found in scenario';

		if ($self->{diffing}) {
			my $diff = $self->_request_diff_string($expected, $got, $idx);
			$msg .= "\n$diff";
		}

		croak $msg;
	}

	# consume this interaction
	$self->{_cursor}++;

	return $self->_denormalize_response($stored);
}

#----------------------------------------------------------------------#
# Internal helpers
#----------------------------------------------------------------------#

sub _build_adapter {
	my $adapter = $_[0];

	# Entry: adapter name or object
	# Exit:  adapter object
	# Side effects: may load adapter class
	# Notes: supports LWP, HTTP_Tiny and Mojo by name

	if (blessed $adapter) {
		return $adapter;
	}

	my %map = (
		LWP	   => 'Test::HTTP::Scenario::Adapter::LWP',
		HTTP_Tiny => 'Test::HTTP::Scenario::Adapter::HTTP_Tiny',
		Mojo	  => 'Test::HTTP::Scenario::Adapter::Mojo',
	);

	my $class = $map{$adapter}
		or croak "Unknown adapter '$adapter'";

	## no critic (ProhibitStringyEval)
	eval "require $class" or croak "Failed to load $class: $@";

	return $class->new();
}

# Entry: serializer name
# Exit:  serializer object
# Side effects: may load serializer class
# Notes: supports YAML and JSON by name

sub _build_serializer {
	my ($name) = @_;

	my %map = (
		YAML => 'Test::HTTP::Scenario::Serializer::YAML',
		JSON => 'Test::HTTP::Scenario::Serializer::JSON',
	);

	my $class = $map{$name}
		or croak "Unknown serializer '$name'";

	## no critic (ProhibitStringyEval)
	eval "require $class" or croak "Failed to load $class: $@";

	return $class->new();
}

# Load fixture interactions from disk if required.

# Populate the scenario's interactions array when in replay mode and the
# fixture has not yet been loaded.

# Reads the fixture file from disk if it exists.

# Idempotent. Does nothing if already loaded or not in replay mode.

# Entry: scenario object
# Exit:  interactions populated if replay mode and file exists
# Side effects: reads from filesystem
# Notes: idempotent and only active in replay mode

sub _load_if_needed {
	my $self = $_[0];

	return if $self->{loaded};
	return if $self->{mode} ne 'replay';

	return unless -e $self->{file};

	my $text = read_text($self->{file});
	my $data = $self->{serializer}->decode_scenario($text);

	$self->{interactions} = $data->{interactions} || [];
	$self->{loaded}	   = 1;

	return;
}

# Write fixture interactions to disk if required.

# Serialize and write recorded interactions to the fixture file at the
# end of a record-mode run.

# Writes to the fixture file on disk.

# Only active in record mode.

# Entry: scenario object
# Exit:  fixtures written if record mode
# Side effects: writes to filesystem
# Notes: diffing and strict behaviour can be added later

sub _save_if_needed {
	my $self = $_[0];

	return if $self->{mode} ne 'record';

	my $data = {
		name		 => $self->{name},
		version	  => 1,
		interactions => $self->{interactions},
	};

	my $text = $self->{serializer}->encode_scenario($data);

	write_text($self->{file}, $text);

	return;
}

# Normalize an adapter-specific request object.

# Convert a request object into a stable, serializable hash structure.

# Delegates to the adapter.

# Entry: adapter specific request object
# Exit:  normalized request hash
# Side effects: none
# Notes: delegates to adapter

sub _normalize_request {
	my ($self, $req) = @_;

	return $self->{adapter}->normalize_request($req);
}

# Normalize an adapter-specific response object.

# Convert a response object into a stable, serializable hash structure.

# Entry: adapter specific response object
# Exit:  normalized response hash
# Side effects: none
# Notes: delegates to adapter

sub _normalize_response {
	my ($self, $res) = @_;

	return $self->{adapter}->normalize_response($res);
}

# Reconstruct an adapter-specific response object.

# Convert a stored response hash back into a real HTTP::Response object.

# Entry: normalized response hash
# Exit:  adapter specific response object
# Side effects: none
# Notes: delegates to adapter

sub _denormalize_response {
	my ($self, $hash) = @_;

	return $self->{adapter}->build_response($hash);
}

# Entry: adapter specific request object
# Exit:  matching interaction hash or undef
# Side effects: none
# Notes: simple method and uri equality for now

sub _find_match {
	my ($self, $req) = @_;

	my $norm = $self->_normalize_request($req);

	for my $interaction (@{ $self->{interactions} || [] }) {
		my $r = $interaction->{request} || {};

		next unless ($r->{method} || '') eq ($norm->{method} || '');
		next unless ($r->{uri}	|| '') eq ($norm->{uri}	|| '');

		return $interaction;
	}

	return;
}

# Compare two normalized request hashes.

# Determine whether an incoming request matches the expected request in
# the fixture.

# Header and body matching may be added later.

sub _requests_match {
	my ($self, $exp, $got) = @_;

	return 0 unless ($exp->{method} || '') eq ($got->{method} || '');
	return 0 unless ($exp->{uri}	|| '') eq ($got->{uri}	|| '');

	# you can extend this later to headers/body if desired
	return 1;
}

# Produce a human-readable diff for mismatched requests.

# Generate a diagnostic string showing differences between expected and
# actual requests.

# Used only when diffing is enabled.

sub _request_diff_string {
	my ($self, $exp, $got, $idx) = @_;

	require Data::Dumper;
	local $Data::Dumper::Terse  = 1;
	local $Data::Dumper::Indent = 1;

	return
	  "HTTP interaction mismatch at index $idx:\n"
	. "  Expected method: $exp->{method}\n"
	. "	   Got method: $got->{method}\n"
	. "  Expected uri:	$exp->{uri}\n"
	. "	   Got uri:	$got->{uri}\n"
	. "  Expected request hash:\n"
	. Data::Dumper::Dumper($exp)
	. "  Got request hash:\n"
	. Data::Dumper::Dumper($got);
}

{
	package Test::HTTP::Scenario::Guard;
	sub new {
		my ($class, $cb) = @_;
		bless $cb, $class;
	}
	sub DESTROY {
		my ($self) = @_;
		$self->();
	}
}

1;

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=head1 REPOSITORY

L<https://github.com/nigelhorne/Test-HTTP-Scenario>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-test-http-scenario at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-HTTP-Scenario>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Test::HTTP::Scenario

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Test-HTTP-Scenario>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HTTP-Scenario>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Test-HTTP-Scenario>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Test::HTTP::Scenario>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
