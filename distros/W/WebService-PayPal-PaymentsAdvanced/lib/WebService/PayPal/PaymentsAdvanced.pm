package WebService::PayPal::PaymentsAdvanced;

use Moo;

use namespace::autoclean;

our $VERSION = '0.000027';

use feature qw( say state );

use Data::GUID;
use List::AllUtils qw( any );
use LWP::UserAgent;
use MooX::StrictConstructor;
use Type::Params qw( compile );
use Types::Common::Numeric qw( PositiveNum );
use Types::Common::String qw( NonEmptyStr );
use Types::Standard qw(
    ArrayRef
    Bool
    CodeRef
    Defined
    HashRef
    InstanceOf
    Int
    Num
    Optional
);
use Types::URI qw( Uri );
use URI;
use URI::FromHash qw( uri uri_object );
use URI::QueryParam;

#<<< don't perltidy
use WebService::PayPal::PaymentsAdvanced::Error::Generic;
use WebService::PayPal::PaymentsAdvanced::Error::HostedForm;
use WebService::PayPal::PaymentsAdvanced::Response;
use WebService::PayPal::PaymentsAdvanced::Response::Authorization;
use WebService::PayPal::PaymentsAdvanced::Response::Authorization::CreditCard;
use WebService::PayPal::PaymentsAdvanced::Response::Authorization::PayPal;
use WebService::PayPal::PaymentsAdvanced::Response::Capture;
use WebService::PayPal::PaymentsAdvanced::Response::Credit;
use WebService::PayPal::PaymentsAdvanced::Response::FromHTTP;
use WebService::PayPal::PaymentsAdvanced::Response::FromRedirect;
use WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST;
use WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST::CreditCard;
use WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST::PayPal;
use WebService::PayPal::PaymentsAdvanced::Response::Inquiry;
use WebService::PayPal::PaymentsAdvanced::Response::Inquiry::CreditCard;
use WebService::PayPal::PaymentsAdvanced::Response::Inquiry::PayPal;
use WebService::PayPal::PaymentsAdvanced::Response::Sale;
use WebService::PayPal::PaymentsAdvanced::Response::Sale::CreditCard;
use WebService::PayPal::PaymentsAdvanced::Response::Sale::PayPal;
use WebService::PayPal::PaymentsAdvanced::Response::SecureToken;
use WebService::PayPal::PaymentsAdvanced::Response::Void;
#>>>

has nonfatal_result_codes => (
    is      => 'ro',
    isa     => ArrayRef [Int],
    default => sub { [0] },
);

has partner => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
    default  => 'PayPal',
);

has password => (
    is       => 'ro',
    isa      => Defined,
    required => 1,
);

has payflow_pro_uri => (
    is     => 'lazy',
    isa    => Uri,
    coerce => 1,
);

has payflow_link_uri => (
    is     => 'lazy',
    isa    => Uri,
    coerce => 1,
);

has production_mode => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has user => (
    is       => 'ro',
    isa      => Defined,
    required => 1,
);

has validate_hosted_form_uri => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has vendor => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has verbose => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

with(
    'WebService::PayPal::PaymentsAdvanced::Role::HasUA',
    'WebService::PayPal::PaymentsAdvanced::Role::ClassFor'
);

sub _build_payflow_pro_uri {
    my $self = shift;

    return uri_object(
        scheme => 'https',
        host   => $self->production_mode
        ? 'payflowpro.paypal.com'
        : 'pilot-payflowpro.paypal.com'
    );
}

sub _build_payflow_link_uri {
    my $self = shift;

    return uri_object(
        scheme => 'https',
        host   => $self->production_mode
        ? 'payflowlink.paypal.com'
        : 'pilot-payflowlink.paypal.com'
    );
}

sub capture_delayed_transaction {
    my $self = shift;

    state $check = compile( NonEmptyStr, Optional [PositiveNum] );
    my ( $origid, $amt ) = $check->(@_);

    ## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)
    return $self->post(
        {
            $amt ? ( AMT => $amt ) : (),
            ORIGID  => $origid,
            TRXTYPE => 'D',
        }
    );
    ## use critic
}

sub _response_for {
    my $self         = shift;
    my $class_suffix = shift;
    my %args         = @_;

    $self->_class_for($class_suffix)->new(
        nonfatal_result_codes => $self->nonfatal_result_codes,
        %args,
    );
}

sub create_secure_token {
    my $self = shift;

    state $check = compile( HashRef, Optional [HashRef] );
    my ( $args, $options ) = $check->(@_);
    $options ||= {};

    my $post = $self->_force_upper_case($args);

    $post->{CREATESECURETOKEN} = 'Y';
    $post->{SECURETOKENID} ||= Data::GUID->new->as_string;

    my $res = $self->post( $post, $options );

    $self->_validate_secure_token_id( $res, $post->{SECURETOKENID} );

    return $res;
}

sub get_response_from_redirect {
    my $self = shift;

    state $check = compile(HashRef);
    my ($args) = $check->(@_);

    my $response = $self->_class_for('Response::FromRedirect')->new($args);

    return $self->_response_for( 'Response', params => $response->params );
}

sub get_response_from_silent_post {
    my $self = shift;

    state $check = compile(HashRef);
    my ($args) = $check->(@_);

    # If the RESPMSG param is missing, then this may just be a garbage, random
    # POST from a bot.

    unless ( $args->{params}->{RESPMSG} ) {
        WebService::PayPal::PaymentsAdvanced::Error::Generic->throw(
            message => 'Bad params supplied from silent POST',
            params  => $args->{params},
        );
    }

    # First we create a SilentPOST response, which may or may not validate the
    # IP. If there's no exception we query the object to find out if this was a
    # PayPal or CreditCard transaction and then return the appropriate class.
    # IPs will only be validate once as the PayPal/CreditCard object
    # instantiation will not provide an IP address.

    my $class_suffix = 'Response::FromSilentPOST';
    my $response     = $self->_response_for( $class_suffix, %{$args} );

    $class_suffix
        .= '::'
        . ( $response->is_credit_card_transaction ? 'CreditCard' : 'PayPal' );

    return $self->_response_for( $class_suffix, params => $response->params );
}

sub inquiry_transaction {
    my $self = shift;

    state $check = compile(HashRef);
    my ($args) = $check->(@_);
    $args->{TRXTYPE} = 'I';

    return $self->post($args);
}

sub post {
    my $self = shift;

    state $check = compile( HashRef, Optional [HashRef] );
    my ( $post, $options ) = $check->(@_);

    $post = $self->_force_upper_case($post);
    $post->{VERBOSITY} = 'HIGH' if $self->verbose;

    my $content = join '&', $self->_encode_credentials,
        $self->_pseudo_encode_args($post);

    my $http_response
        = $self->ua->post( $self->payflow_pro_uri, Content => $content );

    my $params = $self->_class_for('Response::FromHTTP')->new(
        http_response => $http_response,
        request_uri   => $self->payflow_pro_uri,
    )->params;

    if ( $post->{CREATESECURETOKEN} && $post->{CREATESECURETOKEN} eq 'Y' ) {
        return $self->_response_for(
            'Response::SecureToken',
            params                   => $params,
            payflow_link_uri         => $self->payflow_link_uri,
            ua                       => $self->ua,
            validate_hosted_form_uri => $self->validate_hosted_form_uri,
            %{ $options || {} },
        );
    }

    my %class_for_type = (
        A => 'Response::Authorization',
        C => 'Response::Credit',
        D => 'Response::Capture',
        I => 'Response::Inquiry',
        S => 'Response::Sale',
        V => 'Response::Void',
    );

    my $type                  = $post->{TRXTYPE};
    my $response_class_suffix = 'Response';
    if ( $type && exists $class_for_type{$type} ) {

        $response_class_suffix = $class_for_type{$type};

        # Get more specific response classes for CC and PayPal txns.
        unless ( any { $type eq $_ } ( 'C', 'D', 'V' ) ) {
            my $response = $self->_response_for(
                $response_class_suffix,
                params => $params
            );

            $response_class_suffix = sprintf(
                '%s::%s', $response_class_suffix,
                $response->is_credit_card_transaction
                ? 'CreditCard'
                : 'PayPal'
            );
        }
    }

    return $self->_response_for( $response_class_suffix, params => $params );
}

sub refund_transaction {
    my $self = shift;
    state $check = compile( NonEmptyStr, Optional [NonEmptyStr] );
    my ( $origid, $amount ) = $check->(@_);

    return $self->post(
        {
            TRXTYPE => 'C',
            ORIGID  => $origid,
            $amount ? ( AMT => $amount ) : ()
        }
    );
}

sub auth_from_credit_card_reference_transaction {
    my $self = shift;
    return $self->_credit_card_reference_transaction( 'A', @_ );
}

sub sale_from_credit_card_reference_transaction {
    my $self = shift;
    return $self->_credit_card_reference_transaction( 'S', @_ );
}

sub _credit_card_reference_transaction {
    my $self = shift;
    state $check
        = compile( NonEmptyStr, NonEmptyStr, Num, Optional [HashRef] );
    my ( $type, $origid, $amount, $extra ) = $check->(@_);

    return $self->post(
        {
            AMT     => $amount,
            ORIGID  => $origid,
            TENDER  => 'C',
            TRXTYPE => $type,
            $extra ? ( %{$extra} ) : (),
        }
    );
}

sub auth_from_paypal_reference_transaction {
    my $self = shift;
    return $self->_paypal_reference_transaction( 'A', @_ );
}

sub sale_from_paypal_reference_transaction {
    my $self = shift;
    return $self->_paypal_reference_transaction( 'S', @_ );
}

sub _paypal_reference_transaction {
    my $self = shift;
    state $check = compile( NonEmptyStr, NonEmptyStr, Num, NonEmptyStr,
        Optional [HashRef]
    );
    my ( $type, $baid, $amount, $currency, $extra ) = $check->(@_);

    return $self->post(
        {
            ACTION   => 'D',
            AMT      => $amount,
            BAID     => $baid,
            CURRENCY => $currency,
            TENDER   => 'P',
            TRXTYPE  => $type,
            $extra ? ( %{$extra} ) : (),
        }
    );
}

sub void_transaction {
    my $self = shift;

    state $check = compile(NonEmptyStr);
    my ($pnref) = $check->(@_);

    return $self->post( { TRXTYPE => 'V', ORIGID => $pnref } );
}

sub _validate_secure_token_id {
    my $self     = shift;
    my $res      = shift;
    my $token_id = shift;

    # This should only happen if bad actors are involved.
    if ( $res->secure_token_id ne $token_id ) {
        WebService::PayPal::PaymentsAdvanced::Error::Generic->throw(
            message => sprintf(
                'Secure token ids do not match. Yours: %s. From response: %s.',
                $token_id, $res->secure_token_id
            ),
            params => $res->params,
        );
    }
}

# The authentication args will not contain characters which need to be handled
# specially.  Also, I think adding the length to these keys actually just
# doesn't work.

sub _encode_credentials {
    my $self = shift;

    my %auth = (
        PARTNER => $self->partner,
        PWD     => $self->password,
        USER    => $self->user,
        VENDOR  => $self->vendor,
    );

    # Create key/value pairs the way that PayPal::PaymentsAdvanced wants them.
    my $pairs = join '&', map { $_ . '=' . $auth{$_} } sort keys %auth;
    return $pairs;
}

sub _force_upper_case {
    my $self = shift;
    my $args = shift;
    my %post = map { uc $_ => $args->{$_} } keys %{$args};

    return \%post;
}

# Payments Advanced treats encoding key/value pairs like a special snowflake.
# https://metacpan.org/source/PLOBBES/Business-OnlinePayment-PayflowPro-1.01/PayflowPro.pm#L276
sub _pseudo_encode_args {
    my $self = shift;
    my $args = shift;

    my $uri = join '&', map {
        join '=', sprintf( '%s[%i]', $_, length( $args->{$_} ) ), $args->{$_}
    } grep { defined $args->{$_} } sort keys %{$args};
    return $uri;
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced - A simple wrapper around the PayPal Payments Advanced web service

=head1 VERSION

version 0.000027

=head1 SYNOPSIS

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(
        {
            password => 'seekrit',
            user     => 'username',
            vendor   => 'somevendor',
        }
    );

    my $response = $payments->create_secure_token(
        {
            AMT            => 100,
            TRXTYPE        => 'S',
            BILLINGTYPE    => 'MerchantInitiatedBilling',
            CANCELURL      => 'https://example.com/cancel',
            ERRORURL       => 'https://example.com/error',
            L_BILLINGTYPE0 => 'MerchantInitiatedBilling',
            NAME           => 'Chuck Norris',
            RETURNURL      => 'https://example.com/return',
        }
    );

    my $uri = $response->hosted_form_uri;

    # Store token data for later use.  You'll need to implement this yourself.
    $foo->freeze_token_data(
        token    => $response->secure_token,
        token_id => $response->secure_token_id,
    );

    # Later, when PayPal returns a silent POST or redirects the user to your
    # return URL:

    my $redirect_response = $payments->get_response_from_redirect(
        ip_address => $ip,
        params     => $params,
    );

    # Fetch the tokens from the original request. You'll need to implement
    # this yourself.

    my $thawed = $foo->get_thawed_tokens(...);

    # Don't do anything until you're sure the tokens are ok.
    if (   $thawed->secure_token ne $redirect->secure_token
        || $thawed->secure_token_id ne $response->secure_token_id ) {
        die 'Fraud!';
    }

    # Everything looks good.  Carry on!

    print $response->secure_token;

=head1 DESCRIPTION

BETA BETA BETA.  The interface is still subject to change.

This is a wrapper around the "PayPal Payments Advanced" (AKA "PayPal Payflow
Link") hosted forms.  This code does things like facilitating secure token
creation, providing an URL which you can use to insert an hosted_form into
your pages and processing the various kinds of response you can get from
PayPal.

We also use various exception classes to make it easier for you to decide how
to handle the parts that go wrong.

=head1 OBJECT INSTANTIATION

The following parameters can be supplied to C<new()> when creating a new object.

=head2 Required Parameters

=head3 password

The value of the C<password> field you use when logging in to the Payflow
Manager.  (You'll probably want to create a specific user just for API calls).

=head3 user

The value of the C<user> field you use when logging in to the Payflow Manager.

=head3 vendor

The value of the C<vendor> field you use when logging in to the Payflow
Manager.

=head2 Optional Parameters

=head3 nonfatal_result_codes

An arrayref of result codes that will be treated as non-fatal (i.e., that will
not cause an exception). By default, only 0 is considered non-fatal, but
depending on your integration, other codes such as 112 (failed AVS check) may
be considered non-fatal.

=head3 partner

The value of the C<partner> field you use when logging in to the Payflow
Manager. Defaults to C<PayPal>.

=head3 payflow_pro_uri

The hostname for the Payflow Pro API.  This is where token creation requests
get directed.  This already has a sensible (and correct) default, but it is
settable so that you can more easily mock API calls when testing.

=head3 payflow_link_uri

The hostname for the Payflow Link website.  This is the hosted service where
users will enter their payment information.  This already has a sensible (and
correct) default, but it is settable in case you want to mock it while testing.

=head3 production_mode

This is a C<Boolean>.  Set this to C<true> if when you are ready to process
real transactions.  Defaults to C<false>.

=head3 ua

You may provide your own UserAgent, but it must be of the L<LWP::UserAgent>
family.  If you do provide a UserAgent, be sure to set a sensible timeout
value. Requests to the web service frequently run 20-30 seconds.

This can be useful for debugging.  You'll be able to get detailed information
about the network calls which are being made.

    use LWP::ConsoleLogger::Easy qw( debug_ua );
    use LWP::UserAgent;
    use WebService::PayPal::PaymentsAdvanced;

    my $ua = LWP::UserAgent;
    debug_ua($ua);

    my $payments
        = WebService::PayPal::PaymentsAdvanced->new( ua => $ua, ... );

    # Now fire up a console and watch your network activity.

Check the tests which accompany this distribution for an example of how to mock
API calls using L<Test::LWP::UserAgent>.

=head3 validate_hosted_form_uri

C<Boolean>.  If enabled, this module will attempt to GET the uri which you'll
be providing to the end user.  This can help you identify issues on the PayPal
side.  This is helpful because you'll be able to log exceptions thrown by this
method and deal with them accordingly.  If you disable this option, you'll need
to rely on end users to report issues which may exist within PayPal's hosted
pages.  Defaults to C<true>.

=head3 verbose

C<Boolean>.  Sets C<VERBOSITY=HIGH> on all transactions if enabled.  Defaults
to C<true>.

=head2 Methods

=head3 create_secure_token

Create a secure token which you can use to create a hosted form uri.  Returns a
L<WebService::PayPal::PaymentsAdvanced::Response::SecureToken> object.

The first parameter holds the key/value parameters for the request. The second
parameter is optional and holds parameters to the underlying
L<WebService::PayPal::PaymentsAdvanced::Response::SecureToken> object, which is
useful to set attributes such as C<retry_attempts> and C<retry_callback>.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->create_secure_token(
        {
            AMT            => 100,
            TRXTYPE        => 'S',
            BILLINGTYPE    => 'MerchantInitiatedBilling',
            CANCELURL      => 'https://example.com/cancel',
            ERRORURL       => 'https://example.com/error',
            L_BILLINGTYPE0 => 'MerchantInitiatedBilling',
            NAME           => 'Chuck Norris',
            RETURNURL      => 'https://example.com/return'
        }
    );

    print $response->secure_token;

=head3 get_response_from_redirect

This method can be used to parse responses from PayPal to your return URL.
It's essentially a wrapper around
L<WebService::PayPal::PaymentsAdvanced::Response::FromRedirect>.  Returns a
L<WebService::PayPal::PaymentsAdvanced::Response> object.

    my $response = $payments->get_response_from_redirect(
        params     => $params,
    );
    print $response->message;

=head3 get_response_from_silent_post

This method can be used to validate responses from PayPal to your silent POST
url.  If you provide an ip_address parameter, it will be validated against a
list of known IPs which PayPal provides.  You're encouraged to provide an IP
address in order to prevent spoofing of payment responses.  See
L<WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST> for more
information on this behaviour.

This method returns a
L<WebService::PayPal::PaymentsAdvanced::Response::FromSilentPost::PayPal>
object for PayPal transactions.  It returns a
L<WebService::PayPal::PaymentsAdvanced::Response::FromSilentPost::CreditCard>
object for credit card transactions.  You can either inspect the class returned
to you or use the C<is_credit_card_transaction> or C<is_paypal_transaction>
methods to learn which method the customer paid with.  Both methods return a
C<Boolean>.

    my $response = $payments->get_response_from_redirect(
        ip_address => $ip,
        params     => $params,
    );
    print $response->message. "\n";
    if ( $response->is_credit_card_transaction ) {
        print $response->card_type, q{ }, $response->card_expiration;
    }

=head3 post

Generic method to post arbitrary params to PayPal.  Requires a C<HashRef> of
parameters and returns a L<WebService::PayPal::PaymentsAdvanced::Response>
object.  Any lower case keys will be converted to upper case before this
response is sent. The second parameter is an optional C<HashRef>. If provided,
it defines attributes to pass to the
L<WebService::PayPal::PaymentsAdvanced::Response::SecureToken> object.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->post( { TRXTYPE => 'V', ORIGID => $pnref, } );
    say $response->message;

    # OR
    my $response = $payments->post( { trxtype => 'V', origid => $pnref, } );

=head3 capture_delayed_transaction( $ORIGID, [$AMT] )

Captures a sale which you have previously authorized.  Requires the ID of the
original transaction.  If you wish to capture an amount which is not equal to
the original authorization amount, you'll need to pass an amount as the second
parameter.  Returns a response object.

=head3 auth_from_credit_card_reference_transaction( $ORIGID, $amount, $extra )

Process a authorization based on a reference transaction from a credit card.
Requires 2 arguments: an ORIGID from a previous credit card transaction and an
amount. Any additional parameters can be passed via a HashRef as an optional
3rd argument.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->auth_from_credit_card_reference_transaction(
        'BFOOBAR', 1.50', { INVNUM => 'FOO123' }
    );
    say $response->message;

=head3 sale_from_credit_card_reference_transaction( $ORIGID, $amount )

Process a sale based on a reference transaction from a credit card.  See
Requires 2 arguments: an ORIGID from a previous credit card transaction and an
amount.  Any additional parameters can be passed via a HashRef as an optional
3rd argument.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->sale_from_credit_card_reference_transaction(
        'BFOOBAR', 1.50', { INVNUM => 'FOO123' }
    );
    say $response->message;

=head3 auth_from_paypal_reference_transaction( $BAID, $amount, $currency, $extra )

Process an authorization based on a reference transaction from PayPal.
Requires 3 arguments: a BAID from a previous PayPal transaction, an amount and
a currency.  Any additional parameters can be passed via a HashRef as the
optional fourth argument.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->auth_from_paypal_reference_transaction(
        'B-FOOBAR', 1.50, 'USD', { INVNUM => 'FOO123' }
    );
    say $response->message;

=head3 sale_from_paypal_reference_transaction( $BAID, $amount, $currency, $extra )

Process a sale based on a reference transaction from PayPal.  Requires 3
arguments: a BAID from a previous PayPal transaction, an amount and a currency.
Any additional parameters can be passed via a HashRef as an optional fourth
argument.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $response = $payments->sale_from_paypal_reference_transaction(
        'B-FOOBAR', 1.50, 'USD', { INVNUM => 'FOO123' }
    );
    say $response->message;

=head3 refund_transaction( $origid, [$amount] )

Refunds (credits) a previous transaction.  Requires the C<ORIGID> and an
optional C<AMT>.  If no amount is provided, the entire transaction will be
refunded.

=head3 inquiry_transaction( $HashRef )

Performs a transaction inquiry on a previously submitted transaction.  Requires
the ID of the original transaction.  Returns a response object.

    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    my $inquiry = $payments->inquiry_transaction(
        { ORIGID => 'FOO123', TENDER => 'C', }
    );
    say $response->message;

=head3 void_transaction( $ORIGID )

Voids a previous transaction.  Requires the ID of the transaction to void.
Returns a response object.

=head1 SEE ALSO

The official L<Payflow Gateway Developer Guide and
Reference|https://developer.paypal.com/docs/classic/payflow/integration-guide/>

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 CONTRIBUTORS

=for stopwords Andy Jack Dave Rolsky Greg Oschwald Mark Fowler Mateu X Hunter Narsimham Chelluri Olaf Alders William Storey

=over 4

=item *

Andy Jack <ajack@maxmind.com>

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Mateu X Hunter <mhunter@maxmind.com>

=item *

Narsimham Chelluri <nchelluri@users.noreply.github.com>

=item *

Olaf Alders <oalders@maxmind.com>

=item *

William Storey <wstorey@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
#ABSTRACT: A simple wrapper around the PayPal Payments Advanced web service

