# NAME

URL::Signature::Google::Maps::API - Sign URLs for use with Google Maps API Enterprise Business Accounts

# SYNOPSIS

    use URL::Signature::Google::Maps::API;
    my $signer     = URL::Signature::Google::Maps::API->new();
    my $server     = "http://maps.googleapis.com";
    my $path_query = "/maps/api/staticmap?size=600x300&markers=Clifton,VA&sensor=false";
    my $url        = $signer->url($server => $path_query);

# DESCRIPTION

Generates a signed URL for use in the Google Maps API.  The Google Enterprise keys can be stored in an INI file (i.e. /etc/google.conf) or passed on assignment..

# CONSTRUCTOR

## new

Use client and key from INI file /etc/google.conf

    my $signer=URL::Signature::Google::Maps::API->new(channel => "myapp");

Use client and key from construction

    my $signer=URL::Signature::Google::Maps::API->new(
                                                      client  => "abc-xyzpdq",
                                                      key     => "xUUUUUUUUUUUU-UUUUUUUUUUUUU=",
                                                      channel => "myapp",
                                                      );

Don't use client or signature just pass through URLs

    my $signer=URL::Signature::Google::Maps::API->new(client=>"");

# USAGE

## url

Returns a signed URL given a two part URL of server and path\_query.

    my $url=$signer->url($server => $path_query);

Example

    my $url=$signer->url("http://maps.googleapis.com" => "/maps/api/staticmap?size=600x300&markers=Clifton,VA&sensor=false");

This method adds client and channel parameters (if configured) so they should not be added to the passed in path query.

## signature

Returns the signature value if you want to use the mathematics without the url method.

    my $path_query = "/path/script" . "?" . $query;
    my $url=$protocol_server . $path_query . "&signature=" . $signer->signature($path_query);

# Google Enterprise Credentials

You may store the credentials in an INI formatted file or you may specify the credentials on construction or after construction.

Configuration file format

    [GoogleAPI]
    client=abc-xyzpdq
    key=xUUUUUUUUUUUU-UUUUUUUUUUUUU=

## client

Sets and returns the Google Enterprise Client

    Default: Value from INI file

    $signer->client("abc-xyzpdq");

## key

Sets and returns the Google Enterprise Key

    Default: Value from INI file

    $signer->key("xUUUUUUUUUUUU-UUUUUUUUUUUUU=");

## channel

Sets and returns the Google Enterprise channel for determining application in Google Enterprise Support Portal ([http://www.google.com/enterprise/portal](http://www.google.com/enterprise/portal)). 

Default: ""

Note: This is a per application setting not a per user setting.

## config\_filename

Sets and returns the filename of the configuration file.

    Default: /etc/google.conf

## config\_paths

Sets and returns a list of [Path::Class:Dir](https://metacpan.org/pod/Path::Class:Dir) objects to check for a readable basename.

    Precedence: sysconfdir (i.e. /etc), Perl script directory, then current directory (i.e. ".")

    Default: [/etc, $0->dir, .]

## config\_basename

Sets and returns the basename for the Google configuration file.

    Default: google.conf

# BUGS

Please log on github.

# AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT

# COPYRIGHT

MIT License

Copyright (c) 2022 Michael R. Davis

# SEE ALSO

[http://gmaps-samples.googlecode.com/svn/trunk/urlsigning/index.html](http://gmaps-samples.googlecode.com/svn/trunk/urlsigning/index.html), [http://gmaps-samples.googlecode.com/svn/trunk/urlsigning/urlsigner.pl](http://gmaps-samples.googlecode.com/svn/trunk/urlsigning/urlsigner.pl), [Geo::Coder::Google::V3](https://metacpan.org/pod/Geo::Coder::Google::V3)
