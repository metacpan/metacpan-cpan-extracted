package WebService::Box::File;

use strict;
use warnings;

use Moo;
use Sub::Identify qw(sub_name);
use Types::Standard qw(Str Int InstanceOf);

use WebService::Box::Types::Library qw(BoxPerson Timestamp BoxFolderHash OptionalStr SharedLink);
use WebService::Box::Request;
use WebService::Box::Folder;

our $VERSION = 0.01;

has session => (is => 'ro', isa => InstanceOf["WebService::Box::Session"], required => 1);

has [qw/type id name description structure/] => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

has [qw/etag sequence_id sha1 item_status version_number/] => (
    is        => 'ro',
    isa       => OptionalStr,
    predicate => 1,
);

has [qw/size comment_count/] => (
    is        => 'ro',
    isa       => Int,
    predicate => 1,
);

has [qw/created_by modified_by owned_by/] => (
    is        => 'ro',
    isa       => BoxPerson,
    coerce    => BoxPerson()->coercion,
    predicate => 1,
);

has [qw/created_at modified_at trashed_at purged_at content_created_at content_modified_at/] => (
    is        => 'ro',
    isa       => Timestamp,
    coerce    => Timestamp()->coercion,
    predicate => 1,
);

has shared_link => (
    is        => 'ro',
    isa       => SharedLink,
    coerce    => SharedLink()->coercion,
    predicate => 1,
);

has parent_data => (is => 'ro', isa => BoxFolderHash);

has request => (
    is      => 'ro',
    isa     => InstanceOf["WebService::Box::Request"], 
    lazy    => 1,
    default => sub {
        my $self = shift;
        WebService::Box::Request->new( session => $self->session )
    },
);

has _parent_object => (is => 'rwp', isa => InstanceOf["WebService::Box::Folder"]);

has error => (is => 'rwp', isa => Str);

around [qw(
    size comment_count created_by modified_by owned_by created_at modified_at trashed_at purged_at
    content_created_at content_modified_at type name description structure shared_link
    etag sequence_id sha1 item_status version_number
)] => sub {
    my $orig = shift;
    my $self = shift;

    my $method_name = sub_name $orig;

    if ( !$self->id ) {
        $self->session->box->error(
            "invalid method call ($method_name): file id does not exist, create a new object with id"
        );

        return;
    }

    my $predicate   = $self->can( 'has_' . $method_name );
    if ( !$self->$predicate() ) {
        $self = $_[1] = $self->rebuild;
    }

    return $self->$orig();
};

sub rebuild {
    my ($self) = @_;

    $self->_set_error('');

    if ( !$self->id ) {
        $self->session->box->error( 'cannot rebuild: file id does not exist' );
        return;
    }

    my $parent_object = $self->_parent_object;
    my %file_data = $self->request->do(
        ressource => 'files',
        action    => 'get',
        id        => $self->id,
    ) or do { $self->_set_error( $self->request->error ); return };

    $self = $_[0] = WebService::Box::File->new( %file_data, session => $self->session );

    if ( $parent_object && $parent_object->id == $_[0]->parent_data->{id} ) {
        $_[0]->_set__parent_object( $parent_object );
    }

    return $_[0];
}

sub parent {
    my ($self) = @_;

    my $data = $self->parent_data;

    if ( !$data ) {
        if ( !$self->id ) {
            $self->session->box->error( 'no id for parent found and no file id exists' );
            return;
        }

        $self = $_[0] = $self->rebuild;
    }

    if ( !$self->_parent_object ) {
        my $data = $self->parent_data;
        
        $self->_set__parent_object(
            WebService::Box::Folder->new( %{$data}, session => $self->session )
        );
    }

    return $self->_parent_object;
}

sub upload {
    my ($self, $path, $parent) = @_;

    $self->_set_error('');

    my $parent_id = ref $parent ? $parent->id : $parent;

    if ( !-e $path ) {
        $self->session->box->error( 'the file requested to upload does not exist' );
        return;
    }

    my $content = do{ local (@ARGV,$/) = $path; <> };

    my %upload_data = $self->request->do(
        ressource => 'files',
        action    => 'upload',
        file      => { filename => $path, content => $content },
        parent_id => $parent_id, 
    ) or do { $self->_set_error( $self->request->error ); return };

    my $uploaded_file = WebService::Box::File->new( %upload_data, session => $self->session );
    return $uploaded_file;
}

sub download {
}

sub comment {
}

sub comments {
}

sub BUILDARGS {
   my ( $class, @args ) = @_;

   unshift @args, "id" if @args % 2 == 1;

   return { @args };
}

1;

__END__

=pod

=head1 NAME

WebService::Box::File

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
