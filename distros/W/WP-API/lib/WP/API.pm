package WP::API;
{
  $WP::API::VERSION = '0.01';
}
BEGIN {
  $WP::API::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use Carp qw( confess );
use XMLRPC::Lite;
use WP::API::Media;
use WP::API::Post;
use WP::API::Types qw( ClassName NonEmptyStr PositiveInt Uri );
use WP::API::WrappedClass;

use Moose;
use MooseX::StrictConstructor;

has [qw( username password )] => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has blog_id => (
    is      => 'ro',
    isa     => PositiveInt,
    lazy    => 1,
    builder => '_build_blog_id',
);

has proxy => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

has server_time_zone => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

# This exists to make it possible to mock out the XMLRPC::Lite->call method in
# tests.
has _xmlrpc_class => (
    is      => 'ro',
    isa     => ClassName,
    default => 'XMLRPC::Lite',
);

has _xmlrpc => (
    is       => 'ro',
    isa      => 'XMLRPC::Lite',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_xmlrpc',
);

sub _build_xmlrpc {
    my $self = shift;

    return $self->_xmlrpc_class()->proxy( $self->proxy() );
}

sub _build_blog_id {
    my $self = shift;

    my $blogs = $self->call('wp.getUsersBlogs');

    if ( @{$blogs} > 1 ) {
        confess
            'This user belongs to more than one blog. Please supply a blog_id to the WP::API constructor';
    }

    return $blogs->[0]{blogid};
}

for my $type (qw( media page post user )) {
    my $sub = sub {
        my $self = shift;
        return $self->_wrapped_class( 'WP::API::' . ucfirst $type );
    };

    __PACKAGE__->meta()->add_method( $type => $sub );
}

sub _wrapped_class {
    my $self = shift;

    return WP::API::WrappedClass->wrap(
        class => shift,
        api   => $self,
    );
}

sub call {
    my $self   = shift;
    my $method = shift;

    my $call = $self->_xmlrpc()->call(
        $method,
        ( $method eq 'wp.getUsersBlogs' ? () : $self->blog_id() ),
        $self->username(),
        $self->password(),
        @_,
    );

    $self->_check_for_error( $call, $method );

    return $call->result()
        or confess
        "No result from call to $method XML-RPC method and no error!";
}

sub _check_for_error {
    my $self   = shift;
    my $call   = shift;
    my $method = shift;

    my $fault = $call->fault()
        or return;

    my @pieces;
    for my $key (qw( Code String Detail )) {
        my $value = $fault->{'fault'.$key};

        next unless defined $value && length $value;

        push @pieces, "$key = $value";
    }

    my $error = "Error calling $method XML-RPC method: ";
    $error .= join ' - ', @pieces;

    local $Carp::CarpLevel = $Carp::CarpLevel + 2;

    confess $error;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An interface to the WordPress XML-RPC API

__END__

=pod

=head1 NAME

WP::API - An interface to the WordPress XML-RPC API

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $api = WP::API->new(
      username         => 'testuser',
      password         => 'testpass',
      proxy            => 'http://example.com/xmlrpc.php',
      server_time_zone => 'UTC',
  );

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

B<This module is very new and only covers a small portion of the WordPress
API. Patches to increase coverage are welcome.>

This module provides a Perl interface to the WordPress XML-RPC API. See
http://codex.wordpress.org/XML-RPC_WordPress_API for API details.

Generally speaking, classes in this module follow the same naming convention
as WordPress itself when it comes to object attributes. However, the actual
API methods have been made more Perlish, so we have C<< $api->post()->create()
>> instead of C<< $api->newPost() >>.

=head1 METHODS

This module is the main entry point for creating objects from WordPress
data. You should not instantiate any other class directly.

=head2 WP::API->new(...)

This creates a new API object. It accepts the following parameters:

=over 4

=item * username

The username you want the API calls to use. Required.

=item * password

The password for that user. Required.

=item * proxy

The XML-RPC URI. This will be something like
C<http://example.com/xmlrpc.php>. Required.

=item * server_time_zone

This is used to transform server-provided local datetimes into a known time
zone. Required.

=item * blog_id

This is only required if the username you provide is a member of more than one
blog. If so, you must provide the id for the blog you want to access. If the
user only belongs to one blog then this module figures out the blog_id on its
own.

=back

=head2 $api->post()

This returns a shim for the L<WP::API::Post> class. You can call any B<class>
method that class provides, such as C<new()> or C<create>, on this shim.

=head2 $api->media()

This returns a shim for the L<WP::API::Media> class. You can call any B<class>
method that class provides, such as C<new()> or C<create>, on this shim.

=head2 $api->call(...)

Calls an XML-RPC method on the server. The first argument should be an XML-RPC
method name like 'wp.editPost' and the remaining parameters should be the
parameters for the method.

This method automatically prepends the blog_id, username, and password to
calls as needed.

If the call fails for some reason, this method throws an error. Otherwise it
returns the raw data structure returned by WordPress.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
