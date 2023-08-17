package WebService::Rackspace::CloudFiles;
use Moo;
use MooX::StrictConstructor;
use Types::Standard qw(Bool Str Num Int HashRef InstanceOf ClassName);
use DateTime::Format::HTTP;
use WebService::Rackspace::CloudFiles::Container;
use WebService::Rackspace::CloudFiles::Object;
use WebService::Rackspace::CloudFiles::Object::Iterator;
use WebService::Rackspace::CloudFiles::ConnCache;
use LWP::UserAgent::Determined;
use URI::QueryParam;
use JSON::Any;
use Carp qw(confess);
our $VERSION = '2.03';

my $DEBUG = 0;

has 'user'    => ( is => 'ro', isa => Str, required => 1 );
has 'key'     => ( is => 'ro', isa => Str, required => 1 );
has 'location'=> ( is => 'ro', isa => Str, required => 0, default => 'usa');
has 'timeout' => ( is => 'ro', isa => Num, required => 0, default => 30 );
has 'retries' => ( is => 'ro', isa => Str, required => 0, default => '1,2,4,8,16,32' );

has 'connection_cache_class' => (
    is => 'ro',
    isa => ClassName,
    default => 'WebService::Rackspace::CloudFiles::ConnCache'
);

has 'iterator_callback_class' => (
    is => 'ro',
    isa => ClassName,
    default => 'WebService::Rackspace::CloudFiles::Object::Iterator'
);

has locations => (
    traits => [ 'Hash' ],
    isa => HashRef,
    is => 'ro',
    default => sub {
        return {
            uk  => 'https://lon.auth.api.rackspacecloud.com/v1.0',
            usa => 'https://auth.api.rackspacecloud.com/v1.0',
        },
    },
    handles => {
        location_names => 'keys',
    },
);

has location_url => (
    is       => 'ro',
    isa      => Str,
    lazy     => 1,
    required => 0,
    default  => sub {
        my $self = shift;

        return $self->locations->{$self->location} ||
            confess "location $self->{location} unknown: valid locations are " .
                join ', ', $self->location_names ;
    },
);

has 'ua' => ( 
    is          => 'ro', 
    isa         => InstanceOf['LWP::UserAgent'],
    required    => 0, 
    lazy        => 1,
    builder     => '_build_ua',
);

has storage_url => ( 
    is       => 'rw', 
    isa      => Str,
    required => 0, 
    lazy     => 1, 
    default  => sub {  
        my $self = shift;
        $self->_authenticate;
        $self->storage_url;
    },
);

has cdn_management_url => ( 
    is => 'rw', 
    isa => Str,
    required => 0, 
    lazy => 1,
    default => sub {  
        my $self = shift;
        $self->_authenticate;
        $self->cdn_management_url;
    },
);

has token => ( 
    is       => 'rw', 
    isa      => Str,
    required => 0, 
    lazy     => 1,
    default  => sub {  
        my $self = shift;
        $self->_authenticate;
        $self->token;
    },
);

has is_authenticated => (
    is       => 'rw',
    isa      => Bool,
    required => 0,
    default  => 0,
);

sub _build_ua {
    my $self = shift;

    my $ua   = LWP::UserAgent::Determined->new(
        keep_alive            => 10,
        requests_redirectable => [qw(GET HEAD DELETE PUT)],
    );
    $ua->timing($self->retries);
    $ua->conn_cache(
        $self->connection_cache_class->new(
            total_capacity          => 10,
            max_keep_alive_requests => 990,
        )
    );
    my $http_codes_hr = $ua->codes_to_determinate();
    $http_codes_hr->{422} = 1; # used by cloudfiles for upload data corruption
    $ua->timeout( $self->timeout );
    $ua->env_proxy;

    return $ua;
}

sub _authenticate {
    my $self = shift;

    my $request = HTTP::Request->new(
        'GET',
        $self->location_url,
        [   'X-Auth-User' => $self->user,
            'X-Auth-Key'  => $self->key,
        ]
    );
    $self->is_authenticated(1); # needed to prevent infinite recursion on auth requests
    my $response = $self->_request($request);
    $self->is_authenticated(0);

    confess 'Unauthorized'  if $response->code == 401;
    confess 'Unknown error' if !$response->is_success;

    my $storage_url = $response->header('X-Storage-Url')
        || confess 'Missing storage url';
    my $token = $response->header('X-Auth-Token')
        || confess 'Missing auth token';
    my $cdn_management_url = $response->header('X-CDN-Management-Url')
        || confess 'Missing CDN management url';

    $self->storage_url($storage_url);
    $self->token($token);
    $self->cdn_management_url($cdn_management_url);

    $self->is_authenticated(1);
}

before _request => sub {
    my $self = shift;

    $self->_authenticate unless $self->is_authenticated;
};

sub _request {
    my ( $self, $request, $filename ) = @_;
    warn $request->as_string if $DEBUG;
    my $response = $self->ua->request( $request, $filename );
    warn $response->as_string if $DEBUG;
    if ( $response->code == 401 && $request->header('X-Auth-Token') ) {

        # http://trac.cyberduck.ch/ticket/2876
        # Be warned that the token will expire over time (possibly as short
        # as an hour). The application should trap a 401 (Unauthorized)
        # response on a given request (to either storage or cdn system)
        # and then re-authenticate to obtain an updated token.
        $self->is_authenticated(0);
        $self->_authenticate;
        $request->header( 'X-Auth-Token', $self->token );
        warn $request->as_string if $DEBUG;
        $response = $self->ua->request( $request, $filename );
        warn $response->as_string if $DEBUG;
    }
    return $response;
}

sub containers {
    my $self    = shift;
    my $request = HTTP::Request->new( 'GET', 
        $self->storage_url . '?format=json',
        [ 'X-Auth-Token' => $self->token ] );
    my $response = $self->_request($request);
    return if $response->code == 204;
    confess 'Unknown error' if !$response->is_success;
    my @containers;

    foreach my $container_data ( @{JSON::Any->from_json($response->content)} ) {
        push @containers, $self->container(%{$container_data});
    }
    return @containers;
}

sub total_bytes_used {
    my $self    = shift;
    my $request = HTTP::Request->new( 'HEAD', $self->storage_url,
        [ 'X-Auth-Token' => $self->token ] );
    my $response = $self->_request($request);
    confess 'Unknown error' unless $response->is_success;
    my $total_bytes_used = $response->header('X-Account-Bytes-Used');
    $total_bytes_used = 0 if $total_bytes_used eq 'None';
    return $total_bytes_used;
}

sub container {
    my ( $self, %conf ) = @_;
    confess 'Missing name' unless $conf{name};
    $conf{cloudfiles} = $self;
    for (keys %conf){
        if (ref $conf{$_} eq ref JSON::Any->true){
            $conf{$_} = ($conf{$_} ? 'true' : 'false');
        }
    }

    return WebService::Rackspace::CloudFiles::Container->new(%conf);
}

sub create_container {
    my ( $self, %conf ) = @_;
    my $name = $conf{name};
    confess 'Missing name' unless $name;

    my $request = HTTP::Request->new(
        'PUT',
        $self->storage_url . '/' . $name,
        [ 'X-Auth-Token' => $self->token ]
    );
    my $response = $self->_request($request);
    confess 'Unknown error'
        if $response->code != 201 && $response->code != 202;
    return WebService::Rackspace::CloudFiles::Container->new(
        cloudfiles => $self,
        name       => $name,
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WebService::Rackspace::CloudFiles - Interface to Rackspace CloudFiles service

=head1 SYNOPSIS

  use WebService::Rackspace::CloudFiles;
  use Perl6::Say;

  my $cloudfiles = WebService::Rackspace::CloudFiles->new(
      user => 'myusername',
      key  => 'mysecretkey',
  );

  # list all containers
  my @containers = $cloudfiles->containers;
  foreach my $container (@containers) {
      say 'have container ' . $container->name;
  }

  # create a new container
  my $container = $cloudfiles->create_container(name => 'testing');

  # use an existing container
  my $existing_container = $cloudfiles->container(name => 'testing');

  my $total_bytes_used = $cloudfiles->total_bytes_used;
  say "used $total_bytes_used";

  my $object_count = $container->object_count;
  say "$object_count objects";

  my $bytes_used = $container->bytes_used;
  say "$bytes_used bytes";

  # returns a Data::Stream::Bulk object
  # as it may have to make multiple HTTP requests
  my @objects = $container->objects->all;
  foreach my $object (@objects) {
      say 'have object ' . $object->name;
      # also size, etag, content_type, last_modified
  }
  my @objects2 = $container->objects(prefix => 'dir/')->all;

  # To create a new object
  my $xxx = $container->object( name => 'XXX' );
  $xxx->put('this is the value');

  # To set metadata of an object:
  $xxx->object_metadata({
	  description => 'this is a description',
	  useful_number => 17
  });
  
  # To create a new object with the contents of a local file
  my $yyy = $container->object( name => 'YYY', content_type => 'text/plain' );
  $yyy->put_filename('README');

  # To fetch an object:
  my $xxx2 = $container->object( name => 'XXX' );
  my $value = $xxx2->get;
  say 'has name ' . $xxx2->name;
  say 'has md5 ' . $xxx2->etag;
  say 'has size ' . $xxx2->size;
  say 'has content type ' . $xxx2->content_type;
  say 'has last_modified ' . $xxx2->last_modified;

  # To fetch metadata of an object:
  say 'metadata description ' . $xxx2->object_metadata->{'description'};
  say 'metadata useful_number ' . $xxx2->object_metadata->{'useful_number'};
  
  # To download an object to a local file
  $yyy->get_filename('README.downloaded');

  $object->delete;

  $container->delete;

=head1 DESCRIPTION

This module was forked from L<Net::Mosso::CloudFiles> which was written by Leon
Brocard <acme@astray.com>. However, due to Mosso changing its name to Rackspace
it felt right to fork the module to a new namespace. Upgrading from
L<Net::Mosso::CloudFiles> 0.44 should only require you to rename all Net::Mosso
entries to WebService::Rackspace.

This module provides a simple interface to the Rackspace Cloud Files
service. "Cloud Files is reliable, scalable and affordable web-based
storage for backing up and archiving all your static content".
Find out more at L<http://www.rackspacecloud.com/cloud_hosting_products/files>.

To use this module you will need to sign up to Rackspace Cloud Files
and provide a "user" and "key". If you use this module, you will
incurr costs as specified by Rackspace. Please check the costs. If
you use this module with your user and key you will be responsible
for these costs.

I highly recommend reading all about Cloud Files, but in a nutshell
data is stored in objects. Objects are referenced by names and objects
are stored in containers.

=head1 METHODS

=head2 new

The constructor logs you into Cloud Files:

  my $cloudfiles = WebService::Rackspace::CloudFiles->new(
      user => 'myusername',
      key  => 'mysecretkey',
  );

A location for the Cloud Files can now be specified. Valid locations are currently I<usa> and I<uk>, the default location is I<usa>

  my $cloudfiles = WebService::Rackspace::CloudFiles->new(
      user => 'myusername',
      key  => 'mysecretkey',
      location  => 'uk',
  );

If you wish to use a custom location url instead, I<location_url> can be used
to override the usual sites:

  my $cloudfiles = WebService::Rackspace::CloudFiles->new(
      user => 'myusername',
      key  => 'mysecretkey',
      location_url  => 'https://my.cloudfile.me/v1.0',
  );

=head2 containers

List all the containers and return them as L<WebService::Rackspace::CloudFiles::Container> objects:

  my @containers = $cloudfiles->containers;

=head2 create_container

Create a new container and return it as a L<WebService::Rackspace::CloudFiles::Container> object:

  my $container = $cloudfiles->create_container(name => 'testing');

=head2 container

Use an existing container and return it as a L<WebService::Rackspace::CloudFiles::Container> object:

  my $existing_container = $cloudfiles->container(name => 'testing');

=head2 total_bytes_used

Returns the total amount of bytes used in your Cloud Files account:

  my $total_bytes_used = $cloudfiles->total_bytes_used;

=head2 connection_cache_class

=head2 iterator_callback_class

=head2 key

=head2 location

=head2 locations

=head2 retries

=head2 timeout

=head2 user

=head1 TESTING

Testing CloudFiles is a tricky thing. Rackspace charges you a bit of
money each time you use their service. And yes, testing counts as using.
Because of this, this module's test suite skips testing unless
you set the following three environment variables, along the lines of:

  CLOUDFILES_EXPENSIVE_TESTS=1 CLOUDFILES_USER=username CLOUDFILES_KEY=15bf43... perl t/simple.t

=head1 SEE ALSO

L<WebService::Rackspace::CloudFiles::Container>, L<WebService::Rackspace::CloudFiles::Object>.

=head1 AUTHORS

Christiaan Kras <ckras@cpan.org>.
L<Net::Mosso::CloudFiles> by Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2010-2011, Christiaan Kras
Copyright (C) 2008-9, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
