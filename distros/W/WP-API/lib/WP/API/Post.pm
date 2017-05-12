package WP::API::Post;
{
  $WP::API::Post::VERSION = '0.01';
}
BEGIN {
  $WP::API::Post::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use WP::API::Types
    qw( ArrayRef Bool HashRef Maybe NonEmptyStr PositiveInt PositiveOrZeroInt Uri );

use Moose;
use MooseX::StrictConstructor;

my %fields = (
    post_type         => NonEmptyStr,
    post_status       => NonEmptyStr,
    post_title        => NonEmptyStr,
    post_author       => PositiveInt,
    post_excerpt      => Maybe [NonEmptyStr],
    post_content      => NonEmptyStr,
    post_date_gmt     => 'DateTime',
    post_date         => 'DateTime',
    post_modified_gmt => 'DateTime',
    post_modified     => 'DateTime',
    post_format       => NonEmptyStr,
    post_name         => NonEmptyStr,
    post_password     => Maybe [NonEmptyStr],
    comment_status    => NonEmptyStr,
    ping_status       => NonEmptyStr,
    sticky            => Bool,
    post_thumbnail    => HashRef,
    post_parent       => PositiveOrZeroInt,
    post_mime_type    => Maybe [NonEmptyStr],
    link              => Uri,
    guid              => Uri,
    menu_order        => PositiveOrZeroInt,
    custom_fields     => ArrayRef [HashRef],
    terms             => ArrayRef [HashRef],
    enclosure         => HashRef,
);

with 'WP::API::Role::WPObject' => {
    id_method            => 'post_id',
    xmlrpc_get_method    => 'wp.getPost',
    xmlrpc_create_method => 'wp.newPost',
    fields               => \%fields,
};

sub _munge_create_parameters {
    my $class = shift;
    my $p     = shift;

    $p->{post_status} //= 'publish';

    $class->_deflate_datetimes(
        $p,
        'post_date_gmt',     'post_date',
        'post_modified_gmt', 'post_modified',
    );

    return;
}

sub _create_result_as_params {
    my $class = shift;
    my $p     = shift;

    return ( post_id => $p );
}

sub _munge_raw_data {
    my $self = shift;
    my $p    = shift;

    # WordPress 3.5 seems to return an array instead of a struct when the post
    # has no thumbnail.
    {
        local $@;
        if ( eval { my $foo = @{ $p->{post_thumbnail} }; 1 } ) {
            $p->{post_thumbnail} = {};
        }
    }

    return;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An interface for WordPress post objects

__END__

=pod

=head1 NAME

WP::API::Post - An interface for WordPress post objects

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $post = $api->post()->create(
      post_title    => 'Foo',
      post_date_gmt => $dt,
      post_content  => 'This is the body',
      post_author   => 42,
  );

  print $post->post_modified_gmt()->date();

  my $other_post = $api->post()->new( post_id => 99 );
  print $other_post->post_title();

=head1 DESCRIPTION

This class provides methods for creating new posts and fetching data about
existing posts.

See the WordPress API documentation at
http://codex.wordpress.org/XML-RPC_WordPress_API for more details on what all
of the fields mean.

=head1 METHODS

This class provides the following methods:

=head2 $api->post()->new( post_id => $value )

This method constructs a new post object based on data from the WordPress
server. The only accepted parameter is a C<post_id>, which is required.

=head2 $api->post()->create(...)

This method creates a new post on the WordPress server. It accepts a hash of
all the attribute values listed below. See the WordPress API docs for a list
of required fields. Haha, just kidding, they don't tell you, so you'll just
have to guess.

For date fields, you can pass a L<DateTime> object or an ISO8601 string
(e.g. "20130721T20:59:52").

=head2 $post->post_type()

Returns the post's type, something like "post", "page", etc.

=head2 $post->post_status()

Returns the post's status, something like 'publish', 'draft', etc.

=head2 $post->post_title()

Returns the post's title.

=head2 $post->post_author()

Returns the user_id of the post's author.

=head2 $post->post_excerpt()

Returns the post's excerpt if it has one, C<undef> otherwise.

=head2 $post->post_content()

Returns the post's body.

=head2 $post->post_date_gmt()

Returns the post's creation date and time as a L<DateTime> object in the UTC
time zone.

=head2 $post->post_date()

Returns the post's creation date and time as a L<DateTime> object in the
server's local time zone.

=head2 $post->post_modified_gmt()

Returns the post's last modification date and time as a L<DateTime> object in
the UTC time zone.

=head2 $post->post_modified()

Returns the post's last modification date and time as a L<DateTime> object in
the server's local time zone.

=head2 $post->post_format()

Returns the post's format.

=head2 $post->post_name()

Returns the post's name.

=head2 $post->post_password()

Returns the post's password if it has one, C<undef> otherwise.

=head2 $post->comment_status()

Returns the post's comment status, something like "closed" or "open".

=head2 $post->ping_status()

Returns the post's trackback status, something like "closed" or "open".

=head2 $post->sticky()

Returns a boolean indicating whether the post is sticky.

=head2 $post->post_thumbnail()

Returns a hashref of information about the post's featured image. See the
WordPress API docs for details.

B<Note that this might become a real object in the future>.

=head2 $post->post_parent()

Returns the post_id of the post's parent or 0 if it doesn't have one.

=head2 $post->mime_type()

Returns the post's MIME type if it has one, C<undef> otherwise.

=head2 $post->link()

Returns a L<URI> object for the post's URI.

=head2 $post->guid()

Returns a L<URI> object for the post's GUID URI.

=head2 $post->menu_order()

Returns the post's menu order.

=head2 $post->custom_fields()

Returns an array reference of hash references, each of which is a custom field
name and value. See the WordPress API docs for more details.

B<Note that this might become a real object or arrayref of objects in the
future>.

=head2 $post->terms()

Returns an array reference of hash references, each of which is a taxonomy
term. See the WordPress API docs for more details.

B<Note that this might become a real object or arrayref of objects in the
future>.

=head2 $post->enclosure()

Returns a hash reference of data about the post's enclosure. See the WordPress
API for details.

B<Note that this might become a real object in the future>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
