package Fitnesse::Fixtures::PageDriver;

use strict;
use warnings;

use Encode qw(decode encode_utf8 FB_DEFAULT);
use HTTP::Tiny;
use HTML::Entities qw(decode_entities);
use Fitnesse::Fixtures::ResponseContext;

sub new {
  my($class,$options) = @_;
  $options ||= {};
  bless {
    base_url => $options->{base_url}
      || $ENV{TEST_SLIM_FITNESSE_URL}
      || "http://127.0.0.1:8080",
    http => $options->{http} || HTTP::Tiny->new(timeout => 120),
    response => undef,
  } => $class;
}

sub create_page_with_content {
  my($self,$pagename,$content) = @_;
  $self->_post($pagename, {
    responder => "saveData",
    editTime => "9999999999999",
    ticketId => "321",
    pageContent => defined($content) ? $content : "",
  });
  return;
}

sub make_a_test_page {
  my($self,$pagename) = @_;
  $self->_make_page_type($pagename, "Test");
  return;
}

sub make_a_suite_page {
  my($self,$pagename) = @_;
  $self->_make_page_type($pagename, "Suite");
  return;
}

sub _make_page_type {
  my($self,$pagename,$type) = @_;
  $self->_post($pagename, {
    responder => "saveProperties",
    PageType => $type,
  });
}

sub request_page {
  my($self,$pagename) = @_;
  my $response = $self->_request("GET", $pagename);
  return $response->{status};
}

sub content {
  my($self) = @_;
  $self->_content;
}

sub content_contains {
  my($self,$str) = @_;
  index($self->_decoded_content, $str) >= 0 ? "true" : "false";
}

sub content_matches {
  my($self,$pattern) = @_;
  my $regex = eval { qr/$pattern/s };
  die "invalid content pattern: $@" if $@;
  $self->_decoded_content =~ $regex ? "true" : "false";
}

sub line_number_containing {
  my($self,$text) = @_;
  my $content = $self->_content;
  my $position = index($content, $text);
  return -1 if $position < 0;
  my $prior = substr($content, 0, $position);
  my @lines = split /\n/, $prior;
  return @lines || 1;
}

sub _post {
  my($self,$page,$fields) = @_;
  my $response = $self->_request("POST", $page, $fields);
  return $response->{status};
}

sub _request {
  my($self,$method,$uri,$fields) = @_;
  my($path,$query) = split /\?/, ($uri // ""), 2;
  $path =~ s{^/+}{};
  $path = join ".", map { _escape_path($_) } split m{/}, $path;
  my $url = $self->{base_url};
  $url =~ s{/+$}{};
  $url .= "/$path";
  $url .= "?$query" if defined $query;

  my $response = eval {
    $method eq "POST"
      ? $self->{http}->post_form($url, $fields)
      : $self->{http}->get($url);
  };
  if (!$response) {
    my $error = $@ || "HTTP client returned no response";
    $response = { status => 599, reason => $error, content => $error };
  }
  $self->{response} = $response;
  Fitnesse::Fixtures::ResponseContext->store($response);
  die "FitNesse HTTP request failed: $response->{reason}"
    if $response->{status} == 599;
  return $response;
}

sub _escape_path {
  my($value) = @_;
  my $bytes = encode_utf8($value);
  $bytes =~ s/([^A-Za-z0-9_.~-])/sprintf("%%%02X", ord($1))/ge;
  return $bytes;
}

sub _content {
  my($self) = @_;
  die "no FitNesse response is available" unless $self->{response};
  my $content = $self->{response}->{content} // "";
  return $content if utf8::is_utf8($content);
  return decode("UTF-8", $content, FB_DEFAULT);
}

sub _decoded_content {
  decode_entities($_[0]->_content);
}

1;
