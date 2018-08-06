# vim: sw=4 ts=4 ft=perl

package WebService::Braintree;
$WebService::Braintree::VERSION = '1.7';
use 5.010_001;
use strictures 1;

# Load the error codes omnibus so clients can get at them.
use WebService::Braintree::ErrorCodes;

# Load all the interfaces so clients can get at them.
use WebService::Braintree::AddOn;
use WebService::Braintree::Address;
use WebService::Braintree::ApplePay;
use WebService::Braintree::ClientToken;
use WebService::Braintree::CreditCard;
use WebService::Braintree::CreditCardVerification;
use WebService::Braintree::Customer;
use WebService::Braintree::Discount;
use WebService::Braintree::Dispute;
use WebService::Braintree::DocumentUpload;
use WebService::Braintree::EuropeBankAccount;
use WebService::Braintree::IdealPayment;
use WebService::Braintree::Merchant;
use WebService::Braintree::MerchantAccount;
use WebService::Braintree::PaymentMethod;
use WebService::Braintree::PaymentMethodNonce;
use WebService::Braintree::PayPalAccount;
use WebService::Braintree::Plan;
use WebService::Braintree::SettlementBatchSummary;
use WebService::Braintree::Subscription;
use WebService::Braintree::Transaction;
use WebService::Braintree::TransactionLineItem;
use WebService::Braintree::TransparentRedirect;
use WebService::Braintree::UsBankAccount;
use WebService::Braintree::WebhookNotification;
use WebService::Braintree::WebhookTesting;

# Finally, load the configuration class.
use WebService::Braintree::Configuration;

=head1 NAME

WebService::Braintree - A Client Library for wrapping the Braintree Payment
Services Gateway API

=head2 FORK

This is a fork of the original vendor-issued L<Net::Braintree>.  While the
original is deprecated, it continues to work.  However, it contains a number
of code-style and maintainability problems.  This fork was produced to
address some of those problems and to provide a community driven basis for
going forward.

=head2 DOCUMENTATION

The module is fully documented, but that documentation is reverse-engineered.
The public facing API is very similar to the Ruby libraries which are documented
at L<https://developers.braintreepayments.com/ruby/sdk/server/overview>.

You can also look over the test suite for guidance of usage, especially the
C<t/sandbox> tests.  Not all of these tests work (ones marked
C<todo_skip>).  This is because they are an adaptation of code used against
Braintree's private integration server.

As of version 0.94, with appropriate manual intervention for your sandbox
account (documented in C<t/sandbox/README>), more of the sandbox tests
run/pass for this module than for the original module L<Net::Braintree>.

=head2 OBJECT VS CLASS INTERFACE

As of January, 2018, Braintree released a large refactoring to how clients
interact with the Braintre API. They call the different class (old-style) vs.
object (new-style). Under the old style, configuration is global and all the
interactions with the API use the same configuration. Under the new style, each
call I<could> use a new configuration, if needed.

Both styles will be supported for the foreseeable future. Clients can still set
a global configuration and use the class interface, just like before.

In the documentation below, everything applies to both styles, except where
otherwise noted. If there is a difference between them, an exmaple of both will
be provided.

=head2 GENERAL STYLE

In general, clients of this library will not instantiate any objects.  Every
call you make will be a class method.  Some methods will return objects.  In
those cases, those objects will be documented for you.

Unless otherwise noted, all attributes in these objects will be read-only and
will have been populated by the responses from Braintree.

=head3 Object Style

If you use the object style, then you will instantiate and manage instances of
gateway objects. Each gateway object will have its own configuration.

=cut

{
    my $configuration_instance = WebService::Braintree::Configuration->new;
    sub configuration { return $configuration_instance; }
}

=head2 CONFIGURATION

You will need to set some configuration. Please see
L<WebService::Braintree::Configuration/> for details.

=head3 Class Style

    use WebService::Braintree;

    my $conf = WebService::Braintree->configuration;
    $conf->environment( 'sandbox' );
    $conf->merchant_id( 'use_your_merchant_id' );
    $conf->public_key( 'use_your_public_key' );
    $conf->private_key( 'use_your_private_key' );

    my $result = WebService::Braintree::Transaction->sale(
        ...
    );

=head3 Object Style

    use WebService::Braintree;

    my $gateway = WebService::Braintree::Gateway->new({
        environment => 'sandbox',
        merchant_id => 'use_your_merchant_id',
        public_key  => 'use_your_public_key',
        private_key => 'use_your_private_key',
    });

    my $result = $gateway->transaction->sale(
        ...
    );

=head3 Client Tokens

In general, your server code (that uses this library) will be interacting with
a client-side SDK (such as for Mobile or Javascript).  That library will need a
client token in order to interact with Braintree.  This token will be all the
client-side needs, regardless of whether your server is pointing at the sandbox
or to production.

This token is created with L<WebService::Braintree::ClientToken/generate>.

=head2 OBJECT INTERFACE

The object interface is described on each of the gateway classes. In general,
they are identical to the class interface described below, with the change that
you have invoked a method on a generic C<< $gateway >> object instead of using
the class.

q.v. L<WebService::Braintree::Gateway> for more information.

=head2 CLASS INTERFACE

These are the classes that you will interface with.  Please see their
respective documentation for more detail on how to use them. These classes
only provide class methods. These methods all invoke some part of the
Braintree API.

=head3 L<WebService::Braintree::AddOn>

List all plan add-ons.

=head3 L<WebService::Braintree::Address>

Create, update, delete, and find addresses.

=head3 L<WebService::Braintree::ApplePay>

List, register, and unregister ApplePay domains.

=head3 L<WebService::Braintree::ClientToken>

Generate client tokens.  These are used for client-side SDKs to take actions.

=head3 L<WebService::Braintree::CreditCard>

Create, update, delete, and find credit cards.

=head3 L<WebService::Braintree::CreditCardVerification>

Find and list credit card verifications.

=head3 L<WebService::Braintree::Customer>

Create, update, delete, and find customers.

=head3 L<WebService::Braintree::Discount>

List all plan discounts.

=head3 L<WebService::Braintree::Dispute>

Accept, and find disputes.

=head3 L<WebService::Braintree::DocumentUpload>

Manage document uploads.

=head3 L<WebService::Braintree::EuropeBankAccount>

Find Europe Bank Accounts.

=head3 L<WebService::Braintree::IdealPayment>

Find IdealPayment payment methods.

=head3 L<WebService::Braintree::Merchant>

Provision merchants from "raw ApplePay".

=head3 L<WebService::Braintree::MerchantAccount>

Create, update, and find merchant accounts.

=head3 L<WebService::Braintree::PaymentMethod>

Create, update, delete, and find payment methods.

=head3 L<WebService::Braintree::PaymentMethodNonce>

Create, update, delete, and find payment method nonces.

=head3 L<WebService::Braintree::PayPalAccount>

Find and update PayPal accounts.

=head3 L<WebService::Braintree::Plan>

List all subscription plans.

=head3 L<WebService::Braintree::SettlementBatchSummary>

Generate settlement batch summaries.

=head3 L<WebService::Braintree::Subscription>

Create, update, cancel, find, and handle charges for subscriptions.

=head3 L<WebService::Braintree::Transaction>

Create, manage, and search for transactions.  This is the workhorse class and it
has many methods.

=head3 L<WebService::Braintree::TransactionLineItem>

Find all the transaction line-items.

=head3 L<WebService::Braintree::TransparentRedirect>

Manage the transparent redirection of ????.

B<NOTE>: This class needs significant help in documentation.

=head3 L<WebService::Braintree::UsBankAccount>

Find US Bank Accounts.

=head2 SEARCHING

Several of the interfaces provide a C<< search() >> method.  This method
is unique in that it takes a subroutine reference (subref) instead of a hashref
or other parameters.

=head3 Example

    my $results = WebService::Braintree::Transaction->search(sub {
        my $search = shift;
        $search->amount->between(10, 20);
    });

=head3 Additional Documentation

The various field types are documenated at L<WebService::Braintree::AdvancedSearchNodes>.

=head2 RESPONSES

Responses from the interface methods will either be a
L<Result|WebService::Braintree::Result/> or an
L<ErrorResult|WebService::Braintree::ErrorResult/>. You can distinguish between
them by calling C<< $result->is_success >>.

=head3 Success

If the request is successful, Braintee will reply back and you will receive
(in most cases) a L<result/WebService::Braintree::Result> object. This object
will allow you to access the various components of the response.

In some cases, you will receive something different. Those cases are documented
in the method itself.

=head3 Failure

If there is an issue with the request, Braintree will reply back and you will
receive a L<ErrorResult/WebService::Braintree::ErrorResult> object. It will
contain a L<collection/WebService::Braintree::ValidationErrorCollection> of
L<errors/WebService::Braintree::Error> explaining each issue with the request.

=head2 ISSUES

The bugtracker is at L<https://github.com/singingfish/braintree_perl/issues>.

Patches welcome!

=head2 CONTRIBUTING

Contributions are welcome.  The process:

=over 4

=item Submissions

Please fork this repository on Github, create a branch, then submit a pull
request from that branch to the master of this repository.  All other
submissions will be summarily rejected.

=item Developer Environment

We use Docker to encapsulate the developer environment.  There is a Bash script
in the root called C<< run_tests >> that provides an entrypoint to how this
project uses Docker.  The sequence is:

=over 4

=item run_tests build

This will build the Docker developer environment for each Perl version listed
in C<< PERL_VERSIONS >>

=item run_tests unit [ command ]

This will run the unit tests for each Perl version listed in
C<< PERL_VERSIONS >>. You can provide a C<< prove >> command to limit which
test(s) you run.

=item run_tests integration [ command ]

This will run the sandbox tests for each Perl version listed in
C<< PERL_VERSIONS >>. You can provide a C<< prove >> command to limit which
test(s) you run.

=item run_tests cover

This will run the all the tests for each Perl version listed in
C<< PERL_VERSIONS >> and calculate the coverage.

=back

You can optionally select a Perl version or versions (5.10 through 5.24) to
run the command against by setting the C<< PERL_VERSIONS >> environment
variable.  Use a space to separate multiple versions.

This Bash script has been tested to work in Linux, OSX, and GitBash on Windows.

=over 4

=item Signup

Navigate to L<https://www.braintreepayments.com/sandbox>.  Enter your first name,
last name, Company name of "WebService::Braintree", your country, and your email
address.

=item Activate your account

You will receive an email to the address you provided which will contain a link.
Click on it and you'll sent to a page where you will be asked for a password.

=item Create a sandbox_config.json

On the dashboard page of your new sandbox account, three are three values you
will need to put into a C<< sandbox_config.json >>.  The format of the file must
be:

    {
      "merchant_id": "<< value 1 >>",
      "public_key": "<< value 2 >>",
      "private_key": "<< value 3 >>"
    }

replacing what's in the double-quotes with the appropriate values from your
Braintree sandbox's dashboard.

=item Link your Paypal Sandbox Account

You'll need to follow the instructions at L<< https://developers.braintreepayments.com/guides/paypal/testing-go-live/ruby#linked-paypal-testing >>.  This is
required for some of the integration tests to pass.

Within Setting > Processing, select "Link your sandbox" within the PayPal
section.

Once at the Paypal Developer Dashboard:

=over 4

=item * My Apps & Credentials

=item * Rest Apps

=item * Create new App

=item * Give it a name

=item * Copy the information requested back to Braintree

=back

=item Run the tests

You can now run the integration tests with C<< run_tests integration >>.  These
tests will take between 5 and 20 minutes.

=back

=back

=head2 TODO/WISHLIST/ROADMAP

=over 4

=item Many of the integration tests are still skipped.

=item There aren't enough unit tests.

=item The documentation is still sparse, especially for the PURPOSE sections.

=back

=head2 ACKNOWLEDGEMENTS

Thanks to the staff at Braintree for endorsing this fork.

Thanks to ZipRecruiter for sponsoring improvements to the forked code.

Thanks to Rob Kinyon for refactoring significant portions of the codebase.

=head2 LICENSE AND COPYRIGHT

Copyright 2017 Kieren Diment <zarquon@cpan.org>

Copyright 2011-2014 Braintree, a division of PayPal, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of WebService::Braintree
__END__
