# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::GenericSearch;

use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::AdvancedSearch';

my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);

$field->text("id");
$field->multiple_values("ids");

__PACKAGE__->meta->make_immutable;

1;
__END__
