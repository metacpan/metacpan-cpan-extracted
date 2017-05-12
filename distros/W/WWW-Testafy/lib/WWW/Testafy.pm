package WWW::Testafy;

use strict;
use warnings;

our $VERSION = 1.02;

# Copyright 2012 Grant Street Group

=head1 NAME

WWW::Testafy - Testafy API for perl developers

=head1 SYNOPSIS

    use WWW::Testafy;

    my $te = new WWW::Testafy;

    my $id = $te->run_test(
        pbehave  => qq{
            For the url http://www.google.com
            Given a test delay of 1 second
            When the search query field is "Testafy"
            Then the text "Did you mean: testify" is present
        };
    );

    my $passed  = $te->test_passed($id);
    my $planned = $te->test_planned($id);
    print "Passed $passed tests out of $planned\n";
    print $te->test_results_as_string($id);

=cut

use Moose;
use JSON;
use LWP::UserAgent;

=head1 ATTRIBUTES

=over

=item base_api_uri - base URI of the api server

=cut

has 'base_api_uri' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'https://app.testafy.com/api/v0',
);

has 'auth_realm' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Testafy',
);

has 'auth_netloc' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'app.testafy.com:443',
);
    
=item response - HTTP::Response object received from the API server

=cut

has 'response' => (
    is      => 'rw',
    isa     => 'HTTP::Response',
);

=item response_vars - hash of the JSON response

=cut

has 'response_vars' => (
    is      => 'rw',
    isa     => 'HashRef',
);

=item ua - LWP::UserAgent object

=cut

has 'ua' => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    default => sub {
        return LWP::UserAgent->new();
    },
);

has 'testafy_username' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has 'testafy_password' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

=back

=head1 METHODS

=head2 Basic

=head3 $self->make_api_request($api_command, $request_vars)

Args: api_command - command to send to API server
      $request_vars - hashref of values to be encoded into JSON

Returns: HTTP::Response object received

=cut

sub make_api_request {
    my ($self, $api_command, $request_vars) = @_;

    my $uri = $self->base_api_uri . '/' . $api_command;

    $request_vars->{login_name} = $self->testafy_username;
    my $r = {
        json => to_json($request_vars)
    };

    $self->ua->credentials(
        $self->auth_netloc,
        $self->auth_realm,
        $self->testafy_username,
        $self->testafy_password,
    );
    
    $self->response($self->ua->post($uri, $r));
    if (my $content = $self->response->content) {
        eval { $self->response_vars(from_json($content)); };
        $self->response_vars({error => [ $content]}) if $@;
    }

    return $self->response;
}

=head3 $self->message

Returns: value of 'message' key from JSON response

=cut

sub message {
    my $self = shift;

    return $self->response_vars->{message} if $self->response_vars;
}


=head3 $self->error

Returns: arrayref of error messages from JSON response

=cut

sub error {
    my $self = shift;
    
    return $self->response_vars->{error} if $self->response_vars;
}

=head3 $self->error_string

Returns: formatted error strings (joined with newlines)

=cut

sub error_string {
    my $self = shift;

    my $error = $self->error;
    if ($error and @$error) {
        return join("\n", @$error);
    }
}

=head2 Commands for tests

=head3 $self->run_test(%args), including pbehave and browser

If the asynchronous arg flag is set to 1, test is started in background.
Otherwise, it waits for test to completed. The default is 0.

Args: %args - hash of arguments

Returns: trt_id of entry created for test

=cut

sub run_test {
    my $self = shift;

    my $args = {
        verbose => 0,
        @_,
    };

    if ($args->{verbose}) {
        print "Running test with these values:\n";
        for my $key (qw(product pbehave)) {
            print "\t$key: $args->{$key}\n" if defined $args->{$key};
        }
    }

    my $response = $self->make_api_request('test/run', $args);

    return $self->response_vars ? $self->response_vars->{test_run_test_id} : 0E0 
        if $response->is_success;

    print STDERR "Response code: ".$response->code."\n";
    print STDERR "Error(s) while running test: ".join("\n", @{$self->error})
        if $self->error;
    return;
}

=head3 $self->test_status($trt_id)

Args: trt_id - test_run_test_id for test

Returns: current status of the individual test run $trt_id.

=cut

sub test_status {
    my ($self, $trt_id) = @_;

    my $args = {
        trt_id => $trt_id,
    };

    my $response = $self->make_api_request('test/status', $args);
    if ($response->is_success) {
        return $self->response_vars->{status};
    }
}

=head3 $self->test_planned($trt_id)

Args: trt_id - test_run_test_id for test

Returns: tests planned for the individual test run $trt_id.

=cut

sub test_planned {
    my ($self, $trt_id) = @_;

    my $args = {
        trt_id => $trt_id,
    };

    my $response = $self->make_api_request('test/stats/planned', $args);
    if ($response->is_success) {
        return $self->response_vars->{planned};
    }
}

=head3 $self->test_passed($trt_id)

Args: trt_id - test_run_test_id for test

Returns: tests passed in individual test run $trt_id.

=cut

sub test_passed {
    my ($self, $trt_id) = @_;

    my $args = {
        trt_id => $trt_id,
    };

    my $response = $self->make_api_request('test/stats/passed', $args);
    if ($response->is_success) {
        return $self->response_vars->{passed};
    }
}

=head3 $self->test_failed($trt_id)

Args: trt_id - test_run_test_id for test

Returns: tests failed in individual test run $trt_id.

=cut

sub test_failed {
    my ($self, $trt_id) = @_;

    my $args = {
        trt_id => $trt_id,
    };

    my $response = $self->make_api_request('test/stats/failed', $args);
    if ($response->is_success) {
        return $self->response_vars->{failed};
    }
}

=head3 $self->test_results($trt_id)

Args: trt_id - test_run_test_id for test

Returns: array of tests results. Each item in the array is an array ref of
result_type & result.

=cut

sub test_results {
    my ($self, $trt_id) = @_;

    my $args = {
        trt_id => $trt_id,
    };

    my $response = $self->make_api_request('test/results', $args);
    if ($response->is_success) {
        my $results = $self->response_vars->{results};
        return @$results;
    }
}

=head3 $self->test_results_as_string($trt_id)

Returns: test results as a single string, effectively in TAP format.

=cut

sub test_results_as_string {
    my ($self, $trt_id) = @_;

    my @results = $self->test_results($trt_id);
    return join("\n", map { $_->[1] } @results)."\n";
}

1;
