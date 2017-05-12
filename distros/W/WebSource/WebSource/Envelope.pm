package WebSource::Envelope;

use strict;
use Carp;
use URI;
use HTTP::Request::Common;
use XML::LibXML::Common qw(:w3c);
use XML::LibXML;

=head1 NAME

WebSource::Envelope - Container for exchanged data

=head1 DESCRIPTION

  A WebSource::Enveloppe is used to encapsulate the data
  going from one module to another. This alows to attach 
  meta-information such as a document's base uri

  For the moment these types are known :

=over 2

=item - B<xmlnode>

  data is an XML::LibXML Node

=item - B<string>

  data is a string

=item - B<uri>

  data is a URI object

=item - B<http-request> 

  data is an HTTP::Request object

=back

=head1 SYNOPSIS

  use WebSource::Envelope;
  ...
  my $env = WebSource::Envelope->new(
             type => $type, 
             data => $data
             ...
       );
  ...


=head1 METHODS

=cut

our %knowntypes = (
	"object/dom-node"      => 1,
	"object/http-request"  => 1,
	"text/string"          => 1,
	"text/html"            => 1,
	"text/xml"             => 1,
	"object/uri"           => 1,
        "application/pdf"      => 1,
        "empty"                => 1
);

sub new {
  my $class = shift;
  my %params = @_;
  my $self = bless \%params, $class;
	$self->{type} or croak("No type given");
	$knowntypes{$self->{type}} or carp("Type ",$self->{type}," is not known");
  return $self;
}

sub new_from_file {
  my ($class,$filename) = @_;
  my $parser = XML::LibXML->new();
  my $doc = $parser->parse_file($filename);
  my $envRoot = $doc->documentElement();
  my %params;
  foreach my $attr ($envRoot->attributes()) {
    $params{$attr->nodeName} = $attr->nodeValue;
  }
  my $self = bless \%params, $class;
  $self->{type} or croak("No type given");
  $knowntypes{$self->{type}} or carp("Type ",$self->{type}," is not known");
  if($self->{type} eq 'object/dom-node') {
    my @content = $envRoot->findnodes('child::*');
    if(@content) {
      $self->{data} = $content[0];
    } else {
      croak("No content for dom-node");
    }
  } else {
    $self->{data} = $envRoot->findvalue('text()');
  }
  return $self;
}

sub type {
  my $self = shift;
  return $self->{type};
}

sub data {
  my $self = shift;
  return $self->{data};
}

sub dataString {
  my $self = shift;
  my $t = $self->type;
  my $d = $self->data;
  if($t eq "object/dom-node") {
    $d->textContent;
  } elsif($t =~ m{^object/} && $d->can("as_string"))  {
    $d->as_string;
  } else {
    $d;
  }
}

sub dataXML {
  my $self = shift;
  my %params = @_;
  my $t = $self->type;
  my $d = $self->data;
  if($t eq "object/dom-node") {
  	if($params{wantdoc} && $d->nodeType ne "#document") {
  		my $doc = XML::LibXML::Document->createDocument( "1.0", "utf-8" );
  		
  		my $clone = $d->cloneNode(1);
  		$doc->setDocumentElement($clone);
  		$doc->toString(1);
  	} else {
	    $d->toString(1);
  	}
  } elsif($t =~ m{^object/} && $d->can("as_string"))  {
    "<content>" . $d->as_string . "</content>";
  } else {
    "<data>" . $d . "</data>";
  }
}

sub dataAsURI {
  my $self = shift;
  my $t = $self->type;
  if($t eq "object/uri") {
    return $self->data;
  }
  if($t eq "object/http-request") {
    return URI->new($self->data->uri)
  }
  if($self->{baseuri}) {
    return URI->new_abs($self->dataString,$self->{baseuri});
  } else {
    return URI->new($self->dataString);
  }
}
	
sub dataAsHttpRequest {
  my $self = shift;
  my $t = $self->type;
#  print "Got data of type $t\n";
  if($t eq "object/http-request") {
    return $self->data;
  }
  if($t eq "object/dom-node") {
    my $n = $self->data;
    if($n->nodeType == DOCUMENT_NODE) {
      $n = $n->documentElement;
    }
#    print "Namespace URI : ", $n->namespaceURI,"\n";
#    print "Local name    : ", $n->localName,"\n";
    if($n->namespaceURI eq "http://wwwsource.free.fr/ns/websource-types"
       && $n->localName eq "http-request") {
       my $pre = $n->prefix;
       my $base = $n->getAttribute("base");
       my $method = $n->getAttribute("method");
#       print $n->toString(1),"\n";
#       print "Base : $base\n";
#       print "Method : $method\n";
       my $url = URI->new($base);
       my @query = map {
         $_->getAttribute("name") => $_->getAttribute("value")
       } $n->findnodes("${pre}:param");
       my $htreq;
       if ($method =~ m/GET/i) {
         $url->query_form(\@query);
         $htreq = HTTP::Request->new("GET",$url);
       } else {
         $htreq = POST $url, \@query;
       }
    } else {
      return HTTP::Request->new("GET",$self->dataAsURI->as_string);
    }
  } else {
    return HTTP::Request->new("GET",$self->dataAsURI->as_string);
  }
}

sub as_string {
  my $self = shift;
  return "[[" . join("  ", map {
     my $str = ""; 
     $str .= $self->{$_};
     my $l = length($str);
     $l > 70 and $str = substr($str,0,35) . " ... " . substr($str,$l-35,35);
     $_ .  " => " . $str
  } keys(%$self)) . "]]";
}

sub to_file {
  my ($self,$filename) = @_;
  my $parser = new XML::LibXML;
  my $envDoc = $parser->parse_string('<?xml version="1.0" ?><ws:envelope xmlns:ws="http://wwwsource.free.fr/ns/websource" />');
  my $envRoot = $envDoc->documentElement(); 
  foreach my $key (keys(%$self)) {
     if($key ne 'data') {
       my $value = $self->{$key};
       $envRoot->setAttribute($key,$value);
     }
  }

  my $t = $self->type;
  my $d = $self->data;
  if($t eq "object/dom-node") {
    if($d->nodeType == XML_DOCUMENT_NODE) {
      $envRoot->appendChild($d->documentElement);    
    } else {
      $envRoot->appendChild($d);
    }
  } else {
    $envRoot->appendChild($envDoc->create($d));
  }
  
  
  open(my $fh,">",$filename);
  print $fh $envDoc->toString;
  close($fh);
}

=head1 SEE ALSO

WebSource

=cut

1;
