# NAME

Test::HTTP::Scenario - Deterministic record/replay of HTTP interactions for test suites

# VERSION

Version 0.01

# SYNOPSIS

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

# DESCRIPTION

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

# MODES

## record

Real HTTP requests are executed. Each request/response pair is
normalized and appended to the fixture. The fixture file is written at
the end of `run()`.

## replay

No real HTTP requests are made. Requests are matched against the
fixture in order, and responses are reconstructed from stored data.

# STRICT MODE

If `strict => 1` is enabled, replay mode requires that all
recorded interactions are consumed. If the callback returns early,
`run()` croaks with a strict-mode error.

# DIFFING

If `diffing => 1` (default), mismatched requests produce a
detailed diff showing expected and actual method, URI, and normalized
request structures.

# ADAPTERS

Adapters implement:

- request/response normalization
- response reconstruction
- temporary monkey-patching of the HTTP client library

Available adapters:

- LWP

You may also supply a custom adapter object.

# SERIALIZERS

Serializers implement encoding and decoding of fixture files.

Available serializers:

- YAML (default)
- JSON

# USING RECORD AND REPLAY IN REAL-WORLD APPLICATIONS

This section describes the recommended workflow for using
`Test::HTTP::Scenario` in a real-world test suite. The goal is to
capture real HTTP traffic once (record mode) and then replay it
deterministically in all subsequent test runs (replay mode).

## Overview

Record/replay is designed for API client libraries that normally make
live HTTP requests. In record mode, the module performs real network
calls and stores normalized request/response pairs in a fixture file.
In replay mode, the module prevents all network access and returns
synthetic responses reconstructed from the fixture.

This allows your test suite to:

- run without network access
- avoid flakiness caused by external services
- run quickly and deterministically in CI
- capture complex multi-step API flows once and reuse them

## Typical Workflow

### Step 1: Write your test using `with_http_scenario`

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

### Step 2: Run the test suite in record mode

    $ SCENARIO_MODE=record prove -l t/get_user_flow.t

This performs real HTTP requests and writes the fixture file:

    t/fixtures/get_user_flow.yaml

### Step 3: Commit the fixture file to version control

The fixture becomes part of your test assets. It should be treated like
any other test data file.

### Step 4: Run the test suite normally (replay mode)

    $ prove -l t

Replay mode:

- loads the fixture
- intercepts all HTTP requests
- matches them against the recorded interactions
- returns synthetic responses

No network access is required.

## Updating Fixtures

If the API changes or you need to refresh the recorded data, simply
delete the fixture file and re-run the test in record mode:

    $ rm t/fixtures/get_user_flow.yaml
    $ SCENARIO_MODE=record prove -l t/get_user_flow.t

## Example: Multi-Step API Flow

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

## Notes

- Replay mode never performs real HTTP requests.
- Strict mode can be enabled to ensure all interactions are consumed.
- Diffing mode provides detailed diagnostics when a request does not match.
- Fixtures are stable across platforms and Perl versions.

# METHODS

## new

Construct a new scenario object.

### Purpose

Initializes a scenario with a name, fixture file, mode, adapter, and
serializer. Loads adapter and serializer classes and binds the adapter
to the scenario.

### Arguments

- name (Str, required)

    Scenario name.

- file (Str, required)

    Path to the fixture file.

- mode (Str, required)

    Either `record` or `replay`.

- adapter (Str|Object, required)

    Adapter name such as `LWP` or an adapter object.

- serializer (Str, optional)

    Serializer name, default `YAML`.

- diffing (Bool, optional)

    Enable or disable diffing, default true.

- strict (Bool, optional)

    Enable or disable strict behaviour, default false.

### Returns

A new [Test::HTTP::Scenario](https://metacpan.org/pod/Test%3A%3AHTTP%3A%3AScenario) object.

### Side Effects

Loads adapter and serializer classes dynamically. Binds the adapter to
the scenario.

### Notes

The adapter object persists across calls to `run()`.

## run

Execute a coderef under scenario control.

### Purpose

Installs adapter hooks, loads fixtures in replay mode, executes the
callback, and saves fixtures in record mode. Ensures uninstall and
save always occur.

### Arguments

- CODE (Coderef, required)

    The code to execute while the adapter hooks are active.

### Returns

Whatever the coderef returns, preserving list, scalar, or void context.

### Side Effects

- Installs adapter hooks.
- Loads fixtures in replay mode.
- Saves fixtures in record mode.
- Uninstalls adapter hooks at scope exit.

### Notes

Exceptions propagate naturally. Strict mode enforces full consumption
of recorded interactions.

## with\_http\_scenario

Convenience wrapper for constructing and running a scenario.

### Purpose

Creates a scenario object from key/value arguments and immediately
executes `run()` with the supplied coderef.

### Arguments

Key/value pairs identical to `new`, followed by a coderef.

### Returns

Whatever the coderef returns.

### Side Effects

Constructs a scenario and installs adapter hooks during execution.

### Notes

The final argument must be a coderef.

## handle\_request

Handle a single HTTP request in record or replay mode.

### Purpose

In record mode, performs the real HTTP request and stores the
normalized request and response. In replay mode, matches the incoming
request against stored interactions and returns a synthetic response.

### Arguments

- req (Object)

    Adapter-specific request object.

- do\_real (Coderef)

    Coderef that performs the real HTTP request.

### Returns

- In record mode: the real HTTP::Response.
- In replay mode: a reconstructed HTTP::Response.

### Side Effects

- Appends interactions in record mode.
- Advances the internal cursor in replay mode.

### Notes

Matching is currently based on method and URI only. Diffing mode
produces detailed mismatch diagnostics.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

# SEE ALSO

# REPOSITORY

[https://github.com/nigelhorne/Test-HTTP-Scenario](https://github.com/nigelhorne/Test-HTTP-Scenario)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-test-http-scenario at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-HTTP-Scenario](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-HTTP-Scenario).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Test::HTTP::Scenario

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Test-HTTP-Scenario](https://metacpan.org/dist/Test-HTTP-Scenario)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HTTP-Scenario](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HTTP-Scenario)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Test-HTTP-Scenario](http://matrix.cpantesters.org/?dist=Test-HTTP-Scenario)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Test::HTTP::Scenario](http://deps.cpantesters.org/?module=Test::HTTP::Scenario)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
