package URI::Title;

use 5.006;
use warnings;
use strict;

use base qw(Exporter);
our @EXPORT_OK = qw( title );

our $VERSION;

use Module::Pluggable (search_path => ['URI::Title'], require => 1 );
use File::Type;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;


sub _ua {
  my $ua = LWP::UserAgent->new;
  $ua->agent("URI::Title/$VERSION");
  $ua->timeout(20);
  $ua->default_header('Accept-Encoding' => 'gzip');
  return $ua;
}

sub _get_limited {
  my $url = shift;
  my $size = shift || 32*1024;
  my $ua = _ua();
  $ua->max_size($size);
  my $req = HTTP::Request->new(GET => $url);
  $req->header( Range => "bytes=0-$size" );
  $req->header( "Accept-Encoding" => "" ); # vox sends invalid gzipped data?
  my $res = eval { $ua->request($req) };
  return unless $res; # useragent explodes for non-valid uris

  # some servers don't like the Range header. If we
  # get an odd 4xx response that isn't 404, just try getting
  # the full thing. This may be a little impolite.
  return _get_all($url) if $res->code >= 400 and $res->code < 500 and $res->code != 404;
  return unless $res->is_success;
  if (!wantarray) {
    return $res->decoded_content || $res->content;
  }
  my $cset = "iso-8859-1"; # default;
  my $ct = $res->header("Content-type");
  if ($ct =~ /charset\s*=\>?\s*\"?([\w-]+)/i) {
    $cset = lc($1);
    #warn "Got charset $cset from URI headers\n";
  }
  return ($res->decoded_content || $res->content, $cset);
}

sub _get_end {
  my $url = shift;
  my $size = shift || 16*1024;

  my $ua = _ua();

  my $request = HTTP::Request->new(HEAD => $url);
  my $response = $ua->request($request);
  return unless $response; # useragent explodes for non-valid uris
  my $length = $response->header('Content-Length');

  return unless $length; # We can't get the length, and we're _not_
                         # going to get the whole thing.

  my $start = $length - $size;

  $ua->max_size($size);

  my $req = HTTP::Request->new(GET => $url);
  $req->header( Range => "bytes=$start-$length" );
  my $res = $ua->request($req);
  return unless $res; # useragent explodes for non-valid uris

  return unless $res->is_success;
  return $res->decoded_content unless wantarray;
  my $cset = "iso-8859-1"; # default;
  my $ct = $res->header("Content-type");
  if ($ct =~ /charset=\"?(.*)\"?$/) {
    $cset = $1;
  }
  return ($res->decoded_content, $cset);
}

sub _get_all {
  my $url = shift;
  my $ua = _ua();
  my $req = HTTP::Request->new(GET => $url);
  my $res = $ua->request($req);
  return unless $res->is_success;
  return $res->decoded_content unless wantarray;
  my $cset = "iso-8859-1"; # default;
  my $ct = $res->header("Content-type");
  if ($ct =~ /charset=\"?(.*)\"?$/) {
    $cset = $1;
  }
  return ($res->decoded_content, $cset);
}

# cache
our $HANDLERS;
sub _handlers {
  my @plugins = plugins();
  return $HANDLERS if $HANDLERS;
  for my $plugin (@plugins) {
    for my $type ($plugin->types) {
      $HANDLERS->{$type} = $plugin;
    }
  }
  return $HANDLERS;
}

sub title {
  my $param = shift;
  my $data;
  my $url;
  my $type;
  my $cset = "iso-8859-1"; # default

  # we can be passed a hashref. Keys are url, or data.  
  if (ref($param)) {
    if ($param->{data}) {
      $data = $param->{data};
      $data = $$data if ref($data); # we can be passed a ref to the data
    } elsif ($param->{url}) {
      $url = $param->{url};
    } else {
      use Carp qw(croak);
      croak("Expected a single parameter, or an 'url' or 'data' key");
    }

  # otherwise, assume we're passed an url
  } else {
    $url = $param;
  }

  if (!$url and !$data) {
    warn "Need at least an url or data";
    return;
  }

  # If we don't have data, we will have an url, so try to get data.
  if (!$data) {
    # url might be a filename
    if (-e $url) {
      local $/ = undef;
      unless (open DATA, $url) {
        warn "$url looks like a file and isn't";
        return;
      }
      $data = <DATA>;
      close DATA;
      
    # If not, assume it's an url
    } else {
      # special case for itms
      if ($url =~ s/^itms:/http:/) {
        $type = "itms";
        $data = 1; # we don't need it, fake it.

      } else {
        # special case for spotify
        $url =~ s{^(?:http://open.spotify.com/|spotify:)(\w+)[:/]}{http://spotify.url.fi/$1/};
        
        $url =~ s{#!}{?_escaped_fragment_=};

        ($data, $cset) = _get_limited($url);
      }
    }
  }
  if (!$data) {
    #warn "Can't get content for $url";
    return;
  }

  return undef unless $data;

  $type ||= File::Type->new->checktype_contents($data);

  my $handlers = _handlers();
  my $handler = $handlers->{$type} || $handlers->{default}
    or return;

  return $handler->title($url, $data, $type, $cset);
}

1;

__END__

=head1 NAME

URI::Title - get the titles of things on the web in a sensible way

=head1 SYNOPSIS

  use URI::Title qw( title );
  my $title = title('http://microsoft.com');
  print "Title is $title\n";

=head1 DESCRIPTION

I keep having to find the title of things on the web. This seems like a really
simple request, just get() the object, parse for a title tag, you're done. Ha,
I wish. There are several problems with this approach:

=over 4

=item What if the resource is on a very slow server? Do we wait for ever or what?

=item What if the resource is a 900 gig file? You don't want to download that.

=item What if the page title isn't in a title tag, but is buried in the HTML somewhere?

=item What if the resource is an MP3 file, or a word document or something?

=item ...

=back

So, let's solve these issues once.

=head1 METHODS

only one, the title(url) method. Call it with an url, get the title if possible,
undef if it wasn't. Very simple.

=head1 TODO

Many, many, many things. Still unimplemented:

=over 4

=item Get titles of MP3 files, Word Docs, PDFs, etc.

=item Configurable.. well, anything, in fact. Timeout would be a good start.

=item Better error reporting.

=back

=head1 AUTHORS

Tom Insam E<lt>tom@jerakeen.orgE<gt>, original author, 2004-2012.

Philippe Bruhat (BooK) E<lt>book@cpan.orgE<gt>, maintainer, 2014.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 CREDITS

Invented because of a conversation with rjp, who contributed some eyeball-melting and
as-yet-unused code to get titles from MP3s and PDFs, and hex, who has also solved the
problem, and got bits done in a nicer way than I did.

=cut
