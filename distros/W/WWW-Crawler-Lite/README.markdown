# NAME

WWW::Crawler::Lite - A single-threaded crawler/spider for the web.

# SYNOPSIS

    my %pages = ( );
    my $pattern = 'https?://example\.com\/';
    my %links = ( );
    my $downloaded = 0;

    my $crawler;
    $crawler = WWW::Crawler::Lite->new(
      agent       => 'MySuperBot/1.0',
      url_pattern => $pattern,
      http_accept => [qw( text/plain text/html application/xhtml+xml )],
      link_parser => 'default',
      on_response => sub {
        my ($url, $res) = @_;

      warn "$url contains " . $res->content;
      $downloaded++;
      $crawler->stop() if $downloaded++ > 5;
    },
    follow_ok   => sub {
      my ($url) = @_;
      # If you like this url and want to use it, then return a true value:
      return 1;
    },
    on_link     => sub {
      my ($from, $to, $text) = @_;

      return if exists($pages{$to}) && $pages{$to} eq 'BAD';
      $pages{$to}++;
      $links{$to} ||= [ ];
      push @{$links{$to}}, { from => $from, text => $text };
    },
    on_bad_url => sub {
      my ($url) = @_;

        # Mark this url as 'bad':
        $pages{$url} = 'BAD';
      }
    );
    $crawler->crawl( url => "http://example.com/" );

    warn "DONE!!!!!";

    use Data::Dumper;
    map {
      warn "$_ ($pages{$_} incoming links) -> " . Dumper($links{$_})
    } sort keys %links;

# DESCRIPTION

`WWW::Crawler::Lite` is a single-threaded spider/crawler for the web.  It can
be used within a mod_perl, CGI or Catalyst-style environment because it does not
fork or use threads.

The callback-based interface is fast and simple, allowing you to focus on simply
processing the data that `WWW::Crawler::Lite` extracts from the target website.

# PUBLIC METHODS

## new( %args )

Creates and returns a new `WWW::Crawler::Lite` object.

The `%args` hash is not required, but may contain the following elements:

- agent - String

Used as the user-agent string for HTTP requests.

__Default Value:__ - `WWW-Crawler-Lite/$VERSION $^O`

- url_pattern - RegExp or String

New links that do not match this pattern will not be added to the processing queue.

__Default Value:__ `https?://.+`

- http_accept - ArrayRef

This can be used to filter out unwanted responses.

- link_parser - String

Valid values: '`default`' and '`HTML::LinkExtor`'

The default value is '`default`' which uses a naive regexp to do the link parsing.

The upshot of using '`default`' is that the regexp will also find the hyperlinked 
text or alt-text (of a hyperlinked img tag) and give that to your '`on_link`' handler.

__Default Value:__ `[qw( text/html text/plain application/xhtml+xml )]`

- on_response($url, $response) - CodeRef

Called whenever a successful response is returned.

- on_link($from, $to, $text) - CodeRef

Called whenever a new link is found.  Arguments are:

    - $from

    The URL that is linked *from*

    - $to

    The URL that is linked *to*

    - $text

    The anchor text (eg: The HTML within the link - <a href="...">__This Text Here__</a>)

- on_bad_url($url) - CodeRef

Called whenever an unsuccessful response is received.

- delay_seconds - Number

Indicates the length of time (in seconds) that the crawler should pause before making
each request.  This can be useful when you want to spider a website, not launch
a denial of service attack on it.

## stop( )

Causes the crawler to stop processing its queue of URLs.

# AUTHOR

John Drago <jdrago_999@yahoo.com>

# COPYRIGHT

This software is Free software and may be used and redistributed under the same
terms as perl itself.