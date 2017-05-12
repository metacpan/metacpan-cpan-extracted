package WP::API::Media;
{
  $WP::API::Media::VERSION = '0.01';
}
BEGIN {
  $WP::API::Media::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use WP::API::Types
    qw( ArrayRef Bool HashRef Maybe NonEmptyStr PositiveOrZeroInt Uri );

use Moose;
use MooseX::StrictConstructor;

my %fields = (
    date_created_gmt => 'DateTime',
    parent           => PositiveOrZeroInt,
    link             => Uri,
    title            => NonEmptyStr,
    caption          => Maybe [NonEmptyStr],
    description      => Maybe [NonEmptyStr],
    metadata         => HashRef,
    thumbnail        => Uri,
);

with 'WP::API::Role::WPObject' => {
    id_method            => 'attachment_id',
    xmlrpc_get_method    => 'wp.getMediaItem',
    xmlrpc_create_method => 'wp.uploadFile',
    fields               => \%fields,
};

sub _create_result_as_params {
    my $class = shift;
    my $p     = shift;

    return ( attachment_id => $p->{id} );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An interface for WordPress media objects

__END__

=pod

=head1 NAME

WP::API::Media - An interface for WordPress media objects

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use File::Slurp qw( read_file );

  my $content = read_file('path/to/file.jpg');

  my $media = $api->media()->create(
      name      => 'foo.jpg',
      type      => 'image/jpeg',
      bits      => $content,
      overwrite => 1,
  );

  print $media->date_created_gmt()->date();

  my $other_media = $api->media()->new( attachment_id => 99 );
  print $other_media->title();

=head1 DESCRIPTION

This class provides methods for creating new media objects and fetching data
about existing media objects.

See the WordPress API documentation at
http://codex.wordpress.org/XML-RPC_WordPress_API for more details on what all
of the fields mean.

=head1 METHODS

This class provides the following methods:

=head2 $api->media()->new( attachment_id => $value )

This method constructs a new media object based on data from the WordPress
server. The only accepted parameter is a C<attachment_id>, which is required.

=head2 $api->media()->create(...)

This method creates a new media object on the WordPress server. It accepts a
hash with the following keys as of WordPress 3.5:

=over 4

=item * name

The object's file name.

=item * type

The object's MIME type.

=item * bits

The raw media object content.

=item * overwrite

A boolean indicating whether or not to overwrite an existing file with the
same name.

=back

Note that if future versions of WordPress accept more parameter, this API
allows you to pass them. Any key/value pairs you pass will be sent to
WordPress as-is.

=head2 $media->date_created_gmt()

Returns the media object's creation date and time as a L<DateTime> object in
the UTC time zone.

=head2 $media->parent()

Returns the post_id of the media object's parent or 0 if it doesn't have one.

=head2 $media->link()

Returns the full URI of the media object as a L<URI> object.

=head2 $media->title()

Returns the media object's title.

=head2 $media->caption()

Returns the media object's caption if it has one, C<undef> otherwise.

=head2 $media->description()

Returns the media object's description if it has one, C<undef> otherwise.

=head2 $media->metadata()

Returns a rather complicated hash reference. See the WordPress API
documentation for details.

B<Note that this might become a set of real objects in the future>.

=head2 $media->thumbnail()

Returns the thumbnail URI of the media object as a L<URI> object.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
