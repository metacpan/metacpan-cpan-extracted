package WebService::Braintree::PaginatedResult;
$WebService::Braintree::PaginatedResult::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;
extends "WebService::Braintree::ResultObject";

has 'total_items' => (is => 'rw');
has 'page_size' => (is => 'rw');
has 'current_page' => (is => 'rw');

sub init {
    my ($self, $total_items, $page_size, $current_page) = @_;
    $self->total_items($total_items);
    $self->page_size($page_size);
    $self->current_page($current_page);
    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
