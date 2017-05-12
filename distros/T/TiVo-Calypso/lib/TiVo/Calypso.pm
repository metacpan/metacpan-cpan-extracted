package TiVo::Calypso;

use 5.006_001;

our $VERSION = '1.3.5';

## Currently requires these additional modules for full functionality:
##
##  Storable
##  IO::File
##  MP3::Info
##  Digest::MD5
##  Encode
##  LWP::Simple

# Constants for use in QueryServer message
use constant VERSION      => '1';
use constant INTVERSION   => $VERSION;
use constant INTNAME      => 'TiVoServer BC';
use constant ORGANIZATION => 'TiVo, Inc.';
use constant COMMENT      => 'Modifications by Scott Schneider, sschneid at gmail dot com';

# Global expiration time (in hours)
my $expire_hours = 48;

## Generic, overridable interface to dynamic class data
##
##   Autoload will catch any method beginning with an underscore ( _ )
##   and convert the method name to a key value, which is used to
##   access the object's internal DATA hash. Methods written to
##   override interactions with a given key should use lvalue
##   syntax to maintain compatibility with other module internals.

sub AUTOLOAD : lvalue {
    my $self  = shift;
    my $param = $AUTOLOAD;

    $param =~ s/^.*:://;

    return unless $param =~ /^_(.+)$/;

    $self->{'DATA'}->{ uc($1) };
}

## TiVo::Calypso->_uri_unescape( $ )
##
##  Decodes URI strings per RFC 2396

sub _uri_unescape {
    my $self = shift;
    my $str  = shift;

    $str =~ s/\+/ /g;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

    return $str;
}

## TiVo::Calypso->_uri_escape( $ )
##
##  Encodes URI strings per RFC 2396

sub _uri_escape {
    my $self = shift;
    my $str  = shift || return undef;

    $str =~ s/([^A-Za-z0-9\+\-\/_.!~*'() ])/sprintf("%%%02X", ord($1))/eg;
    $str =~ s/ /+/g;

    return $str;
}

## TiVo::Calypso->_servicename( $ )
##
##  Returns the service name (first element of object path) of the object
##  or passed argument

sub _servicename {
    my $self = shift;
    my $path = shift || $self->_Object || return undef;

    $path =~ /^(\/[^\/]*)/;

    return $1;
}

## TiVo::Calypso->_basename( $ )
##
##  Returns the basename (filename) of the object's internal Path
##  or passed argument

sub _basename {
    my $self = shift;
    my $path = shift || $self->_Path || return undef;

    my @path_parts = split( /\//, $path );

    return pop @path_parts;
}

## TiVo::Calypso->_query_container
##
##   Returns a data structure (suitable for use with xml_out) which
##   describes this object in response to a QueryContainer command

sub _query_container {
    my $self   = shift;
    my $params = shift;

    my $script_name = $params->_EnvScriptName || "";

    my $details = {
        'Item' => [
            {
                'Details' => {
                    'Title' => $self->_Title || $self->_basename,
                    'ContentType'  => $self->_ContentType,
                    'SourceFormat' => $self->_SourceFormat
                }
            },
            {
                'Links' =>
                  { 'Content' => { 'Url' => $script_name . $self->_Url } }
            }
        ]
    };

    return $details;
}

##############################################################################
# TiVo::Calypso::Server
#   The core server object for processing requests
##############################################################################
package TiVo::Calypso::Server;
@ISA = ('TiVo::Calypso');

## TiVo::Calypso::Server->new( % )
##
##  Constructor for TiVo::Calypso::Server. Accepts parameters via arguement
##  hash.
##    SERVER_NAME
##    CACHE_DIR

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    my %params = (@_);

    $self->_Name     = $params{'SERVER_NAME'} || 'TiVo Server';
    $self->_CacheDir = $params{'CACHE_DIR'};

    $self->_Services = {};

    return $self;
}

## TiVo::Calypso::Server->load_cache( $ )
##
##  Loads the requested object from the external cache.

sub load_cache {
    my $self = shift;
    my $path = shift || return undef;

    my $cache_dir = $self->_CacheDir || return undef;

    require Storable;
    require Digest::MD5;

    my $cache_name = Digest::MD5::md5_hex($path);
    my $cache_path = "$cache_dir/$cache_name";
    my $rval       = eval { Storable::retrieve("$cache_path") };

    # Check if it is expired.
    my $expiration = $self->expire( $rval, $path, $cache_path );

    return $rval;
}

## TiVo::Calypso::Server->expire( $ )
##
##  Checks the external cache vs. the source file for the
##  object to determine if the object is expired.  If the
##  object is expired, it marks it as expired.

sub expire {
    my $self       = shift;
    my $item       = shift || return 1;
    my $path       = shift || return 1;
    my $cache_path = shift || return 1;

    # If the file exists, and if it was retrieved, check
    # if it is expired.
    my $rval = 1;    # Assume it's expired
    if ( defined($item) ) {
        my $service = $self->_servicename($path);

        return 1 unless defined $self->_Services->{$service};
        $service = $self->_Services->{$service};

        my $real_path = $service->obj_to_path($path);

        # Check file times.
        my @st_cache = stat($cache_path);
        my $ctime    = $st_cache[9];

        if ( !-r $real_path ) {

            # Path not found.  Expire item.
            $item->_Expired = 1;
        }
        else {

            # Path exists, compare times to see if we need
            # to expire it.
            my @st_orig = stat($real_path);
            my $otime   = $st_orig[9];

            my $timenow = time();
            my $xtime   = $timenow - ( $expire_hours * 60 * 60 );

            # If it's expired, mark it as so.  It's expired if either
            # the actual file is newer than the cached file/directory,
            # or the cache file is older than the allowed expiration
            # duration (the current time - $expire_hours ).
            if ( $otime > $ctime || $ctime < $xtime ) {

                # Expire item from cache and remove.
                $item->_Expired = 1;

                unlink $cache_path;
            }
            else {
                $item->_Expired = 0;
            }
        }

        $rval = $item->_Expired;
    }

    return $rval;
}

## TiVo::Calypso::Server->store_cache( $ )
##
##  Stores the given object in the external cache.

sub store_cache {
    my $self   = shift;
    my $object = shift || return undef;

    my $cache_dir = $self->_CacheDir || return undef;

    require Storable;
    require Digest::MD5;

    my $cache_name = Digest::MD5::md5_hex( $object->_Object );

    my $rval = eval { Storable::store( $object, "$cache_dir/$cache_name" ); };

    return $rval;
}

## TiVo::Calypso::Server->freeze( $ )
##
##  Stores the given Object in memory and passes it to the server's current
##  external cache functions

sub freeze {
    my $self   = shift;
    my $object = shift || return undef;

    return $self->store_cache($object);
}

## TiVo::Calypso::Server->thaw( $ )
##
##  Returns the requested Object from Cache, creating it when necessary

sub thaw {
    my $self = shift;
    my $path = shift || return undef;

    my ($item);

    $item = $self->load_cache($path) unless $path eq '/Shuffle';

    if ( !defined($item) || $item->_Expired == 1 ) {
        $item = $self->create_object($path);

        $self->freeze($item);
    }

    return $item;
}

## TiVo::Calypso::Server->create_object( $ )
##
##  Creates a new Item or Container object using the full filesystem
##  path provided.

sub create_object {
    my $self = shift;
    my $path = shift || return undef;

    my ($item);

    # Check for '/' special condition
    if ( $path eq '/' ) {
        $item = TiVo::Calypso::Container::Server->new(
            SERVICE => "/",
            TITLE   => $self->_Name
          )
          || return undef;

        my @contents =
          map { $self->_Services->{$_} } keys %{ $self->_Services };

        $item->_Contents = \@contents;
    }
    elsif ( $path eq '/Shuffle' ) {
        my $service = '/Music';

        return undef unless defined $self->_Services->{$service};
        $service = $self->_Services->{$service};

        $path = $service->obj_to_path($path);

        $item = TiVo::Calypso::Container->new(
            PATH    => $path,
            SERVICE => $service
          )
          || return undef;
    }
    elsif ( $path =~ /\/Browse\// ) {
        my $service = '/Music';

        return undef unless defined $self->_Services->{$service};
        $service = $self->_Services->{$service};

        $path = $service->obj_to_path($path);

        return undef if grep { /^\.\.$/ } split( /\//, $path );

        my $letter = $1 if $path =~ /.+?\/Browse\/(.*)/;
        $path = $1 if $path =~ /(.+?)\/Browse.*/;

        opendir( DIR, $path ) || return undef;

        while ( defined( my $file = readdir DIR ) ) {
            next if $file =~ /^\./;

            if ( defined $server ) {
                my $object_path = $self->_Object . "/" . $file;
                my $child       = $server->thaw($object_path) || next;

                push( @contents, $child );
            }
            else {
                next unless $file =~ /^$letter/;

                my $full_path = $path . "/" . $file;

                if ( -d $full_path ) {
                    my $child = TiVo::Calypso::Container->new(
                        PATH    => $full_path,
                        SERVICE => $service
                      )
                      || next;

                    push( @contents, $child );
                }
                elsif ( -r $full_path ) {
                    my @parts  = split( /\./, $full_path );
                    my $suffix = uc( pop @parts );

                    my $class = "TiVo::Calypso::Item::$suffix";
                    my $child =
                      eval { $class->new( $full_path, $self->_Service ); }
                      || next;

                    push( @contents, $child );
                }
            }
        }

        closedir(DIR);

        $self->_Contents = \@contents;
        $server->freeze($self) if defined $server;

        $item = TiVo::Calypso::Container->new(
            SERVICE => "/Music/Browse/$letter",
            TITLE   => "/Music/Browse/$letter"
        )
        || return undef;

        $item->_Contents = \@contents;
    }

    # Perform filesystem scan
    else {
        my $service = $self->_servicename($path);

        return undef unless defined $self->_Services->{$service};
        $service = $self->_Services->{$service};

        $path = $service->obj_to_path($path);

        return undef if grep { /^\.\.$/ } split( /\//, $path );

        # Create a directory container
        if ( -d $path ) {
            $item = TiVo::Calypso::Container->new(
                PATH    => $path,
                SERVICE => $service
              )
              || return undef;
        }

        # Create a file item
        elsif ( -r $path ) {
            my @parts  = split( /\./, $path );
            my $suffix = uc( pop @parts );

            my $class = "TiVo::Calypso::Item::$suffix";
            $item = eval { $class->new( $path, $service ); } || return undef;
        }
    }

    return $item || undef;
}

## TiVo::Calypso::Server->add_service( $ )
##
##  Adds a TiVo::Calypso::Container object to the service list for this server.

sub add_service {
    my $self    = shift;
    my $service = shift || return undef;

    $self->_Services->{ $service->_Object } = $service;
    $self->freeze($service);

    return $self->_Services->{ $service->_Object };
}

## TiVo::Calypso::Server->request( $ $ $ )
##
##  Processes a client request and returns the output from the appropriate
##  command method. The return value is a list: first element
##  is a scalar containing the mime-type of the returned data, second
##  element is a reference to the data itself. Both scalar refs and
##  IO::File refs may be returned, so the calling application must check
##  for and support both types.

sub request {
    my $self   = shift;
    my $params = shift || return undef;

    # Use a passed TiVo::Calypso::Request object if given or
    # create a TiVo::Calypso::Request object from arguments if needed
    if ( ( ref $params ) !~ /^TiVo::Calypso::Request/ ) {

        # See TiVo::Calypso::Request for the proper syntax of these arguments
        my $script_name  = $params;
        my $path_info    = shift;
        my $query_string = shift;

        $params = TiVo::Calypso::Request->new( $script_name, $path_info, $query_string );
    }

    # File transfer requested? (binary output)
    if ( defined( $params->_EnvPathInfo ) && $params->_EnvPathInfo ) {
        my $path_info = $self->_uri_unescape( $params->_EnvPathInfo );

        my $item = $self->thaw($path_info) || return undef;

        $self->scrobble($item) if $item->_Service->_Scrobble;

        my ( $headers, $ref ) = $item->send( $params, $self );

        my $isDirty = $item->_Dirty;

        if ( $isDirty == 1 ) {
            $item->_Dirty = 0;
            $self->freeze($item);
        }

        return ( $headers, $ref );
    }

    # Command given? (XML output)
    else {
        my $command = uc( $params->_Command ) || 'QUERYCONTAINER';

        # Create and eval the method name dynamically
        my $method   = "command_$command";
        my $response = eval { $self->$method($params); };

        # Call command_UNKNOWN if the eval failed
        if ( !defined $response ) {
            $response = $self->command_UNKNOWN($@);
        }

        # Set the default mime-type to be returned
        my $mime_type = 'text/xml';

        # Check to see if clint requested a different format
        if ( defined( $params->_Format ) ) {
            $mime_type = $params->_Format;

            # If text/html was requested, simply display the xml as plaintext
            if ( $mime_type eq 'text/html' ) {
                $mime_type = 'text/plain';
            }
        }

        my $xml = $self->xml_out($response) || return undef;

        # Wrap XML with header and footer
        my $return = "<?xml version='1.0' encoding='ISO-8859-1' ?>\n";
        $return .= $xml;
        $return .= "<!-- Copyright (c) 2002 TiVo Inc.-->\n";

        my $headers = {
            'Content-Type'   => $mime_type,
            'Content-Length' => length $return
        };

        return ( $headers, \$return );
    }

    my $response = $self->command_QUERYCONTAINER($params);

    return undef;
}

sub scrobble {
    my $self = shift;
    my $item = shift || return undef;

    require Digest::MD5;

    use Encode;
    use LWP::Simple;

    my ( $sec, $min, $hour, $day, $month, $year ) =
      (localtime)[ 0, 1, 2, 3, 4, 5 ];
    my $utc_date = sprintf(
        "%04d-%02d-%02d %02d:%02d:%02d",
        ( $year + 1900 ),
        ( $month + 1 ),
        $day, ( $hour + 6 ),
        $min, $sec
    );

    my $handshake =
        $item->_Service->_ScrobblePostURL
      . '/?hs=true'
      . '&p=1.1'
      . '&c=tst'
      . '&v=1.0'
      . '&u='
      . $item->_Service->_ScrobbleU;

    my ( $update, $challenge, $post_url, $interval ) = split /\n/,
      get($handshake);

    my $password_md5 = Digest::MD5::md5_hex( $item->_Service->_ScrobbleP );
    my $md5_password_digest =
      Digest::MD5::md5_hex( $password_md5 . $challenge );

    for ( $item->_Service->_ScrobbleU,
        $item->_Artist, $item->_Title, $item->_Album, $item->_Duration,
        $utc_date )
    {
        $_ = encode( 'utf8', $_ );
    }

    my $scrobblepost =
        $post_url
      . '?u='    . $item->_Service->_ScrobbleU
      . '&s='    . $md5_password_digest
      . '&a[0]=' . $item->_Artist
      . '&t[0]=' . $item->_Title
      . '&b[0]=' . $item->_Album
      . '&m[0]=' . ''
      . '&l[0]=' . $item->_Duration
      . '&i[0]=' . $utc_date;

    my @response = split /\n/, get($scrobblepost);

    return;
}

## TiVo::Calypso::Server->xml_out( $ [$] )
##
##  Converts a referenced hash/array data structure to XML. Use array
##  references to pass keys when order of the resulting XML tags
##  is important. Keys passed in a hash reference will have no
##  predictable ordering.

sub xml_out {
    my $self   = shift;
    my $data   = shift || return undef;
    my $indent = shift || 0;

    my $return;

    my @keys;

    my $data_type = ref $data;

    # Process each key if the passed reference was a hash
    if ( $data_type eq 'HASH' ) {
        foreach my $key ( keys %$data ) {

            # Force undef values to empty strings before printing
            $data->{$key} = "" unless defined( $data->{$key} );

            my $key_type = ref( $data->{$key} );

            # Recurse again if the child key is another hash
            if ( $key_type eq 'HASH' ) {
                $return .= ' ' x $indent . "<$key>\n";
                $return .= $self->xml_out( $data->{$key}, $indent + 2 ) || "";
                $return .= ' ' x $indent . "</$key>\n";
            }

            # Recurse on each element if the child key is an array
            elsif ( $key_type eq 'ARRAY' ) {
                $return .= ' ' x $indent . "<$key>\n";
                foreach my $item ( @{ $data->{$key} } ) {
                    $return .= $self->xml_out( $item, $indent + 2 ) || "";
                }
                $return .= ' ' x $indent . "</$key>\n";
            }

            # Assume the child is a text node otherwise, and print
            else {
                $return .=
                  ' ' x $indent . "<$key>" . $data->{$key} . "</$key>\n";
            }
        }
    }

    # Recurse on each element if the passed ref is an array
    elsif ( $data_type eq 'ARRAY' ) {
        foreach my $item (@$data) {
            $return .= $self->xml_out( $item, $indent );
        }
    }

    # What's this? Print it and hope for the best
    else {
        $return .= "$data\n";
    }

    return $return;
}

## TiVo::Calypso::Server->command_QUERYSERVER( $ )
##
##  Generates response to QueryServer command
##  Expects to be passed a TiVo::Calypso::Request object
##  Returns data structure suitable for use with xml_out

sub command_QUERYSERVER {
    my $self   = shift;
    my $params = shift;

    my $return = {
        'TiVoServer' => {
            'Version'         => $self->VERSION,
            'InternalVersion' => $self->INTVERSION,
            'InternalName'    => $self->INTNAME,
            'Organization'    => $self->_Organization || $self->ORGANIZATION,
            'Comment'         => $self->_Comment || $self->COMMENT
        }
    };

    return $return;
}

## TiVo::Calypso::Server->command_QUERYCONTAINER( $ )
##
##  Generates response to QueryContainer command
##  Expects to be passed a TiVo::Calypso::Request object
##  Returns data structure suitable for use with xml_out

sub command_QUERYCONTAINER {
    my $self   = shift;
    my $params = shift;

    my $container = $params->_Container;

    # Return service containers unless otherwise requested
    $container = '/' unless defined $container;

    my ($object);

    $object = $self->thaw($container) || return undef;

    my @list;

    if ( defined( $params->_Recurse ) && uc( $params->_Recurse ) eq 'YES' ) {

        # Explode the content list and get a recursive flat list of objects
        @list = @{ $object->explode($self) };
    }
    else {

        # Take the top-level list of objects and remove any subfolder list refs

        @list = @{ $object->contents($self) };

        @list = grep { ref($_) ne 'ARRAY' } @list;

        # We'll always perform the default Sort of Type,Title
        unless ( $params->_Container eq '/Shuffle' ) {
            @list = sort {
                return -1
                  if ( ref $a ) =~ /^TiVo::Calypso::Container/
                  && ( ref $b ) =~ /^TiVo::Calypso::Item/;
                return 1
                  if ( ref $b ) =~ /^TiVo::Calypso::Container/
                  && ( ref $a ) =~ /^TiVo::Calypso::Item/;

                return uc( $a->_Path ) cmp uc( $b->_Path );
            } @list;
        }
    }

=n/a
    # Filters are, at this time, broken. -ss

    # Apply any requested filters
    if ( defined( $params->_Filter ) ) {
        my %types;
        my @filters;

        if ( $params->_Filter =~ /,/ ) {
            @filters = split( /,/, $params->_Filter );
        }
        else {
            @filters = ( $params->_Filter );
        }

        # Construct a list of every possible matching type instead
        # of matching against each object's SourceFormat individually
        my $possible_types = $object->_Service->_MediaTypes;
        $possible_types->{'FOLDER'} = 'x-container/folder';

        foreach my $filter (@filters) {
            my ( $major, $minor ) = split( /\//, $filter );

            $major = $major || '*';
            $minor = $minor || '*';

            # Compare the filter to each supported MediaType for this service
            foreach my $supported ( keys %$possible_types ) {
                my ( $s_major, $s_minor ) =
                  split( /\//, $possible_types->{$supported} );

                if (   ( $major eq $s_major || $major eq '*' )
                    && ( $minor eq $s_minor || $minor eq '*' ) )
                {
                    $types{"$s_major/$s_minor"} = 1;
                }
            }
        }

        @list = grep { defined( $types{ $_->_SourceFormat } ) } @list;
    }
=cut

    my $total_duration = 0;

    # Check for any audio files that passed the Filter and sum their Duration
    foreach (@list) {
        if ( defined( $_->_Duration ) ) {
            $total_duration += $_->_Duration;
        }
    }

    # Perform any requested sorts. Currently incomplete, only supports Random
    # and Type,Title
    if ( defined( $params->_SortOrder ) ) {
        if ( uc( $params->_SortOrder ) eq 'RANDOM' ) {

            # Remove RandomStart from the object list before sorting
            my $start;
            if ( defined( $params->_RandomStart ) ) {
                my $prefix = $params->_EnvScriptname;

                my $short_start = $params->_RandomStart;
                $short_start =~ s/^$prefix//;

                foreach my $i ( 0 .. $#list ) {
                    next unless defined $list[$i]->_Url;
                    next unless $list[$i]->_Url eq $short_start;

                    $start = splice( @list, $i, 1 );
                    last;
                }

            }

            srand( $params->_RandomSeed ) if defined $params->_RandomSeed;

            my $i;
            for ( $i = @list ; --$i ; ) {
                my $j = int rand( $i + 1 );
                next if $i == $j;
                @list[ $i, $j ] = @list[ $j, $i ];
            }

            # Reattach RandomStart as the first object
            unshift( @list, $start ) if defined $start;
        }
    }

    my $count = scalar @list || 0;

    # Anchor defaults to first item
    my $anchor_pos = 0;

    if ( defined( $params->_AnchorItem ) ) {
        my $prefix = $params->_EnvScriptname;

        my $short_anchor = $params->_AnchorItem;
        $short_anchor =~ s/^$prefix//;

        foreach my $i ( 0 .. $#list ) {
            next unless defined $list[$i]->_Url;
            next unless $list[$i]->_Url eq $short_anchor;

            $anchor_pos = $i + 1;
            last;
        }

        # Adjust the anchor position if a positive or negative offset is given
        if ( defined( $params->_AnchorOffset ) ) {
            my $anchor_offset = $params->_AnchorOffset || 0;
            $anchor_pos += $anchor_offset;
        }

    }

    # Trim return list, if requested
    if ( defined( $params->_ItemCount ) ) {
        my $count = $params->_ItemCount;

        # Wrap the pointer if a negative count is requested
        if ( $count < 0 ) {
            $count *= -1;

            # Jump to end of list if no Anchor is provided
            if ( defined( $params->_AnchorItem ) ) {
                $anchor_pos -= $count + 1;
            }
            else {
                $anchor_pos = $#list - $count + 1;
            }
        }

        # Check for under/overflow
        if ( $anchor_pos >= 0 && $anchor_pos <= $#list ) {
            @list = splice( @list, $anchor_pos, $count );
        }
        else {
            $anchor_pos = 0;
            undef @list;
            undef $params->_AnchorItem;
            undef $params->_AnchorOffset;
            undef $params->_ItemCount;
            return $self->command_QUERYCONTAINER( $params );
        }
    }

    # Build description of each item to be returned
    my @children;
    foreach my $child (@list) {
        push( @children, $child->_query_container($params) );
    }

    my $return = {
        'TiVoContainer' => [
            {
                'Details' => {
                    'Title'       => $object->_Title,
                    'ContentType' => $object->_ContentType
                      || 'x-container/folder',
                    'SourceFormat' => $object->_SourceFormat
                      || 'x-container/folder',
                    'TotalItems'    => $count,
                    'TotalDuration' => $total_duration
                }
            },
            { 'ItemStart' => $anchor_pos },
            { 'ItemCount' => scalar @children || 0 },
            \@children
        ]
    };

    return $return;
}

## TiVo::Calypso::Server->command_UNKNOWN( $ )
##
##  Generates response to Unknown commands
##  Expects to be passed a TiVo::Calypso::Request object
##  Returns data structure suitable for use with xml_out

sub command_UNKNOWN {
    my $self   = shift;
    my $params = shift;

    return {};
}

##############################################################################
# TiVo::Calypso::Container
#   Attaches TiVo methods to a particular directory
##############################################################################
package TiVo::Calypso::Container;
@ISA = ('TiVo::Calypso');

## TiVo::Calypso::Container->new( % )
##
##  Generic TiVo::Calypso::Container constructor
##  Accepts parameters via an argument hash.
##  Expects to be passed a full pathname and either a string describing
##  the service prefix (if this container is to be a service) or another
##  TiVo::Calypso::Container object (if this container is to be a subdirectory
##  of an existing service).

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    my %params = (@_);

    my $service = $params{'SERVICE'} || return undef;
    $self->_Path = $params{'PATH'};

    # This container is a subdirectory
    if ( ( ref $service ) =~ /^TiVo::Calypso::Container/ ) {
        $self->_Object = $service->path_to_obj( $self->_Path ) || return undef;
        $self->_Service = $service;
    }

    # This container is a service container
    else {
        $self->_Object  = $service;
        $self->_Service = $self;
    }

    # Set folder title, if provided
    $self->_Title = $params{'TITLE'};

    # Defaults common to all Containers
    $self->_SourceFormat = 'x-container/folder';
    $self->_Url          =
      '?Command=QueryContainer&Container='
      . $self->_uri_escape( $self->_Object );

    $self->_Expired = 0;

    # Call class-specific init method
    $self->init(%params) || return undef;

    return $self;
}

## TiVo::Calypso::Container->init( )
##
##  Generic TiVo::Calypso::Container initialization

sub init {
    my $self = shift;

    $self->_ContentType = 'x-container/folder';

    $self->_Title = $self->_Title || $self->_basename;

    return 1;
}

## TiVo::Calypso::Container->path_to_obj( $ )
##
##  Converts the given pathname to an object path relative to the
##  current service

sub path_to_obj {
    my $self = shift;
    my $path = shift || return undef;

    my $service_p = $self->_Path;
    my $service_o = $self->_Object;

    $path =~ s/^$service_p/$service_o/;

    return $path;
}

## TiVo::Calypso::Container->obj_to_path( $ )
##
##  Converts the given object path (relative to the current service) to
##  a full filesystem pathname

sub obj_to_path {
    my $self = shift;
    my $path = shift || return undef;

    my $service_p = $self->_Path;
    my $service_o = $self->_Object;

    $path =~ s/^$service_o/$service_p/;

    return $path;
}

## TiVo::Calypso::Container->contents( $ )
##
##  Returns the contents of a TiVo::Calypso::Container directory as a list ref
##  of Item and Container objects.

sub contents {
    my $self   = shift;
    my $server = shift;

    return $self->_Contents if defined $self->_Contents;

    my @contents;

    local *DIR;
    if ( $self->_Path eq '/Shuffle' ) {
        my ( @artists, @songs );

        opendir( DIR, $server->_Services->{'/Shuffle'}->_Path ) || return undef;

        while ( defined( my $file = readdir DIR ) ) {
            next if $file =~ /^\./;

            push @artists, $file;
        }

        closedir(DIR);

        srand();

        for (1) {
            my ( @albums, @songlist );

            my $artist = $artists[ rand @artists ];

            opendir( DIR,
                $server->_Services->{'/Shuffle'}->_Path . '/' . $artist )
              || return undef;

            while ( defined( my $file = readdir DIR ) ) {
                next if $file =~ /^\./;

                push @albums, $artist . '/' . $file;
            }

            closedir(DIR);

            my $album = $albums[ rand @albums ];

            opendir( DIR,
                $server->_Services->{'/Shuffle'}->_Path . '/' . $album )
              || return undef;

            while ( defined( my $file = readdir DIR ) ) {
                next if $file =~ /^\./;

                push @songlist, $album . '/' . $file;

            }

            closedir(DIR);

            push @songs, $songlist[ rand @songlist ];
        }

        foreach my $song (@songs) {
            my @parts  = split( /\./, $song );
            my $suffix = uc( pop @parts );

            my $class = "TiVo::Calypso::Item::$suffix";
            my $child = eval {
                $class->new(
                    $server->_Services->{'/Shuffle'}->_Path . '/' . $song,
                    $self->_Service );
            } || next;

            push @contents, $child;
        }
    }
    elsif ( $self->_Path eq $server->_Services->{'/Music'}->_Path ) {
        foreach (qw/ * A B C D E F G H I J K L M N O P Q R S T U V W X Y Z /) {
            my $child = TiVo::Calypso::Container->new(
                PATH    => $self->_Path . "/Browse/" . $_,
                SERVICE => $self->_Service
              )
              || next;

            push( @contents, $child );
        }
    }
    else {
        opendir( DIR, $self->_Path ) || return undef;

        while ( defined( my $file = readdir DIR ) ) {
            next if $file =~ /^\./;

            if ( defined $server ) {

                my $object_path = $self->_Object . "/" . $file;
                my $child       = $server->thaw($object_path) || next;

                push( @contents, $child );

            }
            else {

                my $full_path = $self->_Path . "/" . $file;

                if ( -d $full_path ) {

                    my $child = TiVo::Calypso::Container->new(
                        PATH    => $full_path,
                        SERVICE => $self->_Service
                      )
                      || next;

                    push( @contents, $child );

                }
                elsif ( -r $full_path ) {

                    my @parts  = split( /\./, $full_path );
                    my $suffix = uc( pop @parts );

                    my $class = "TiVo::Calypso::Item::$suffix";
                    my $child =
                      eval { $class->new( $full_path, $self->_Service ); }
                      || next;

                    push( @contents, $child );
                }

            }

        }

        closedir(DIR);
    }

    # Cache the new information we just built
    $self->_Contents = \@contents;
    $server->freeze($self) if defined $server;

    return \@contents;
}

## TiVo::Calypso::Container->explode( $ )
##
##  Converts the single-directory Container and Item list format of an
##  object's contents() to a recursive list of all Containers and Items.

sub explode {
    my $self   = shift;
    my $server = shift;

    my $list = $self->contents($server);

    @$list = sort {
        return -1
          if ( ref $a ) =~ /^TiVo::Calypso::Container/ && ( ref $b ) =~ /^TiVo::Calypso::Item/;
        return 1
          if ( ref $b ) =~ /^TiVo::Calypso::Container/ && ( ref $a ) =~ /^TiVo::Calypso::Item/;
        return uc( $a->_Path ) cmp uc( $b->_Path );

        #$        return uc($a->_Album) cmp uc($b->_Album) ||
        #$            $a->_Track <=> $b->_Track ||
        #$            $a->_Path  <=> $b->_Path ||
        #$            uc($a->_Title) cmp uc($b->_Title);
    } @$list;

    my @return;

    foreach my $item (@$list) {

        if ( ( ref $item ) =~ /^TiVo::Calypso::Container/ ) {

            # Fetch the most current copy of this item from Cache
            $item = $server->thaw( $item->_Object ) || next;

            push( @return, $item );
            push( @return, @{ $item->explode($server) } );

        }
        else {

            push( @return, $item );

        }

    }

    return \@return;
}

package TiVo::Calypso::Container::Server;
@ISA = ("TiVo::Calypso::Container");

## TiVo::Calypso::Container::Server->init( )
##
##  Defines a Server psuedo-container which overrides the generic init
##  method. Sets content types unique to a Server container;

sub init {
    my $self = shift;

    $self->_Object  = "/";
    $self->_Service = "/";

    $self->_ContentType = 'x-container/tivo-server';

    $self->_Title = $self->_Title || "TiVo Server";

    return 1;
}

# TiVo::Calypso::Container extension
package TiVo::Calypso::Container::Music;
@ISA = ("TiVo::Calypso::Container");

## TiVo::Calypso::Container::Music->init( )
##
##  Defines a Music container which overrides the generic init
##  method. Sets content and media types unique to a 'Music'
##  container.

sub init {
    my $self = shift;

    my %params = (@_);

    $self->_ContentType = 'x-container/tivo-music';

    # Media types accepted for this container.
    # When creating a handler for a new media type, be sure to
    # register it with the appropriate service via:
    #   $service->_MediaTypes->{'NewSuffix'} = 'mime/type';

    $self->_MediaTypes = { 'MP3' => 'audio/mpeg' };

    $self->_Title = $self->_Title || "Music";

    if ( $params{'SCROBBLER'} ) {
        $self->_Scrobble        = 1;
        $self->_ScrobblePostUrl = $params{'SCROBBLER'}->{'POSTURL'};
        $self->_ScrobbleU       = $params{'SCROBBLER'}->{'USERNAME'};
        $self->_ScrobbleP       = $params{'SCROBBLER'}->{'PASSWORD'};
    }

    return 1;
}

##############################################################################
# TiVo::Calypso::Item #   Attaches TiVo methods to a particular file
##############################################################################
package TiVo::Calypso::Item;
@ISA = ('TiVo::Calypso');

## TiVo::Calypso::Item->new( $ $ )
##
##  Constructor for generic TiVo::Calypso::Item
##  Expects to be passed a full pathname and a TiVo::Calypso::Container service
##  to pull container information from

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_Path    = shift || return undef;
    $self->_Service = shift || return undef;

    # use the file suffix to determine file type
    my @parts  = split( /\./, $self->_Path );
    my $suffix = uc( pop @parts );

    # Skip this file if the service doesn't claim to support it
    return undef unless defined $self->_Service->_MediaTypes;

    $self->_SourceFormat = $self->_Service->_MediaTypes->{$suffix}
      || return undef;

    $self->_Object = $self->_Service->path_to_obj( $self->_Path )
      || return undef;
    $self->_Url = $self->_uri_escape( $self->_Object );

    # Contruct ContentType from SourceFormat
    my $content_type = $self->_SourceFormat;
    $content_type =~ s/\/.*$/\/\*/;

    $self->_ContentType = $content_type;

    $self->_Dirty = 0;

    # Call class-specific init method
    $self->init || return undef;

    return $self;
}

##
## TiVo::Calypso::Item->init( )
##
##  Generic TiVo::Calypso::Item initialization
##
sub init {
    my $self = shift;

    return 1;
}

## TiVo::Calypso::Item->send( )
##
##  Generic TiVo::Calypso::Item file transfer

sub send {
    my $self = shift;

    require IO::File;

    my $handle = IO::File->new( $self->_Path );

    my $headers = {
        'Content-Type'   => $self->_SourceFormat,
        'Content-Length' => $self->_SourceSize
    };

    return ( $headers, $handle );
}

# TiVo::Calypso::Item extension
package TiVo::Calypso::Item::MP3;
@ISA = ('TiVo::Calypso::Item');

## TiVo::Calypso::Item::MP3->init( )
##
##  Overrides generic init method for TiVo::Calypso::Item and includes MP3
##  specific fields

sub init {
    my $self = shift;

    # use the file suffix to determine file type
    my @parts  = split( /\./, $self->_Path );
    my $suffix = uc( pop @parts );

    # Assume MP3 for lack of anything better.
    require MP3::Info;

    my $tag  = MP3::Info::get_mp3tag( $self->_Path );
    my $info = MP3::Info::get_mp3info( $self->_Path );

    return undef unless defined $info;

    $self->_SourceBitRate = sprintf( "%d", $info->{'BITRATE'} * 1000 ) || 0;
    $self->_SourceSampleRate = sprintf( "%d", $info->{'FREQUENCY'} * 1000 )
      || 0;
    $self->_Duration = sprintf( "%d", ( $info->{'SECS'} * 1000 ) ) || 0;

    $self->_Genre  = $tag->{'GENRE'}  || "";
    $self->_Artist = $tag->{'ARTIST'} || "";
    $self->_Album  = $tag->{'ALBUM'}  || "";
    $self->_Year   = $tag->{'YEAR'}   || "";
    $self->_Title  = $tag->{'TITLE'}  || $self->_basename;

    # Get timestamps and size if the file referenced by Path exists
    if ( stat( $self->_Path ) ) {
        $self->_SourceSize = -s $self->_Path;

        my $change_date = ( stat(_) )[9];
        my $access_date = ( stat(_) )[8];

        $change_date = sprintf( "0x%x", $change_date );
        $access_date = sprintf( "0x%x", $access_date );

        # *nix does not seem to have a portable "creation date" stamp.
        # Using last change date, instead.
        $self->_CreationDate   = $change_date;
        $self->_LastChangeDate = $change_date;
        $self->_LastAccessDate = $access_date;
    }

    return 1;
}

## TiVo::Calypso::Item::MP3->_query_container
##
##   Returns a data structure suitable for use with xml_out which
##   describes this object in response to a QueryContainer command

sub _query_container {
    my $self   = shift;
    my $params = shift;

    my $script_name = $params->_EnvScriptName || "";

    my $details = {
        'Item' => [
            {
                'Details' => {
                    'Title'        => $self->_Title,
                    'ContentType'  => $self->_ContentType,
                    'SourceFormat' => $self->_SourceFormat,
                    'ArtistName'   => $self->_Artist,
                    'SongTitle'    => $self->_Title,
                    'AlbumTitle'   => $self->_Album,
                    'MusicGenre'   => $self->_Genre,
                    'Duration'     => $self->_Duration
                }
            },
            {
                'Links' => {
                    'Content' => {
                        'Url'      => $script_name . $self->_Url,
                        'Seekable' => 'Yes'
                    }
                }
            }
        ]
    };

    return $details;
}

## TiVo::Calypso::Item::MP3->send( $ )
##
##  TiVo::Calypso::Item send extension supporting MP3 seeking

sub send {
    my $self   = shift;
    my $params = shift;

    require IO::File;

    my $handle = IO::File->new( $self->_Path );
    my $length = $self->_SourceSize;

    if ( defined $params->_Seek ) {
        my $seek_ms     = $params->_Seek;
        my $seek_offset =
          sprintf( "%d", ( $seek_ms / $self->_Duration ) * $self->_SourceSize );

        seek( $handle, $seek_offset, 0 );

        $length = $length - $seek_offset;
    }

    my $headers = {
        'Content-Type'         => $self->_SourceFormat,
        'Content-Length'       => $length,
        'TivoAccurateDuration' => $self->_Duration
    };

    return ( $headers, $handle );
}

##############################################################################
# TiVo::Calypso::Request
#   Stores information about a given command request which needs to be
#   passed from object to object
##############################################################################
package TiVo::Calypso::Request;
@ISA = ('TiVo::Calypso');

## TiVo::Calypso::Request->new( $ $ $ )
##
##  Constructor for TiVo::Calypso::Request.
##  Expects to be passed three strings:
##
##    Script Name:  The path and name of the CGI/server as requested in the URI
##                  This is the same string provided by webserver in the
##                  $SCRIPT_NAME environment variable
##    Path Info:    The path information appended after the CGI/server in
##                  the URI, but before the paramater list.
##                  This is the same string provided by webserver in the
##                  $PATH_INFO environment variable
##    Query String  The key/value query string appended to the end of the URI
##                  This is the same string provided by webserver in the
##                  $QUERY_STRING environment variable

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_EnvScriptName  = shift;
    $self->_EnvPathInfo    = shift;
    $self->_EnvQueryString = shift;

    # Parse the query_string, if provided
    if ( defined( $self->_EnvQueryString ) ) {
        $self->parse( $self->_EnvQueryString );
    }

    return $self;
}

## TiVo::Calypso::Request->parse( $ )
##
##   Trim, split, and decode a standard CGI query string. The key/value
##   pairs are stored in the object's internal DATA hash

sub parse {
    my $self  = shift;
    my $query = shift;

    # Skip the query if it doesn't contain anything useful
    if ( defined($query) && $query =~ /[=&]/ ) {

        # remove everything before the '?' and replace '+' with a space
        $query =~ s/.*\?//;
        $query =~ s/\+/ /g;

        my @pairs = split( /&/, $query );

        foreach my $pair (@pairs) {
            my ( $key, $value ) = split( /=/, $pair, 2 );

            if ( defined($key) ) {

                # Escape each key and value before storing
                $key = $self->_uri_unescape($key);
                $self->{'DATA'}->{ uc($key) } = $self->_uri_unescape($value);
            }
        }
    }
}

1;
