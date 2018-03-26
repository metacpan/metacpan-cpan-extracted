# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ResourceCollection;
$WebService::Braintree::ResourceCollection::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ResourceCollection

=head1 PURPOSE

This class provides a way of iterating over a collection of resources. It will
lazily retrieve the objects from Braintree.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

# These attributes and methods are undocumented because they're meant to be
# internal-use only. But, prepending underscores makes the code ugly.

has 'callback' => (
    is => 'ro',
    isa => 'CodeRef',
    required => 1,
);
has 'response' => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

sub ids {
    my $self = shift;
    return $self->response->{search_results}{ids};
}

sub page_size {
    my $self = shift;
    return $self->response->{search_results}{page_size};
}

=head1 METHODS

=cut

=head2 is_success

This returns true if the request was successful, otherwise false.

=cut

sub is_success {
    my $self = shift;
    return 1 unless $self->response->{api_error_response};
    return 0;
}

=head2 first

This returns the first object in this collection.

If there is nothing in the collection, this returns undef.

=cut

sub first {
    my $self = shift;
    return if $self->is_empty;
    return $self->callback->([$self->ids->[0]])->[0];
}

=head2 is_empty

This returns true if the collection has anything in it, otherwise false.

=cut

sub is_empty {
    my $self = shift;
    $self->maximum_size == 0;
}

=head2 maximum_size

This returns the number of elements in this collection.

=cut

sub maximum_size {
    my $self = shift;
    return (scalar @{$self->ids || []});
}

=head2 each($block)

This takes a subroutine and executes that subroutine for each element in this
collection.

=cut

sub each {
    my ($self, $block) = @_;

    my @page = ();
    for (my $count = 0; $count < $self->maximum_size; $count++) {
        push(@page, $self->ids->[$count]);
        if ((scalar @page) == $self->page_size) {
            $self->execute_block_for_page($block, \@page);
            @page = ();
        }
    }

    $self->execute_block_for_page($block, \@page) if @page;
    return;
}

sub execute_block_for_page {
    my ($self, $block, $page) = @_;
    $block->($_) for @{$self->callback->($page)};
    return;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
