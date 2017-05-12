package WebService::Box::Folder;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int InstanceOf);
use WebService::Box::Types::Library qw(BoxPerson Timestamp BoxFolderHash OptionalStr);
use WebService::Box::Request;
use WebService::Box::File;

our $VERSION = 0.01;

has session => (is => 'ro', isa => InstanceOf["WebService::Box::Session"], required => 1);

has [qw/type id name description structure/] => (
    is  => 'ro',
    isa => Str,
);

has [qw/etag sequence_id sha1 item_status version_number/] => (
    is  => 'ro',
    isa => OptionalStr,
);

has [qw/size comment_count/] => (
    is  => 'ro',
    isa => Int,
);

has [qw/created_by modified_by owned_by/] => (
    is     => 'ro',
    isa    => BoxPerson,
    coerce => BoxPerson()->coercion,
);

has [qw/created_at modified_at trashed_at purged_at content_created_at content_modified_at/] => (
    is     => 'ro',
    isa    => Timestamp,
    coerce => Timestamp()->coercion,
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

sub parent {
    my ($self) = @_;

    my $data = $self->parent_data;

    if ( !$data ) {
        if ( !$self->id ) {
            $self->session->box->error( 'no id for parent found and no file id exists' );
            return;
        }

        my %file_data = $self->request->do(
            ressource => 'files',
            id        => $self->id,
        );

        $self = $_[0] = WebService::Box::File->new( %file_data, session => $self->session );
    }

    if ( !$self->_parent_object ) {
        my $data               = $self->parent_data;
        my %parent_data_result = $self->request->do(
            ressource => 'folders',
            id        => $data->{id},
        ); 
        
        $self->_set__parent_object(
            WebService::Box::Folder->new( %{$data}, session => $self->session )
        );
    }

    return $self->_parent_object;
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

WebService::Box::Folder

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
