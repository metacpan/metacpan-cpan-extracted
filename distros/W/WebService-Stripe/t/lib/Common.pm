package t::lib::Common;

use v5.14;
use Exporter qw(import);
use Test::More import => [qw(plan)];
use WebService::Stripe;

my %constants;
BEGIN {
    %constants = (
        # Card Issuers
        STRIPE_CARD_AMEX               => '378282246310005',
        STRIPE_CARD_AMEX_ALT           => '371449635398431',
        STRIPE_CARD_DINERS_CLUB        => '30569309025904',
        STRIPE_CARD_DINERS_CLUB_ALT    => '38520000023237',
        STRIPE_CARD_DISCOVER           => '6011111111111117',
        STRIPE_CARD_DISCOVER_ALT       => '6011000990139424',
        STRIPE_CARD_JCB                => '3530111333300000',
        STRIPE_CARD_JCB_ALT            => '3566002020360505',
        STRIPE_CARD_MASTERCARD         => '5555555555554444',
        STRIPE_CARD_MASTERCARD_DEBIT   => '5200828282828210',
        STRIPE_CARD_MASTERCARD_PREPAID => '5105105105105100',
        STRIPE_CARD_VISA               => '4242424242424242',
        STRIPE_CARD_VISA_ALT           => '4012888888881881',
        STRIPE_CARD_VISA_DEBIT         => '4000056655665556',
        STRIPE_CARD_VISA_DEBIT_ALT     => '4000056655665564', # Transfers will fail
        # Card Scenarios
        STRIPE_CARD_BYPASS_BALANCE   => '4000000000000077',
        STRIPE_CARD_ADDR_FAIL        => '4000000000000010',
        STRIPE_CARD_LINE1_FAIL       => '4000000000000028',
        STRIPE_CARD_ZIP_FAIL         => '4000000000000036',
        STRIPE_CARD_ADDR_UNAVAILABLE => '4000000000000044',
        STRIPE_CARD_CVC_FAIL         => '4000000000000101',
        STRIPE_CARD_CHARGE_FAIL      => '4000000000000341',
        STRIPE_CARD_DECLINED         => '4000000000000002',
        STRIPE_CARD_INCORRECT_CVC    => '4000000000000127',
        STRIPE_CARD_EXPIRED          => '4000000000000069',
        STRIPE_CARD_PROC_ERROR       => '4000000000000119',
        STRIPE_CARD_DISPUTED         => '4000000000000259',
        # Dispute Evidence
        STRIPE_DISPUTE_WINNING => 'winning_evidence',
        STRIPE_DISPUTE_LOSING  => 'losing_evidence',
        # Tax ID
        STRIPE_TAX_ID_VALID   => '000000000',
        STRIPE_TAX_ID_INVALID => '111111111',
        # Banking
        STRIPE_BANK_US_ROUTING_NO              => '110000000',
        STRIPE_BANK_CA_ROUTING_NO              => '11000-000',
        STRIPE_BANK_ACCOUNT                    => '000123456789',
        STRIPE_BANK_ACCOUNT_NOT_EXISTS         => '000111111116',
        STRIPE_BANK_ACCOUNT_CLOSED             => '000111111113',
        STRIPE_BANK_ACCOUNT_INSUFFICIENT_FUNDS => '000222222227',
        STRIPE_BANK_ACCOUNT_NOT_AUTHORIZED     => '000333333335',
        STRIPE_BANK_ACCOUNT_INVALID_CURRENCY   => '000444444440',
    );
}
use constant \%constants;

our @EXPORT_OK   = (qw( skip_unless_has_secret stripe ), keys %constants);
our %EXPORT_TAGS = (constants => [ keys %constants ]);

sub skip_unless_has_secret {
    plan skip_all => 'PERL_STRIPE_TEST_API_KEY is required' unless api_key();
}

sub stripe {
    my %params = @_;
    state $client = WebService::Stripe->new(
        api_key => api_key(),
        version => '2014-12-17',
        %params
    );
    return $client;
}

sub api_key { $ENV{PERL_STRIPE_TEST_API_KEY} }

1;
