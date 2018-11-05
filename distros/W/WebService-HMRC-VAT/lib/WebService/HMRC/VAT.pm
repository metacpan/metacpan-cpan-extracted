package WebService::HMRC::VAT;

use 5.006;
use Carp;
use JSON::MaybeXS;
use Moose;
use namespace::autoclean;
use URI::Escape;

extends 'WebService::HMRC::Request';

=head1 NAME

WebService::HMRC::VAT - Interact with the UK HMRC VAT API

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WebService::HMRC::VAT;
    my $vat = WebService::HMRC::VAT->new({
        vrn => '123456789'
    });
    $vat->auth->access_token->('MY-ACCESS-TOKEN');

    # Display outstanding VAT returns
    my $result = $vat->obligations({
        from  => '2018-01-01',
        to    => '2018-12-31',
        state => 'O',
    });
    if($result->is_success) {
        foreach my $o (@{$result->data->{obligations}) {
            print "VAT return " . $o->{periodKey};
            print " due " . $o->{due} . "\n";
        }
    }

    # Submit a VAT return
    $result = $vat->submit_return({
        periodKey => "#001",                 # from ->obligations()
        vatDueSales => 100.00,               # Box 1 on paper form
        vatDueAcquisitions => 100.00,        # Box 2 on paper form
        totalVatDue => 200.00,               # Box 3 on paper form
        vatReclaimedCurrPeriod => 100.00,    # Box 4 on paper form
        netVatDue => 100.00,                 # Box 5 on paper form
        totalValueSalesExVAT => 500,         # Box 6 on paper form
        totalValuePurchasesExVAT => 500,     # Box 7 on paper form
        totalValueGoodsSuppliedExVAT => 500, # Box 8 on paper form
        totalAcquisitionsExVAT => 500,       # Box 9 on paper form
        finalised => 1,                      # Boolean user declaration
    });
    if($result->is_success) {
        print "VAT Return submitted:\n"
        printf "Receipt ID: %s\n", $result->header('Receipt-ID');
        printf "Form Bundle: %s\n", $result->data->{formBundleNumber};
    }

=head1 DESCRIPTION

Perl module to interact with the UK's HMRC Making Tax Digital
`VAT` API. This allows VAT returns to be submitted or viewed,
and obligations, payments and liabilities to be viewed.

For more information, see:
L<https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/vat-api/1.0>

=head1 REQUIRES

=over

=item * L<JSON::MaybeXS>

=item * L<Moose>

=item * L<namespace::autoclean>

=item * L<URI::Escape>

=back

=head1 EXPORTS

Nothing

=head1 PROPERTIES

Inherits from L<WebService::HMRC::Request>.

=head2 vrn

VAT registration number for which records are being queries or submitted.
Required parameter for initialisation.

The VAT registration number must be purely numeric, without any spaces or
GB prefix.

=cut

has vrn => (
   is => 'rw',
   isa => 'Int',
   required => 1,
);

=head1 METHODS

Inherits from L<WebService::HMRC::Request>.

=head2 obligations({ from => 'YYYY-MM-DD', to => 'YYYY-MM-DD', [status => $status, ] [test_mode => $test_mode] })

Retrieve a set of VAT filing obligations for the specified date range. Returns
a WebService::HMRC::Response object reference. Requires permission for the
C<read:vat> service scope.

=head3 Parameters

=over

=item from

Return obligations from this date, specified as YYYY-MM-DD.
Required parameter.

=item to

Return obligations up to this date, specified as YYYY-MM-DD.
Required parameter.

=item status

Optional parameter to filter the obligations returned. May be set to 'O' to
return only 'open' obligations, or 'F' to return only 'fulfilled' obligations.

Default is to return all obligations, both fulfilled and open.

=item test_mode

Optional parameter used only for testing against the HMRC sandbox api.

This parameter should not be used in production systems - it causes dummy
test data to be returned.

By default, when testing against the sandbox with no C<test_mode> specified,
the test api simulates the scenario where the client has quarterly
obligations and one is fulfilled

Other test scenarios are available by setting the C<test_mode> parameter
as detailed below:

C<QUARTERLY_NONE_MET> simulates the scenario where the client has quarterly
obligations and none are fulfilled.

C<QUARTERLY_ONE_MET> simulates the scenario where the client has quarterly
obligations and one is fulfilled.

C<QUARTERLY_TWO_MET> simulates the scenario where the client has quarterly
obligations and two are fulfilled.

C<QUARTERLY_THREE_MET> simulates the scenario where the client has quarterly
obligations and three are fulfilled.

C<QUARTERLY_FOUR_MET> simulates the scenario where the client has quarterly
obligations and four are fulfilled.

C<MONTHLY_NONE_MET> simulates the scenario where the client has monthly
obligations and none are fulfilled.

C<MONTHLY_ONE_MET> simulates the scenario where the client has monthly
obligations and one month is fulfilled.

C<MONTHLY_TWO_MET> simulates the scenario where the client has monthly
obligations and two months are fulfilled.

C<MONTHLY_THREE_MET> simulates the scenario where the client has monthly
obligations and three months are fulfilled.

C<NOT_FOUND> simulates the scenario where no data is found.

=back

=head3 Response Data

For full details of the response data, see the HMRC API specification. In summary,
the data contains a single element `obligations` pointing to an array of
VAT return obligations:

    {
      obligations => [
        {
          periodKey => "#001"
          start     => "2017-04-06",
          end       => "2017-07-05",
          due       => "2017-08-12",
          status    => "F",
          received  => "2017-08-05", # only present if 'Fulfilled'
        },
        {
          periodKey => "#004"
          start     => "2018-01-06",
          end       => "2018-04-05",
          due"      => "2018-05-12",
          status    => "O",
        },
      ]
    }

=head3 Example usage

    my $result = $vat->obligations({
        from => '2018-01-01',
        to   => '2018-12-31',
    });
    foreach my $obligation( @{$result->data->{obligations}} ) {
        print "-- VAT Return Obligation --\n"
        print "           ID: $obligation->{periodKey}\n";
        print " Period Start: $obligation->{start}\n";
        print "   Period End: $obligation->{end}\n";
        print "     Due Date: $obligation->{due}\n";
        print "Received Date: ";
        if ($obligation->{status} eq 'F') {
            print "$obligation->{received}\n";
        }
        else {
            print "Still Outstanding\n";
        }
    }

=cut

sub obligations {

    my ($self, $args) = @_;
    my @headers;

    $self->_require_date_range($args);

    my $endpoint = sprintf(
        '/organisations/vat/%s/obligations',
        $self->vrn,
    );

    my $params = {
        from => $args->{from},
        to   => $args->{to},
    };

    # status is an optional parameter
    if($args->{status}) {
        $args->{status} =~ m/^[OF]$/ or croak 'status parameter is invalid';
        $params->{status} = $args->{status};
    }

    if($args->{test_mode}) {
        push @headers, ('Gov-Test-Scenario' => $args->{test_mode});
        carp 'TEST MODE enabled - returning dummy test data!';
    }

    return $self->get_endpoint({
        endpoint => $endpoint,
        auth_type => 'user',
        parameters => $params,
        headers => [@headers],
    });
}


=head2 liabilities({ from => 'YYYY-MM-DD', to => 'YYYY-MM-DD', [test_mode => $test_mode] })

Retrieve a set of VAT payment liabilities. Returns a WebService::HMRC::Response
object reference. Requires permission for the C<read:vat> service scope.

=head3 Parameters

=over

=item from

Return liabilities from this date, specified as YYYY-MM-DD.
Required parameter. The date must be before today's date, otherwise the api
will return an error.

=item to

Return liabilities up to this date, specified as YYYY-MM-DD.
Required parameter.

=item test_mode

Optional parameter used only for testing against the HMRC sandbox api.

If set to C<SINGLE_LIABILITY>, returns a single valid liability when used
with dates from 2017-01-02 and to 2017-02-02.

If set to C<MULTIPLE_LIABILITIES>, returns multiple valid liabilities when
used with dates from 2017-04-05 and to 2017-12-21.

This parameter should not be used in production systems - it causes dummy
test data to be returned.

=back

=head3 Response Data

For full details of the response data, see the HMRC API specification. In summary,
the data contains a single element `liabilities` pointing to an array of
VAT payment liabilities:

    {
      liabilities => [
        {
          taxPeriod => {
            from => "2017-04-06",
            to   => "2017-07-06"
          },
          type => "VAT ...",
          originalAmount => 6000.00,
          outstandingAmount => 100.00,
          due => "2017-07-06"
        },
      ]
    }

=head3 Example usage

    my $result = $vat->liabilities({
        from => '2018-01-01',
        to   => '2018-03-31',
    });
    foreach my $liability( @{$result->data->{liabilities}} ) {
        print "-- VAT Payment Liability --\n"
        print "           Type: $liability->{type}\n";
        print "   Period Start: $liability->{taxPeriod}->{from}\n";
        print "     Period End: $liability->{taxPeriod}->{to}\n";
        print "Original Amount: $liability->{originalAmount}\n";
        print "     Due Amount: $liability->{outstandingAmount}\n";
        print "       Due Date: $liability->{due}\n";
    }

=cut

sub liabilities {

    my ($self, $args) = @_;
    my @headers;

    $self->_require_date_range($args);

    my $endpoint = sprintf(
        '/organisations/vat/%s/liabilities',
        $self->vrn,
    );

    my $params = {
        from => $args->{from},
        to   => $args->{to},
    };

    if($args->{test_mode}) {
        push @headers, ('Gov-Test-Scenario' => $args->{test_mode});
        carp 'TEST MODE enabled - returning dummy test data!';
    }

    return $self->get_endpoint({
        endpoint => $endpoint,
        auth_type => 'user',
        parameters => $params,
        headers => [@headers],
    });
}


=head2 payments({ from => 'YYYY-MM-DD', to => 'YYYY-MM-DD', [test_mode => $test_mode]  })

Retrieve a set of payments received by HMRC in respect of VAT over the
specified date range. Returns a WebService::HMRC::Response object reference.
Requires permission for the C<read:vat> service scope.

=head3 Parameters

=over

=item from

Return payments from this date, specified as YYYY-MM-DD.
Required parameter.

=item to

Return payments up to this date, specified as YYYY-MM-DD.
Required parameter.

=item test_mode

Optional parameter used only for testing against the HMRC sandbox api.

If set to C<SINGLE_PAYMENT>, returns a single valid payment when used with
dates from 2017-01-02 and to 2017-02-02.

If set to C<MULTIPLE_PAYMENTS>, returns multiple valid payments when used
with dates from 2017-02-27 and to 2017-12-21.

This parameter should not be used in production systems - it causes dummy
test data to be returned.

=back

=head3 Response Data

For full details of the response data, see the HMRC API specification. In
summary, the data contains a single element `payments` pointing to an array
of payments received by HMRC:

    {
      payments => [
        {
          amount => 100.00,
          received => "2017-04-06"
        },
      ]
    }

=head3 Example usage

    my $result = $vat->payments(
        from => '2018-01-01',
        to   => '2018-03-31',
    );
    foreach my $payment( @{$result->data->{payments}} ) {
        print "-- VAT Payments Received by HMRC --\n"
        print "Date Received: $payment->{received}\n";
        print "       Amount: $payment->{amount}\n";
    }

=cut

sub payments {

    my ($self, $args) = @_;
    my @headers;

    $self->_require_date_range($args);

    my $endpoint = sprintf(
        '/organisations/vat/%s/payments',
        $self->vrn,
    );

    my $params = {
        from => $args->{from},
        to   => $args->{to},
    };

    if($args->{test_mode}) {
        push @headers, ('Gov-Test-Scenario' => $args->{test_mode});
        carp 'TEST MODE enabled - returning dummy test data!';
    }

    return $self->get_endpoint({
        endpoint => $endpoint,
        auth_type => 'user',
        parameters => $params,
        headers => [@headers],
    });
}


=head2 get_return({ period_key => $period_key })

Retrieve a previously submitted VAT return corresponding to the supplied
period_key. Returns a WebService::HMRC::Response object reference.
Requires permission for the C<read:vat> service scope.

=head3 Parameters

=over

=item period_key

The ID code for the period that uniquely identifies a submitted
VAT return, as contained within the response from an obligations()
method call.

=back

=head3 Response Data

For full details of the response data, see the HMRC API specification. In
summary, the data is a hashref comprising the following elements which
correspond to fields on the traditional paper VAT100 form:

    {
      periodKey => "#001",
      vatDueSales => 100.00,
      vatDueAcquisitions => 100.00,
      totalVatDue => 200,
      vatReclaimedCurrPeriod => 100.00,
      netVatDue => 100,
      totalValueSalesExVAT => 500,
      totalValuePurchasesExVAT => 500,
      totalValueGoodsSuppliedExVAT => 500,
      totalAcquisitionsExVAT => 500
    }

Note that some fields are returned as integers where only whole pounds
are required to be submitted by HMRC.

=cut

sub get_return {

    my ($self, $args) = @_;

    defined $args->{period_key}
        or croak 'period_key parameter missing or undefined';

    my $endpoint = sprintf(
        '/organisations/vat/%s/returns/%s',
        $self->vrn,
        uri_escape($args->{period_key}),
    );

    return $self->get_endpoint({
        endpoint => $endpoint,
        auth_type => 'user',
    });
}


=head2 submit_return($hashref)

Retrieve a previously submitted VAT return corresponding to the supplied
period_key. Returns a WebService::HMRC::Response object reference.
Requires permission for the C<write:vat> service scope.

=head3 Parameters

For full details of the required parameters and the rules for calculating
each value, see the HMRC API specification and VAT documentation. The
brief descriptions here are intended as a simplified overview to help
understand the code and are not a comprehensive or necessarily accurate
representation of VAT law.

In summary, the data is a hashref comprising the following elements which
correspond to fields on the traditional paper VAT100 form. All parameters
are required.

=over

=item period_key

The ID code for the period that uniquely identifies a submitted
VAT return, as contained within the response from an obligations()
method call.

=item vatDueSales

VAT due on sales and other outputs. Corresponds to box 1 on the traditional
VAT100 paper form.

=item vatDueAcquisitions

VAT due on acquisitions from other EC member states as part of the reverse-
charge scheme. Corresponds to box 2 on the traditional VAT100 paper form.

=item totalVatDue

The sum of vatDueSales and vatDueAcquisitions. Corresponds to box 3 on the
traditional VAT100 paper form.

=item vatReclaimedCurrPeriod

VAT reclaimed on purchases and other inputs, including acquisitions from other
EC member states. This corresponds to box 4 on the traditional VAT100 paper
form.

=item netVatDue

The absolute (unsigned, always positive) difference between totalVatDue and
vatReclaimedCurrPeriod. This corresponds to box 5 on the traditional VAT100
paper form.

=item totalValueSalesExVAT

Total value of sales and all other outputs, excluding any VAT, rounded to
an integer value. This corresponds to box 6 on the traditional VAT100 paper
form.

=item totalValuePurchasesExVAT

Total value of purchases and all other inputs, excluding any VAT and including
any exempt purchases. This corresponds to box 7 on the traditional VAT100
paper form.

=item totalValueGoodsSuppliedExVAT

Total value of all supplies of goods (but not services) to other EC member
states and costs directly related to that supply (such as freight or
insurance), excluding any VAT. This corresponds to box 8 on the traditional
VAT100 paper form.

=item totalAcquisitionsExVAT

Total value of acquisitions of goods from other EC member states and
directly related costs (such as freight or insurance), excluding any VAT.
This corresponds to box 9 on the traditional VAT100 paper form.

=item finalised

Boolean declaration that the data being submitted has been finalised and
approved by the user. Must be true for successful submission.

This parameter is converted to a JSON()->true or JSON()->false
boolean value before encoding to json for submission.

Defaults to false.

=back

=head3 Response Headers

For full details of the response headers, see the HMRC API specification. In
summary the headers confirm receipt of the submission, comprising:

=over

=item Receipt ID

Unique reference number returned for a submission.

=item Receipt-Timestamp

ISO8601 format timestamp of the form '2018-02-14T09:32:15Z'.

=item X-CorrelationId

Unique ID for this operation.

=back

=head3 Response Data

For full details of the response data, see the HMRC API specification. In
summary, the response data is a hashref with keys:

=over

=item processingDate

ISO8601 timestamp indicating the time that the submission was processed.

=item formBundleNumber

Unique number representing the "Form Bundle" in which the submitted data
has been stored by HMRC.

=item paymentIndicator

Set to 'DD' if payment is due to HMRC and they hold a Direct Debit
instruction for the client, 'BANK' if a repayment is due from HMRC and
they hold bank details to make the repayment, otherwise this element is
not present in the returned data.

=item chargeRefNumber

Present only is payment is due to HMRC.

=back

=head3 Example

    my $result = $vat->submit_return({
        periodKey => "#001",
        vatDueSales => 100.00,
        vatDueAcquisitions => 0.00,
        totalVatDue => 100.00,
        vatReclaimedCurrPeriod => 50.00,
        netVatDue => 50.00,
        totalValueSalesExVAT => 500,
        totalValuePurchasesExVAT => 250,
        totalValueGoodsSuppliedExVAT => 0,
        totalAcquisitionsExVAT => 0,
        finalised => 1,
    })
    if($result->is_success) {
        print "==== VAT Return Submitted ====\n";
        printf "        Receipt ID: %s\n", $result->header('Receipt-ID');
        printf " Receipt Timestamp: %s\n", $result->header('Receipt-Timestamp');
        printf "       Tracking ID: %s\n", $result->header('X-CorrelationId');
        printf "   Processing Date: %s\n", $result->data->{processingDate};
        printf "       Form Bundle: %s\n", $result->data->{formBundleNumber};
        if($result->data->{paymentIndicator}) {
            printf " Payment Indicator: %s\n", $result->data->{paymentIndicator};
        }
        if($result->data->{paymentIndicator}) {
            printf "  Charge Reference: %s\n", $result->data->{chargeRefNumber};
        }
    }

=cut

sub submit_return {

    my ($self, $data) = @_;

    $data && ref $data && ref $data eq 'HASH'
        or croak 'data parameter is missing or not a hashref';

    defined $data->{periodKey} or croak 'periodKey data field is undefined';

    # Convert finalised element to JSON true/false boolean
    $data->{finalised} = $data->{finalised} ? JSON()->true
                                            : JSON()->false;

    # Validate numeric data fields, coerce into number before JSON encoding
    foreach my $field(qw(
        vatDueSales
        vatDueAcquisitions
        totalVatDue
        vatReclaimedCurrPeriod
        netVatDue
        totalValueSalesExVAT
        totalValuePurchasesExVAT
        totalValueGoodsSuppliedExVAT
        totalAcquisitionsExVAT
    )) {
        defined $data->{$field} or croak "$field data field is undefined";
        $data->{$field} += 0; # coerce to number
    }

    my $endpoint = sprintf(
        '/organisations/vat/%s/returns',
        $self->vrn,
    );

    return $self->post_endpoint_json({
        endpoint => $endpoint,
        data => $data,
        auth_type => 'user',
    });
}



# PRIVATE METHODS

# _require_date_range(%args)
#
# Checks that supplied args has has keys `from` and `to` and
# that they match the pattern "YYYY-MM-DD". Returns true if so,
# otherwise croaks.

sub _require_date_range {

    my ($self, $args) = @_;

    $args->{from} && $args->{from} =~ m/^\d\d\d\d-\d\d-\d\d$/
        or croak 'from parameter is missing or invalid';

    $args->{to} && $args->{to} =~ m/^\d\d\d\d-\d\d-\d\d$/
        or croak 'to parameter is missing or invalid';

    return 1;
}

=head1 AUTHORISATION

Access to the HMRC Making Tax Digital VAT APIs requires that an application
be registered with HMRC and enabled for this service. Additionally permission
must be granted by a registered user for the application to access the
C<read:vat> or C<write:vat> service scope, as noted for each method.

Authorisation is provided by means of an C<access token>.

For more details on obtaining and using access tokens, See
L<WebService::HMRC::Authenticate>.

Further information, application credentials and documentation may be obtained
from the
L<HMRC Developer Hub|https://developer.service.hmrc.gov.uk/api-documentation>.

=head1 TESTING

The basic tests are run as part of the installation instructions shown above
use an invalid uri as an endpoint. This tests basic interaction with the
module's method and does not require an internet connection.

Developer pre-release tests may be run with the following command:

    prove -l xt/

With a working internet connection, HMRC application credentials and an access
token granted by a test user enrolled for the Making Tax Digital for Business
VAT service, interaction with the real HMRC sandbox api can be tested. The
test user's VAT registration number must also be provided.

The credentials are specified as environment variables when running the tests:

    HMRC_ACCESS_TOKEN=[MY-ACCESS-TOKEN] \
    HMRC_VRN=[USER-VAT-REGISTRATION-NUMBER] \
    make test TEST_VERBOSE=1

=head1 AUTHOR

Nick Prater, <nick@npbroadcast.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-hmrc-vat at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-HMRC-VAT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc WebService::HMRC::VAT

The C<README.pod> file supplied with this distribution is generated from the
L<WebService::HMRC::VAT> module's pod by running the following
command from the distribution root:

    perldoc -u lib/WebService/HMRC/VAT.pm > README.pod

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-HMRC-VAT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-HMRC-VAT>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-HMRC-VAT/>

=item * Github

L<https://github.com/nick-prater/WebService-HMRC-VAT>

=back

=head1 ACKNOWLEDGEMENTS

This module was originally developed for use as part of the
L<LedgerSMB|https://ledgersmb.org/> open source accounting software.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Nick Prater.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

__PACKAGE__->meta->make_immutable;
1; # End of WebService::HMRC::VAT
