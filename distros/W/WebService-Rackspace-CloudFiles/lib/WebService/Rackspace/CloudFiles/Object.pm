package WebService::Rackspace::CloudFiles::Object;
use Moo;
use MooX::StrictConstructor;
use Types::Standard qw(Bool Str StrMatch Num Int HashRef InstanceOf);
use Digest::MD5 qw(md5_hex);
use Digest::MD5::File qw(file_md5_hex);
use File::stat;
use Carp qw(confess);
use WebService::Rackspace::CloudFiles::DateTime;

has 'cloudfiles' =>
    ( is => 'ro', isa => InstanceOf['WebService::Rackspace::CloudFiles'], required => 1 );
has 'container' =>
    ( is => 'ro', isa => InstanceOf['WebService::Rackspace::CloudFiles::Container'], required => 1 );
has 'name' => ( is => 'ro', isa => Str, required => 1 );
has 'etag' => ( is => 'rw', isa => StrMatch[qr/^[a-z0-9]{32}$/] );
has 'size' => ( is => 'rw', isa => Int );
has 'content_type' =>
    ( is => 'rw', isa => Str, default => 'binary/octet-stream' );

has 'last_modified' => (
    is => 'rw',
    isa => InstanceOf['WebService::Rackspace::CloudFiles::DateTime'],
    coerce => sub { 
      my $val = shift; 
      $val = DateTime::Format::HTTP->parse_datetime($val) unless ref $val;
      bless $val, 'WebService::Rackspace::CloudFiles::DateTime';
      return $val;
    }
);

has 'cache_value' => (
    is        => 'rw',
    isa       => Bool,
    required  => 1,
    default   => 0
);

has 'always_check_etag' => (
    is        => 'rw',
    isa       => Bool,
    required  => 1,
    default   => 1
);


has 'object_metadata' => (
    is        => 'rw',
    isa       => HashRef,
    required  => 0,
    default   => sub  {
        return {};
    }  
);

has 'value' => (
    is        => 'rw',
    required  => 0,
    default   => undef,
);

has 'local_filename' => (
    is        => 'rw',
    isa       => Str,
    required  => 0
);




__PACKAGE__->meta->make_immutable;

sub _url {
    my ($self) = @_;
    my $url
        = $self->cloudfiles->storage_url . '/'
        . $self->container->name . '/'
        . $self->name;
    utf8::downgrade($url);
    return $url;
}

# get the CDN management url for this object (for edge purge)
sub _management_url {
    my ($self) = @_;
    my $url
        = $self->cloudfiles->cdn_management_url . "/"
        . $self->container->name . '/'
        . $self->name;
    utf8::downgrade($url);
    return $url;
}


sub _cdn_url {
    my($self,$ssl) = @_;
    $ssl ||= 0;
    return sprintf('%s/%s',
        $ssl ? $self->container->cdn_ssl_uri : $self->container->cdn_uri,
        $self->name);
}

sub cdn_url {
    return shift->_cdn_url;
}

sub cdn_ssl_url {
    return shift->_cdn_url(1);
}

sub head {
    my $self    = shift;
    my $request = HTTP::Request->new( 'HEAD', $self->_url,
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->_request($request);
    confess 'Object ' . $self->name . ' not found' if $response->code == 404;
    confess 'Unknown error' unless $response->is_success;
    $self->_set_attributes_from_response($response);
    return $response->content;
}

sub get {
    my ($self, $force_retrieval) = @_;
    
    if (!$force_retrieval && $self->cache_value() && defined($self->value()) ) {
        return $self->value();
    } else {
        my $request = HTTP::Request->new( 'GET', $self->_url,
            [ 'X-Auth-Token' => $self->cloudfiles->token ] );
        my $response = $self->cloudfiles->_request($request);
        confess 'Object ' . $self->name . ' not found' if $response->code == 404;
        confess 'Unknown error' if !$response->is_success;
        confess 'Data corruption error'
            if $response->header('ETag') ne md5_hex( $response->content );
        $self->_set_attributes_from_response($response);
        if ($self->cache_value()) {
            $self->value($response->content);
        }
        return $response->content();
    }
}

sub get_filename {
    my ( $self, $filename, $force_retrieval ) = @_;
    
    ## if we aren't forcing retrieval, and we are caching values, and we have a local_filename
    ## defined and it matches the filename we were just given, and the local_filename actually
    ## exists on the filesystem... then we can think about using the cached value.
    
    if (!$force_retrieval && $self->cache_value() && defined($self->local_filename()) &&
         $self->local_filename() eq $filename && -e $self->local_filename() ) {
            
        ## in order to do this, we have to at least verify that the file we have matches
        ## the file on cloud-files.  Best way to do that is to load the metadata and 
        ## compare the etags.
        $self->head();
        if ($self->etag() eq file_md5_hex($filename)) {
            ## our local data matches what's in the cloud, we don't have to re-download
            return $self->local_filename();
        }
    }
    
    ## if we are here, we have to download the file.
    my $request = HTTP::Request->new( 'GET', $self->_url,
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->_request( $request, $filename );

    confess 'Object ' . $self->name . ' not found' if $response->code == 404;
    confess 'Unknown error' if !$response->is_success;
    confess 'Data corruption error' unless $self->_validate_local_file( $filename,  
                                                                        $response->header('Content-Length'),  
                                                                        $response->header('ETag') );
    $self->_set_attributes_from_response($response);
    my $last_modified = $self->last_modified->epoch;

    # make sure the file has the same last modification time
    utime $last_modified, $last_modified, $filename;
    if ($self->cache_value()) {
        $self->local_filename($filename);
    }
    return $filename;
}



sub delete {
    my $self    = shift;
    my $request = HTTP::Request->new( 'DELETE', $self->_url,
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->_request($request);
    confess 'Object ' . $self->name . ' not found' if $response->code == 404;
    confess 'Unknown error' if !$response->is_success;
}

sub purge_cdn {
    my ($self, @emails) = @_;
    my $request = HTTP::Request->new( 'DELETE', $self->_management_url,
        [ 'X-Auth-Token' => $self->cloudfiles->token,
          'X-Purge-Email' => join ', ', @emails] );
    my $response = $self->cloudfiles->_request($request);
    confess 'Not Found' if $response->code == 404;
    confess 'Unauthorized request' if $response->code == 403;
    confess 'Unknown error' if !$response->is_success;
}

sub put {
    my ( $self, $value ) = @_;
    my $name    = $self->name;
    my $md5_hex    = md5_hex($value);
    my $size    = length($value);

    my $request = HTTP::Request->new(
        'PUT',
        $self->_url,
        $self->_prepare_headers($md5_hex, $size),
        $value
    );
    my $response = $self->cloudfiles->_request($request);
    
    if ($response->is_success) {
        ## since the value was set successfully, we can set all our instance data appropriately.
        
        $self->etag($md5_hex);
        $self->size($size);
        if ($self->cache_value) {
            $self->value($value);
        }
        return;
    }
    confess 'Missing Content-Length or Content-Type header'
        if $response->code == 412;
    confess 'Data corruption error' if $response->code == 422;
    confess 'Data corruption error' if $response->header('ETag') ne $md5_hex;
    confess 'Unknown error'         unless $response->is_success;
}

sub put_filename {
    my ( $self, $filename ) = @_;
    my $name = $self->name;

    my $md5_hex = file_md5_hex($filename);
    my $stat    = stat($filename) || confess("No $filename: $!");
    my $size    = $stat->size;

    my $request = HTTP::Request->new(
        'PUT',
        $self->_url,
        $self->_prepare_headers($md5_hex, $size),
        $self->_content_sub($filename),
    );
    my $response = $self->cloudfiles->_request($request);
    
    if ($response->is_success) {
        $self->etag($md5_hex);
        $self->size($size);
        if ($self->cache_value) {
            $self->local_filename($filename);
        }
    }
    
    confess 'Missing Content-Length or Content-Type header'
        if $response->code == 412;
    confess 'Data corruption error' if $response->code == 422;
    confess 'Data corruption error' if !defined($response->header('ETag')) ||
					($response->header('ETag') ne $md5_hex);
    confess 'Unknown error'         unless $response->is_success;
}

my %Supported_headers = (
    map { $_ => 1 }
    'Content-Encoding',
    'Content-Disposition',
    'X-Object-Manifest',
    'Access-Control-Allow-Origin',
    'Access-Control-Allow-Credentials',
    'Access-Control-Expose-Headers',
    'Access-Control-Max-Age',
    'Access-Control-Allow-Methods',
    'Access-Control-Allow-Headers',
    'Origin',
    'Access-Control-Request-Method',
    'Access-Control-Request-Headers',
);

sub _prepare_headers {
    my ($self, $etag, $size) = @_;
    my $headers = HTTP::Headers->new();
    
    $headers->header('X-Auth-Token' => $self->cloudfiles->token );
    $headers->header('Content-length' => $size );
    $headers->header('ETag' => $etag );
    $headers->header('Content-Type' => $self->content_type);
    
    my $header_field;
    foreach my $key (keys %{$self->object_metadata}) {
        $header_field = $key;
        $header_field = 'X-Object-Meta-' . $header_field
            unless $Supported_headers{$header_field};
        # make _'s -'s for header sending.
        $header_field =~ s/_/-/g;
        
        $headers->header($header_field => $self->object_metadata->{$key});
    }
    return $headers;
}


sub _content_sub {
    my $self      = shift;
    my $filename  = shift;
    my $stat      = stat($filename);
    my $remaining = $stat->size;
    my $blksize   = $stat->blksize || 4096;

    confess "$filename not a readable file with fixed size"
        unless -r $filename and ( -f _ || $remaining );
    my $fh = IO::File->new( $filename, 'r' )
        or confess "Could not open $filename: $!";
    $fh->binmode;

    return sub {
        my $buffer;

        # upon retries the file is closed and we must reopen it
        unless ( $fh->opened ) {
            $fh = IO::File->new( $filename, 'r' )
                or confess "Could not open $filename: $!";
            $fh->binmode;
            $remaining = $stat->size;
        }

        # warn "read remaining $remaining";
        unless ( my $read = $fh->read( $buffer, $blksize ) ) {

#                       warn "read $read buffer $buffer remaining $remaining";
            confess
                "Error while reading upload content $filename ($remaining remaining) $!"
                if $! and $remaining;

            # otherwise, we found EOF
            $fh->close
                or confess "close of upload content $filename failed: $!";
            $buffer ||= ''
                ;    # LWP expects an emptry string on finish, read returns 0
        }
        $remaining -= length($buffer);
        return $buffer;
    };
}

sub _set_attributes_from_response {
    my ( $self, $response ) = @_;
    
    $self->etag( $response->header('ETag') );
    $self->size( $response->header('Content-Length') );
    $self->content_type( $response->header('Content-Type') );
    $self->last_modified( $response->header('Last-Modified') );
    my $metadata = {};
    foreach my $headername ($response->headers->header_field_names) {
        if ($headername =~ /^x-object-meta-(.*)/i) {
            my $key = $1;
            ## undo our _ to - translation
            $key =~ s/-/_/g;
            $metadata->{lc($key)} = $response->header($headername);
        }
    }
    $self->object_metadata($metadata);
}

sub _validate_local_file {
    my ($self, $localfile, $size, $md5) = @_;
    
    my $stat = stat($localfile);
    my $localsize = $stat->size;
    
    # first check size, if they are different, we don't need to bother with 
    # an expensive md5 calculation on the whole file.
    if ($size != $localsize ) {
        return 0;
    }
    
    if ($self->always_check_etag && ($md5 ne file_md5_hex($localfile))) {
        return 0;
    }
    return 1;
}

1;

__END__

=head1 NAME

WebService::Rackspace::CloudFiles::Object - Represent a Cloud Files object

=head1 SYNOPSIS

  # To create a new object
  my $xxx = $container->object( name => 'XXX' );
  $xxx->put('this is the value');

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

  # To download an object to a local file
  $yyy->get_filename('README.downloaded');

=head1 DESCRIPTION

This class represents an object in Cloud Files. It is created by
calling object or objects on a L<WebService::Rackspace::CloudFiles::Container> object.

=head1 METHODS

=head2 name

Returns the name of the object.

  say 'has name ' . $object->name;

=head2 head

Fetches the metadata of the object:

  $object->head;
  
 
=head2 always_check_etag

When set to true, forces md5 calculation on every file download and
compares it to the provided etag. This can be a very expensive operation,
especially on larger files. Setting always_check_etag to false will avoid the
checksum on the file and will validate the file transfer was complete by 
comparing the file sizes after download.  Defaults to true. 

=head2 cache_value

When set to true, any values retrieved from the server will be cached 
within the object, this allows you to continue to use the value 
without re-retrieving it from CloudFiles repeatedly.  Defaults to false.

=head2 get

Fetches the metadata and content of an object:

  my $value = $object->get;

If cache_value is enabled, will not re-retrieve the value from CloudFiles.
To force re-retrieval, pass true to the get routine:

  my $value = $object->get(1);

=head2 get_filename

Downloads the content of an object to a local file,
checks the integrity of the file, sets metadata in the object
and sets the last modified time of the file to the same as the object.

  $object->get_filename('README.downloaded');

If cache_value is enabled and the file has already been retrieved and is 
present on the filesystem with the filename provided, and the file size and
md5 hash of the local file match what is in CloudFiles, the file will not
be re-retrieved and the local file will be returned as-is.  To force a
re-fetch of the file, pass a true value as the second arg to get_filename():

  $object->get_filename('README.downloaded',1);

=head2 delete

Deletes an object:

  $object->delete;

=head2 purge_cdn

Purges an object in a CDN enabled container without having to wait for the TTL
to expire. 

  $object->purge_cdn;

Purging an object in a CDN enabled container may take long time. So you can
optionally provide one or more emails to be notified after the object is
fully purged. 

  my @emails = ('foo@example.com', 'bar@example.com');
  $object->purge_cdn(@emails);

=head2 put

Creates a new object:

  my $xxx = $container->object( name => 'XXX' );
  $xxx->put('this is the value');

=head2 put_filename

Creates a new object with the contents of a local file:

  my $yyy = $container->object( name => 'YYY', content_type => 'text/plain' );
  $yyy->put_filename('README');

=head2 etag

Returns the entity tag of the object, which is its MD5:

  say 'has md5 ' . $object->etag;

=head2 size

Return the size of an object in bytes:

  say 'has size ' . $object->size;

=head2 content_type

Return the content type of an object:

  say 'has content type ' . $object->content_type;

=head2 last_modified

Return the last modified time of an object as a L<DateTime> object:

  say 'has last_modified ' . $object->last_modified;
  
=head2 object_metadata

Sets or returns a hashref of metadata to be stored along with the file
in CloudFiles.  This hashref must containe key => value pairs and values
must be scalar type, if you require storage of complex data, you will need
to flatten it in some way prior to setting it here.  Also, due to the way
that CloudFiles works with metadata, when retrieved from CloudFiles, your
keys will be lowercase.  Note that since underscores are not permitted in
keys within CloudFiles, any underscores are translated to dashes when 
transmitted to CloudFiles.  They are re-translated when they are retrieved.
This is mentioned only because if you access your data through a different 
language or interface, your metadata keys will contain dashes instead of 
underscores.

=head2 cdn_url

Retrieve HTTP CDN url to object.

=head2 cdn_ssl_url

Retrieve HTTPS CDN url to object.

=head2 cloudfiles

=head2 container

=head2 value

=head1 SEE ALSO

L<WebService::Rackspace::CloudFiles>, L<WebService::Rackspace::CloudFiles::Container>.

=head1 AUTHORS

Christiaan Kras <ckras@cpan.org>.
Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2010-2011, Christiaan Kras
Copyright (C) 2008-9, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
