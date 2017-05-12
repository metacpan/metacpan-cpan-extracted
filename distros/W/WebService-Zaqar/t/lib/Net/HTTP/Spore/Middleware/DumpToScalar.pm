package Net::HTTP::Spore::Middleware::DumpToScalar;

# ABSTRACT: middleware for adding a simple header to all requests

use Moose;
extends 'Net::HTTP::Spore::Middleware';

has 'dump_log' => (is => 'ro',
                   required => 1);

sub push_request {
    my ($self, $request) = @_;
    push @{$self->dump_log}, $request;
}

sub shift_request {
    my $self = shift;
    return shift @{$self->dump_log};
}

sub call {
    my ($self, $req) = @_;
    $self->push_request($req);
}

1;
