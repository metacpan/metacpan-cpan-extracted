package URL::Signature::Google::Maps::API;
use strict;
use warnings;
use base qw{Package::New};
use Path::Class qw{file dir};
use Config::IniFiles qw{};
use MIME::Base64 qw{};
use Digest::HMAC_SHA1 qw{};

our $VERSION='0.02';

=head1 NAME

URL::Signature::Google::Maps::API - Sign URLs for use with Google Maps API Enterprise Business Accounts

=head1 SYNOPSIS

  use URL::Signature::Google::Maps::API;
  my $signer     = URL::Signature::Google::Maps::API->new();
  my $server     = "http://maps.googleapis.com";
  my $path_query = "/maps/api/staticmap?size=600x300&markers=Clifton,VA&sensor=false";
  my $url        = $signer->url($server => $path_query);

=head1 DESCRIPTION

Generates a signed URL for use in the Google Maps API.  The Google Enterprise keys can be stored in an INI file (i.e. /etc/google.conf) or passed on assignment..

=head1 CONSTRUCTOR

=head2 new

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

=head1 USAGE

=head2 url

Returns a signed URL given a two part URL of server and path_query.

  my $url=$signer->url($server => $path_query);

Example

  my $url=$signer->url("http://maps.googleapis.com" => "/maps/api/staticmap?size=600x300&markers=Clifton,VA&sensor=false");

This method adds client and channel parameters (if configured) so they should not be added to the passed in path query.

=cut

sub url {
  my $self       = shift;
  my $server     = shift;
  my $path_query = shift;
  if ($self->client) {
    $path_query.=sprintf("&channel=%s", $self->channel) if $self->channel;
    $path_query.=sprintf("&client=%s", $self->client);
  }
  my $url=$server . $path_query;
  $url.=sprintf("&signature=%s", $self->signature($path_query)) if $self->client;
  #warn("URL: $url\n");
  return $url;
}

=head2 signature

Returns the signature value if you want to use the mathematics without the url method.

  my $path_query = "/path/script" . "?" . $query;
  my $url=$protocol_server . $path_query . "&signature=" . $signer->signature($path_query);

=cut

sub signature {
  my $self       = shift;
  my $path_query = shift;
  my $signature  = $self->_Digest->reset->add($path_query)->b64digest;
  $signature     =~ tr/\+/\-/;
  $signature     =~ tr/\//\_/;
  return $signature;
}

=head1 Google Enterprise Credentials

You may store the credentials in an INI formatted file or you may specify the credentials on construction or after construction.

Configuration file format

  [GoogleAPI]
  client=abc-xyzpdq
  key=xUUUUUUUUUUUU-UUUUUUUUUUUUU=

=head2 client

Sets and returns the Google Enterprise Client

  Default: Value from INI file

  $signer->client("abc-xyzpdq");

=cut

sub client {
  my $self=shift;
  $self->{"client"}=shift if @_;
  $self->_setCredentials unless defined $self->{"client"};
  return $self->{"client"};
}

=head2 key

Sets and returns the Google Enterprise Key

  Default: Value from INI file

  $signer->key("xUUUUUUUUUUUU-UUUUUUUUUUUUU=");

=cut

sub key {
  my $self=shift;
  $self->{"key"}=shift if @_;
  $self->_setCredentials unless defined $self->{"key"};
  return $self->{"key"};
}

sub _setCredentials {
  my $self=shift;
  if (-r $self->config_filename) {
    $self->{"key"}    = $self->_ConfigIniFiles->val("GoogleAPI", "key"   , "");
    $self->{"client"} = $self->_ConfigIniFiles->val("GoogleAPI", "client", "");
  } else {
    $self->{"key"}    = "";
    $self->{"client"} = "";
  }
  return $self;
}

=head2 channel

Sets and returns the Google Enterprise channel for determining application in Google Enterprise Support Portal (L<http://www.google.com/enterprise/portal>). 

Default: ""

Note: This is a per application setting not a per user setting.

=cut

sub channel {
  my $self=shift;
  $self->{"channel"}=shift if @_;
  $self->{"channel"}="" unless defined $self->{"channel"};
  return $self->{"channel"};
}

=head2 config_filename

Sets and returns the filename of the configuration file.

  Default: /etc/google.conf

=cut

sub config_filename {
  my $self=shift;
  $self->{"config_filename"}=shift if @_;
  unless (defined $self->{"config_filename"}) {
    my $filename;
    foreach my $path ($self->config_paths) {
      $filename=file($path, $self->config_basename);
      last if -r $filename;
    }
    $self->{"config_filename"}=$filename;
  }
  return $self->{"config_filename"};
} 

=head2 config_paths

Sets and returns a list of L<Path::Class:Dir> objects to check for a readable basename.

  Precedence: sysconfdir (i.e. /etc), Perl script directory, then current directory (i.e. ".")

  Default: [/etc, $0->dir, .]

=cut

sub config_paths {
  my $self=shift;
  $self->{"config_paths"}=shift if @_;
  unless (ref($self->{"config_paths"}) eq "ARRAY") {
    my @paths=(file($0)->dir, dir(".")); #current directory is default
    if ($^O ne "MSWin32") {
      eval("use Sys::Path");
      if ($@) {
        unshift @paths, dir("/etc");
      } else {
        unshift @paths, dir(Sys::Path->sysconfdir);
      }
    }
    $self->{"config_paths"}=\@paths;
  }
  return wantarray ? @{$self->{"config_paths"}} : $self->{"config_paths"};
}

=head2 config_basename

Sets and returns the basename for the Google configuration file.

  Default: google.conf

=cut

sub config_basename {
  my $self=shift;
  $self->{"config_basename"}=shift if @_;
  $self->{"config_basename"}="google.conf" unless defined $self->{"config_basename"};
  return $self->{"config_basename"};
}

#head1 Object Accessors
#
#head2 _ConfigIniFiles
#
#Returns the cached L<Config::IniFiles> object
#
#=cut

sub _ConfigIniFiles {
  my $self=shift;
  unless (defined $self->{'_ConfigIniFiles'}) {
    my $filename=$self->config_filename; #support for objects that can stringify paths.
    $self->{'_ConfigIniFiles'}=Config::IniFiles->new(-file=>"$filename");
  }
  return $self->{'_ConfigIniFiles'};
}

#head2 _Digest
#
#Returns a cached L<Digest::HMAC_SHA1> object initialized with the enterprise key.
#
#Note: Must be reset before re-use.
#
#  my $digest=$signer->Digest->reset;
#
#cut

sub _Digest {
  my $self=shift;
  unless (defined $self->{"_Digest"}) {
    my $base64=$self->key;
    #$content =~ tr{-_}{+/}; #tweak from Geo::Coder::Google::V3
    $base64 =~ tr/-/\+/;
    $base64 =~ tr/_/\//;
    my $binary=MIME::Base64::decode_base64($base64);
    $self->{"_Digest"}=Digest::HMAC_SHA1->new($binary);
  }
  return $self->{"_Digest"};
}

=head1 BUGS

Please log on GitHub.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT

=head1 COPYRIGHT

MIT License

Copyright (c) 2022 Michael R. Davis

=head1 SEE ALSO

L<http://gmaps-samples.googlecode.com/svn/trunk/urlsigning/index.html>, L<http://gmaps-samples.googlecode.com/svn/trunk/urlsigning/urlsigner.pl>, L<Geo::Coder::Google::V3>

=cut

1;
