package WebService::ValidSign::API::DocumentPackage;
our $VERSION = '0.002';
use Moo;
use namespace::autoclean;

# ABSTRACT: A REST API client for ValidSign

use WebService::ValidSign::Object::Sender;
use HTTP::Request;
use HTTP::Request::Common;
use Carp qw(croak);

has json => (
    is => 'ro',
    builder => 1,
);

sub _build_json {
    require JSON::XS;
    return JSON::XS->new->convert_blessed;
}

has action_endpoint => (
    is      => 'ro',
    default => 'packages'
);

sub details {
    my ($self, $package) = @_;

    my $uri = $self->get_endpoint($self->action_endpoint, $package->id);
    my $request = HTTP::Request->new(
        GET => $uri,
        [
            'Content-Type' => 'application/json',
            Accept         => 'application/json',
        ]
    );
    return $self->call_api($request);

}

sub create_with_documents {
    my ($self, $package) = @_;
    my $uri = $self->get_endpoint($self->action_endpoint);
    my $json = $self->json->encode($package);

    my $request = $self->_add_documents($package, $uri, $json);

    my $response = $self->call_api($request);
    $package->id($response->{id});
    return $response->{id};
}

sub _add_documents {
    my ($self, $package, $uri, $json) = @_;

    my @files;
    if ($package->count_documents == 1) {
        push(@files, ( file => [ $package->documents->[0]->path ] ));
    }
    else {
        foreach (@{$package->documents}) {
            push(@files, ( 'file[]' => [ $_->path ] ))
        }
    }

    return POST $uri,
        'Content_Type' => 'form-data',
        Accept         => 'application/json',
        Content        => [
            defined $json ? (payload => $json) : (),
            @files,
    ];
}

sub create {
    my ($self, $package) = @_;

    if ($package->has_id) {
        croak("Package is already created, it has an ID");
    }

    if ($package->has_documents) {
        return  $self->create_with_documents($package);
    }

    my $json = $self->json->encode($package);
    my $uri  = $self->get_endpoint($self->action_endpoint);

    my $request = HTTP::Request->new(
        POST => $uri,
        [
            'Content-Type' => 'application/json',
            Accept         => 'application/json',
        ],
        $json
    );

    my $response = $self->call_api($request);
    $package->id($response->{id});
    return $response->{id};
}

sub add_document {
    my ($self, $package) = @_;

    if (!$package->has_id) {
        croak("Please create a document package first on the ValidSign endpoint");
    }

    my $json = $self->json->encode($package);

    my $uri = $self->get_endpoint(
        $self->action_endpoint,
        $package->id,
        'documents'
    );

    my $req = $self->_add_documents($package, $uri, $json);
    my $response = $self->call_api($req);
    return $response->{id};
}

with "WebService::ValidSign::API";

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::API::DocumentPackage - A REST API client for ValidSign

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 ATTRIBUTES

=head1 METHODS

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
