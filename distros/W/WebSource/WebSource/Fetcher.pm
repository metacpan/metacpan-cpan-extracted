package WebSource::Fetcher;

use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use WebSource::Module;
use Carp;
eval "use Net::INET6Glue::INET_is_INET6"; # use Net::INET6Glue::INET_is_INET6 when available

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Fetcher : fetching module
  When run downloads given urls and returns the corresponding http response
 
=head1 DESCRIPTION

A fetch operator is declared with the following format :

  <ws:fetch name="opname" forward-to="ops" />


=head1 SYNOPSIS

  $fetcher = WebSource::Fetcher->new(wsnode => $node);

  # for the rest it works as a WebSource::Module

=head1 METHODS

=over 2

=item B<< $source = WebSource->new(desc => $node); >>

Create a new Fetcher;

=cut

sub _init_ {
  my $self = shift;
  $self->{method}         or $self->{method} = 'GET';
  $self->log(6,"Default method set to '",$self->{method},"'");
  $self->SUPER::_init_;
  $self->{useragent}      or $self->{useragent} =
    LWP::UserAgent->new(
			agent => "WebSource/1.0",
			keep_alive => 1,
			timeout => 20,
                        env_proxy => 0,
		       );
  if($self->{cookies}) {
    $self->log(5,"Got cookie jar : ",$self->{cookies});
  } else {
    $self->log(5,"Creating new cookie jar");
    $self->{cookies} = HTTP::Cookies->new;
  }
  $self->{maxreqinterval} or $self->{maxreqinterval} = 3;
  $self->{maxtries}       or $self->{maxtries} = 3;
}

sub makeRequest {
  my $self = shift;
  my $env = shift;
  if($env->type eq "object/http-request") {
    return $env->data;
  }
  my $str = $env->dataString;
  my $uri = $env->{baseuri} ?
            URI->new_abs($str,$env->{baseuri}) :
            URI->new($str);
  if($uri) {
    $self->log(6,"Generating HTTP::Request for $uri with method '",$self->{method},"'");
    return HTTP::Request->new($self->{method},$uri);
  }
  return undef;
}

=item B<< $fetcher->handle($env); >>

Builds an HTTP::Request from the data in enveloppe, fetches
the URI (eventually stores it in a file) and builds
the corresponding DOM object

=cut

sub handle {
  my $self = shift;
  my $data = shift;
#  my $request = $self->makeRequest($data);
  my $request = $data->dataAsHttpRequest;
  if(!$request) {
    $self->log(1,"Couldn't convert to HTTP::Request");
    return ();
  }
  my $scheme = $request->uri->scheme;
  if(!($scheme eq "http" || $scheme eq "ftp" || $scheme eq "https" || $scheme eq "file")) {
    $self->log(1,"Can't fetch scheme ",$scheme);
    return ();
  } 
  $self->log(5,"Handling request \n",$request->as_string);
#  $self->{cookies}->add_cookie_header($request);
  $self->log(3, "Posting request\n",
    "-------------------\n",
    $request->as_string,
    "-------------------");
  my $tries = $self->{maxtries};
  $tries > 0 or $tries = 1; 
  my $response;
  while($tries > 0) {
    $self->temporize();
    $self->log(5, "Try ",  $self->{maxtries} - $tries + 1, " / ", $self->{maxtries});
    $response = $self->{useragent}->request($request);;
    $tries = $response->is_success ? 0 : $tries - 1;
    ($response->code eq "500" && $response->message =~ m/SIGINT/) 
      and die($response->message);
    $self->log(5, "Response status : ",$response->status_line);
  }
  if($response->is_success) {
    $self->log(1, "success");
#    $self->{cookies}->extract_cookies($response);

    my $base = $response->request->uri;
    my %meta = %$data;
    $self->log(6,"Meta data is as follows :\n",
         map{ $_ . " => " . $meta{$_} ."\n" } keys(%meta)
    );
    $self->log(3,$response->headers->as_string());
    $response->headers->scan(sub { my ($h,$v) = @_; $meta{$h} = $v; });
    if($meta{'Content-Type'}) {
      $self->log(2,"Parsing Content-Type: ".$meta{'Content-Type'});
      
      if($meta{'Content-Type'} =~ m/([A-Za-z0-9\/\-]+)(?:;\s+charset=([a-zA-Z0-9\-]+))?/) {
        $meta{type} = $1;
        $meta{encoding} = $2;
      }
    }
#    $meta{encoding} = $response->content_encoding;
#    $meta{type} = $response->content_type;
    $meta{baseuri} = $base;
    $meta{data}    = $response->content;
    $self->log(2,"Content-Encoding: ".$meta{encoding});
    return WebSource::Envelope->new(%meta);
  } else {
    if ($response->{request}) {
      $self->log(1, "WebSource : couldn't fetch ",
            $request->uri, " received ",
            $response->{request}->status_line);
    } else {
      $self->log(1, $response->message);
    }
  }
  return ();
}

sub temporize {
  my $self = shift;
  my $sleep = 0;

  if($self->{lastrequest}) {
    my $dist = time() - $self->{lastrequest};
    $sleep = $self->{minreqinterval} - $dist;
  }
  if ($sleep > 0) {
    $self->log(3, "WebSource : temporizing : waiting ", $sleep, " seconds");
    sleep($sleep);
  }
  $self->{lastrequest} = time();
}

=back

=head1 SEE ALSO

WebSource::Module

=cut

1;
