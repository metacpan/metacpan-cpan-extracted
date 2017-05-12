package WebSource;
our $REVSTR = '$Revision: 1.13 $';
$REVSTR =~ m/Revision: ([^ ]+)/;
our $REVISION = $1;
our $VERSION='2.4.5';

use strict;
use Carp;

use LWP::UserAgent;
use HTTP::Cookies;
use WebSource::Parser;
use WebSource::Envelope;

use File::Spec;

our $NameSpace = 'http://wwwsource.free.fr/ns/websource';
our %ModClass = (
 "fetch"		=> 'WebSource::Fetcher',
 "extract"		=> 'WebSource::Extract',
 "filter"		=> 'WebSource::Filter',
 "query"		=> 'WebSource::Query',
 "format"		=> 'WebSource::Format',
 "xmlparser"	=> 'WebSource::XMLParser',
 "cache"		=> 'WebSource::Cache',
 "soap"			=> 'WebSource::Soap',
 "database"		=> 'WebSource::DB',
 "map"			=> 'WebSource::Map',
 "dummy"		=> 'WebSource::Module',
 "file"			=> 'WebSource::File',
 "xmlsender" 	=> 'WebSource::XMLSender',
 "meta-tag"		=> 'WebSource::MetaTag'
);


=head1 NAME

WebSource - a general data wrapping tool particularly well suited for online data
(but what data in not online in some way today ;) )

=head1 DESCRIPTION

WebSource gives a general and normalized framework way to access
data made available via the web. An access to subparts of the 
Web is made by defining a task. This task is built by composing 
query building, extraction, fetching and filtering subtasks.

=head1 SYNOPSIS

  $source = WebSource->new(wsd => $description);
  @results = $source->query($query);
or
  $result = $source->set_query($query);
  while($result = $source->next_result()) {
    ...
  }

=head1 ABSTRACT

WebSource originally was a generic wrapper around a Web Source. 
Given an XML description of a source it allows to query the source
and retreive its results. The format of the query and the result
remain source dependant however.

It is now configurable enough allow to do complex tasks on the web : such as 
fetching, extracting, filtering data one the Web. Each complex task is
described by an XML task description file (WebSource description). This task
is decomposed into simple subtasks of different flavors.

Existing subtask flavors are :
  - B<extract>
      I<input>   an XML::LibXML::Document
      I<output>  an XML::LibXML::Node
      Applys an Xpath on the document and returns the set of nodes
  - B<fetch> 
      I<input>   a URL (or XML::LibXML::Node containing a url)
      I<output>  an XML::LibXML::Document 
  - B<format>
      I<input>   an XML::Document
      I<output>  a string
  - B<filter>
      I<input>   anything
      I<output>  anything (but not all)
  - B<external>
      This type of subtask uses an external perl module as a task.
      This allows to define highly configurable tasks.
      I<input>   depends on external module
      I<output>  depends on external module
  - B<meta-tag>
      I<input>   anything
      I<output>  anything (with updated meta-data)
      
=head1 METHODS

=over 2

=item B<< $source = WebSource->new(wsd => $wsd); >>

Create a new WebSource object working with the given a WebSource description

The following named paramters can be given :

=over 2

=item C<wsd>

Use a generic engine with the given source description file

=item C<max_results>

Do not output more than max_results

=back

=cut

sub new {
  my $class = shift;
  my %param = @_;
  $param{wsd} or croak("No WebSource description given");
  $param{useragent}      or $param{useragent} =
    LWP::UserAgent->new(
			agent => "WebSource/1.0",
			keep_alive => 1,
			timeout => 30,
                        requests_redirectable => ['GET', 'HEAD', 'POST'],
                        env_proxy => 1,
		       );
  $param{cookies}        or $param{cookies} = HTTP::Cookies->new;
  $param{useragent}->cookie_jar($param{cookies});
  $param{maxreqinterval} or $param{maxreqinterval} = 3;
  $param{maxtries}       or $param{maxtries} = 3;
  $param{parser}         or $param{parser} = XML::LibXML->new;
  $param{parser}->expand_xinclude(1);
  $param{result_count} = 0;
  my $self = bless \%param, $class;
  $self->_init;
  return $self;
}

sub _init {
  my $self = shift;
  my $wsd = $self->{wsd};
  my $doc = $self->load_wsd($wsd);
  $self->{wsddoc} = $doc;
  $self->apply_imports;
}

sub load_wsd {
	my ($self, $wsd, $base) = @_;
 	my $parser = $self->{parser};
	my $doc;
	if($base) {
		if(-f $base) {
			my @path = File::Spec->splitpath();
			pop @path;
			$base = File::Spec->catpath(@path);
		}
		$wsd = $base ? File::Spec->rel2abs($wsd,$base) : File::Spec->rel2abs($wsd);
	}
	$self->log(2,"Loading " .$wsd);
	if(-f $wsd) {
      	$parser->base_uri("file://" . $wsd);
    	$doc = $parser->parse_file($wsd);
    	$parser->base_uri("");
	} else {
		my $resp = $self->{useragent}->get($wsd);
		$resp->is_success or croak "Couldn't download description $wsd";
		$parser->base_uri($wsd);
		$doc = $parser->parse_string($resp->content);
		$parser->base_uri("");
	}
	$doc or croak "Couldn't parse document $wsd";
	return $doc;
}

sub init {
  my $self = shift;
  
  $self->apply_options;  

  my $wsd = $self->{wsd};
  my $parser = $self->{parser};
  my $doc = $self->{wsddoc};

  #
  # Fetch all module descriptions and build the
  # corresponding module
  #

  my $root = $doc->documentElement;
  my $first;
  my $last;
  my %modules;
  my %forwards;
  my %feedbacks;
  my @nodes = $root->childNodes;
  while (@nodes) {
    my $mnode = shift(@nodes);
    $mnode->nodeType == 1 or next;
    $mnode->namespaceURI eq $NameSpace or next;
    my $type = $mnode->localname;
    my %params = %$self;
    my $name = $mnode->getAttribute("name");
    if($mnode->hasAttribute("abort-if-empty")) {
	    $params{abortIfEmpty} = ($mnode->getAttribute("abort-if-empty") eq "yes");
    } else {
    	$params{abortIfEmpty} = 0;
    }
    if($type eq 'options' || $type eq 'include') {
      # do nothing these are handled seperately
    } elsif($type eq 'init') {
      my $uri = $mnode->getAttribute("browse");
      my $resp = $self->{useragent}->get($uri);
      $self->{cookies}->extract_cookies($resp);
    } elsif($ModClass{$type} || $type eq 'external') {
      $self->log(5,"Creating subtask of type ",$type);
      my $class;
      if($type eq 'external') {
        $class = $mnode->getAttribute("module");
        $class or croak("No module declared for external");
      } else {
        my $subtype = $mnode->getAttribute("type");
        $class = $subtype ?
                    $ModClass{$type} . "::" . $subtype :
                    $ModClass{$type};
      }
      $self->log(5,"Using perl module ",$class);
      eval "require $class";
      if(!$@) {
        $modules{$name} = $class->new( %params,
          wsdnode => $mnode, name => $name);
        if($mnode->hasAttribute("forward-to")) {
	        $forwards{$name} = $mnode->getAttribute("forward-to");
        }
        if($mnode->hasAttribute("feedback-to")) {
	        $feedbacks{$name} = $mnode->getAttribute("feedback-to");
        }
        $first or $first = $name;
        $last = $name;
      } else {
        croak("Couldn't load '$class' : $@");
      }
    } else {
      $self->log(1,"Module named '$name' is of an unknown type '$type'");    
    }
  }
  
  if(!$first) {
  	croak("No modules defined in description file");
  }

  #
  # Connect the modules to each other
  #
  foreach my $key (keys(%forwards)) {
    foreach my $other (split(/ /,$forwards{$key})) {
      if($modules{$other}) {
        $self->log(5,"Setting $key as producer of $other");
        $modules{$key} or croak("No module named $key defined");
        $modules{$other}->producers($modules{$key});
      }
    }
  }

  #
  # Configure feed back sending
  #
  foreach my $key (keys(%feedbacks)) {
    foreach my $other (split(/ /,$feedbacks{$key})) {
      if($modules{$other}) {
        $self->log(5,"Configuring $key to send feedback to $other");
        $modules{$key} or croak("No module named $key defined"); 
        $modules{$key}->isa('WebSource::Filter') or
          croak($modules{$key}->{name} . " is not a filter");
        $modules{$other}->can("feedback") or 
          croak($modules{$other}->{name} . " doesn't have a feedback method");
        $modules{$key}->listeners($modules{$other});
      }
    }
  }


  #
  # Setup first and last
  #
  $self->{first} = $modules{$first};
  $self->{last}  = $modules{$last};
  $self->log(5,"Initial module is $first");
  $self->log(5,"Final module is $last");
}


sub log {
  my $self = shift;
  my $level = shift;
  if($self->{logger}) {
    $self->{logger}->log($level, "[WebSource] ", @_);
  }
}

=item B<< $source->push($item); >>

Pass the initial data to the first subtask

=cut

sub push {
  my ($self) = shift;
  $self->init;
  $self->{first}->push(map { WebSource::Envelope->new(type => "text/string", data => $_) } @_ );
}

=item B<< $source->query($query); >>

Build a query %hash for the given parameters and push it in

=cut

sub query {
  my $self = shift;
  $self->init;
  my %query = @_;
  if($query{data}) {
    $query{type} = "text/string";
  } else {
    $query{type} = "empty";
  }
  my $env = WebSource::Envelope->new(%query);
  $self->{first}->push($env);
}

=item B<< $source->set_max_results($count); >>

Set the maximum number of results to output to $count

=cut

sub set_max_results {
  my ($self,$count) = @_;
  $self->{max_results} = $count;
}

=item B<< $source->next_result(); >>

Returns the following result for the task

=cut

sub next_result {
  my $self = shift;
  if($self->{max_results} && $self->{max_results} <= $self->{cnt_results}) {
    return undef;
  }
  my $res = $self->{last}->produce;
  $res and ($self->{result_count} += 1);
  return $res;
}

=back

=item B<< $source->parameters; >>

Returns a has of the initial tasks parameters

=cut

sub parameters {
  my $self = shift;
  return $self->{first}->parameters;
}

=item B<< $source->option_spec; >>

Returns the spec of the options translated for Getopt::Mixed

=cut

sub option_spec {
  my $self = shift;
  my $doc = $self->{wsddoc};
  my $xpc = XML::LibXML::XPathContext->new($doc);
  $xpc->registerNs('ws',$NameSpace);
  
  my @spec;
  foreach my $onode ($xpc->findnodes('/ws:source/ws:options/*')) {
    my $name = "";
    if($onode->nodeName() eq "option") {
      warn("Using option element under ws:options is deprecated. Directly use the options name as element name.");
      $name = $onode->getAttribute("name");
    } else {
      $name = $onode->nodeName();    
    }
    my $shortcut = $onode->getAttribute("shortcut");
    my $type = $onode->getAttribute("type");
    if($name) {
      my $str = $name;
      if($type eq "string") {
         $str .= "=s";
      } elsif($type eq "integer") {
         $str .= "=i";
      } elsif($type eq "float") {
         $str .= "=f";
      }
      if($shortcut) {
        $str .= " " . $shortcut . ">" . $name; 
      }
      CORE::push(@spec,($str));
      $self->log(3,"generated option spec '$str'\n");
    } else {
      $self->log(1,"unamed option detected.");
    }
  }
  return @spec;
}

=item B<< $source->set_option($opt,$val) >>

Sets source specific option $opt to value $val

=cut

sub set_option {
  my ($self,$opt,$val) = @_;
  $self->log(2,"Setting option $opt to value $val");
  
  my $xpc = XML::LibXML::XPathContext->new($self->{wsddoc});
  $xpc->registerNs('ws',$NameSpace);
  
  if(my @optnode = $xpc->findnodes("//ws:options")) {
    if (my @nodes = $optnode[0]->getChildrenByTagName($opt)) {
      if($nodes[0]->hasChildNodes()) {
        $nodes[0]->firstChild()->setData($val);
      } else {
        $nodes[0]->appendText($val);
      }
    } else {
      my $nn = $self->{wsddoc}->createElement($opt);
      $nn->appendText($val);
      $optnode[0]->appendChild($nn);
    }
  } else {
    croak("Setting option while ws:options node is absent");
  }
}


=item B<< $source->apply_imports >>

Handles node of type <ws:import href="" /> by inserting nodes from the wsd file referenced by href
into (imported document) into the current wsd document (target document).
A node is inserted from the imported document into the target document only if a node with the same
name does not exist in the target document.

=cut

sub apply_imports {
  my ($self) = @_;
  my $doc = $self->{wsddoc};
  my $xpc = XML::LibXML::XPathContext->new($doc);
  $xpc->registerNs('ws',$NameSpace);
  
  my @import_nodes = $xpc->findnodes("//ws:import");
  while(@import_nodes) {
    my $im_node  = shift @import_nodes;
    my $im_par   = $im_node->parentNode;
    my $im_wsd   = $im_node->getAttribute("href");
  	$self->log(2,"Processing import of ".$im_wsd);
    my $im_doc   = $self->load_wsd($im_wsd,$self->{wsd});

    foreach my $el ($im_doc->documentElement->childNodes) {
    	$el->nodeType == 1 or next;
    	my $nodeType = $el->localName;
    	if($nodeType eq 'options') {
    		# If options have not been locally redefined import them
    		if(!$xpc->exists('//ws:options')) {
				$im_par->insertBefore($el,$im_node);
			}	
    	} else {
	    	my $name = $el->getAttribute("name");
			if(!$xpc->exists('//*[@name="' . $name . '"]')) {
				$im_par->insertBefore($el,$im_node);
			}
    	}
    }
    $im_par->removeChild($im_node);
  }
}

=item B<< $source->apply_options >>

Handles node of type <ws:attribute name="aname" value="oname" /> by adding
and attribut name aname with the value of the option named oname
to the parent node. The ws:attribute node is then removed.

=cut

sub apply_options {
  my ($self) = @_;
  my $doc = $self->{wsddoc};
  my $xpc = XML::LibXML::XPathContext->new($doc);
  $xpc->registerNs('ws',$NameSpace);
  
  my @optnode = $xpc->findnodes("//ws:options");
  foreach my $sa ($xpc->findnodes("//ws:set-attribute")) {
    my $p = $sa->parentNode;
    my $aname = $sa->getAttribute("name");
    my $oexpr = $sa->getAttribute("value-of");
    if($oexpr eq "") {
      $self->log(1,"Warning : Empty value-of attribute on ws:set-attribute");
    } else {
      my $oval = $optnode[0]->findvalue($oexpr);
      if($oval) {
        $p->setAttribute($aname,$oval);
      } else {
        $self->log(1,"Warning : Expr '$oexpr' has no value");
      }
      $p->removeChild($sa);
    }
  }
  $self->log(6,"After applying options...\n", $doc->toString(1));
}

=head1 SEE ALSO

ws-query, WebSource::Extract, WebSource::Fetch, WebSource::Filter, etc.

=cut

1;
