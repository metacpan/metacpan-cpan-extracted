package WebService::Box;

# ABSTRACT: manage your documents on Box.com

use strict;
use warnings;

use Carp;
use Moo;
use Types::Standard qw(Str Int);

use WebService::Box::Session;

our $VERSION = 0.02;

has api_url    => (is => 'ro', isa => Str, required => 1, default => sub{ "" } );
has upload_url => (is => 'ro', isa => Str, required => 1, default => sub{ "" } );
has on_error   => (is => 'ro', isa => sub{
         die "invalid value for 'on_error'" if (
             ( ref $_[0] and ref $_[0] ne 'CODE' ) ||
             ( !ref $_[0] and defined $_[0] and $_[0] ne 'die' and $_[0] ne 'warn' )
         );
     }, default => sub{ \&_my_die } );

has on_warn   => (is => 'ro', isa => sub{
         die "invalid value for 'on_warn'" if (
             ( ref $_[0] and ref $_[0] ne 'CODE' ) ||
             !ref $_[0]
         );
     }, default => sub{ \&_my_warn } );

sub error {
    my ($self, $message) = @_;

    return if !$self->on_error;

    if ( !ref $self->on_error ) {
        if ( $self->on_error eq 'die' ) {
            _my_die( $message );
        }
        if ( $self->on_warn eq 'warn' ) {
            _my_warn( $message );
        }
    }
    else {
        $self->on_error->( $message );
    }
}

sub warn {
    my ($self, $message) = @_;

    return if !$self->on_warn;

    if ( !ref $self->on_warn ) {
        _my_warn( $message );
    }
    else {
        $self->on_warn->( $message );
    }
}

sub create_session {
    my ($self)
}

sub _my_die {
    croak $_[0];
}

sub _my_warn {
    carp $_[0];
}

1;

__END__

=pod

=head1 NAME

WebService::Box - manage your documents on Box.com

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  my $box    = WebService::Box->new(
      api_url    => $api_url,     # usually no need to use this parameter
      upload_url => $upload_url,  # the library knows the standard box urls

      on_error => sub {},         # what should happen when an
                                  # error occurs. valid values: subroutine, undef, die, warn
  );

  my $client = $box->create_session(
      client_id     => $client_id,
      client_secret => $secret,
      auth_token    => $auth_token, # optional
      refresh_token => $refresh_token,
      redirect_url  => 'http://host.example/',
  );

  my $file          = $client->file;
  my $uploaded_file = $file->upload( '/path/to/local.file', $folder_id );
  my $new_file      = $file->upload( '/path/to/local.file', $folder_object );

  my $data          = $new_file->download;

  my $folder    = $client->folder( $id );
  my $files     = $folder->files;
  my $subfolder = $folder->folder;

=head1 METHODS

=head2 new

=head2 create_session

=head2 file

=head2 folder

=head1 FILE METHODS

=head2 upload

=head2 comment

=head2 delete

=head2 folder

=head1 FILE ATTRIBUTES

=head2 FOLDER METHODS

Those methods belong to C<WebService::Box::Folder>.

=head2 files

Returns a list of C<WebService::Box::File> objects. Each object represents a file
in the Box. If the request was not successful C<undef> is returned.

    my $folder = $client->folder( $id );
    my $files  = $folder->files;
    for my $file ( @{ $files } ) {
        print $file->id, ": ", $file->name;
    }

=head2 folder

Returns a list ob folder objects. Each object is a subfolder.

  my $subfolders = $folder->folder;
  my $subfolders = $client->folder( $id )->folder;

=head2 parent

Returns an object for the parent object

  my $parent_folder = $folder->parent;
  my $parent_folder = $client->folder( $id )->parent;

=head2 create

Create a new folder in the Box. Returns an object that represents that new folder.
You can pass either the ID of the parent folder or a C<WebService::Box::Folder> object.
The second para

  my $new_folder = $client->folder->create( 'new_folder_name', $parent_id );

  # alternatively
  my $new_folder = $client->folder->create(
      name      => 'new_folder_name',
      parent_id => $parent_id,
  );

=head1 FOLDER ATTRIBUTES

=head1 ADDITIONAL INFORMATION

All methods that need information from Box do request once and cache the results of those
requests. So a second call of that method on the same object will use the cached results.

The client caches the access_token it its expiration. When the access_token is expired
it requests a new one. That's why the refresh_token is needed.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
