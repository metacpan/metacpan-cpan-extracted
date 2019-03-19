package WebService::ValidSign::API::DocumentPackage;
our $VERSION = '0.003';
use Moo;
use namespace::autoclean;

# ABSTRACT: A REST API client for ValidSign

use WebService::ValidSign::Object::Sender;
use HTTP::Request;
use HTTP::Request::Common;
use Carp qw(croak);
use List::Util qw(first);

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

    if ($package->has_id) {
        croak("Package is already created, it has an ID");
    }

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

    if (!$package->has_documents) {
        croak("Unable to add documents, we have none!");
    }

    if ($package->count_documents == 1) {
        push(@files, ( file => [ $package->documents->[0]->path ] ));
    }
    else {
        foreach (@{$package->documents}) {
            push(@files, ( 'file[]' => [ $_->path ] ))
        }
    }

    # Monkey patch so LWP::MediaTypes can deal with us
    local *File::Temp::path = sub { return shift->filename };

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

sub find {
    my ($self, $id) = @_;

    my $uri = $self->get_endpoint($self->action_endpoint, $id);
    my $request = HTTP::Request->new(
        GET => $uri,
        [
            'Content-Type' => 'application/json',
            Accept         => 'application/json',
        ]
    );

    my $res = $self->call_api($request);
    return WebService::ValidSign::Object::DocumentPackage->new(%$res);
}

sub download_document {
    my ($self, $package, $document_id) = @_;

    if (!$package->has_id) {
        croak("Please create a document package first on the ValidSign endpoint");
    }

    if (!$document_id && !$package->count_documents) {
        croak(    "Unable to download documents, package has none, or you did"
                . " not supply one!");
    }
    $document_id //= $package->documents->[0]->{id};

    my $uri = $self->get_endpoint($self->action_endpoint, $package->id,
            'documents', $document_id, 'pdf');

    return $self->download_file($uri);

    return;
}

sub download_documents {
    my ($self, $package) = @_;

    if (!$package->has_id) {
        croak("Please create a document package first on the ValidSign endpoint");
    }

    if ($package->has_documents) {
        my $uri = $self->get_endpoint($self->action_endpoint, $package->id,
            qw(documents zip));
        return $self->download_file($uri);
    }
    return;

}

with "WebService::ValidSign::API";

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::API::DocumentPackage - A REST API client for ValidSign

=head1 VERSION

version 0.003

=head1 SYNOPSIS

You should not need to instantiate this object yourself. Use L<WebService::ValidSign> for this.

    use WebService::ValidSign;
    my $api = WebService::ValidSign->new(
        secret => 'foo',
        endpoint => 'https://some.url/api',
    );

    my $pkg_api = $api->package;

=head1 ATTRIBUTES

=head2 action_endpoints

Implement the endpoint as required by L<WebService::ValidSign::API>.

=head1 METHODS

=head2 find

    $self->find("someid");

Find a document package based on the ID. You get a L<WebService::ValidSign::Object::DocumentPackage> object when we have found the document package.

CAVEAT!

The object is not full up to spec, as the documents are still an arrayref
filled with hashrefs. Later implementations will try to fix this issue.

=head2 create

    $self->create($pkg);

Create a document package on the ValidSign side. You need to pass a
L<Webservice::ValidSign::Object::DocumentPackage> to the call. It cannot have
and ID as you would be able to create two packages with the same ID. You can
call this function with, or without documents attached to the document package.

=head2 create_with_documents

    $self->create_with_documents($pkg);

Similar to the create call, but this one can only be called when there are documents attached to the document package.

=head2 download_document

    $self->download_document($pkg, $document_id);

Download a document from package. When no document id is supplied we will only download the first document. If you supply one, we will use this document id.
There is not check to see if the document actually exists in the document package. Callers should check these themselves (via the C<find> command).

=head2 download_documents

    $self->download_documents($pkg);

Download all documents from the package. You will get a filehandle to a zip
file. Use L<Archive::ZIP> to extract the files.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
