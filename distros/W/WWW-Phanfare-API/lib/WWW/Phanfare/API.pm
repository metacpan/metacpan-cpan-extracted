package WWW::Phanfare::API;

=head1 NAME

WWW::Phanfare::API - Perl wrapper for Phanfare API

=head1 VERSION

Version 0.09

=cut

use strict;
use warnings;
use Carp;
use REST::Client;
use Digest::MD5 qw(md5_hex);
use URI::Escape;
use XML::Simple;

our $VERSION = '0.09';
our $site = 'http://www.phanfare.com/api/?';
our $AUTOLOAD;

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self  = { @_ };
  bless $self, $class;
  return $self;
}

# Load date from url
sub geturl {
  my($self,$url,$post) = @_;

  # Create REST agent with cookies
  unless ( $self->{_rest} ) {
    $self->{_rest} = new REST::Client;
    $self->{_rest}->getUseragent()->cookie_jar({});
  }
  my $rest = $self->{_rest};

  # GET or POST
  if ( $post ) {
    $rest->POST( $url, $post );
  } else {
    $rest->GET( $url );
  }

  # Verify Response
  carp sprintf(
    "Return code %s: %s",
    $rest->responseCode(),
    $rest->responseContent()
  ) unless $rest->responseCode() eq '200';

  # Content
  $rest->responseContent();
}

# All API methods implemented as autoload functions.
#
#   $papi->Function() becomes REST::Client::GET(..."method=Function"...)
#
sub AUTOLOAD {
  my $self = shift;
  croak "$self is not an object" unless ref($self);

  my $method = $AUTOLOAD;
  $method =~ s/.*://;   # strip fully-qualified portion
  croak "method not defined" unless $method;

  # Verify keys are defined
  croak 'api_key not defined' unless $self->{api_key};
  croak 'private_key not defined' unless $self->{private_key};

  my %param = @_;

  # Is POST content included
  delete $param{content} if my $content = $param{content};

  # Build signature request string
  my $req = join '&',
    sprintf('%s=%s', 'api_key', $self->{api_key}),
    sprintf('%s=%s', 'method', $method),
    map { sprintf '%s=%s', $_, (defined $param{$_} ? $param{$_} : '') } keys %param;

  # Sign request string
  my $sig = md5_hex( $req . $self->{private_key} );

  # Build URL escaped request string
  $req = join '&',
    sprintf('%s=%s', 'api_key', $self->{api_key}),
    sprintf('%s=%s', 'method', $method),
    map { sprintf '%s=%s', $_, uri_escape( defined $param{$_} ? $param{$_} : '' ) } keys %param;
  $req .= sprintf '&%s=%s', 'sig', $sig;

  return XML::Simple::XMLin $self->geturl( $site.$req, $content );
} 

# Make sure not caught by AUTOLOAD
sub DESTROY {}

=head1 SYNOPSIS

Create agent. Developer API keys required.

    use WWW::Phanfare::API;
    my $api = WWW::Phanfare::API->new(
      api_key     => 'xxx',
      private_key => 'yyy',
    );

Authentication with account:

    my $session = $api->Authenticate(
       email_address => 'my@email',
       password      => 'zzz',
    )
    die "Cannot authenticate: $session->{code_value}"
      unless $session->{'stat'} eq 'ok';
    my $target_uid = $session->{session}{uid};
 
Or authenticate as guest:

    $api->AuthenticateGuest();

Get list of albums:

    my $albumlist = $api->GetAlbumList(
      target_uid => $session->{session}{uid}
    )->{albums}{album};

    printf(
      "%s %s %s\n",
      $_->{album_id}, substr($_->{album_start_date}, 0, 10), $_->{album_name}
    ) for @$albumlist;

Create new album, upload an image to it and delete it all again.

    my $album = $api->NewAlbum(
      target_uid => $target_uid,
    );

    my $album_id   = $album->{album}{album_id};
    my $section_id = $album->{album}{sections}{section}{section_id};
    my $content    = read_file('IMG_1234.jpg', binmode => ':raw');

    my $image = $api->NewImage(
      target_uid => $target_uid,
      album_id   => $album_id,
      section_id => $section_id,
      filename   => 'IMG_1234.jpg',
      content    => $content,
    );

    my $del_album = $api->DeleteAlbum(
      target_uid => $target_uid,
      album_id   => $album_id,
    );

Load an image.

    my $image = $api->geturl( $url );


=head1 DESCRIPTION

Perl wrapper the Phanfare API. A developer API key is required for using
this module.

=head1 SUBROUTINES/METHODS

Refer to methods and required parameters are listed on
http://help.phanfare.com/index.php/API .

api_key and private_key is only required for the constructor,
not for individual methods.

Methods return hash references.
The value of the 'stat' key will be 'ok' if the call succeeded.
Value of 'code_value' key has error message.

=head2 new

Create a new API agent.

=head2 geturl

Load data from URL.

=head1 AUTHOR

Soren Dossing, C<< <netcom at sauber.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-phanfare-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Phanfare-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Phanfare::API


You can also look for information at:

=over 4

=item * Github's request tracker

L<https://github.com/sauber/p5-www-phanfare-api/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Phanfare-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Phanfare-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Phanfare-API/>

=back


=head1 SEE ALSO

=over 4

=item * Official Phanfare API Refence Guide

L<http://help.phanfare.com/index.php/API>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
