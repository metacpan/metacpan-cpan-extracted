package WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST;

use Moo;

use namespace::autoclean;

our $VERSION = '0.000026';

use Types::Common::String qw( NonEmptyStr );
use Types::Standard qw( InstanceOf );
use WebService::PayPal::PaymentsAdvanced::Mocker::Helper;

has _helper => (
    is => 'lazy',
    isa =>
        InstanceOf ['WebService::PayPal::PaymentsAdvanced::Mocker::Helper'],
    default =>
        sub { WebService::PayPal::PaymentsAdvanced::Mocker::Helper->new },
);

has _secure_token_id => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
    init_arg => 'secure_token_id',
);

sub paypal_success {
    my $self = shift;
    my %args = @_;

    return $self->_massage_args(
        {
            ADDRESSTOSHIP   => '1 Main St',
            AMT             => '50.00',
            AVSADDR         => 'Y',
            AVSDATA         => 'YYY',
            AVSZIP          => 'Y',
            BAID            => 'XXX',
            BILLTOCOUNTRY   => 'US',
            BILLTOEMAIL     => 'paypal_buyer@example.com',
            BILLTOFIRSTNAME => 'Test',
            BILLTOLASTNAME  => 'Buyer',
            BILLTONAME      => 'Test Buyer',
            CITYTOSHIP      => 'San Jose',
            CORRELATIONID   => 'XXX',
            COUNTRY         => 'US',
            COUNTRYTOSHIP   => 'US',
            EMAIL           => 'paypal_buyer@example.com',
            FIRSTNAME       => 'Test',
            INVNUM          => 61,
            INVOICE         => 61,
            LASTNAME        => 'Buyer',
            METHOD          => 'P',
            NAME            => 'Test Buyer',
            NAMETOSHIP      => 'Test Buyer',
            PAYERID         => 'R8RAGUNASE6VA',
            PAYMENTTYPE     => 'instant',
            PENDINGREASON   => 'authorization',
            PNREF           => 'XXX',
            PPREF           => 'XXX',
            RESPMSG         => 'Approved',
            RESULT          => '0',
            SECURETOKEN     => 'XXX',
            SHIPTOCITY      => 'San Jose',
            SHIPTOCOUNTRY   => 'US',
            SHIPTOSTATE     => 'CA',
            SHIPTOSTREET    => '1 Main St',
            SHIPTOZIP       => 95131,
            STATETOSHIP     => 'CA',
            TAX             => '0.00',
            TENDER          => 'P',
            TOKEN           => 'XXX',
            TRANSTIME       => 'XXX',
            TRXTYPE         => 'A',
            TYPE            => 'A',
            ZIPTOSHIP       => 95131,
        },
        \%args,
    );
}

sub credit_card_success {
    my $self = shift;
    my %args = @_;

    return $self->_massage_args(
        {
            ACCT          => 4482,
            AMT           => 50.00,
            AUTHCODE      => 111111,
            AVSADDR       => 'Y',
            AVSDATA       => 'YYY',
            AVSZIP        => 'Y',
            BILLTOCOUNTRY => 'US',
            CARDTYPE      => 3,
            CORRELATIONID => 'fb36aaa2675e',
            COUNTRY       => 'US',
            COUNTRYTOSHIP => 'US',
            CVV2MATCH     => 'Y',
            EMAILTOSHIP   => q{},
            EXPDATE       => 1221,
            IAVS          => 'N',
            INVNUM        => 69,
            INVOICE       => 69,
            LASTNAME      => 'NotProvided',
            METHOD        => 'CC',
            PNREF         => 'XXX',
            PPREF         => 'XXX',
            PROCAVS       => 'X',
            PROCCVV2      => 'M',
            RESPMSG       => 'Approved',
            RESULT        => 0,
            SECURETOKEN   => '9dWh93jXhkkOi4C3INWBAWgxN',
            SECURETOKENID => 'XXX',
            SHIPTOCOUNTRY => 'US',
            TAX           => 0.00,
            TENDER        => 'CC',
            TRANSTIME     => '2015-08-27 15:01:42',
            TRXTYPE       => 'A',
            TYPE          => 'A',
        },
        \%args
    );
}

sub credit_card_duplicate_invoice_id {
    my $self = shift;
    my %args = @_;

    return $self->_massage_args(
        {
            ACCT          => 4482,
            AMT           => '50.00',
            AVSDATA       => 'XXN',
            BILLTOCOUNTRY => 'US',
            CARDTYPE      => 3,
            COUNTRY       => 'US',
            COUNTRYTOSHIP => 'US',
            EMAILTOSHIP   => q{},
            EXPDATE       => 1221,
            HOSTCODE      => 10536,
            INVNUM        => 64,
            INVOICE       => 64,
            LASTNAME      => 'NotProvided',
            METHOD        => 'CC',
            PNREF         => 'XXX',
            RESULT        => 30,
            SECURETOKEN   => 'XXX',
            SHIPTOCOUNTRY => 'US',
            TAX           => '0.00',
            TENDER        => 'CC',
            TRANSTIME     => 'XXX',
            TRXTYPE       => 'A',
            TYPE          => 'A',
            RESPMSG =>
                'Duplicate trans:  10536-The transaction was refused as a result of a duplicate invoice ID supplied.  Attempt with a new invoice ID',
        },
        \%args
    );
}

sub credit_card_auth_verification_success {
    my $self = shift;
    my %args = @_;

    return $self->_massage_args(
        \%args,
        {
            ACCT          => 5800,
            AMT           => '0.00',
            AUTHCODE      => 111111,
            AVSADDR       => 'Y',
            AVSDATA       => 'YYY',
            AVSZIP        => 'Y',
            BILLTOCOUNTRY => 'US',
            CARDTYPE      => 0,
            CORRELATIONID => 'dad41bc8ed27',
            COUNTRY       => 'US',
            COUNTRYTOSHIP => 'US',
            CVV2MATCH     => 'Y',
            EMAILTOSHIP   => q{},
            EXPDATE       => 1221,
            HOSTCODE      => 10574,
            IAVS          => 'N',
            LASTNAME      => 'NotProvided',
            METHOD        => 'CC',
            PNREF         => 'XXX',
            PPREF         => 'XXX',
            PROCAVS       => 'X',
            PROCCVV2      => 'M',
            RESPMSG =>
                'Verified =>  10574-This card authorization verification is not a payment transaction.',
            SECURETOKEN   => 'XXX',
            RESULT        => 0,
            SHIPTOCOUNTRY => 'US',
            TAX           => '0.00',
            TENDER        => 'CC',
            TRANSTIME     => 'XXX',
            TRXTYPE       => 'A',
            TYPE          => 'A',
        },
    );
}

sub _massage_args {
    my $self         = shift;
    my $default_args = shift;
    my $user_args    = shift;

    $default_args = $self->_set_defaults($default_args);

    my $args = { %{$default_args}, %{$user_args} };
    if ( $self->_secure_token_id eq 'NOPPREF' ) {
        delete $args->{PPREF};
    }
    return $args;
}

sub _set_defaults {
    my $self     = shift;
    my $defaults = shift;

    my %method_for = (
        BAID          => 'baid',
        CORRELATIONID => 'correlationid',
        PNREF         => 'pnref',
        PPREF         => 'ppref',
        TRANSTIME     => 'transtime',
        SECURETOKEN   => 'secure_token',
        TOKEN         => 'token',
    );

    for my $key ( keys %method_for ) {
        if ( exists $defaults->{$key} ) {
            my $method = $method_for{$key};
            $defaults->{$key} = $self->_helper->$method;
        }
    }

    $defaults->{SECURETOKENID} = $self->_secure_token_id;
    if ( $self->_secure_token_id eq 'NOPPREF' ) {
        delete $defaults->{PPREF};
    }
    return $defaults;
}

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST - Easily mock Silent POST transactions

=head1 VERSION

version 0.000026

=head1 SYNOPSIS

    use LWP::UserAgent;
    use WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST;

    my $mocker
        = WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST->new();

    my $ua = LWP::UserAgent->new(...);
    $ua->post(
        '/silent-post-url',
        $mocker->paypal_success,
        'X-Forwarded-For' => '173.0.81.65'
    );

=head2 paypal_success

Returns a C<HashRef> of POST params which can be used to mock a successful
PayPal authorization.

=head2 credit_card_success

Returns a C<HashRef> of POST params which can be used to mock a successful
credit card authorization.

=head2 credit_card_auth_verification_success

Returns a C<HashRef> of POST params which can be used to mock a successful zero
dollar credit card authorization.

=head2 credit_card_duplicate_invoice_id

Returns a C<HashRef> of POST params which can be used to mock a unsuccessful
credit card payment.  In this case you've sent an invoice ID which is already
attached to a previously successful transaction.

=head1 DESCRIPTION

Use these methods to get a HashRef of params which you can POST to your
application's silent POST endpoint. Keep in mind that if you have IP
validation enabled you'll either need to spoof the originating IP of the
request or disable the IP validation in test mode.  I'd encourage you to do
the former, if at all possible.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Easily mock Silent POST transactions

