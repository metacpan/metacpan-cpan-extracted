package WebService::Embedly;

use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

#use Mouse;
#use Mouse::Util::TypeConstraints;

use LWP::UserAgent;
use JSON;
#use URI;
use URI::Escape;
use Ouch qw(:traditional);
use Regexp::Common qw /URI/;
our $VERSION = '0.10';

=encoding utf8

=head1 NAME

WebService::Embedly - Perl interface to the Embedly API

=head1 VERSION

Version 0.10

=cut

=head1 SYNOPSIS

    use WebService::Embedly;
    use Ouch qw(:traditional);

    my $embedly = WebService::Embedly->new({ api_key => 'get_your_key_at_embed.ly',
   					     maxwidth => 500 });

    my $oembed_ref;
    my $e = try {
      $oembed_ref = $embedly->oembed('http://youtu.be/I8CSt7a7gWY');
    };

    if ( catch_all, $e) {
       warn("embedly api failed: ".$e);
       return;
    }

    #made it here, everything good.
    my $embed_html = $oembed_ref->{html};

=cut

=head1 DESCRIPTION

The C<WebService::Embedly> is a class implementing for querying the Embed.ly web service.  Prior to using this module you should go to L<http://embed.ly> and sign up for an api_key.

You can quickly try out the API by executing: ./sample/usage.pl --apikey you_api_key_from_embed.ly

C<WebService::Embedly> exposes three methods: oembed, preview, objectify.  Each method has additional bits of metadata about the request URL.  oembed method follows the oembed standard documented here L<http://oembed.com/>

Refer to L<http://embed.ly> to learn more about the data that is returned for preview L<http://embed.ly/docs/endpoints/1/preview> and objectify L<http://embed.ly/docs/endpoints/2/objectify>

Exception handling is used to expose failures. The Ouch module (:traditional) is used to handle try/catch blocks.  See the Exception block below for all the possible catches. Example:

    my $e = try {
      $oembed_ref = $embedly->oembed('http://youtu.be/I8CSt7a7gWY');
    };

    if ( catch 500, $e) {
       #Server is down
       return;
    }
    if ( catch 401, $e) {
       #Your API key has used all its credits
       return;
    }
    elsif ( catch_all, $e) {
       #I hate the individual exception catching, lets get this over with it.
       return;
    }


C<WebService::Embedly> uses Mouse (lighter version of Moose) to handle its object management.

=cut

=head1 CONSTRUCTOR

You must pass the api_key into the constructor:

    my $embedly = WebService::Embedly->new({ api_key => 'get_your_key_at_embed.ly'});

C<WebService::Embedly> uses LWP::UserAgent to handle its web requests.  You have the option to pass in your own LWP object in case of special requirements, like a proxy server:

    my $ua = LWP::UserAgent->new();
    $ua->proxy('http', 'http://proxy.sn.no:8001/');

    my $embedly = WebService::Embedly->new({ api_key => 'get_your_key_at_embed.ly',
                                      ua => $ua
                                    });

=head2 Optional Params

C<WebService::Embedly> supports all optional parameters at the time of this writing L<http://embed.ly/docs/endpoints/arguments>.  Refer to the embedly documentation for the complete description.  In the majority of cases you only need to pay attention to the maxwidth param.  It is highly recommended to specify maxwidth since the embed html could overflow the space you provide for it.

=head3 maxwidth

This is the maximum width of the embed in pixels. maxwidth is used for scaling down embeds so they fit into a certain width.  If the container for an embed is 500px you should pass maxwidth=500 in the query parameters. 

=head3 maxheight

This is the maximum height of the embed in pixels.

=head3 width

Will scale embeds type rich and video to the exact width that a developer specifies in pixels.

=head3 format (default: json)

The response format - Accepted values: (xml, json)

=head3 callback

Returns a (jsonp) response format. The callback is the name of the javascript function to execute.

=head3 wmode 

Will append the wmode value to the flash object. Possible values include window, opaque and transparent.

=head3 allowscripts (default: false)

By default Embedly does not return script embeds for jsonp requests. They just don’t work and cause lots of issues. In some cases, you may need the script tag for saving and displaying later.  Accepted values: (true, false)

=head3 nostyle (default: false)

There are a number of embeds that Embedly has created including Amazon.com, Foursquare, and Formspring. These all have style elements and inline styles associated with them that make the embeds look good. Accepted values: (true, false)

=head3 autoplay (default: false)

This will tell the video/rich media to automatically play when the media is loaded. Accepted values: (true, false)

=head3 videosrc (default: false)

Either true Embedly will use the video_src meta or Open Graph tag to create a video object to embed. Accepted values: (true, false)

=head3 words

The words parameter has a default value of 50 and works by trying to split the description at the closest sentence to that word count.

=head3 chars

chars is much simpler than words. Embedly will blindly truncate a description to the number of characters you specify adding ... at the end when needed.

=cut

=head1 EXCEPTIONS

All exceptions are thrown in terms of http status codes.  Exceptions from the web service are passed through directly.  For example L<http://embed.ly/docs/endpoints/1/oembed> and scroll down to view the Error Codes.  For most situations you can simply do this:

    my $e = try {
      $oembed_ref = $embedly->oembed('http://youtu.be/I8CSt7a7gWY');
    };

    if ( catch_all, $e) {
       warn("embedly api failed: ".$e);
       #do something...
    }

=cut

has 'api_key' => (
		  is  => 'ro',
		  isa => 'Str',
		  required => 1,
);

has 'oembed_base_uri' => (
		       is => 'ro',
		       isa => 'Str',
		       default => 'http://api.embed.ly/1/oembed'
);

has 'preview_base_uri' => (
		       is => 'ro',
		       isa => 'Str',
		       default => 'http://api.embed.ly/1/preview'
);

has 'objectify_base_uri' => (
		       is => 'ro',
		       isa => 'Str',
		       default => 'http://api.embed.ly/1/objectify'
);

has 'ua' => (
	     is => 'ro',
	     isa => 'LWP::UserAgent',
	     required => 1,
	     default => sub { my $ua = LWP::UserAgent->new;
			      $ua->timeout(10);
			      return $ua;
			    },
);

has 'json' => (
	     is => 'ro',
	     isa => 'JSON',
	     required => 1,
	     default => sub { JSON->new->utf8; },
);

has 'maxwidth' => (
		   is  => 'rw',
		   isa => 'Int',
		   required => 0,
		   predicate => 'has_maxwidth'
		  );

has 'maxheight' => (
		    is  => 'rw',
		    isa => 'Int',
		    required => 0,
		    predicate => 'has_maxheight'
		   );

has 'width' => (
		is  => 'rw',
		isa => 'Int',
		required => 0,
		predicate => 'has_width'
	       );

has 'format' => (
		   is  => 'rw',
		   isa => 'Str',
		   required => 0,
		   predicate => 'has_format'
		  );

has 'callback' => (
		   is  => 'rw',
		   isa => 'Str',
		   required => 0,
		   predicate => 'has_callback'
		  );

has 'wmode' => (
		is  => 'rw',
		isa => 'Str',
		required => 0,
		predicate => 'has_wmode'
	       );

has 'allowscripts' => (
		       is  => 'rw',
		       isa => 'Str',
		       required => 0,
		       predicate => 'has_allowscripts'
		      );


has 'nostyle' => (
		  is  => 'rw',
		  isa => 'Str',
		  required => 0,
		  predicate => 'has_nostyle'
	       );

has 'autoplay' => (
		   is  => 'rw',
		   isa => 'Str',
		   required => 0,
		   predicate => 'has_autoplay'
		  );

has 'videosrc' => (
		   is  => 'rw',
		   isa => 'Str',
		   required => 0,
		   predicate => 'has_videosrc'
	       );


has 'words' => (
		is  => 'rw',
		isa => 'Int',
		required => 0,
		predicate => 'has_words'
	       );


has 'chars' => (
		is  => 'rw',
		isa => 'Int',
		required => 0,
		predicate => 'has_chars'
	       );



#optional params

=head1 METHODS

=head2 oembed;

=head2 preview;

=head2 objectify;

Embed.ly provide three different methods: oembed, preview, objectify depending on the amount of information/access you need each take the same parameters.  However different data is returned depending on which method used.

There are three ways to call each method

=head3 Single URL

Fetch metadata about a single URL - call method with full url as a string

    $oembed_ref = $embedly->oembed('http://youtu.be/I8CSt7a7gWY');

=head3 Multiple URLs

Fetch metadata about multiple URLs - call method with array ref of urls

   my @urls = qw(http://yfrog.com/ng41306327j http://twitter.com/embedly/status/29481593334 http://blog.embed.ly/31814817 http://soundcloud.com/mrenti/merenti-la-karambaa);
   $oembed_ref = $embedly->oembed(\@urls);

=head3 Extra Information

Fetch metadata about URL(s) and include additional query arguments L<http://embed.ly/docs/endpoints/arguments> - call methods with with hash ref of attributes

   my $query_ref = {


Can throw an exception (ouch) so wrap in an eval or use Ouch module and refer to its syntax

=cut

sub oembed {
  my ($self, $embed_url) = @_;

  my $res = $self->_request( { embed_url => $embed_url,
			       base_uri  => $self->oembed_base_uri
			     } );

  return ($res);
}


sub preview {
  my ($self, $embed_url) = @_;

  my $res = $self->_request( { embed_url => $embed_url,
			       base_uri  => $self->preview_base_uri
			     } );

  return ($res);
}

sub objectify {
  my ($self, $embed_url) = @_;

  my $res = $self->_request( { embed_url => $embed_url,
			       base_uri  => $self->objectify_base_uri
			     } );

  return ($res);
}

sub _request {
  my ($self, $in) = @_;

  my $embed_url = $in->{embed_url};
  my $base_uri  = $in->{base_uri};

  my %params = ( key => $self->api_key );

  if (ref($embed_url) eq 'ARRAY') {
    my $cnt = int(@{$embed_url});
    if ($cnt > 20) {
      throw 400, 'Cannot pass more than 20 urls in a single request';
    }

    my @escaped_urls;
    foreach my $e_url (@{$embed_url}) {
      unless ( $RE{URI}{HTTP}->{-scheme => qr/https?/}->matches($e_url) ) {
	throw 400, 'Look-up URL does not look like a properly formatted url: ' . $e_url;
      }
      push @escaped_urls, uri_escape_utf8($e_url) ;
    }
    $params{urls} = join (',', @escaped_urls);
  }
  else {
    #quick check to see if we have a url
    unless ( $RE{URI}{HTTP}->{-scheme => qr/https?/}->matches($embed_url) ) {
      throw 400, 'Look-up URL does not look like a properly formatted url: ' . $embed_url;
    }
    $params{url} = uri_escape_utf8($embed_url);
  }

#  can't use query_form because embedly can't handle full application/x-www-form-urlencoded for multi urls (the comma between urls needs to stay a comma and not escaped to %2C) boo
#  my $uri = URI->new($base_uri);
#  $uri->query_form($params);

  my $url = $base_uri . '?';
  foreach my $param (keys %params) {
    $url .= $param .'='. $params{$param} . '&';
  }

  if ( $self->has_maxwidth ) {
    $url .= 'maxwidth='. $self->maxwidth . '&';
  }

  if ( $self->has_maxheight ) {
    $url .= 'maxheigth='. $self->maxheight . '&';
  }

  if ( $self->has_width ) {
    $url .= 'width='. $self->width . '&';
  }

  if ( $self->has_format ) {
    $url .= 'format='. $self->format . '&';
  }

  if ( $self->has_callback ) {
    $url .= 'callback='. $self->callback . '&';
  }

  if ( $self->has_wmode ) {
    $url .= 'wmode='. $self->wmode . '&';
  }

  if ( $self->has_allowscripts ) {
    $url .= 'allowscripts=true&';
  }

  if ( $self->has_nostyle ) {
    $url .= 'nostyle=true&';
  }

  if ( $self->has_autoplay ) {
    $url .= 'autoplay=true&';
  }

  if ( $self->has_videosrc ) {
    $url .= 'videosrc=true&';
  }

  if ( $self->has_words ) {
    $url .= 'words='. $self->words . '&';
  }

  if ( $self->has_chars ) {
    $url .= 'chars='. $self->chars . '&';
  }

  #take off the trailing '&'
  chop ($url);

#  warn ($url);

  my $res = $self->ua->get($url);

  if ($res->is_success) {
    my $data_ref;
    eval {
      $data_ref = $self->json->decode($res->decoded_content);
    };
    if ($@) {
      #Should be a different code than 500
      throw 500, 'Could not parse JSON response', $@;
    }
    return $data_ref;
  }
  else {
    ## figure out all the different failures form the API
    if ($res->code) {
      throw $res->code, $res->status_line;
    }
    else {
      throw 500, 'HTTP Request to embed.ly failed', $res->status_line;
    }
  }
}

=head1 AUTHOR

Jason Wieland C<jwieland@cpan.org>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/jwieland/embedly-perl/issues>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Embedly

You can also look for information at: https://github.com/jwieland/embedly-perl

=over 4

=item * View source / report bugs

L<https://github.com/jwieland/embedly-perl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jason Wieland and 12engines LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

__PACKAGE__->meta->make_immutable();

1; # End of WebService::Embedly
