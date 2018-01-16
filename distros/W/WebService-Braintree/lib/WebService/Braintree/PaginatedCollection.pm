package WebService::Braintree::PaginatedCollection;
$WebService::Braintree::PaginatedCollection::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
extends "WebService::Braintree::ResultObject";

has 'callback' => (is => 'rw');

sub init {
    my ($self, $callback) = @_;
    $self->callback($callback);
    return $self;
}

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
