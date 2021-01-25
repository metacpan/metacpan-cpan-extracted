package Verotel::FlexPay;

use strict;
use warnings;
use Digest::SHA qw( sha256_hex sha1_hex );
use Params::Validate qw(:all);
use URI;
use Carp;
use utf8;

use base 'Exporter';

# WARNING: Use X.X.X format for $VERSION -> see: https://rt.cpan.org/Public/Bug/Display.html?id=119713
# because 0.20.1 < 0.1 (0.1 is converted to real number)
our $VERSION = '4.0.1';

our @EXPORT_OK = qw(
    get_signature
    get_status_URL
    get_purchase_URL
    get_subscription_URL
    get_upgrade_subscription_URL
    get_cancel_subscription_URL
    validate_signature
);

my $STATUS_URL = 'https://secure.verotel.com/salestatus';
my $FLEXPAY_URL = 'https://secure.verotel.com/startorder';
my $CANCEL_URL = 'https://secure.verotel.com/cancel-subscription';
my $PROTOCOL_VERSION = '3.5';

=head1 NAME

Verotel::FlexPay

=head1 DESCRIPTION

This library allows merchants to use Verotel payment gateway and get paid by their users via Credit Card and other payment methods.

=head2 get_signature($secret, %params)

Returns signature for the given parameters using L<$secret>.

Signature is an SHA-256 hash as hexadecimal number generated from L<$secret>
followed by the parameters joined with colon (:). Parameters ("$key=$value")
are alphabeticaly orderered by their keys. Only the following parameters are
considered for signing:

=head1 AUTHOR

Verotel dev team

=head1 SUPPORT

Documentation PDF for the library can be found on the Verotel blog (http://blog.verotel.com/downloads/).

=over 2

version,
shopID, saleID, referenceID,
priceAmount, priceCurrency,
description, name
custom1, custom2, custom3
subscriptionType
period
trialAmount, trialPeriod
cancelDiscountPercentage

=back

=head3 Example:

    get_signature('aaB',
        shopID => '123',
        custom1 => 'xyz',
        custom2 => undef ,
        ignored => 'bla'
    );

returns the SHA-256 string for "aaB:custom1=xyz:custom2=:shopID=123" converted to lowercase.

=cut

sub get_signature {
    my $secret = shift;
    my %params = @_;
    %params = _filter_params( %params );
    return _signature($secret, \%params);
}


=head2 validate_signature($secret, %params)

Returns true if the signature passed in the parameters match the signature computed from B<all> parameters (except for the signature itself).

=head3 Example:

    validate_signature('aaB',
        shopID => 123,
        saleID => 345,
        signature => 'acb4dd91827bc79999a04ac2082d0e43bb018a9ce563dfd3e863fbae32e5f381'
    );

returns true as the signature passed as the parameter is the same as the signature computed for "aaB:saleID=345:shopID=123"

Note: It accepts SHA-256 signature, but for now accepts also old SHA-1 signature for backward compatiblity.

=cut

sub validate_signature {
    my ($secret, %params) = @_;
    my $verified_sign  = lc(delete $params{signature});
    my $calculated_sign  = _signature($secret, \%params);
    return 1 if $verified_sign eq $calculated_sign;

    my $old_sha1_sign = _signature($secret, \%params, \&sha1_hex);
    return ($verified_sign eq $old_sha1_sign ? 1 : 0);
}


=head2 get_purchase_URL($secret, %params)

Return URL for purchase with signed parameters (only the parameters listed in the description of get_signature() are considered for signing).

=head3 Example:

    get_purchase_URL('mySecret', shopID => 65147, priceAmount => '6.99', priceCurrency  => 'USD');

returns

    "https://secure.verotel.com/startorder?priceAmount=6.99&priceCurrency=USD&shopID=65147&type=purchase&version=3.5&signature=37d56280eae410d2e5d6b67ccd29fd84173f2eed5a329c9b2f7fe9a77ad95441"

=cut

sub get_purchase_URL {
    my ($secret, %params) = @_;
    return _generate_URL($FLEXPAY_URL, $secret, 'purchase',  %params);
}

=head2 get_subscription_URL($secret, %params)

Return URL for subscription with signed parameters (only the parameters listed in the description of get_signature() are considered for signing).

=head3 Example:

    get_subscription_URL('mySecret', shopID => 65147, subscriptionType => 'recurring', period => 'P1M');

returns

    "https://secure.verotel.com/startorder?period=P1M&shopID=65147&subscriptionType=recurring&type=subscription&version=3.5&signature=2f2ffd9ba91dec62be74b143d0093ce7cefc62d1dab237aa3a327d76188cf77c"

=cut

sub get_subscription_URL {
    my ($secret, %params) = @_;
    return _generate_URL($FLEXPAY_URL, $secret, 'subscription', %params);
}

=head2 get_subscription_URL($secret, %params)

Return URL for upgrade subscription with signed parameters (only the parameters listed in the description of get_signature() are considered for signing).

=head3 Example:

    get_upgrade_subscription_URL('mySecret', shopID => 65147, subscriptionType => 'recurring', period => 'P1M');

returns

    "https://secure.verotel.com/startorder?period=P1M&shopID=65147&subscriptionType=recurring&type=upgradesubscription&version=3.5&signature=2276fd3aea2ca4027641515c731c6783ec2def70504c5276c5f4599039129e52"

=cut

sub get_upgrade_subscription_URL {
    my ($secret, %params) = @_;
    return _generate_URL($FLEXPAY_URL, $secret, 'upgradesubscription', %params);
}


=head2 get_status_URL($secret, %params)

Return URL for status with signed parameters (only the parameters listed in the description of get_signature() are considered for signing).

=head3 Example:

    get_status_URL('mySecret', shopID => '65147', saleID => '1485');

returns

    "https://secure.verotel.com/salestatus?saleID=1485&shopID=65147&version=3.5&signature=1a24a2d189824c6800d85131f11a2fca0ebbc233f31cad6d45e947496e423ff7"

=cut

sub get_status_URL {
    my ($secret, %params) = @_;
    return _generate_URL($STATUS_URL, $secret, undef, %params);
}


=head2 get_cancel_subscription_URL($secret, %params)

Return URL for cancel subscription with signed parameters (only the parameters listed in the description of get_signature() are considered for signing).

=head3 Example:

    get_cancel_subscription_URL('mySecret', shopID => '65147', saleID => '1485');

returns

    "https://secure.verotel.com/cancel-subscription?saleID=1485&shopID=65147&version=3.5&signature=1a24a2d189824c6800d85131f11a2fca0ebbc233f31cad6d45e947496e423ff7"

=cut

sub get_cancel_subscription_URL {
    my ($secret, %params) = @_;
    return _generate_URL($CANCEL_URL, $secret, undef, %params);
}


################ PRIVATE METHODS ##########################


sub _generate_URL {
    my ($baseURL, $secret, $type, %params) = (@_);

    if (!$secret) {croak "no secret given"};
    if (!%params) {croak "no params given"};

    $params{version} = $PROTOCOL_VERSION;
    if (defined $type) {
        $params{type} = $type;
    }

    # remove empty values:
    my @sorted_params = map { (defined($params{$_}) && $params{$_} ne '')
                            ? ($_ => $params{$_})
                            : ()
                    } sort keys %params;

    my $url         = new URI($baseURL);
    my $signature   = get_signature($secret, @sorted_params);

    $url->query_form(@sorted_params, signature => $signature);

    return $url->as_string();
}

sub _signature {
    my ($secret, $params_ref, $algorigthm_func) = @_;
    my @values = map { $_.'='.(defined $params_ref->{$_} ? $params_ref->{$_} : "") }
                        sort keys %$params_ref;
    my $encString = join(":", $secret, @values);
    utf8::encode($encString);

    $algorigthm_func ||= \&sha256_hex;
    return lc($algorigthm_func->($encString));
}

sub _filter_params {
    my (%params) = @_;

    my @keys = grep { m/ ^(
                            version
                            | shopID
                            | price(Amount|Currency)
                            | paymentMethod
                            | description
                            | referenceID
                            | saleID
                            | custom[123]
                            | subscriptionType
                            | period
                            | name
                            | trialAmount
                            | trialPeriod
                            | cancelDiscountPercentage
                            | type
                            | backURL
                            | declineURL
                            | precedingSaleID
                            | upgradeOption
                        )$
                    /x } keys %params;

    my %filtered = map { $_ => $params{$_} } @keys;

    return %filtered;
}

1;
