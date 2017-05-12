package WWW::Google::Contacts::Roles::CRUD;
{
    $WWW::Google::Contacts::Roles::CRUD::VERSION = '0.39';
}

use Moose::Role;
use Carp qw( croak );
use WWW::Google::Contacts::Data;

requires 'create_url';

has raw_data_for_backwards_compability => ( is => 'rw' );
has server => ( is => 'ro', required => 1 );

sub as_xml {
    my $self  = shift;
    my $entry = {
        entry => {
            'xmlns'          => 'http://www.w3.org/2005/Atom',
            'xmlns:gd'       => 'http://schemas.google.com/g/2005',
            'xmlns:gContact' => 'http://schemas.google.com/contact/2008',
            %{ $self->to_xml_hashref },
        },
    };
    my $xml = WWW::Google::Contacts::Data->encode_xml($entry);
    return $xml;
}

sub create_or_update {
    my $self = shift;
    if ( $self->has_id ) {
        return $self->update;
    }
    else {
        return $self->create;
    }
}

sub create {
    my $self = shift;

    my $xml = $self->as_xml;
    my $res =
      $self->server->post( $self->create_url, undef, 'application/atom+xml',
        $xml );
    my $data = WWW::Google::Contacts::Data->decode_xml( $res->content );
    $self->set_from_server($data);
    1;
}

sub retrieve {
    my $self = shift;
    croak "No id set" unless $self->id;

    my $res  = $self->server->get( $self->id );
    my $data = WWW::Google::Contacts::Data->decode_xml( $res->content );
    $self->raw_data_for_backwards_compability($data);
    $self->set_from_server($data);
    $self;
}

sub update {
    my $self = shift;
    croak "No id set" unless $self->id;

    my $xml = $self->as_xml;
    $self->server->put( $self->id, $self->etag, 'application/atom+xml', $xml );
    $self;
}

sub delete {
    my $self = shift;
    croak "No id set" unless $self->id;

    $self->server->delete( $self->id, $self->etag );
    1;
}

1;
