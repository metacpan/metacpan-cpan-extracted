package Test::Rest::Context;
use strict;
use warnings;
use base qw(Class::Accessor);
use Carp;
use WWW::Mechanize;
use Template;
use XML::LibXML;
use String::Random;
use Data::Dumper;
__PACKAGE__->mk_accessors( qw(test tests stash ua tt base_url) );

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my %opts = @_;
  $opts{stash} ||= {};
  $opts{ua} ||= WWW::Mechanize->new;
  $opts{tt} ||= Template->new(INCLUDE_PATH => '.')  || die $Template::ERROR, "\n";
  return bless \%opts, $class;
}

sub add_response {
  my $self = shift;
  my $response = shift;
  my $document;
  if ($response->header('Content-Type') =~ /\bxml\b/) {
    eval {
      $document = XML::LibXML->load_xml(string => $response->decoded_content);
    };
    if ($@) {
      die ("Error parsing response " . $response->request->uri . ": " . $@ . " $Test::Rest::where");
    }
  }
  else {
    $document = XML::LibXML::Document->new;
  }
  $self->stash->{documents} ||= [];
  $self->stash->{responses} ||= [];
  push @{$self->stash->{documents}}, $document;
  push @{$self->stash->{responses}}, $response;
  $self->stash->{response} = $response;
  $self->stash->{document} = $document;
}

sub expand_string {
  my $self = shift;
  my $string = shift;
  my $output;
  $self->stash->{test} = $self;
  $string =~ s/\{([^{}]*?)\}/[% $1 %]/misg;
  $string =~ s/\{\{(.*?)\}\}/{$1}/misg;
  $string =~ s/\$\((.*?)\)/$self->xpath($1)/misge;
  $self->tt->process(\$string, $self->stash, \$output) || die ($self->tt->error() . " for template '$string'", "\n");
  delete $self->stash->{test};
  return $output;
}

sub expand_url {
  my $self = shift;
  my $string = $self->expand_string(shift);
  my $url = URI->new($string);
  unless (defined $url->scheme and length $url->scheme) {
    $url = $self->base_url->clone;
    $url->path_query($string);
  }
  return $url->as_string;
}

sub random {
  my $self = shift;
  my $n = shift || 8; 
  my $random = new String::Random;
  return $random->randregex('[A-Za-z]{'.$n.'}');
}

sub xpath {
  my $self = shift;
  my $xpath = shift;
  my @node = defined($self->stash->{document}->documentElement) ?
    $self->stash->{document}->documentElement->findnodes($xpath) : ();
  if (@node) {
    return $node[0]->nodeType == XML_ELEMENT_NODE ? $node[0]->textContent : $node[0]->nodeValue;
  }
  else {
    return '';
  }
}

1;
