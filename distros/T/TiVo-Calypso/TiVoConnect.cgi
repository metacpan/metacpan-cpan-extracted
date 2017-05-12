#!/usr/bin/perl

##  Example CGI usage of TiVo::Calypso
##  Version 1.3.4

##  Install this CGI using the following Apache directive:
##      Alias /TiVoConnect /FULL/path/to/TiVoConnect.cgi
##
##  Be sure to enable the CGI handler for .cgi extensions


use TiVo::Calypso;



my $server = TiVo::Calypso::Server->new(
    SERVER_NAME => "My Server",
    CACHE_DIR => "/tmp"
);

my $music_service = TiVo::Calypso::Container::Music->new(
    TITLE => "Music Library",
    PATH => "/mp3",
    SERVICE => "/Music",
    SCROBBLER => {
        POSTURL => 'http://post.audioscrobbler.com',
        USERNAME => 'scrobbleuser',
        PASSWORD => 'p4ssw0rd'
    }
);

my $music_shuffle = TiVo::Calypso::Container::Music->new(
    TITLE => "Shuffled Playlist",
    PATH => "/mp3",
    SERVICE => "/Shuffle",
    SCROBBLER => {
        POSTURL => 'http://post.audioscrobbler.com',
        USERNAME => 'scobbleuser',
        PASSWORD => 'p4ssw0rd'
    }
);

$server->add_service( $music_service );
$server->add_service( $music_shuffle );



## Process a request using environment variables set by
## web server

my( $headers, $data ) = $server->request(
    $ENV{'SCRIPT_NAME'},
    $ENV{'PATH_INFO'},
    $ENV{'QUERY_STRING'}
);

# Command failed completely if no headers were returned
if( defined($headers) ) {

    # Print the recommended headers
    foreach ( keys %$headers ) {
        print "$_: ", $headers->{$_}, "\r\n" if $headers->{$_};
    }
    print "\r\n";

    # If the returned data is a scalar ref, simply print it out
    if( ref $data eq 'SCALAR' ) {
        print $$data;

    # If it's a filehandle ref, read from the file
    } elsif( ref $data eq 'IO::File' ) {
        my $block;
        while( $data->read( $block, 1024 ) ) {
            print $block;
        }

        # Close file
        undef $data;
    }
} else {
    print "Status: 404 Not Found\r\n";
    print "\r\n";
    print "Bad request.\n";
}

exit;
