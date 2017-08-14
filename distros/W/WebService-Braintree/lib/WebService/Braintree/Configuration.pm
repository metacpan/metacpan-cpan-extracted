package WebService::Braintree::Configuration;
$WebService::Braintree::Configuration::VERSION = '0.92';
=head1 NAME

WebService::Braintree::Configuration

=head1 PURPOSE

This keeps all configuration information for your WebService::Braintree
installation.

A singleton of this class is instantiated when you use L<WebService::Braintree>.
You are intended to set attributes of this class immediately, then the rest of
the distribution knows what to do.

=cut

use WebService::Braintree::Gateway;
use Moose;

# IS THIS UNUSED? I cannot find reference in the current documentation for Ruby
# or Node.JS nor is it referenced anywhere else in the code.
has partner_id => (is => 'rw');

=head1 ATTRIBUTES

Get these values from L<Braintree's API credentials documentation|https://articles.braintreepayments.com/control-panel/important-gateway-credentials#api-credentials>.

These attributes are standard mutators. If you invoke them with a value, they
will set the attribute to that value. If you invoke them without a value, they 
will return the current value.

=head2 merchant_id(?$value)

This is your merchant_id.

=cut

has merchant_id => (is => 'rw');

=head2 public_key(?$value)

This is your public_key.

=cut

has public_key => (is => 'rw');

=head2 private_key(?$value)

This is your private_key.

=cut

has private_key => (is => 'rw');

=head2 environment(?$value)

This is your environment. The environment can be:

=over 4

=item development | integration

This is when you're using a local server for testing. It's unlikely you will
ever want to use this.

=item sandbox

This is when you're using your Braintree sandbox for testing.

=item qa

This is when you're using qa-master.braintreegateway.com for testing.

=item production

This is when you're live and rocking.

=back

If you provide a value other than the ones listed above, a warning will be
thrown. This distribution will probably not work properly in that case.

Management reserves the right to change this from a warning to a thrown
exception in the future.

=head1 USAGE

Do yourself a favor and store these values in a configuration file, not your
source-controlled code.

=cut

has environment => (
    is => 'rw',
    trigger => sub {
        my ($self, $new_value, $old_value) = @_;
        if ($new_value !~ /integration|development|sandbox|production|qa/) {
            warn "Assigned invalid value to WebService::Braintree::Configuration::environment";
        }
        if ($new_value eq "integration") {
            $self->public_key("integration_public_key");
            $self->private_key("integration_private_key");
            $self->merchant_id("integration_merchant_id");
        }
    }
);

has gateway => (is  => 'ro', lazy => 1, default => sub {
    WebService::Braintree::Gateway->new({config => shift})
});

sub base_merchant_path {
    my $self = shift;
    return "/merchants/" . $self->merchant_id;
}

sub base_merchant_url {
    my $self = shift;
    return $self->base_url() . $self->base_merchant_path;
}

sub base_url {
    my $self = shift;
    return $self->protocol . "://" . $self->server . ':' . $self->port;
}

sub port {
    my $self = shift;
    if ($self->environment =~ /integration|development/) {
        return $ENV{'GATEWAY_PORT'} || "3000"
    } else {
        return "443";
    }
}

sub server {
    my $self = shift;
    return "localhost" if $self->environment eq 'integration';
    return "localhost" if $self->environment eq 'development';
    return "api.sandbox.braintreegateway.com" if $self->environment eq 'sandbox';
    return "api.braintreegateway.com" if $self->environment eq 'production';
    return "qa-master.braintreegateway.com" if $self->environment eq 'qa';
}

sub auth_url {
    my $self = shift;
    return "http://auth.venmo.dev:9292" if $self->environment eq 'integration';
    return "http://auth.venmo.dev:9292" if $self->environment eq 'development';
    return "https://auth.sandbox.venmo.com" if $self->environment eq 'sandbox';
    return "https://auth.venmo.com" if $self->environment eq 'production';
    return "https://auth.qa.venmo.com" if $self->environment eq 'qa';
}

sub ssl_enabled {
    my $self = shift;
    return ($self->environment !~ /integration|development/);
}

sub protocol {
    my $self = shift;
    return $self->ssl_enabled ? 'https' : 'http';
}

=head1 METHODS

There is one read-only method.

=head2 api_version()

This returns the Braintree API version this distribution speaks.

=cut

sub api_version {
    return "4";
}

__PACKAGE__->meta->make_immutable;

1;
__END__
