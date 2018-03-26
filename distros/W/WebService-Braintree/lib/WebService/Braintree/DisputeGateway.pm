# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::DisputeGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

use WebService::Braintree::Util qw(validate_id);

has 'gateway' => (is => 'ro');

use WebService::Braintree::_::Dispute;
use WebService::Braintree::DisputeSearch;

sub accept {
    my $self = shift;
    my ($id) = @_;
    confess "ArgumentError" unless validate_id($id);

    $self->_make_request("/disputes/${id}/accept", "put", undef);
}

sub finalize {
    my $self = shift;
    my ($id) = @_;
    confess "ArgumentError" unless validate_id($id);

    $self->_make_request("/disputes/${id}/finalize", "put", undef);
}

sub add_file_evidence {
    my $self = shift;
    my ($id, $upload_id) = @_;
    confess "ArgumentError" unless validate_id($id);
    confess "ArgumentError" unless validate_id($upload_id);

    $self->_make_request("/disputes/${id}/evidence", "post", {document_upload_id => $upload_id});
}

sub add_text_evidence {
    my $self = shift;
    my ($id, $content) = @_;
    confess "ArgumentError" unless validate_id($id);
    confess "ArgumentError" unless validate_id($content);

    $self->_make_request("/disputes/${id}/evidence", "post", {comments => $content});
}

sub remove_evidence {
    my $self = shift;
    my ($id, $evidence_id) = @_;
    confess "ArgumentError" unless validate_id($id);
    confess "ArgumentError" unless validate_id($evidence_id);

    $self->_make_request("/disputes/${id}/evidence/${evidence_id}", "delete", undef);
}

sub find {
    my $self = shift;
    my ($id) = @_;
    confess "ArgumentError" unless validate_id($id);

    $self->_make_request("/disputes/${id}", "get", undef);
}

sub search {
    my ($self, $block) = @_;

    return $self->paginated_collection({
        method => 'post',
        url => "/disputes/advanced_search",
        inflate => [qw/disputes dispute _::Dispute/],
        search => $block->(WebService::Braintree::DisputeSearch->new),
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
