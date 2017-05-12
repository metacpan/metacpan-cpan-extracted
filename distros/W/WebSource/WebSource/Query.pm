package WebSource::Query;

use strict;
use Carp;

use WebSource::Module

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Query - Build a query (HTTP request) given a hash

=head1 DESCRIPTION

A Query operator builds an HTTP query for each input. 
The declaration of a query operator is a DOM Node with the following format :

  <ws:query name="opname" method="POST|GET" forward-to="ops">
    <base>http://somewhere/query.cgi</base>
    <parameters>
      <param name="p1" default="v1" />
      ...                                                                
      <param name="pn" default="vn" />
    </parameters>
  </ws:query>

=head1 METHODS

See WebSource::Module

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  my $wsd = $self->{wsdnode} or croak("No description node given\n");
  $self->{base_uri} = $wsd->findvalue('base');
  $self->{method}   = $wsd->getAttribute('method');
}

sub handle {
  my $self = shift;
  my $env = shift;

  my ($query, $missing) = $self->build_query($env);
  if(@$missing) {
    croak "Missing query parameters :\n\t- '" . join("'\n\t- '",@$missing) . "'\n";
  }

  my $req = $self->make_request($query,$env);
  return WebSource::Envelope->new(
				  type => "object/http-request",
				  data => $req);
}

sub build_query {
  my ($self,$env) = @_;
#  $env->type eq "hash" or croak("Envelope didn't contain hash\n");
#  my $qref = $env->data;
  my $qref = $env;
  my @params = $self->{wsdnode}->findnodes('parameters/param');
  my @missing;

  my %query;
  foreach $_ (@params) {
    my $name = $_->getAttribute("name");
    my $value;

    $_->hasAttribute("rename") and 
      croak("Deprecated use of attribute rename in query parameters");

    if($_->hasAttribute("value-of")){
      my $key = $_->getAttribute("value-of");
      if (exists($qref->{$key})) {
        if($qref->{$key}) {
          $value = ($key eq 'data') ?
                        $env->dataString :
                        $qref->{$key};
        }
      } else {
	$value = "";
      }
    }
    if(!defined($value) && $_->hasAttribute("default")) {
      $value = $_->getAttribute("default");
    }

    if (defined($value)) {
      $query{$name} = $value;
    } else {
      push(@missing, ($name));
    }
  };

  return (\%query,\@missing);
}

sub make_request {
  my ($self,$query,$env) = @_;
  my $uri = URI->new($self->{base_uri} ? $self->{base_uri} : $env->dataAsURI);
  my $qstr;
  map {
   $qstr .= "\t". $_ . " => " . $query->{$_} ."\n";
  } keys(%$query);
  $self->log(5,"Built query : \n",$qstr);
  $uri->query_form(%$query);
  my $method = $self->{method};
  if($method ne "GET") {
    my $query = $uri->query;
    $uri->query(undef);
    my $req = HTTP::Request->new('POST',$uri);
    $req->content_type("application/x-www-form-urlencoded");
    $req->content_length(length($query));
    $req->content($query);
    return $req;
  } else {
    return HTTP::Request->new('GET',$uri);
  }
}

sub parameters {
  my ($self) = @_;
  return map {
    $_->getAttribute("name") => $_->getAttribute("default")
  } $self->{wsdnode}->findnodes('parameters/param');
}

=head1 SEE ALSO

WebSource

=cut

1;
