package Web::oEmbed;

use strict;
use 5.8.1;
our $VERSION = '0.04';

use Any::Moose;
has 'format'    => (is => 'rw', default => 'json');
has 'discovery' => (is => 'rw');
has 'providers' => (is => 'rw', isa => 'ArrayRef', default => sub { [] });
has 'agent'     => (is => 'rw', isa => 'LWP::UserAgent', default => sub {
                        require LWP::UserAgent;
                        LWP::UserAgent->new( agent => __PACKAGE__ . "/" . $VERSION );
                    });

use URI;
use Web::oEmbed::Response;

sub register_provider {
    my($self, $provider) = @_;
    $provider->{regexp} = $self->_compile_url($provider->{url});
    push @{$self->providers}, $provider;
}

sub _compile_url {
    my($self, $url) = @_;
    my $res;
    my $uri = URI->new($url);
    $res  = $uri->scheme . "://";
    $res .=  _run_regexp($uri->host, '[0-9a-zA-Z\-]+');
    $res .=  _run_regexp($uri->path, "[$URI::uric]+" );
    $res;
}

sub _run_regexp {
    my($str, $replacement) = @_;
    $str =~ s/(?:(\*)|([^\*]+))/$1 ? $replacement : quotemeta($2)/eg;
    $str;
}

sub provider_for {
    my($self, $uri) = @_;
    for my $provider (@{$self->providers}) {
        if ($uri =~ m!^$provider->{regexp}!) {
            return $provider;
        }
    }
    return;
}

sub request_url {
    my($self, $uri, $opt) = @_;

    my $params = {
        url    => $uri,
        format => $opt->{format} || $self->format,
    };

    $params->{maxwidth}  = $opt->{maxwidth}  if exists $opt->{maxwidth};
    $params->{maxheight} = $opt->{maxheight} if exists $opt->{maxheight};

    my $provider = $self->provider_for($uri) or return;
    my $req_uri  = URI->new( $provider->{api} );
    if ($req_uri->path =~ /%7Bformat%7D/) { # yuck
        my $path = $req_uri->path;
        $path =~ s/%7Bformat%7D/$params->{format}/;
        $req_uri->path($path);
        delete $params->{format};
    }

    $req_uri->query_form($params);
    $req_uri;
}

sub embed {
    my($self, $uri, $opt) = @_;

    my $url = $self->request_url($uri, $opt) or return;
    my $res = $self->agent->get($url);

    Web::oEmbed::Response->new_from_response($res, $uri);
}

1;
__END__

=encoding utf-8

=for stopwords oEmbed

=head1 NAME

Web::oEmbed - oEmbed consumer

=head1 SYNOPSIS

  use Web::oEmbed;

  my $consumer = Web::oEmbed->new({ format => 'json' });
  $consumer->register_provider({
      url  => 'http://*.flickr.com/*',
      api  => 'http://www.flickr.com/services/oembed/',
  });

  my $response = eval { $consumer->embed("http://www.flickr.com/photos/bulknews/2752124387/") };
  if ($response) {
      $response->matched_uri;   # 'http://www.flickr.com/photos/bulknews/2752124387/'
      $response->type;          # 'photo'
      $response->title;         # title of the photo
      $response->url;           # JPEG URL
      $response->width;         # JPEG width
      $response->height;        # JPEG height
      $response->provider_name; # Flickr
      $response->provider_url;  # http://www.flickr.com/

      print $response->render;  # handy shortcut to generate <img/> tag
  }

=head1 DESCRIPTION

Web::oEmbed is a module that implements oEmbed consumer.

=head1 METHODS

=over 4

=item new

  $consumer = Web::oEmbed->new;
  $consumer = Web::oEmbed->new({ format => 'json' });

Creates a new Web::oEmbed instance. You can specify the default format
that will be used when it's not specified in the C<embed> method.

=item register_provider

  $consumer->register_provider({
      name => 'Flickr',
      url  => 'http://*.flickr.com/*',
      api  => 'http://www.flickr.com/services/oembed/,
  });

Registers a new provider site. C<name> is optional while C<url> and
C<api> are required. If you specify the mangled C<url> parameter like
'*://www.flickr.com/' it will die with an error. You can call this
method multiple times to add multiple oEmbed providers.

=item embed

  $response = $consumer->embed("http://www.example.com/");
  $response = $consumer->embed( URI->new("http://photos.example.com/"), { format => 'xml' } );

Given an URL it will try to find the correspondent provider based on
their registered URL scheme, and then send the oEmbed request to the
oEmbed provider endpoint and parse the response. The method returns an
instance of Web::oEmbed::Response.

Returns undef if there's no provider found for the URL. Throws an
error if there's an error in JSON/XML parsing etc. (Note: I don't like
this interface because there's no cleaner way to handle and diagnose
errors. This might be changed.)

C<format> optional parameter specifies which C<format> is sent to the
provider as a prefered format parameter. When omitted, the default
format parameter set in C<new> is used. If it's not speciied in C<new>
either, the default will be C<json>.

B<NOT IMPLEMENTED YET>: When optional parameter C<discovery> is set,
the consumer will issue the HTTP request to the original URL to
discover the oEmbed discovery tag described in the oEmbed spec chapter
4. If the oEmbed discovery tag is found in the HTML, it will then
issue the oEmbed request against the provider.

=back

=head1 METHODS in Web::oEmbed::Response

=over 4

=item http_response

  $res = $response->http_response;

Returns an underlying HTTP::Response object.

=item matched_uri

  $uri = $response->matched_uri;

Returns the matched URL given to the original C<embed> method.

=item type

=item version

=item title

=item author_name

=item author_url

=item provider_name

=item provider_url

=item cache_age

=item thumbnail_url

=item thumbnail_width

=item thumbnail_height

Returns the value of response parameters.

=item url, width, height

Returns the value of response parameters if response type is I<photo>.

=item html, width, height

Returns the value of response parameters if response type is I<video> or I<rich>.

=item render

  $html = $response->render;

Returns the HTML that you can use to display the embedded object. This
method is an alias to C<html> accessor if there is one in the response
(i.e. I<video> or I<rich>), or creates an A tag to represent C<photo>
or C<rich> response.

=back

=head1 TODO

Currently if you register 100 providers, the I<embed> method could
potentially iterate through all of providers to run the regular
expression, which doesn't sound good. I guess we could come up with
some Trie-ish regexp solution that immediately returns the
correspondent provider by compiling all regular expressions into one.

Patches are welcome on this :)

=head1 COPYRIGHT

Six Apart, Ltd. E<lt>cpan@sixapart.comE<gt>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.oembed.com/>, L<JSON::XS>, L<XML::LibXML::Simple>

=cut
