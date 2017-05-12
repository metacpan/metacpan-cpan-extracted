#!/usr/bin/perl
#   $Id: example-5.pl 56 2008-06-23 16:54:31Z adam $

=head1 NAME

Example-5 - A complete web server based RSS-client

=head2 Example 5

The following example is a complete web server based RSS-Client. The XSL stylesheet from the previous
example should work perfectly for the example to function. The example is slightly larger, so it has
been broken down into smaller logical units. The listing here works well as either an C<Apache::Registry> 
or a plain CGI application. The example also includes server side data caching - for simple low volume usage,
something that a dedicated caching-proxy is better able to provide in high volume use.

=head3 1: Main core of application

The typical Perl pragma and CGI modules are loaded. The C<Cache::FileCache> module is loaded to provide
light-weight data caching. The hash C<%config> stores configuration data, this data could easily be
loaded in from one of the many configuration file modules.

=cut

	use strict;
	use warnings;
	use CGI;
	use CGI::Carp;
	use XML::RSS::Tools;
	use Cache::FileCache;

		$|++;
		my $q = CGI->new;
		my %config= (
			xsl_path => '/usr/local/apache/cgi-bin/',
			css1     => '/style/style.css',
			css2     => '/style/news-style.css',
			title    => 'i r e d a l e consulting | News Feeds |',
			language => 'en-GB',
			namespace=> 'xhtml',
			cache_depth    => 1,
			auto_purge     => '+2h',
			default_expire => '+1h',
			cache_root     => '/tmp/FileCache/news');
		my $input = process_params($q);
		top_html($q, $input, \%config);
		tad ("Usage: news2html.pl?site=uri;style=xsl[;cache=off | ;debug=on]\n", $q)
			unless $input->{uri} & $input->{xsl};
		my ($cache, $cache_key, $data) = manage_cache($q, $input, \%config);
		$data = process_rss_feed($q, $input, \%config) unless $data;
		print $data;
		end_fragment($q, $input);
		$cache->set($cache_key, $data) if $cache;
		%ENV = ();
		exit;

=head3 2: Processing Input parameters

The input parameters are extracted using C<CGI.pm> and
returned as a reference to a hash.

=cut

	sub process_params {
		my $q = shift;
		my %p;
		$p{uri}  = $q->param("site") if $q->param("site");
		$p{xsl}  = $q->param("style") if $q->param("style");
		$p{debug}= $q->param("debug") if $q->param("debug");
		$p{cache_status} = lc($q->param("cache")) || "on";
		return \%p;
	}

=head3 3: Sending the HTTP headers and starting the HTML

The normal HTTP headers and the top of the HTML is sent to the browser using C<CGI>. Should
any error occur now, the browser should get a message, rather than a 500 error.

=cut

	sub top_html {
		my $q     = shift;
		my $input = shift;
		my $config= shift;
		$input->{uri} = "No Site URI" unless $input->{uri};
		$input->{xsl} = "No XSL stylesheet" unless $input->{xsl};
		print $q->header(-type      => "text/html",
		                 -expires   => $config->{default_expire}),
		      $q->start_html(-title => $config->{title} . " " . $input->{uri} . " and " . $input->{xsl},
		                     -lang  => $config->{language}, 
		                     -style => {-src => $config->{css1},
		                     	        -verbatim => '@import url(' . $config->{css2} . ');'}
		);
		print $q->comment("\nInput Conditions:\nURI: ", $input->{uri},
		                              "\nxsl sheet: ", $input->{xsl},
		                              "\nCache:     ", $input->{cache_status}, "\n") if $input->{debug}; 
	};

=head3 4: Creating the Cache object

A cache key is created from the RSS feed URI and the name of the XSL stylesheet.
A C<FileCache> object is created. If the user requested an uncached object then the cache object and key
are returned and any data stored against the cache key is removed from the cache. If the user did not request
new data, then the cache is queried for data, and if any is found it is returned along with the cache object
and key, otherwise only the cache key and object are returned.

=cut

	sub manage_cache {
		my $q      = shift;
		my $input  = shift;
		my $config = shift;
		my $cache_key = $input->{uri} . $input->{xsl};
		my $cached_file;
		my $c_handle = Cache::FileCache->new(
			{namespace   => $config->{namespace},
			 default_expires_in  => $config->{default_expire},
			 auto_purge_interval => $config->{auto_purge},
			 cache_depth         => $config->{cache_depth},
			 cache_root          => $config->{cache_root},
			 auto_purge_on_set   => 1
			} ) || tad ("Unable to create Cache object", $q);
		if ($input->{cache_status} eq "off") {
			$c_handle->remove($cache_key);
		} else {
			$cached_file = $c_handle->get($cache_key);
			$cached_file .= "\n<!-- Cached Fragment -->\n" if $cached_file &amp;&amp; $input->{debug};
		}
		return $c_handle, $cache_key, $cached_file;
	}

=head3 5: Processing the RSS Feed

A C<XML::RSS::Tools> object is created. It is configured for no conversion, and to use the HTTP
client C<HTTP::Lite>. The XSL stylesheet is loaded first, then the URI of the RSS feed is passed
to the object. Finally transformation is performed, and the resultant XHTML returned. If any process
fails then a fatal error is raised via the C<tad> Terminate And Die method.

=cut

	sub process_rss_feed{
		my $q      = shift;
		my $input  = shift;
		my $config = shift;
		my $rss = XML::RSS::Tools->new;
		$rss->set_version(0);
		$rss->set_http_client("lite");		# HTTP::GHTTP does not work on Windows/mod_Perl
		if (! $rss->xsl_file($config->{xsl_path} . $input->{xsl})) {tad ($rss->as_string('error'), $q)};
		print $q->comment("\nHTTP Client: " . $rss->get_http_client . "\n") if $input->{debug};
		if (! $rss->rss_uri($input->{uri})) {tad ($rss->as_string('error'), $q)};
		if ($rss->transform) {
			return $rss->as_string;
		} else {
			tad ($rss->as_string('error'), $q);
		}
	}

=head3 6: End the HTML

C<CGI.pm> is used to build the bottom of the page, and generate some
navigation buttons. Note the http://www.mozilla.org/ a C<view-source> URI prefix,
you may need to remove this if your browser cannot support this construct.

=cut

	sub end_fragment {
		my $q     = shift;
		my $input = shift;
		my $ref   = $q->referer() || "";
		my $self  = $q->self_url;
		print $q->hr, $q->start_div({-id => "navigation"});
		print $q->a({
			-href  => $ref,
			-title => "Click to Go Back"}, "Go Back"), " " if $ref;
		print $q->a({
			-href  => "view-source: " . $input->{uri},
			-title => "Click to See Source RSS Feed (Opens a New Window)",
			-target=> "_blank"}, "View RSS"), " ",
		      $q->a({
			-href  => "view-source:$self",
			-title => "View HTML Page Source"}, "View HTML"), " ";
		$self  .= ";cache=off" unless $self =~ /cache=off/;
		print $q->a({
			-href  => "$self",
			-title => "Reload RSS Feed From Source"}, "Refresh Feed"),
		      $q->end_div, $q->end_html;
	}

=head3 7: Something went wrong, report the error and clean up

In listing B<7>, is a generic failure handler. Any error condition is reported by C<CGI::Carp> to the server
error logs, a helpful message is sent to the user, and the C<%ENV>
hash is cleaned up.

=cut

	sub tad {
		my $error = shift || "Unknown Error";
		my $q     = shift;
		warn $error;
		print $q->hr, $q->h1("News 2 HTML Error:"), $q->h2($error), $q->hr, $q->end_html;
		%ENV = ();
		exit;
	}

=head2 See Also

L<CGI>, L<Apache::Registry>, L<Cache::FileCache>, L<CGI::Carp>, L<HTTP::Lite>

=cut
