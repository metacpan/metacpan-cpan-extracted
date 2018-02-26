package WebService::Braintree::TransparentRedirect;
$WebService::Braintree::TransparentRedirect::VERSION = '1.1';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::TransparentRedirect

=head1 PURPOSE

This class generates and manages the transparent redirects.

=head1 EXPLANATION

TODO

=cut

use Moose;

=head1 CLASS METHODS

=head2 confirm()

This takes a query string and returns whatever confirm() returns.

=cut

sub confirm {
    my($class, $query_string) = @_;
    $class->gateway->transparent_redirect->confirm($query_string);
}

=head2 transaction_data()

This takes a hashref of params and returns whatever transaction_data() returns.

=cut

sub transaction_data {
    my ($class, $params) = @_;
    $class->gateway->transparent_redirect->transaction_data($params);
}

=head2 create_customer_data()

This takes a hashref of params and returns whatever create_customer_data() returns.

=cut

sub create_customer_data {
    my ($class, $params) = @_;
    $class->gateway->transparent_redirect->create_customer_data($params);
}

=head2 update_customer_data()

This takes a hashref of params and returns whatever update_customer_data() returns.

=cut

sub update_customer_data {
    my ($class, $params) = @_;
    $class->gateway->transparent_redirect->update_customer_data($params);
}

=head2 create_credit_card_data()

This takes a hashref of params and returns whatever create_credit_card_data() returns.

=cut

sub create_credit_card_data {
    my ($class, $params) = @_;
    $class->gateway->transparent_redirect->create_credit_card_data($params);
}

=head2 update_credit_card_data()

This takes a hashref of params and returns whatever update_credit_card_data() returns.

=cut

sub update_credit_card_data {
    my ($class, $params) = @_;
    $class->gateway->transparent_redirect->update_credit_card_data($params);
}

=head2 url()

This takes no parameters and returns whatever url() returns.

=cut

sub url {
    my $class = shift;
    $class->gateway->transparent_redirect->url;
}

sub gateway {
    WebService::Braintree->configuration->gateway;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
