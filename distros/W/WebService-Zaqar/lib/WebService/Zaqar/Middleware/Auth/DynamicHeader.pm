package WebService::Zaqar::Middleware::Auth::DynamicHeader;

# ABSTRACT: middleware for adding a dynamic authentication header value

use Moose;
extends 'Net::HTTP::Spore::Middleware::Auth';

has header_name => (isa => 'Str', is => 'ro', required => 1);
has header_value_callback => (isa => 'Code', is => 'ro', required => 1);

sub call {
    my ($self, $req) = @_;
    return unless $self->should_authenticate($req);
    my $value = $self->header_value_callback->($req);
    if (defined $value) {
        $req->header($self->header_name => $value);
    }
}

1;
