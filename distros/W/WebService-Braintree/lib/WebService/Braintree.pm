package WebService::Braintree;
$WebService::Braintree::VERSION = '0.93';
use strict;
use warnings;
use WebService::Braintree::Address;
use WebService::Braintree::AdvancedSearchFields;
use WebService::Braintree::AdvancedSearchNodes;
use WebService::Braintree::ApplePayCard;
use WebService::Braintree::CreditCard;
use WebService::Braintree::Customer;
use WebService::Braintree::CustomerSearch;
use WebService::Braintree::DisbursementDetails;
use WebService::Braintree::Dispute;
use WebService::Braintree::MerchantAccount;
use WebService::Braintree::PartnerMerchant;
use WebService::Braintree::PaymentMethod;
use WebService::Braintree::PayPalAccount;
use WebService::Braintree::PayPalDetails;
use WebService::Braintree::ResourceCollection;
use WebService::Braintree::SettlementBatchSummary;
use WebService::Braintree::Subscription;
use WebService::Braintree::SubscriptionSearch;
use WebService::Braintree::Transaction;
use WebService::Braintree::TransactionSearch;
use WebService::Braintree::Disbursement;
use WebService::Braintree::TransparentRedirect;
use WebService::Braintree::WebhookNotification;
use WebService::Braintree::WebhookTesting;
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

The module is sparsely documented, at best.  The public facing API is very
similar to the Ruby libraries which are documented at
L<https://developers.braintreepayments.com/ruby/sdk/server/overview>.


You can also look over the test suite for guidance of usage, especially the
C<xt/sandbox> tests.  Not all of these tests work (ones marked
C<todo_skip>.  This is because they are an adaptation of code used against
Braintree's private integration server.  Care has been taken that the same
sandbox tests that fail in this module also fail for L<Net::Braintree>, and
in the same manner.

=head2 GENERAL STYLE

In general, clients of this library will not instantiate any objects.  Every
call you make will be a class method.  Some methods will return objects.  In
those cases, those objects will be documented for you.

=cut

my $configuration_instance = WebService::Braintree::Configuration->new;

sub configuration { return $configuration_instance; }

=head2 CONFIGURATION

You will need to set some configuration.

    use WebService::Braintree;

    my $conf = WebService::Braintree->configuration;
    $conf->environment( 'sandbox' );
    $conf->merchant_id( 'use_your_merchant_id' );
    $conf->public_key( 'use_your_public_key' );
    $conf->private_key( 'use_your_private_key' );

Please see L<WebService::Braintree::Configuration/> for more information.

=head3 Client Tokens

In general, your server code (that uses this library) will be interacting with
a client-side SDK (such as for Mobile or Javascript).  That library will need a
client token in order to interact with Braintree.  This token will be all the
client-side needs, regardless of whether your server is pointing at the sandbox
or to production.

This token is created with L<WebService::Braintree::ClientToken/generate>.

=head2 INTERFACE

There are twelve classes that you will interface with.  Please see their
respective documentation for more detail on how to use them.

=head3 L<WebService::Braintree::Address>

Create, update, delete, and find addresses.

=head3 L<WebService::Braintree::ClientToken>

Generate client tokens.  These are used for client-side SDKs to take actions.

=head3 L<WebService::Braintree::CreditCard>

Create, update, delete, and find credit cards.

=head3 L<WebService::Braintree::CreditCardVerification>

Find and list credit card verifications.

=head3 L<WebService::Braintree::Customer>

Create, update, delete, and find customers.

=head3 L<WebService::Braintree::MerchantAccount>

Create, update, and find merchant accounts.

=head3 L<WebService::Braintree::PaymentMethod>

Create, update, delete, and find payment methods.

=head3 L<WebService::Braintree::PayPalAccount>

Find and update PayPal accounts.

=head3 L<WebService::Braintree::SettlementBatchSummary>

Generate settlement batch summaries.

=head3 L<WebService::Braintree::Subscription>

Create, update, cancel, find, and handle charges for subscriptions.

=head3 L<WebService::Braintree::Transaction>

Create, manage, and search for transactions.  This is the workhorse class and it
has many methods.

=head3 L<WebService::Braintree::TransparentRedirect>

Manage the transparent redirection of ????.

B<NOTE>: This class needs significant help in documentation.

=head2 SEARCHING

Several of the class interfaces provide a C<< search() >> method.  This method
is unique in that it takes a subroutine reference (subref) instead of a hashref
or other parameters.

Documentation for this is forthcoming.

=head2 ISSUES

The bugtracker is at
L<https://github.com/singingfish/braintree_perl/issues>.

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

=item run_tests build [ command ]

=item run_tests test [ command ]

=item run_tests integration [ command ]

=item run_tests cover

=back

You can optionally select a Perl version or versions (5.10 through 5.24) to
run the command against by setting the C<< PERL_VERSIONS >> environment
variable.  Use a space to separate multiple versions.

This Bash script has been tested to work in Linux, OSX, and GitBash on Windows.

=item Running the tests in xt/

The tests in C<< t/ >> are unit tests.  The tests in C<< xt/ >> are E2E tests
that run against Braintree's sandbox / integration environment.  To run them,
you will need to have a Braintree sandbox account linked to Paypal.

=over 4

=item Signup

Navigate to L<https://www.braintreepayments.com/sandbox>.  Enter your first name,
last name, Comany name of "WebService::Braintree", your country, and your email
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

=item There is no pod documentation.

=item Sandbox tests fail

Some of this is likely needed because the sandbox account needs to be set
up just right, and some may be because the paypal test integration server
is emulating stateful transactions.

=item Excessive metaobject wrangling

The usage of L<Moose> in this code is sub-opimtimal.  In particular the
following classes use the metaobject in a way that makes what is happening
difficult to understand:

=over 4

=item L<WebService::Braintree::ResultObject>

This class is now the only one that is not immutable in the codebase.
Unpicking how to make this mutable is problematic.

The constructors for the following should be fixed to be explicit (requires
understanding of what ResultObject is doing):

=item L<WebService::Braintree::AdvancedSearchFields>

=item L<WebService::Braintree::SubscriptionSearch>

=item L<WebService::Braintree::CreditCardVerificationSearch>

=item L<WebService::Braintree::CustomerSearch>

=item L<WebService::Braintree::Result>

=item L<WebService::Braintree::TransactionSearch>

=back

Also, having stared at the internals of some objects in the perl debugger
for a bit, I fear there may be memory leaks, but I have not investigated
this closely.  It's also possible that the way that several of the above
methods use a C<$field> variable in package lexical scope that this module
may not be fork-safe.  These concerns also apply to L<Net::Braintree> (only
it has a bigger memory footprint).

=item Sandbox tests

One of the sandbox tests is really really slow.

=back

=head2 ACKNOWLEDGEMENTS

Thanks to the staff at Braintree for endorsing this fork.

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
