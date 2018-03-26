# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::PaginatedCollection;
$WebService::Braintree::PaginatedCollection::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::PaginatedCollection

=head1 PURPOSE

This class provides a way of iterating over a paginated collection of resources.
It will lazily retrieve the objects from Braintree.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

=head1 METHODS

=cut

has callback => (is => 'ro');

=head2 each($block)

This takes a subroutine and executes that subroutine for each page of results
in this collection.

=cut

sub each {
    my ($self, $block) = @_;

    my $current_page = 0;
    my $total_items = 0;

    while (1) {
        $current_page += 1;

        my $result = $self->callback->($current_page);
        $total_items = $result->total_items;

        foreach my $item (@{$result->current_page}) {
            $block->($item);
        }

        last if $current_page * $result->page_size >= $total_items;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
