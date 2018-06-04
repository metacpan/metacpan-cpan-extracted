# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::CreditCard;
$WebService::Braintree::CreditCard::VERSION = '1.5';
use 5.010_001;
use strictures 1;

use WebService::Braintree::CreditCard::CardType;
use WebService::Braintree::CreditCard::Commercial;
use WebService::Braintree::CreditCard::CountryOfIssuance;
use WebService::Braintree::CreditCard::Debit;
use WebService::Braintree::CreditCard::DurbinRegulated;
use WebService::Braintree::CreditCard::Healthcare;
use WebService::Braintree::CreditCard::IssuingBank;
use WebService::Braintree::CreditCard::Location;
use WebService::Braintree::CreditCard::Payroll;
use WebService::Braintree::CreditCard::Prepaid;

=head1 NAME

WebService::Braintree::CreditCard

=head1 PURPOSE

This class creates, updates, deletes, and finds credit cards.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 create()

This takes a hashref of parameters and returns a L<response|WebService::Braintee::Result> with the C<< credit_card() >> set.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->credit_card->create($params);
}

=head2 from_nonce()

This takes a nonce and returns a L<response|WebService::Braintee::Result> with the C<< credit_card() >> set.

=cut

sub from_nonce {
    my ($class, $nonce) = @_;
    $class->gateway->credit_card->from_nonce($nonce);
}

=head2 find()

This takes a token and returns a L<response|WebService::Braintee::Result> with the C<< credit_card() >> set.

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->credit_card->find($token);
}

=head2 update()

This takes a token and a hashref of parameters. It will update the corresponding
credit card (if found) and return a L<response|WebService::Braintee::Result>
with the C<< credit_card() >> set.

=cut

sub update {
    my($class, $token, $params) = @_;
    $class->gateway->credit_card->update($token, $params);
}

=head2 delete()

This takes a token. It will delete the corresponding credit card (if found) and
return a L<response|WebService::Braintee::Result> with the C<< credit_card() >> set.

=cut

sub delete {
    my ($class, $token) = @_;
    $class->gateway->credit_card->delete($token);
}

=head2 credit()

This takes a token and an optional hashref of parameters. This delegates to
L<WebService::Braintree::Transaction/credit>, setting the
C<< payment_method_token >> appropriately.

=cut

sub credit {
    my ($class, $token, $params) = @_;
    $class->gateway->transaction->credit({
        %{$params//{}},
        payment_method_token => $token,
    });
}

=head2 sale()

This takes a token and an optional hashref of parameters. This delegates to
L<WebService::Braintree::Transaction/sale>, setting the
C<< payment_method_token >> appropriately.

=cut

sub sale {
    my ($class, $token, $params) = @_;
    $class->gateway->transaction->sale({
        %{$params//{}},
        payment_method_token => $token,
    });
}

=head2 expired()

This returns a L<collection|WebService::Braintree::ResourceCollection> of all
the expired L<credit cards|WebService::Braintree::_::CreditCard>.

C<< expired_cards() >> is an alias to this method.

=cut

sub expired {
    my ($class) = @_;
    $class->gateway->credit_card->expired();
}

sub expired_cards {
    shift->expired(@_);
}

=head2 expiring_between()

This takes two L<DateTime>s and returns a L<collection|WebService::Braintree::ResourceCollection> of all the L<credit cards|WebService::Braintree::_::CreditCard>
expiring between them.

=cut

sub expiring_between {
    my ($class, $start, $end) = @_;
    $class->gateway->credit_card->expiring_between($start, $end);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
