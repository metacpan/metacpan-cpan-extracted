###########################################
package XML::RSS::FromHTML::Simple;
use warnings;
use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::RSS;
use HTML::Entities qw(decode_entities);
use URI::URL ();
use HTTP::Date;
use DateTime;
use HTML::TreeBuilder;
use Log::Log4perl qw(:easy get_logger);
use Data::Dumper;
use Data::Hexdumper;
use Encode qw(is_utf8 _utf8_off);
use base qw(Class::Accessor);

our $VERSION = "0.05";

__PACKAGE__->mk_accessors($_) for qw(url html_file rss_file encoding 
                                     link_filter
                                     html title base_url ua error
                                     rss_attrs
                                    );

###########################################
sub make_rss {
###########################################
  my($self) = @_;

  $self->defaults_set();

  my $mtime;

    # Fetch URL
  if($self->url()) {

      INFO "Fetching URL ", $self->url();

      my $resp = $self->ua()->get($self->url());

      if($resp->is_error()) {
          ERROR "Fetching ", $self->url(), " failed (", $resp->message, ")";
          $self->error($self->url(), ": ", $resp->message);
          return undef;
      }

      if(get_logger()->is_debug()) {
          DEBUG byte_hexdump( "Result: " . $resp->decoded_content() );
      }
      $self->html( $resp->decoded_content() );

      DEBUG "HTML is ",
            is_utf8($self->html) ? "" : "*not* ",
            "utf8";

      my $http_time = 
                $resp->header('last-modified');
      DEBUG Dumper($resp->headers());

      if($http_time) {
          INFO "Last modified: $http_time";
          $mtime   = str2time($http_time);
      } else {
          ERROR "'Last modified' missing (using current time).";
          $mtime = time;
      }

  } elsif($self->html_file()) {
      LOGDIE "base_url required with HTML file" unless 
          defined $self->base_url();

      INFO "Reading HTML file ", $self->html_file();
      local $/ = undef;
      open FILE, "<", $self->html_file() or 
          LOGDIE "Cannot open ", $self->html_file();
      $self->html(scalar <FILE>);
      close FILE;
      $mtime = (stat($self->html_file))[9];
  } else {
      if(! $self->html()) {
           $self->error("No HTML found (use html_file or url)");
           return undef;
      }
  }

  my $isotime = DateTime->from_epoch(
                              epoch => $mtime);
  DEBUG "Last modified: $isotime";

  my $rss = XML::RSS->new(
    encoding => $self->encoding()
  );

  $rss->channel(
    title => $self->title(),
    link  => $self->url(),
    dc    => { date => $isotime . "Z"},
  );

  $self->base_url( $self->url() ) unless $self->base_url();

  foreach(exlinks($self->html(), $self->base_url())) {

    my($lurl, $text) = @$_;
      
    $text = decode_entities($text);

    $self->rss_attrs({});

    if($self->link_filter()->($lurl, $text, $self)) {
      INFO "Adding rss entry: $text $lurl";
      if(get_logger()->is_debug()) {
          DEBUG byte_hexdump("TEXT=" . $text);
          DEBUG byte_hexdump("URL=" . $lurl);
      }
      $rss->add_item(
        title => $text,
        link  => $lurl,
        %{ $self->rss_attrs() },
      );
    }
  }

  INFO "Saving output in ", $self->rss_file();
  $rss->save($self->rss_file()) or 
      die "Cannot write to ", $self->rss_file();
}

###########################################
sub exlinks {
###########################################
  my($html, $base_url) = @_;

  DEBUG "Extracting links from HTML base=$base_url", 

  my @links = ();

  my $tree = HTML::TreeBuilder->new();

  $tree->parse($html) or return ();

  for(@{$tree->extract_links('a')}) {
      my($link, $element, $attr, 
         $tag) = @$_;
    
      next unless $attr eq "href";

      my $uri = URI->new_abs($link, 
                             $base_url);
      next unless 
        length $element->as_trimmed_text();

      push @links, 
           [URI->new_abs($link, $base_url),
            $element->as_trimmed_text()];
    }

    return @links;
}


###########################################
sub defaults_set {
###########################################
    my($self) = @_;
   
    $self->url( "" ) unless defined $self->{url};
    $self->html_file( "" ) unless defined $self->{html_file};
    $self->rss_file( "out.xml" ) unless defined $self->{rss_file};
    $self->encoding( "utf-8" ) unless $self->{encoding};
    $self->link_filter( sub { 1 } ) unless defined $self->{link_filter};
    $self->html( "" ) unless defined $self->{html};
    $self->title( "No Title" ) unless defined $self->{title};
    $self->base_url( "" ) unless defined $self->{base_url};
    $self->ua( LWP::UserAgent->new() ) unless defined $self->{ua};
}

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    DEBUG "Making accessor $name for package $package";

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;

            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

###########################################
sub byte_hexdump {
###########################################
    my($string) = @_;

    my $flag = "UTF8 OFF";

    if(is_utf8($string)) {
        $flag = "UTF8 ON";
    }

    _utf8_off($string);

    return "$flag ", hexdump(data => $string);
}

1;

__END__

=head1 NAME

XML::RSS::FromHTML::Simple - Create RSS feeds for sites that don't offer them

=head1 SYNOPSIS

    use XML::RSS::FromHTML::Simple;

    my $proc = XML::RSS::FromHTML::Simple->new({
        title    => "My new cool RSS feed",
        url      => "http://perlmeister.com/art_eng.html",
        rss_file => "new_articles.xml",
    });

    $proc->link_filter( sub {
        my($link, $text) = @_;

            # Only extract links that contain 'linux-magazine'
            # in their URL
        if( $link =~ m#linux-magazine#) {
            return 1;
        } else {
            return 0;
        }
    });

        # Create RSS file
    $proc->make_rss() or die $proc->error();

=head1 ABSTRACT

This module helps creating RSS feeds for sites that don't have them.
It examines HTML documents, extracts their links and puts them and
their textual descriptions into an RSS file.

=head1 DESCRIPTION

C<XML::RSS::FromHTML::Simple> helps reeling in web pages and 
creating RSS files from them.
Typically, it is used with websites that are displaying news 
content in HTML, but aren't providing RSS files of their own.
RSS files are typically used to track the content on frequently 
changing news websites and to provide a way for other programs to figure
out if new news have arrived.

To create a new RSS generator, call C<new()>: 

    use XML::RSS::FromHTML::Simple;

    my $f = XML::RSS::FromHTML::Simple->new({
        title    => "My new cool RSS",
        url      => "http://perlmeister.com/art_eng.html",
        rss_file => $outfile,
    });

C<url> is the URL to a site whichs content you'd like to track. 
C<title> is an optional feed title which will show up later in the
newly created RSS. C<rss_file> is the name of the resulting RSS file,
it defaults to C<out.xml>.

Instead of reeling in a document via HTTP, you can just as well
use a local file:

    my $f = XML::RSS::FromHTML::Simple->new({
        html_file => "art_eng.html",
        base_url  => "http://perlmeister.com",
        rss_file  => "perlnews.xml",
    });

Note that in this case, a C<base_url> is necessary to allow the
generator to put fully qualified URLs into the RSS file later.

C<XML::RSS::FromHTML::Simple> creates accessor functions for all
of its attributes. Therefore, you could just as well create a boilerplate
object and set its properties afterwards:

    my $f = XML::RSS::FromHTML::Simple->new();
    $f->html_file("art_eng.html");
    $f->base_url("http://perlmeister.com");
    $f->rss_file("perlnews.xml");

Typically, not all links embedded in the HTML document should be
copied to the resulting RSS file. The C<link_filter()> attribute
takes a subroutine reference, which decides for each URL whether to 
process it or ignore it:

    $f->link_filter( sub {
        my($url, $text) = @_;

        if($url =~ m#linux-magazine\.com/#) {
            return 1;
        } else {
            return 0;
        }
    });

The C<link_filter> subroutine gets called with each URL and its link text,
as found in the HTML content. If C<link_filter> returns 1, the link will
be added to the RSS file. If C<link_filter> returns 0, the link will
be ignored.

To start the RSS generator, run

    $f->make_rss() or die $f->error();

which will generate the RSS file. If anything goes wrong, C<make_rss()>
returns false and the C<error()> method will tell why it failed.

In addition to decide if the Link is RSS-worthy,
the filter may also change the value of the URL, the corresponding
link text or any other RSS fields. The third argument passed to 
C<link_filter> by the processor is the processor object itself,
which offers a C<rss_attrs()> method to set additional values
or modify the link text or the link itself:

    $f->link_filter( sub {
        my($url, $text, $processor) = @_;

        if($url =~ m#linux-magazine\.com/#) {
            $processor->rss_attrs({ 
                description => "This is cool stuff",
                link        => 'http://link.here.instead.com',
                title       => 'New Link Text',
            });
            return 1;
        } else {
            return 0;
        }
    });

=head2 UTF-8 Woes

C<XML::RSS::FromHTML::Simple> has been designed to handle UTF-8
encoded web pages well, but there are a few gotchas you should be
aware of.

If the C<LWP::UserAgent> used by C<XML::RSS::FromHTML::Simple> detects
that a web page is utf-8-encoded, it will return its content
in utf-8 encoded strings via the C<decoded_content()> method.

This means that if you filter on this content, you need to use
utf-8 strings for comparisons, and if you specify strings or
regexes literally in your code in utf-8, you'll have to make
sure that the C<use utf8> pragma is set (unless, by the time
you're reading this, we have the year 2038 and all source code gets 
written in utf8 by default).

Also make sure that your regexes
handle non-ascii characters which might occur in those strings. 
Simon Cozen's "Advanced Perl
Programming" has an excellent chapter on how to tackle some of 
these problems correctly.

Secondly,
the current version of LWP has an issue with pages that have 
UTF-8-encoded data in the I<HEAD> section. It will print a warning
like

   Parsing of undecoded UTF-8 will give garbage when decoding entities
   at .../LWP/Protocol.pm line 114.

which can be worked around by setting

    my $ua = LWP::UserAgent->new(parse_head => 0);

and providing this resilient user agent to the C<XML::RSS::FromHTML::Simple>
constructor:

    my $f = XML::RSS::FromHTML::Simple->new({
        url      => "...",
        rss_file => "...",
        ua       => $ua,
    });

Note that this relies on the web server sending a header like

    Content-Type: text/html; charset=utf-8' 

or the resulting string won't have the utf-8 bit set.

Details on this problem are available at

    http://www.nntp.perl.org/group/perl.libwww/2007/02/msg6965.html
    http://www.nntp.perl.org/group/perl.libwww/2006/08/msg6801.html

in the libwww mailing list archive.

=head2 DEBUGGING

C<XML::RSS::FromHTML::Simple> is C<Log::Log4perl>-enabled, to figure
out what's going on under the hood, simply call

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

before using C<XML::RSS::FromHTML::Simple>. For details on Log4perl,
check the http://log4perl.sourceforge.net website.

=head2 HISTORY

This module has been inspired by Sean Burke's article in TPJ 11/2002.
I've discussed its code in the 02/2005 issue of Linux Magazine:

    http://www.linux-magazine.com/issue/51/Perl_Collecting_News_Headlines.pdf

There's also XML::RSS::FromHTML on CPAN, which looks like it's offering
a more powerful API. The focus of XML::RSS::FromHTML::Simple, on the other
hand, is simplicity.

=head1 LEGALESE

This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <m@perlmeister.com>
