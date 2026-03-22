package Test::HTTP::Scenario::Adapter::LWP;

use strict;
use warnings;

use Carp qw(croak carp);
use Scalar::Util qw(blessed);

#----------------------------------------------------------------------#
# Constructor
#----------------------------------------------------------------------#
# Entry:
#   class name
#
# Exit:
#   new adapter object with internal state initialised
#
# Side effects:
#   none
#
# Notes:
#   - scenario is attached later via set_scenario()
#   - installed/uninstalled counters guard install/uninstall
#
sub new {
	my $class = $_[0];

	return bless {
		scenario       => undef,   # scenario object (set via set_scenario)
		installed      => 0,       # install() guard counter
		uninstalled    => 0,       # uninstall() guard counter
		_orig_request  => undef,   # original LWP::UserAgent::request coderef
	}, $class;
}

#----------------------------------------------------------------------#
# Scenario attachment
#----------------------------------------------------------------------#
# Entry:
#   $scenario => Test::HTTP::Scenario object
#
# Exit:
#   adapter now references scenario
#
# Side effects:
#   none
#
# Notes:
#   - no weaken() because scenario lifetime is controlled by tests
#
sub set_scenario {
	my ($self, $scenario) = @_;
	$self->{scenario} = $scenario;

	return;
}

#----------------------------------------------------------------------#
# Install: monkey‑patch LWP::UserAgent::request
#----------------------------------------------------------------------#
# Entry:
#   none
#
# Exit:
#   request() overridden to call scenario->handle_request
#
# Side effects:
#   - modifies LWP::UserAgent::request globally
#
# Notes:
#   - recursion‑safe via localised glob
#   - install() is idempotent per adapter instance
#
sub install {
    my ($self) = @_;
    return if $self->{installed}++;

    no warnings 'redefine';

    # Capture original request method (glob slot)
    $self->{_orig_request} ||= \&LWP::UserAgent::request;

    my $adapter = $self;
    my $orig    = $self->{_orig_request};

    *LWP::UserAgent::request = sub {
        my ($ua, $request, @rest) = @_;

        my $scenario = $adapter->{scenario};
        unless ($scenario) {
            carp "STRAY LWP REQUEST DURING GLOBAL DESTRUCTION";
            return $orig->($ua, $request, @rest);
        }

        # Prevent recursion: internal calls use original method
        local *LWP::UserAgent::request = $orig;

        return $scenario->handle_request(
            $request,
            sub { $orig->($ua, $request, @rest) },
        );
    };

    return;
}

#----------------------------------------------------------------------#
# Uninstall: restore original LWP::UserAgent::request
#----------------------------------------------------------------------#
# Entry:
#   none
#
# Exit:
#   original request() restored
#
# Side effects:
#   - modifies LWP::UserAgent::request globally
#
# Notes:
#   - uninstall() is idempotent per adapter instance
#
sub uninstall {
    my ($self) = @_;
    return if $self->{uninstalled}++;

    no warnings 'redefine';

    if ($self->{_orig_request}) {
        *LWP::UserAgent::request = $self->{_orig_request};
    }

    return;
}

#----------------------------------------------------------------------#
# Request normalization
#----------------------------------------------------------------------#
# Entry:
#   $req => HTTP::Request object
#
# Exit:
#   hashref with method, uri, headers, body
#
# Side effects:
#   none
#
# Notes:
#   - stable, serializable structure for fixture storage
#
sub normalize_request {
    my ($self, $req) = @_;

    croak "normalize_request() expects an HTTP::Request"
        unless blessed($req) && $req->isa('HTTP::Request');

    return {
        method  => $req->method,
        uri     => $req->uri->as_string,
        headers => { $req->headers->flatten },
        body    => $req->content,
    };
}

#----------------------------------------------------------------------#
# Response normalization
#----------------------------------------------------------------------#
# Entry:
#   $res => HTTP::Response object
#
# Exit:
#   hashref with status, reason, headers, body
#
# Side effects:
#   none
#
# Notes:
#   - decoded_content(charset => 'none') preserves raw bytes
#
sub normalize_response {
    my ($self, $res) = @_;

    croak "normalize_response() expects an HTTP::Response"
        unless blessed($res) && $res->isa('HTTP::Response');

    return {
        status  => $res->code,
        reason  => $res->message,
        headers => { $res->headers->flatten },
        body    => $res->decoded_content(charset => 'none'),
    };
}

#----------------------------------------------------------------------#
# Build a real HTTP::Response from stored hash
#----------------------------------------------------------------------#
# Entry:
#   $hash => normalized response hash
#
# Exit:
#   HTTP::Response object
#
# Side effects:
#   none
#
# Notes:
#   - headers restored exactly as stored
#
sub build_response {
    my ($self, $hash) = @_;

    require HTTP::Response;

    my $res = HTTP::Response->new(
        $hash->{status}  // 200,
        $hash->{reason}  // 'OK',
    );

    if (my $h = $hash->{headers}) {
        while (my ($k, $v) = each %$h) {
            $res->header($k => $v);
        }
    }

    $res->content($hash->{body} // '');

    return $res;
}

1;

__END__

=head1 NAME

Test::HTTP::Scenario::Adapter::LWP - LWP adapter for Test::HTTP::Scenario

=head1 SYNOPSIS

  use Test::HTTP::Scenario::Adapter::LWP;

  my $adapter = Test::HTTP::Scenario::Adapter::LWP->new;
  $adapter->set_scenario($scenario);
  $adapter->install;

=head1 DESCRIPTION

This adapter integrates L<Test::HTTP::Scenario> with L<LWP::UserAgent>.
It temporarily overrides C<request()> to route HTTP traffic through the
scenario engine for record and replay.

=head1 METHODS

=head2 new

Construct a new LWP adapter.

=head3 Purpose

Initializes adapter state and prepares for scenario attachment.

=head3 Arguments (Params::Validate::Strict)

None.

=head3 Returns (Returns::Set)

=over 4

=item * adapter object

=back

=head3 Side Effects

None.

=head3 Notes

Scenario must be attached via C<set_scenario()> before use.

=head3 Example

  my $adapter = Test::HTTP::Scenario::Adapter::LWP->new;

=cut

=head2 set_scenario

Attach a scenario to the adapter.

=head3 Purpose

Associates the adapter with a L<Test::HTTP::Scenario> instance.

=head3 Arguments

=over 4

=item * scenario (Object)

Scenario object.

=back

=head3 Returns

True value.

=head3 Side Effects

Stores the scenario reference.

=head3 Notes

Must be called before C<install()>.

=head3 Example

  $adapter->set_scenario($scenario);

=cut

=head2 install

Install the LWP request override.

=head3 Purpose

Monkey-patch C<LWP::UserAgent::request> so that all HTTP requests pass
through the scenario engine.

=head3 Arguments

None.

=head3 Returns

True value.

=head3 Side Effects

=over 4

=item * Overrides C<LWP::UserAgent::request> globally.

=item * Captures original request method on first install.

=back

=head3 Notes

Idempotent per adapter instance.

=head3 Example

  $adapter->install;

=cut

=head2 uninstall

Restore the original LWP request method.

=head3 Purpose

Undo the override installed by C<install()>.

=head3 Arguments

None.

=head3 Returns

True value.

=head3 Side Effects

Restores original C<request()> method.

=head3 Notes

Idempotent per adapter instance.

=head3 Example

  $adapter->uninstall;

=cut

=head2 normalize_request

Normalize an HTTP::Request.

=head3 Purpose

Convert an LWP request into a stable, serializable hash.

=head3 Arguments

=over 4

=item * req (HTTP::Request)

=back

=head3 Returns

Hashref with method, uri, headers, body.

=head3 Side Effects

None.

=head3 Example

  my $norm = $adapter->normalize_request($req);

=cut

=head2 normalize_response

Normalize an HTTP::Response.

=head3 Purpose

Convert an LWP response into a stable, serializable hash.

=head3 Arguments

=over 4

=item * res (HTTP::Response)

=back

=head3 Returns

Hashref with status, reason, headers, body.

=head3 Side Effects

None.

=head3 Example

  my $norm = $adapter->normalize_response($res);

=cut

=head2 build_response

Reconstruct an HTTP::Response from stored data.

=head3 Purpose

Convert a normalized response hash back into a real LWP response.

=head3 Arguments

=over 4

=item * hash (HashRef)

=back

=head3 Returns

HTTP::Response object.

=head3 Side Effects

None.

=head3 Example

  my $res = $adapter->build_response($hash);

=cut

