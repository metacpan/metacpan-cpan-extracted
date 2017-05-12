package WebService::Braintree;

use warnings;
use strict;

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

=head1 IMPORTANT

This is a community fork of the deprecated L<Net:BrainTree> module renamed
to the WebService::Braintree.  While unsupported by paypal, this library is
endorsed for future development by the open source community.

=head2 DOCUMENTATION

similiar to ruby.
Read the tests, especially t/sandbox, and the ruby docs at L<XXX>.  Note the sandbox tests are ...

=head2 TODO/Wishlist

More code cleaning
Eliminate the metaobject wrangling
use Moo
Work out why the really slow sandbox tests are slow.
work out how to get the TODO sandbox libraries passing.

=head2 FORK

This is a fork of the original vendor-issued L<Net::Braintree>.  While the
original is deprecated, it continues to work. However, it contains a number
of code-style and maintainability problems.  This fork was produced to
address some of those problems and to provide a community driven basis for
going forward.

=head2 DOCUMENTATION

The module is sparesly documented at best.  The public facing API is very
similar to the ruby libraries which are documented at
L<https://developers.braintreepayments.com/ruby/sdk/server/overview>.


You can also look over the test suite for guidance of usage, especially the
C<xt/sandbox> tests.  Not all of these tests work (ones marked
C<todo_skip>).  This is because they are an adaptation of code used against
Braintree's private integration server.  Care has been taken that the same
sandbox tests that fail in this module also fail for L<Net::Braintree>, and
in the same manner.
>>>>>>> a9a0a89da60649fdf74c04859112dbfe3a29475d

=cut

my $configuration_instance = WebService::Braintree::Configuration->new;

sub configuration { return $configuration_instance; }


=head2 ISSUES

The bugtracker is at
L<https://github.com/braintree/braintree_perl/issues>.

Patches welcome!

=head2 TODO/WISHLIST/ROADMAP

=over 4

=item There is no pod documentation.

=item Sandbox tests fail

Some of this is likely because the sandbox account needs to be set
up just right, and some may be because the paypal test integration server
is emulating stateful transactions.

=item Excessive metaobject wrangling

The usage of L<Moose> in this code is subomtimal.  In particular the
following classes use the metaobject in a way that makes what is happening
difficult to understand:

=over 4

=item L<WebService::Braintree::ResultObject>

This class is now the only one that is not immutable in the codebase.
Unpicking how to make this immutable is problematic.  Once this package is
immutable a port to L<Moo> is likely straightforward.

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
