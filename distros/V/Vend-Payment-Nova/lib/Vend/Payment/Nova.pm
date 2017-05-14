
package Vend::Payment::Nova;

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA  02111-1307  USA.

=head1 NAME

Vend::Payment::Nova - Interchange Nova Support

=head1 SYNOPSIS

    &charge=nova

        or

    [charge mode=nova param1=value1 param2=value2]

=head1 PREREQUISITES

  Net::SSLeay
 
    or
  
  LWP::UserAgent and Crypt::SSLeay

Only one of these need be present and working.

=head1 DESCRIPTION

The Vend::Payment::Nova module implements the nova() routine for using
Nova IC payment services with Interchange. It is compatible on a call level
with the other Interchange payment modules -- in theory (and even usually in
practice) you could switch from CyberCash to Nova with a few configuration
file changes.

To enable this module, place this directive in C<interchange.cfg>:

    Require module Vend::Payment::Nova

This I<must> be in interchange.cfg or a file included from it.

NOTE: Make sure CreditCardAuto is off (default in Interchange demos).

The mode can be named anything, but the C<gateway> parameter must be set
to C<nova>. To make it the default payment gateway for all credit
card transactions in a specific catalog, you can set in C<catalog.cfg>:

    Variable   MV_PAYMENT_MODE  nova

It uses several of the standard settings from Interchange payment. Any time
we speak of a setting, it is obtained either first from the tag/call options,
then from an Interchange order Route named for the mode, then finally a
default global payment variable, For example, the C<id> parameter would
be specified by:

    [charge mode=nova merhcant_id=YourMerchantID]

or

    Route nova merhcant_id YourMerchantID

or with only Nova as a payment provider

    Variable MV_PAYMENT_ID     YourMerchantID

A fully valid catalog.cfg entry to work with the standard demo would be:

    Variable MV_PAYMENT_MODE      nova
    Variable MV_PAYMENT_MERCHANT_ID  YourMerchantID 
    Variable MV_PAYMENT_USER_ID      YourUserID
    Variable MV_PAYMENT_PIN          YourUserPIN 

=head1 VERSION HISTORY

=over

=item *

06-10-2008 - Version 1.01

=item

01-13-2009 - Version 1.02
    - Joseph Montanez reports that Nova might (rarely) return 'APPROVAL' instead of 'APPROVED'.

=item

03-17-2011 - Version 1.03
    - added 'use strict;' -- an oversight, but didn't require any further changes. :-)
    - some formatting changes, and made a DEBUG constant
    - added VERSION to Makefile.PL

=back

=head1 BUGS

The only currently supported transaction type is 'sale'.

=head1 AUTHOR

Murray Nesbitt (murray AT cpan.org)

=cut

BEGIN {

    my $selected;
    eval {
        package Vend::Payment;
        require Net::SSLeay;
        import Net::SSLeay qw(post_https make_form make_headers);
        $selected = "Net::SSLeay";
    };

    $Vend::Payment::Have_Net_SSLeay = 1 unless $@;

    unless ($Vend::Payment::Have_Net_SSLeay) {

        eval {
            package Vend::Payment;
            require LWP::UserAgent;
            require HTTP::Request::Common;
            require Crypt::SSLeay;
            import HTTP::Request::Common qw(POST);
            $selected = "LWP and Crypt::SSLeay";
        };

        $Vend::Payment::Have_LWP = 1 unless $@;

    }

    unless ($Vend::Payment::Have_Net_SSLeay or $Vend::Payment::Have_LWP) {
        die __PACKAGE__ . " requires Net::SSLeay or Crypt::SSLeay";
    }

    ::logGlobal("%s payment module initialized, using %s", __PACKAGE__, $selected)
        unless $Vend::Quiet or ! $Global::VendRoot;

}

use vars qw/$Have_LWP $Have_Net_SSLeay/;
use strict;

use constant DEBUG => 0;

my %AVS_CODES = (
    'A' => 'Address matches - Zip Code does not match.',
    'B' => 'Street address match, Postal code in wrong format. (International issuer)',
    'C' => 'Street address and postal code in wrong formats',
    'D' => 'Street address and postal code match (international issuer)',
    'E' => 'AVS Error',
    'G' => 'Service not supported by non-US issuer',
    'I' => 'Address information not verified by international issuer.',
    'M' => 'Street Address and Postal code match (international issuer)',
    'N' => 'No Match on Address (Street) or Zip',
    'O' => 'No Response sent',
    'P' => 'Postal codes match, Street address not verified due to incompatible formats.',
    'R' => 'Retry, System unavailable or Timed out',
    'S' => 'Service not supported by issuer',
    'U' => 'Address information is unavailable',
    'W' => '9 digit Zip matches, Address (Street) does not match.',
    'X' => 'Exact AVS Match',
    'Y' => 'Address (Street) and 5-digit Zip match.',
    'Z' => '5 digit Zip matches, Address (Street) does not match.',
);

my %CVV_CODES = (
    'M' => 'CVV2 Match',
    'N' => 'CVV2 No match',
    'P' => 'Not Processed',
    'S' => 'Issuer indicates that CVV2data should be present on the card, but the merchant has indicated that the CVV2 data is not resent on the card',
    'U' => 'Issuer has not certified for CVV2 or Issuer has not provided Visa with the CVV2 encryption Keys.',
);

sub nova {
    my ($user, $amount) = @_;

    my ($opt, $merchant_id, $user_id, $pin);
    if(ref $user) {
        $opt = $user;
        $merchant_id = $opt->{merchant_id} || charge_param('merchant_id');
        $user_id = $opt->{user_id} || charge_param('user_id');
        $pin = $opt->{pin} || charge_param('pin');
    }

    my %actual;
    if($opt->{actual}) {
        %actual = %{$opt->{actual}};
    }
    else {
        %actual = map_actual();
    }

    ::logDebug("Mapping: " . ::uneval(%actual)) if DEBUG;

    my $exp = sprintf('%02d%02d', $actual{mv_credit_card_exp_month}, $actual{mv_credit_card_exp_year});

    $actual{mv_credit_card_number} =~ s/\D//g;
    $actual{phone_day} =~ s/\D//g;

    my $precision = $opt->{precision} || charge_param('precision') || 2;

    $amount = $opt->{total_cost} || undef;

    $opt->{transaction} ||= 'sale';

    unless($amount) {
        $amount = Vend::Interpolate::total_cost();
        $amount = Vend::Util::round_to_frac_digits($amount,$precision);
    }

    my %values = (
        ssl_merchant_id => $merchant_id,
        ssl_user_id => $user_id,
        ssl_pin => $pin,
        ssl_show_form => 'false',
        ssl_transaction_type => 'CCSALE',
        ssl_result_format => 'ASCII',
        ssl_first_name => $actual{b_fname},
        ssl_last_name => $actual{b_lname},
        ssl_email => $actual{email},
        ssl_city => $actual{b_city},
        ssl_state => $actual{b_state},
        ssl_avs_zip => $actual{b_zip},
        ssl_invoice_number => $opt->{order_id},
        ssl_card_number => $actual{mv_credit_card_number},
        ssl_exp_date => $exp,
        ssl_amount => $amount,
        ssl_description => "0001~Generic Order String~$amount~1~N~||",
        ssl_ship_to_phone => $actual{phone_day},

        # CVV
        ssl_cvv2 => 'present',
        ssl_cvv2cvc2_indicator => 1,
        ssl_cvv2cvc2 => $actual{mv_credit_card_cvv2},

        # AVS
        ssl_avs_address => substr($actual{b_address}, 0, 20),
        ssl_avs_zip => $actual{b_zip},
    );

#$values{'ssl_test_mode'} = 'TRUE';

    ::logDebug("Values to be sent: " . ::uneval(%values)) if DEBUG;

    $opt->{submit_url} = $opt->{submit_url}
                   || 'https://www.myvirtualmerchant.com/VirtualMerchant/process.do';

    my $merchant_return = post_data($opt, \%values);

    ::logDebug("request returned: $merchant_return->{result_page}") if DEBUG;

    my %result;

    my @lines = split /\n/, $merchant_return->{result_page};
    foreach (@lines) {
        chomp;
        ::logDebug("found response line=$_") if DEBUG;
        my ($name, $val) = split(/=/,$_);
        ::logDebug("name=$name value=$val") if DEBUG;
        $result{$name} = $val;
    }

    if ($result{ssl_result} == 0 && ($result{ssl_result_message} eq 'APPROVED' || $result{ssl_result_message} eq 'APPROVAL')) {
        $result{MStatus} = $result{'pop.status'} = 'success';
        $result{'order-id'} = $opt->{order_id};
    }
    else {
        $result{MStatus} = 'failed';
        $result{MErrMsg} = $result{ssl_result_message};
    }

    $result{'pop.auth-code'}     = $result{'ssl_approval_code'} if defined $result{'ssl_approval_code'};
    $result{'pop.avs_code'}      = $AVS_CODES{$result{'ssl_avs_response'}} if defined $result{'ssl_avs_response'};
    $result{'pop.txn-id'}        = $result{'ssl_txn_id'} if defined $result{'ssl_txn_id'};
    $result{'pop.error-message'} = $result{'ssl_result_message'} if defined $result{'ssl_result_message'};
    $result{'pop.cvv2_code'}     = $CVV_CODES{$result{'ssl_cvv2_response'}} if defined $result{'ssl_cvv2_response'};

    ::logDebug("Nova request result: " . ::uneval(\%result) ) if DEBUG;

    return %result;
}

1;
