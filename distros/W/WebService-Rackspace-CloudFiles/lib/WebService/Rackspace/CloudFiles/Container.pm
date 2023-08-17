package WebService::Rackspace::CloudFiles::Container;
use Moo;
use MooX::StrictConstructor;
use Types::Standard qw(Bool Str Num Int HashRef InstanceOf);
use WebService::Rackspace::CloudFiles::Object::Iterator;
use JSON::Any;
use Carp qw(confess);
 
has 'cloudfiles' =>
    ( is => 'ro', isa => InstanceOf['WebService::Rackspace::CloudFiles'], required => 1 );
has 'name' => (is => 'ro', isa => Str, required => 1);
has 'cdn_enabled'   => (is => 'rw', isa => Bool);
has 'ttl'           => (is => 'rw', isa => Num);
has 'log_retention' => (is => 'rw', isa => Str);
has 'cdn_uri'       => (is => 'rw', isa => Str);
has 'cdn_ssl_uri'   => (is => 'rw', isa => Str);
has 'cdn_streaming_uri'   => (is => 'rw', isa => Str);
has 'bytes'         => (is => 'rw', isa => Num);
has 'count'         => (is => 'rw', isa => Num);

__PACKAGE__->meta->make_immutable;

sub _url {
    my ( $self, $url_type ) = @_;

    $url_type ||= '';
    my $storage_url = $url_type eq 'cdn' ? 'cdn_management_url' : 'storage_url';
    my $url = $self->cloudfiles->$storage_url . '/' . $self->name;
    utf8::downgrade($url);
    return $url;
}

sub cdn_init {
    my $self = shift;
    
    my $response = $self->head('cdn');
    my $cdn_enabled = $response->header('X-CDN-Enabled');
    $self->cdn_enabled(ref $cdn_enabled eq ref JSON::Any->true ? 1 : 0 );
    $self->ttl( $response->header('X-TTL') );
    $self->log_retention( $response->header('X-Log-Retention') );
    $self->cdn_uri( $response->header('X-CDN-URI') );
    $self->cdn_ssl_uri( $response->header('X-CDN-SSL-URI') );
    $self->cdn_streaming_uri( $response->header('X-CDN-STREAMING-URI') );
}

sub cdn_enable {
    my ($self, $ttl, $log_retention) = @_;
    $ttl ||= 259200;
    $log_retention ||= 0;
    my $request = HTTP::Request->new('PUT', $self->_url('cdn'),
        [ 'X-Auth-Token'    => $self->cloudfiles->token,
          'X-CDN-Enabled'   => 'True',
          'X-TTL'           => $ttl,
          'X-Log-Retention' => $log_retention ? 'True' : 'False' ] );
    my $response = $self->cloudfiles->_request($request);
    confess 'Unknown error' unless $response->is_success;

    $self->ttl( $ttl );
    $self->log_retention( $log_retention );
    $self->cdn_uri( $response->header('X-CDN-URI') );
    $self->cdn_ssl_uri( $response->header('X-CDN-SSL-URI') );
}

sub cdn_disable {
    my $self = shift;
    my $request = HTTP::Request->new('POST', $self->_url('cdn'),
        [ 'X-Auth-Token'  => $self->cloudfiles->token,
          'X-CDN-Enabled' => 'False' ] );
    my $response = $self->cloudfiles->_request($request);
    confess 'Unknown error' unless $response->is_success;

    $self->ttl( 0 );
    $self->log_retention( 0 );
    $self->cdn_uri( $response->header('X-CDN-URI') );
    $self->cdn_ssl_uri( $response->header('X-CDN-SSL-URI') );
}

sub head {
    my ($self, $url) = @_;
    my $request = HTTP::Request->new('HEAD', $self->_url($url),
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->_request($request);
    confess 'Unknown error' unless $response->is_success;
    return $response;
}

sub object_count {
    my $self     = shift;
    my $response = $self->head;
    return $response->header('X-Container-Object-Count');
}

sub bytes_used {
    my $self    = shift;
    my $response = $self->head;
    return $response->header('X-Container-Bytes-Used');
}

sub delete {
    my $self    = shift;
    my $request = HTTP::Request->new( 'DELETE', $self->_url,
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->_request($request);
    confess 'Not empty' if $response->code == 409;
    confess 'Unknown error' if !$response->is_success;
}

sub purge_cdn {
    my ($self, @emails) = @_;
    my $request = HTTP::Request->new( 'DELETE', $self->_url('cdn'),
        [ 'X-Auth-Token' => $self->cloudfiles->token,
          'X-Purge-Email' => join ', ', @emails] );
    my $response = $self->cloudfiles->_request($request);
    confess 'Not Found' if $response->code == 404;
    confess 'Unauthorized request' if $response->code == 403;
    confess 'Unknown error' if !$response->is_success;
}

sub objects {
    my ( $self, %args ) = @_;

    my $limit = 10_000;
    my $marker;
    my $prefix   = $args{prefix};
    my $finished = 0;

    return $self->cloudfiles->iterator_callback_class->new(
        callback => sub {
            return undef if $finished;

            my $url = URI->new( $self->_url );
            $url->query_param( 'limit',  $limit );
            $url->query_param( 'marker', $marker );
            $url->query_param( 'prefix', $prefix );
            $url->query_param( 'format', 'json' );
            my $request = HTTP::Request->new( 'GET', $url,
                [ 'X-Auth-Token' => $self->cloudfiles->token ] );
            my $response = $self->cloudfiles->_request($request);
            return if $response->code == 204;
            confess 'Unknown error' if !$response->is_success;
            return undef unless $response->content;
            my @objects;

            my @bits = @{ JSON::Any->jsonToObj( $response->content ) };
            return unless @bits;
            foreach my $bit (@bits) {
                push @objects,
                    WebService::Rackspace::CloudFiles::Object->new(
                    cloudfiles    => $self->cloudfiles,
                    container     => $self,
                    name          => $bit->{name},
                    etag          => $bit->{hash},
                    size          => $bit->{bytes},
                    content_type  => $bit->{content_type},
                    last_modified => $bit->{last_modified},
                    );
            }

            if ( @bits < $limit ) {
                $finished = 1;
            } else {
                $marker = $objects[-1]->name;
            }

            return \@objects;
        }
    );
}

sub object {
    my ( $self, %conf ) = @_;
    confess 'Missing name' unless $conf{name};
    return WebService::Rackspace::CloudFiles::Object->new(
        cloudfiles => $self->cloudfiles,
        container  => $self,
        %conf,
    );
}

1;

__END__

=head1 NAME

WebService::Rackspace::CloudFiles::Container - Represent a Cloud Files container

=head1 DESCRIPTION

This class represents a container in Cloud Files. It is created by
calling new_container or container on a L<WebService::Rackspace::CloudFiles> object.

=head1 METHODS

=head2 name

Returns the name of the container:

  say 'have container ' . $container->name;

=head2 cdn_enabled

Return true if the container is public.

=head2 ttl

The TTL (Time To Live) of the container and its objects.

=head2 log_retention

=head2 cdn_uri

HTTP CDN URL to container, only applies when the container is public.

=head2 cdn_ssl_uri

HTTPS CDN URL to container, only applies when the container is public.

=head2 cdn_init

Retrieve CDN settings if the container is public.

=head2 cdn_enable($ttl, $log_retention)

Enable CDN to make contents of container public. I<$ttl> Defaults to 72-hours
and I<$log_retention> defaults to false.

=head2 cdn_disable

Disable the CDN enabled container. Doesn't purge objects from CDN which means
that they'll be available until their TTL expires.

=head2 head

Perform a HEAD request.

=head2 object_count

Returns the total number of objects in the container:

  my $object_count = $container->object_count;

=head2 bytes_used

Returns the total number of bytes used by objects in the container:

  my $bytes_used = $container->bytes_used;

=head2 objects

Returns a list of objects in the container as
L<WebService::Rackspace::CloudFiles::Object> objects. As the API only returns
ten thousand objects per request, this module may have to do multiple
requests to fetch all the objects in the container. This is exposed
by using a L<Rackspace::CloudFiles::Object::Iterator> object. You can also pass
in a prefix:

  foreach my $object ($container->objects->all) {
    ...
  }

  my @objects = $container->objects(prefix => 'dir/')->all;

=head2 object

This returns a L<WebService::Rackspace::CloudFiles::Object> representing
an object.

  my $xxx = $container->object( name => 'XXX' );
  my $yyy = $container->object( name => 'YYY', content_type => 'text/plain' );

=head2 delete

Deletes the container, which should be empty:

  $container->delete;

=head2 purge_cdn

Purges a CDN enabled container without having to wait for the TTL to expire. 

  $container->purge_cdn;

Purging a CDN enabled container may take a very long time. So you can optionally
provide one or more emails to be notified after the container is fully purged. 

  my @emails = ('foo@example.com', 'bar@example.com');
  $container->purge_cdn(@emails);

=head2 cloudfiles

=head1 SEE ALSO

L<WebService::Rackspace::CloudFiles>, L<WebService::Rackspace::CloudFiles::Object>.

=head1 AUTHORS

Christiaan Kras <ckras@cpan.org>.
Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2010-2011, Christiaan Kras
Copyright (C) 2008-9, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
