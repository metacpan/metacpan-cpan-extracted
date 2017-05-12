package WebSource::XMLSender;

use strict;
use LWP::UserAgent;
use HTTP::Request;
use WebSource::Module;
use Carp;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::XMLSender : XML sending module
 Sends incoming XML data to the server and returns the XML response
 
=head1 DESCRIPTION

An xmlsend operator is declared with the following format :

  <ws:xmlsend name="opname" forward-to="ops"
  	 url="http://example.com/location"
  	 metho="POST" />


=head1 SYNOPSIS

  $xmlsender = WebSource::XMLSender->new(wsnode => $node);

  # for the rest it works as a WebSource::Module

=head1 METHODS

=over 2

=item B<< $source = WebSource->new(desc => $node); >>

Create a new XMLSender;

=cut

sub _init_ {
  my $self = shift;
  $self->log(6,"Default method set to '",$self->{method},"'");
  $self->SUPER::_init_;
  $self->{useragent}      or $self->{useragent} =
    LWP::UserAgent->new(
			agent => "WebSource/1.0",
			keep_alive => 1,
			timeout => 20,
            env_proxy => 1,
    );
  $self->{maxreqinterval} or $self->{maxreqinterval} = 3;
  $self->{maxtries}       or $self->{maxtries} = 3;
  my $wsd = $self->{wsdnode};
  if($wsd) {
    $self->{url} = $wsd->getAttribute("url");
    $self->{method} = $wsd->getAttribute("method");
  } 
  $self->{method}         or $self->{method} = 'POST';
}

=item B<< $xmlsender->handle($env); >>

Builds an HTTP::Request with the XMLSender's using the input XML document
and sends it to the url configured in the source description file

=cut

sub handle {
  my $self = shift;
  my $data = shift;
  my $headers = HTTP::Headers->new(Content_Type => "text/xml");
  $headers->content_encoding('utf-8');
  my $request = HTTP::Request->new(
  	$self->{method},
  	$self->{url},
  	$headers,
  	$data->dataXML(wantdoc => 1)
  );

  $self->log(3,"Posting request\n",
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

    my $base = $response->request->uri;
    my %meta = %$data;
    $self->log(6,"Meta data is as follows :\n",
         map{ $_ . " => " . $meta{$_} ."\n" } keys(%meta)
    );
    $response->headers->scan(sub { my ($h,$v) = @_; $meta{$h} = $v; });
    $meta{encoding} = $response->content_encoding;
    $meta{type} = "text/xml";
    $meta{baseuri} = $base;
    $meta{data}    = $response->content;
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
