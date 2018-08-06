# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Role::Interface;

use 5.010_001;
use strictures 1;

use Moo::Role;

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

1;
__END__
