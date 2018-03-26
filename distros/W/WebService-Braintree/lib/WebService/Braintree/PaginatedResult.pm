# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::PaginatedResult;

use 5.010_001;
use strictures 1;

use Moose;

has total_items => (is => 'ro');
has page_size => (is => 'ro');
has current_page => (is => 'ro');

__PACKAGE__->meta->make_immutable;

1;
__END__
