# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::GenericSearch;

use 5.010_001;
use strictures 1;

use Moo;
with 'WebService::Braintree::Role::AdvancedSearch';

use constant FIELDS => [];

__PACKAGE__->text_field("id");
__PACKAGE__->multiple_values_field("ids");

__PACKAGE__->meta->make_immutable;

1;
__END__
