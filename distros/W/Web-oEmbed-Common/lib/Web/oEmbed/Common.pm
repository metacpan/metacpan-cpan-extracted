=head1 PACKAGE

Web::oEmbed::Common - Define several well-known oEmbed providers.


=head1 SYNOPSIS

  my $consumer = Web::oEmbed::Common->new();
  $consumer->set_embedly_api_key( '0123ABCD0123ABCD0123ABCD' );

  my $response = $consumer->embed( $link_url );
  if ( $response ) {
    print $response->title;
    print $response->render;
  }


=head1 DESCRIPTION

Web::oEmbed::Common provides a subclass of L<Web::oEmbed> that is pre-configured with the oEmbed API endpoints for dozens of popular web sites.

The interface mirrors that of L<Web::oEmbed>: create an oEmbed client object and call its C<embed> method for each URL you'd like more information about, then extract the response information using the L<methods defined by Web::oEmbed::Response|Web::oEmbed/METHODS_in_Web::oEmbed::Response>. 


=head2 Defined Providers

When you create a new instance of Web::oEmbed::Common, it is initialized with a default set of well-known providers. 

Endpoints are currently defined for the following content sites: Blip.tv, DailyMotion, 5min, Flickr, FunnyOrDie.com, Hulu, PhotoBucket, PollDaddy.com, Qik, Revision3, Scribd, SmugMug, Viddler, Vimeo, WordPress.tv, YouTube.

Endpoints are also defined for the oEmbed proxy / adaptor services from Embed.ly and oohEmbed.com, each of which supports over a dozen content sites. Use of the Embed.ly service is subject to a daily rate limit, so you should consider obtaining your own API key by registering on their site.


=head2 Registering Additional Providers

You can add your own definitions using the C<register_provider> method. 

As with L<Web::oEmbed>, each provider definition should include a C<api> parameter with the oEmbed endpoint URL, but there are minor differences in how you specify the target URLs which that service can handle.

The provider definition's C<url> option can contain a whitespace-separated list of multiple URL patterns to match against. These URLs can contain optional portions or alternatives in parentheses.


=head1 SEE ALSO

L<http://www.oembed.com/>, L<Web::oEmbed>


=head1 AUTHOR

Developed by Matthew Simon Cavalletto.  You may contact the author 
directly at C<evo@cpan.org> or C<simonm@cavalletto.org>.

I found some of these oEmbed endpoint URLs defined in similar libraries 
in other languages, including wp-includes/class-oembed, django-oembed, and ruby-oembed.


=head1 LICENSE 

Copyright 2010, 2011 Matthew Simon Cavalletto. 

You may use, modify, and distribute this software under the same terms as Perl.

See http://dev.perl.org/licenses/ for more information.

=cut


package Web::oEmbed::Common;

use strict;
use 5.006;

use Carp;
use Any::Moose;

our $VERSION = '0.05';

########################################################################

use Web::oEmbed;
extends 'Web::oEmbed';

{
	# Embed.ly passes back a non-standard "description" field.
	package Web::oEmbed::Response;
	has 'description', is => 'rw';
}

########################################################################

# Bulk registration
sub register_providers {
    my($self, @providers) = @_;

	foreach my $provider ( @providers ) {
		$self->register_provider( $provider ) 
	}
}

sub _compile_url {
    my($self, $incoming) = @_;
	
	# Pass multiple space-separated URLs in a single string
	my @incoming = grep length($_), split ' ', $incoming;
	
	# Generate alternatives for parenthesized optional elements in the pattern
	# to facilitate the frequent case of supporting both x.com and www.x.com.
	my @urls;
	while ( @incoming ) {
		my $url = shift @incoming;
		
		unless ( $url =~ m{\(([^\)]*)\)} ) {
			push @urls, $url;
			next;
		}
		my @alts = split '\|', $1;
		if ( @alts == 1 ) {
			unshift @alts, '';
		}
		unshift @incoming, map {
			my $version = $url;
			$version =~ s{\(([^\)]*)\)}{$_};
			$version;
		} @alts
	}
	
	# The URL lists from oohEmbed includes patterns like *yfrog.com
	# so we over-ride the default Web::oEmbed behavior to allow * to match . in
	# hostnames, so the above line will match both www.yfrog.com and yfrog.com.
	join '|', map {
		# warn "Working on URL: $_\n";
		# no 'warnings';
	    my $uri = URI->new( $_ );
		$uri->scheme . '://'
		. Web::oEmbed::_run_regexp($uri->host, '[0-9a-zA-Z\-\.]*')
		. Web::oEmbed::_run_regexp($uri->path, "[$URI::uric]+" )
	} @urls
}

# Anchor right end of regexp.
sub provider_for {
    my ($self, $uri) = @_;
    foreach my $provider ( @{$self->providers} ) {
        if ($uri =~ m!^$provider->{regexp}(\#|$)!) {
            return $provider;
        }
    }
    return;
}

########################################################################

sub BUILD {
	my $self = shift;
	$self->register_common();
}

sub register_common {	
	(shift)->register_providers( 
		{
			name => 'Flickr', 
			api  => 'http://www.flickr.com/services/oembed/', 
			url  => 'http://(www.)flickr.com/photos/*', 
		},
		{ 
			name => 'YouTube',                                                                                                              
			api  => 'http://www.youtube.com/oembed', 
			url  => 'http://*youtube.com/watch* http://youtu.be/*', 
		},
		{
			name => 'Viddler', 
			api  => 'http://lab.viddler.com/services/oembed/', 
			url  => 'http://(www.)viddler.com/*', 
		},
		{
			name => 'Qik', 
			api  => 'http://qik.com/api/oembed.json', 
			url  => 'http://qik.com/*', 
		},
		{
			name => 'Vimeo', 
			api  => 'http://vimeo.com/api/oembed.json', 
			url  => 'http://(www.)vimeo.com/*', 
		},
		{
			name => 'Revision3',
			api  => 'http://revision3.com/api/oembed/', 
			url  => 'http://*revision3.com/*', 
		},
		{                                                                                                                        
			name => 'Scribd',                                                                                                              
			api  => 'http://www.scribd.com/services/oembed',                                                                           
			url  => 'http://(www.)scribd.com/*',                                                                                  
		},
		{                                                                                                                        
			name => '5min',                                                                                                              
			api  => 'http://api.5min.com/oembed.xml',                                                                           
			url  => 'http://www.5min.com/video/*',                                                                                  
		},
		{ 
			name => 'Blip.tv',                                                                                                              
			api  => 'http://blip.tv/oembed/', 
			url  => 'http://blip.tv/file/*', 
		},
		{ 
			name => 'DailyMotion',                                                                                                              
			api  => 'http://www.dailymotion.com/api/oembed', 
			url  => 'http://*dailymotion.com/*', 
		},
		{ 
			name => 'SmugMug',                                                                                                              
			api  => 'http://api.smugmug.com/services/oembed/', 
			url  => 'http://*smugmug.com/*', 
		},
		{ 
			name => 'Hulu',                                                                                                              
			api  => 'http://www.hulu.com/api/oembed.json', 
			url  => 'http://*hulu.com/watch/*', 
		},
		{ 
			name => 'PhotoBucket',                                                                                                              
			api  => 'http://photobucket.com/oembed', 
			url  => 'http://i*.photobucket.com/albums/* http://gi*.photobucket.com/groups/*', 
		},
		{ 
			name => 'WordPress.tv',                                                                                                              
			api  => 'http://wordpress.tv/oembed/', 
			url  => 'http://wordpress.tv/*', 
		},
		{ 
			name => 'PollDaddy.com',                                                                                                              
			api  => 'http://polldaddy.com/oembed/', 
			url  => 'http://*polldaddy.com/*', 
		},
		{ 
			name => 'FunnyOrDie.com',                                                                                                              
			api  => 'http://www.funnyordie.com/oembed', 
			url  => 'http://*funnyordie.com/videos/*', 
		},
		{ 
			name => 'Pownce',
			api  => 'http://api.pownce.com/2.1/oembed.json', 
			url  => 'http://*.pownce.com/*', 
		},
		{ 
			name => 'Poll Everywhere',                                                                                                              
			api  => 'http://www.polleverywhere.com/services/oembed/', 
			url  => 'http://www.polleverywhere.com/*polls/*', 
		},
		{ 
			name => 'My Opera',                                                                                                              
			api  => 'http://my.opera.com/service/oembed', 
			url  => 'http://my.opera.com/*', 
		},
		{ 
			name => 'Clearspring',                                                                                                              
			api  => 'http://widgets.clearspring.com/widget/v1/oembed/', 
			url  => 'http://www.clearspring.com/widgets/*',
		},
		{
			name => 'Embed.ly',
			api  =>
 'http://api.embed.ly/1/oembed?key=6f4159f0be0011e0aa814040d3dc5c07',
			url =>  'http://*/*',
		},
		{ 
			name => 'oohEmbed',                                                                                                              
			api  => 'http://oohembed.com/oohembed/', 
			url  => 'http://*.5min.com/Video/* http://*.amazon.(com|co.uk|de|ca|jp)/*/(gp/product|o/ASIN|obidos/ASIN|dp)/* http://*.blip.tv/* http://*.collegehumor.com/video:* http://*.thedailyshow.com/video/* http://*.dailymotion.com/* http://dotsub.com/view/* http://*.flickr.com/photos/* http://*.funnyordie.com/videos/* http://video.google.com/videoplay?* http://www.hulu.com/watch/* http://*.livejournal.com/ http://*.metacafe.com/watch/* http://*.nfb.ca/film/* http://*.phodroid.com/*/*/* http://qik.com/* http://*.revision3.com/* http://*.scribd.com/* http://*.slideshare.net/* http://*.twitpic.com/* http://(www.)twitter.com/*/statuses/* http://*.viddler.com/explore/* http://(www.)vimeo.com/* http://(www.)vimeo.com/groups/*/videos/* http://*.wikipedia.org/wiki/* http://*.wordpress.com/yyyy/mm/dd/* http://(*.)xkcd.com/*/ http://(www.)yfrog.(com|ru|com.tr|it|fr|co.il|co.uk|com.pl|pl|eu|us)/* http://*.youtube.com/watch*',
		},
	);
}

sub set_embedly_api_key {
	my ( $class, $api_key ) = @_;

	for ( @{ $class->providers } ) {
		if ( $_->{name} eq 'Embed.ly' ) {
			$_->{api} = 'http://api.embed.ly/1/oembed?key=' . $api_key
		}
	}
}

########################################################################

1;
