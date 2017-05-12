package WWW::Meta::XML::Browser;

use strict;
use warnings;

=head1 NAME

WWW::Meta::XML::Browser - Perl module to simulate a browser session described in a XML file

=head1 SYNOPSIS

  use WWW::Meta::XML::Browser;

  my $session = WWW::Meta::XML::Browser->new();
  $session->process_file('file.xml');
  $session->process_all_request_nodes();
  $session->print_all_request_results();

=head1 ABSTRACT

This module reads a XML file from a given source and makes the HTTP-requests defined in this XML file.
The result of such a request can be filtered using a XSL stylesheet.
The following requests can be build using results from the transformation.

=head1 DESCRIPTION

=head2 WRITING A SESSION DESCRIPTION FILE

The most important part when working with C<WWW::Meta::XML::Browser> is to write a session description file. Such a file describes which http requests are made and how the results of the requests are handled.

The session description file is a simple XML file. The root element is E<lt>www-meta-xml-browserE<gt> and the DTD can be found at L<http://www.boksa.de/pub/xml/dtd/www-meta-xml-browser_v0.08.dtd>, which leads us to the following construct:

  <?xml version="1.0" ?>
  <!DOCTYPE www-meta-xml-browser SYSTEM "http://www.boksa.de/pub/xml/dtd/www-meta-xml-browser_v0.08.dtd">
  <www-meta-xml-browser>
  <!-- ... -->
  </www-meta-xml-browser>

The optional meta-element can be specified as a child of the root element. The element acts as a container for different information regarding the handling of the request elements.

=head3 META-PERL INFORMATION

The perl element is a child of the meta element and can contain perl related information. The perl element can have one of the child elements described below.

=head4 ELEMENT: callback; ATTRIBUTES: name

The callback element is used to define an anonymous subroutine which can later be used as a callback. The name under which the callback can be accessed is specified by the required name attribut. The form of the callback (parameters, return value) depends on the later usage, an example for a (not very useful :-)) result-callback is the following:

  <callback name="some-callback"><![CDATA[
  sub {
    my ($result) = @_;

    return $result;
  }
  ]]></callback>


=head3 REQUEST DEFINITIONS

A session description file must contain at least one request.

=head4 DEFINING A REQUEST WITHOUT CONTENT

Under the root element we will add some elements for the requests we want to make. A very complete request will look like the following:

  <request url="http://www.google.de/" method="get" stylesheet="google-index.xsl" result-callback="some-callback">
  </request>

The only attribute of the request-element that is required is url, all other attributes can be left out.

If method is left out the default method get will be used.

If stylesheet is left out, the raw html will be transformed to a valid XML document which will than be stored as the result of that request.

The result-callback gives the user the possibility to change the raw html before it will be transformed to a XML document by calling the specified callback. This callback can be an element of the callbacks hash specified when the instance is created or a callback specified in the XML file (L<ELEMENT: callback; ATTRIBUTES: name>). If a callback is specified in the callbacks hash as well as in the XML file the callback from the hash will be used. A result callback is called with the raw html as the only parameter and is required to return a valid html document.

=head4 DEFINING A REQUEST WITH CONTENT

The request-element has an optional child element, which can be used to specify the content of a request. The element is called content and is used as a child of the request element as follows (remember that & has to be written as &amp; in XML):

  <request url="http://www.google.de/search" method="get">
    <content>q=42&amp;ie=ISO-8859-1&amp;hl=de&amp;meta=</content>
  </request>

This example shows that the content will be sent using the specified method (get in this case) to the url of the request (http://www.google.de/search).

=head4 EMBEDDED REQUESTS

Embedded request can be used to fetch pages from a result page. They can be created in the XSL stylesheet to dynamically parse a tree of pages. 

As soon as a www-meta-xml-browser-request-element is created in the XSL stylesheet it is processed like a normal request-element and the result is inserted.

If the result consists of multiple pages the container-attribute has to be specified and is used as the new root for the merged (optionally transformed) pages.

=head3 REPLACEMENT EXPRESSIONS IN A SESSION DESCRIPTION FILE

There are some cases in which static urls and a static content don't fit the requirements of what has to be done.

For this case WWW::Meta::XML::Browser has an easy way to use arguments passed to the instance during creation or values from a previous result.

To access arguments passed to the instance during creation the following simple syntax is used:

  #{args:key}

The word key has to be replaced with the key of the hash containing the arguments. This will lead to the replacement of C<#{args:key}> with the appropriate value from the hash.

Accessing previous results basically goes the same way, some example show, that it even offers more possibilities:

  #{0:0:/foo}
  #{4:1-3:/foo/too}
  #{1::/foo/@argument}
  #escape{0:0:/foo}
  #escape{4:1-3:/foo/too}
  #escape{1::/foo/@argument}

The first three example and the last three examples have only one difference, which is the word escape. This command simply tells the module to url-escape the value that is returned by that later part of the expression.

Let's look at these expressions in detail:

The first part (the number before the first colon) specifies the index (starting with 0) of the request which we want to access. This index can be mapped directly to the session description file.

The second part (between the first and the second colon) specifies the subrequest results (more about subrequests later) that will be looked at. 0 in the first example specifies the first subrequest. 1-3 in the second example specifies the subrequests 2,3 and 4 (remember, we begin indexing with 0). The third example accesses all subrequests.

The last part (after the second colon) specifies an XPath-Expression, which is looked up in each of the subrequest results and a list of all values which match the Expression is generated.

This list is taken and each value of the list will replace the whole replacement expression, and for each replacement one http request is made.

Naturally if the url or the content contains more than one replacement expression all possible combinations are requested (which actually is the product of the different numbers of matching XPath-Expressions).

These different http requests make up the subrequests which are stored and can be accessed, when needed. Please not that subrequests can be merged into a singele subrequest result using L<merge_subrequests()>.

=head2 CREATING A NEW BROWSER OBJECT

To create a new browser object the L<new()>-method is called, with an optional hash containing options.

  $browser = WWW::Meta::XML::Browser->new(%options);

The following options are possible:

  args => \%args

C<\%args> is the pointer to a hash which values can be accessed from the session description file by their keys. The syntax to access the hash values from the session file is C<#{args:key}>, where key is a key from the hash.

  debug => 1

When the debug option is set, the module produces a lot of debug output about execution times.

  debug_callback => \&debug

C<\&debug> has to be a pointer to a subroutine taking two parameters. The first parameter is a number >= 0 which describes the logging level. The second parameter is the string which is the message to be printed.
Please note that there is a default routine L<_debug()>.

  result_doc_callback => \&result

C<\&result> has to be a pointer to a subroutine taking one parameter. The parameter is an instance of C<XML::LibXML::Document> and can be manipulated. The subroutine must return an instance of C<XML::LibXML::Document>.
Please note that there is a default routine L<_result()>.

  callbacks => \%callbacks

C<\%callbacks> is a pointer to a hash of references to subroutines. These subroutines can be used in various situations during the processing of the XML file.

=head2 PROCESSING A SESSION DESCRIPTION FILE

To read the session description file one of the following methods is called, depending on the source of the file.

  $browser->process_file($file);
                 -or-
  $browser->process_url($url);
                 -or-
  $browser->process_string($string);
                 -or-
  $browser->process_xml_doc($doc);

The names of the methods should be self-explaining:

L<process_file()> is called when the session description file is on a local disk an read by the script directly (this should be the most common case).

L<process_url()> is called when the session description file is accessed by an http request.

L<process_string()> is called when the session description data is available in a scalar variable.

L<process_xml_doc()> is called when the XML document has already been parsed (as done by the three methods above and we have a instance of XML::LibXML::Document.

=head2 PROCESSING THE REQUESTS FROM THE SESSION DESCRIPTION FILE

After the session description file has been processed as shown above, the request nodes contained in the XML document can be processed.

  $browser->process_all_request_nodes();
                   -or-
  while (my $r_node = $browser->get_next_request_node()) {
    $subrequest_result = $browser->process_request_node($r_node);
  }

L<process_all_request_nodes()> encapsulates the second construction with the while loop.
Both constructions execute all http requests generated from the session description file and store the results of the (optionally transformed) requests.

=head2 ACCESSING THE RESULTS

The result of a spceific request can be accessed with a simple call which returns an instance of C<XML::LibXML::Document>.

  $result = $browser->get_request_result($request_index, $subrequest_index);

To access the results one has to understand how results are stored. The results are stored in a two-dimensional array.

The first index (which starts with 0 for the first request) describes the request which can be found in the session description file.

The second index describes the real index after all permutations caused by possible replacements in the url or content have been generated.

For example C<$browser-E<gt>get_request_result(0, 2)> returns the result of the third request generated from the first request node in the session description file.

=head1 EXPORT

None by default.

=cut

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WWW::Meta::XML::Browser ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.08';

use Digest::MD5;
use HTTP::Cookies;
use HTTP::Request;
use LWP::UserAgent;
use Time::HiRes;
use URI::Escape;
use XML::LibXML;
use XML::LibXSLT;

my $ROOT_XPATH								= '/www-meta-xml-browser';

my $META_XPATH								= $ROOT_XPATH.'/meta';
my $PERL_META_XPATH							= $META_XPATH.'/perl';
my $CALLBACK_XPATH							= $PERL_META_XPATH.'/callback';

my $REQUEST_XPATH							= $ROOT_XPATH.'/request';
my $AUTHORIZATION_XPATH						= './authorization';
my $CONTENT_XPATH							= './content';

my $XPATH_REGEXP							= '\#(escape)*\{(\d+?):(.*?):(.+?)\}';
my $ARGS_REGEXP								= '\#(escape)*\{args:(.*?)\}';

my $URL_ATTRIBUTE							= 'url';
my $METHOD_ATTRIBUTE						= 'method';
my $RESULT_CALLBACK_ATTRIBUTE				= 'result-callback';
my $STYLESHEET_ATTRIBUTE					= 'stylesheet';

my $CALLBACK_NAME_ATTRIBUTE					= 'name';

my $EMBEDDED_REQUEST_CONTAINER_ATTRIBUTE	= 'container';

my $XML_VERSION								= '1.0';

my $USER_AGENT								= "WWW::Meta::XML::Browser ".$VERSION;
my $TIMEOUT									= 30;

=head1 METHODS

The following methods are available:

=over 4

=cut



=item $browser = WWW::Meta::XML::Browser->new(%options);

This class method contructs a new C<WWW::Meta::XML::Browser> object and returns a reference to it.

The hash C<%options> can be used to control the behaviour of the module and to provide some data to it as well. At the moment the following Key/Value pairs are supported:

  KEY:                    VALUE:          DESCRIPTION:
  ---------------         -----------     -------------
  args	                  \%args          a pointer to a hash of arguments which can be used in
                                          requests
  debug                   0/1             a boolean true or boolean false value can be passed to
                                          the module to control weather debugging information are
                                          printed or not
  debug_callback          \&debug         a pointer to a debug-callback
  result_doc_callback     \&result        a pointer to a result-doc-callback
  callbacks               \%callbacks     a pointer to a hash of subroutines which can be used as
                                          callbacks in different situations

=cut

sub new {
	my $type = shift;
	my (%cnf) = @_;
	
	my $this = {};
	
	bless $this, $type;

	$this->{debug_callback} = \&_debug;
	$this->{result_doc_callback} = \&_result;
	$this->{callbacks} = {};
	
	$this->{args} = $cnf{'args'} if $cnf{'args'};		
	$this->{debug} = 1 if $cnf{'debug'};
	$this->{debug_callback} = $cnf{'debug_callback'} if $cnf{'debug_callback'};
	$this->{result_doc_callback} = $cnf{'result_doc_callback'} if $cnf{'result_doc_callback'};
	$this->{callbacks} = $cnf{'callbacks'} if $cnf{'callbacks'};

	$this->{request_nodes} = ();

	$this->{request_results} = ();

	$this->{ua} = LWP::UserAgent->new(cookie_jar => HTTP::Cookies->new(), requests_redirectable => ['GET', 'POST', 'HEAD']);
	$this->{ua}->agent($USER_AGENT);
	$this->{ua}->timeout($TIMEOUT);
	&{$this->{debug_callback}}(0, "LWP::UserAgent created") if $this->{debug};

	$this->{xml_parser} = XML::LibXML->new();
	$this->{xml_parser}->validation(1);
	$this->{xml_parser}->load_ext_dtd(1);
	&{$this->{debug_callback}}(0, "XML::LibXML-Parser created") if $this->{debug};
	
	$this->{xml_doc} = undef;
		
	return $this;
}



=item process_url($url);

Reads the XML file containing session description from the specified url and constructs a XML document from it which is then passed to L<process_xml_doc()>.

=cut

sub process_url {
	my $this = shift;
	my ($url) = @_;

	&{$this->{debug_callback}}(0, "process_url() called") if $this->{debug};
	my $source = LWP::UserAgent::get($url);
	&{$this->{debug_callback}}(1, "LWP::UserAgent::get($url) succeeded") if $this->{debug};

	my $parser = XML::LibXML->new();
	$parser->recover(1);
	my $doc = $parser->parse_html_string($source);
	
	&{$this->{debug_callback}}(1, "parse_html_string() succeeded") if $this->{debug};

	$this->process_xml_doc($doc);
}



=item process_file($file);

Reads the XML file containing session description and constructs a XML document from it which is then passed to L<process_xml_doc()>.

=cut

sub process_file {
	my $this = shift;
	my ($file) = @_;

	&{$this->{debug_callback}}(0, "process_file() called") if $this->{debug};
	my $doc = $this->{xml_parser}->parse_file($file);
	&{$this->{debug_callback}}(1, "parse_file($file) succeeded") if $this->{debug};
	
	$this->process_xml_doc($doc);
}



=item process_string($string);

Constructs a XML document from the given string which is then passed to L<process_xml_doc()>.

=cut

sub process_string {
	my $this = shift;
	my ($string) = @_;
	
	&{$this->{debug_callback}}(0, "process_string() called") if $this->{debug};
	my $doc = $this->{xml_parser}->parse_string($string);

	$this->process_xml_doc($doc);
}



=item process_xml_doc($doc);

Takes the given XML ocument and reads the request-nodes in the XML file. These request nodes are stored internally to be processed.

=cut

sub process_xml_doc {
	my $this = shift;
	my ($doc) = @_;

	&{$this->{debug_callback}}(0, "xml_doc stored") if $this->{debug};
	$this->{xml_doc} = $doc;

	&{$this->{debug_callback}}(0, "process_xml_doc() called") if $this->{debug};
	my $r_nodeset = $doc->findnodes($REQUEST_XPATH);

	foreach my $r_node ($r_nodeset->get_nodelist()) {	
		push(@{$this->{request_nodes}}, $r_node);	
	}

	&{$this->{debug_callback}}(1, ($#{$this->{request_nodes}} + 1)." request nodes read") if $this->{debug};	
}



=item $node = get_next_request_node();

Returns the next request-node which than can be processed using L<process_request_node()>

=cut

sub get_next_request_node {
	my $this = shift;

	return shift(@{$this->{request_nodes}});
}



=item process_all_request_nodes();

Iterates over all request nodes and processes each of them.

=cut

sub process_all_request_nodes {
	my $this = shift;

	while (my $r_node = $this->get_next_request_node()) {
			push(@{$this->{request_results}}, $this->process_request_node($r_node));
	}
}



=item $subrequest_result = process_request_node($r_node);

Processes the request node. This subroutine does the actual work:
It generates all permutations of the url
It genarates all permutations of the content
It generates all permutations ot the url and the content
It makes the requests and processes the results
it returns the (optionally transformed) results

=cut

sub process_request_node {
	my $this = shift;
	my ($r_node) = @_;

	&{$this->{debug_callback}}(0, "process_request_node() called") if $this->{debug};
	&{$this->{debug_callback}}(1, "processing url: ".$r_node->getAttribute($URL_ATTRIBUTE)) if $this->{debug};

	my @processed_url = ();	
	$this->parse_string($r_node->getAttribute($URL_ATTRIBUTE), \@processed_url);	

	if ($this->{debug}) {
		foreach my $url (@processed_url) {
			&{$this->{debug_callback}}(2, "expanded url: ".$url) if $this->{debug};
		}
	}

	
	# process the content specified for the request
	my $c_nodeset = $r_node->findnodes($CONTENT_XPATH);

	&{$this->{debug_callback}}(1, "processing content") if $this->{debug};

	my @processed_content = $this->process_content_nodeset($c_nodeset);

	if ($this->{debug}) {
		foreach my $content (@processed_content) {
			&{$this->{debug_callback}}(2, "expanded content: ".$content) if $this->{debug};
		}
	}


	my @subrequest_result = ();

	foreach my $url (@processed_url) {

		foreach my $content (@processed_content) {
			my ($res, $doc);
			
			$res = $this->make_request($url, $r_node->getAttribute($METHOD_ATTRIBUTE), $content);		

			my $result_callback = $r_node->getAttribute($RESULT_CALLBACK_ATTRIBUTE);

			if ($res && $result_callback) {
				my ($result, $callback);
			
				&{$this->{debug_callback}}(1, "result callback called: ".$result_callback."(\$res->content())") if $this->{debug};
								
				if ($callback = $this->_read_callback($result_callback)) {

					my $t0 = [Time::HiRes::gettimeofday()] if $this->{debug};

					$result = &{$callback}($res->content());			
					
					&{$this->{debug_callback}}(3, "time to process callback \"".$result_callback."\": ".Time::HiRes::tv_interval($t0)) if $this->{debug};

					$doc = $this->process_result($result, $r_node->getAttribute($STYLESHEET_ATTRIBUTE));							
				}
				else {
					$doc = $this->process_result_doc($res, $r_node->getAttribute($STYLESHEET_ATTRIBUTE));
				}
			}
			elsif ($res) {	
				$doc = $this->process_result_doc($res, $r_node->getAttribute($STYLESHEET_ATTRIBUTE));
			}
			
			if ($doc) {
				push(@subrequest_result, $doc);
			}
		}

	}

	return \@subrequest_result;
}



=item @processed_content = process_content_nodeset($c_nodeset);

Processes a content nodeset and generates all possible permutations by replacing the tokens.

=cut

sub process_content_nodeset {
	my $this = shift;

	my ($c_nodeset) = @_;

	my @content;
		
	foreach my $c_node ($c_nodeset->get_nodelist()) {
		
		my $content = $c_node->string_value();
		
		# strip all whitespaces
		$content =~ s/\s*//gs;
		
		# strip leading '&'s
		$content =~ s/^&*//gs;
		
		my $ctx = Digest::MD5->new();
		$ctx->add($content);
        my $digest = $ctx->hexdigest();
        
        $content =~ s/&amp;/$digest/gis;
        
		my @raw_content = split(/&/, $content);		

		foreach my $pair (@raw_content) {
			$pair  =~ s/$digest/&amp;/gis;
			
			my ($name, $value);
			
			if ($pair =~ /(.+?)=(.*)/) {					
				($name, $value) = ($1, $2);
								
				if (($value !~ /$XPATH_REGEXP/) && ($value !~ /$ARGS_REGEXP/)) {
					$value = uri_escape($value);
				}
				
				push(@content, $name.'='.$value);
			}
			else {
				if (($pair !~ /$XPATH_REGEXP/) && ($pair !~ /$ARGS_REGEXP/)) {
					$value = uri_escape($pair);
				}
				else {
					$value = $pair;
				}
												
				push(@content, $value);
			}
		}
	}
	
	my $content = join('&', @content);
		
	my @processed_content = ();
	$this->parse_string($content, \@processed_content);

	return @processed_content;
}



=item make_request($url, $method, $content);

Makes a request to C<$url> sending the C<$content> using C<$method> and returns the result. If a username and a password have bee specified within the url, they will be used for HTTP-Basic authentication if necessary.

=cut

sub make_request {
	my $this = shift;
	my ($url, $method, $content) = @_;

	my $username = undef;
	my $password = undef;

	if ($url =~ /^(http:\/\/)(.+?):(.+?)\@(.+)$/) {
		my $username	= $2;
		my $password	= $3;
		my $url			= $1.$4;
	}

	&{$this->{debug_callback}}(1, "make_request() called") if $this->{debug};
	&{$this->{debug_callback}}(2, "url:     ".$url) if $this->{debug};
	&{$this->{debug_callback}}(2, "content: ".$content) if $this->{debug};
	&{$this->{debug_callback}}(2, "method:  ".$method) if $this->{debug};

	if (defined($username) && defined($password)) {
		&{$this->{debug_callback}}(2, "authorization:  ".$username." ".$password) if $this->{debug};
	}

	my $t0 = [Time::HiRes::gettimeofday()] if $this->{debug};
	
	my $req;

	if ($method =~ /get/i) {
		$req = HTTP::Request->new('GET' => $url.'?'.$content);
	}
	elsif  ($method =~ /post/i) {
		$req = HTTP::Request->new('POST' => $url);
		$req->content_type('application/x-www-form-urlencoded');
		$req->content($content);
	}

	if (defined($username) && defined($password)) {
		$req->authorization($username => $password)
	}
		
	my $res = $this->{ua}->request($req);
	
	&{$this->{debug_callback}}(2, "time:    ".Time::HiRes::tv_interval($t0)) if $this->{debug};

	if ($res->is_success()) {
		return $res;
	}
	elsif ($res->is_redirect()) {
		warn "Redirect (".$res->code().") to \"".$res->headers->header('Location')."\"\n";
		return 0;
	}
	else {
		warn "Error (".$res->code().") while processing request result from ".$method."-request to ".$url." with content ".$content."\n";
		warn $res->content()."\n";
		return 0;
	}
}



=item $doc = process_result_doc($res, $stylesheet);

Processes the result (C<$res>) as returned by L<make_request()> by transforming it into a XML document.
Internally L<process_result()> is called with C<$res>->content() and C<$stylesheet>.

=cut

sub process_result_doc {
	my $this = shift;	
	my ($res, $stylesheet) = @_;

	return $this->process_result($res->content(), $stylesheet);
}



=item $doc = process_result($result, $stylesheet);

Processes the result-string (C<$result>) by transforming it into a XML document.
If a XSL-Stylesheet (C<$stylesheet>) has been specified for the given request the XML document will be transformed using that stylesheet.
The resulting XML document is then returned.

=cut

sub process_result {
	my $this = shift;	
	my ($result, $stylesheet) = @_;

	&{$this->{debug_callback}}(1, "process_result() called") if $this->{debug};
		
	# the result doc is undef by default and will not change if the request was not successfull
	my $doc = undef;

	my $t0 = [Time::HiRes::gettimeofday()] if $this->{debug};

	# create a parser for the result
	my $parser = XML::LibXML->new();
	$parser->recover(1);

	# parse the html and generate the result doc
	$doc = $parser->parse_html_string($result);

	&{$this->{debug_callback}}(2, "time to parse html:       ".Time::HiRes::tv_interval($t0)) if $this->{debug};

	# if a stylesheet has been specified use it to transform the result doc
	if ($stylesheet) {	
		my $t0 = [Time::HiRes::gettimeofday()] if $this->{debug};

		my $style_doc = $parser->parse_file($stylesheet);

		my $xslt = XML::LibXSLT->new();
		my $stylesheet = $xslt->parse_stylesheet($style_doc);

		# overwrite the old result doc with the new result doc
		$doc = $stylesheet->transform($doc);	

		&{$this->{debug_callback}}(2, "time to transform result: ".Time::HiRes::tv_interval($t0)) if $this->{debug};
	}



	# processing embedded requests after having applied the stylesheet if it has been specified
	my $doc_string = $doc->toString();


	my $contains_embedded_request = 0;
	if ($doc_string =~ /(<www-meta-xml-browser-request.*?\/>)/gis) {
		$doc_string =~ s/(<www-meta-xml-browser-request.*?\/>)/$this->process_embedded_request($parser->parse_string($1)->getDocumentElement())/egis;
		$contains_embedded_request = 1;
	}
	if ($doc_string =~ /(<www-meta-xml-browser-request.*?>.+?<\/www-meta-xml-browser-request>)/gis) {
		$doc_string =~ s/(<www-meta-xml-browser-request.*?>.+?<\/www-meta-xml-browser-request>)/$this->process_embedded_request($parser->parse_string($1)->getDocumentElement())/egis;
		$contains_embedded_request = 1;
	}

	if ($contains_embedded_request) {
		$doc = $parser->parse_string($doc_string);
	}

	return &{$this->{result_doc_callback}}($doc);	
}



=item $xml_string = process_embedded_request($embedded_request_node);

Processes an embedded request node, by processing it as a normal node (using L<process_request_node()>).
If the embedded request node returns only one XML document it is transformed to a string and returned.
If the embedded request node returns more than one XML documents they are merged unded the name specified by the C<$EMBEDDED_REQUEST_CONTAINER_ATTRIBUTE>-attribute of the embedded requst node.

=cut 

sub process_embedded_request {
	my $this = shift;
	my ($er_node) = @_;
	
	my $subrequest_result = $this->process_request_node($er_node);

	if (scalar(@{$subrequest_result}) > 1) {
		my $doc = $this->merge_xml_array($subrequest_result, $er_node->getAttribute($EMBEDDED_REQUEST_CONTAINER_ATTRIBUTE));		
		return $doc->documentElement()->toString();
	}
	else {
		return ${$subrequest_result}[0]->documentElement()->toString();
	}
}



=item $result = get_request_result($request_index, $subrequest_index);

Returns the request-result specified by C<$request_index> and C<$subrequest_index>.

=cut

sub get_request_result {
	my $this = shift;
	my ($request_index, $subrequest_index) = @_;

	return ${$this->{request_results}}[$request_index][$subrequest_index];
}



=item print_all_request_results();

Iterates over all the request results and prints them.

=cut

sub print_all_request_results {
	my $this = shift;

	my @requests = @{$this->{request_results}};
	my $r = 0;

	foreach my $request (@requests) {		
		my @subrequests = @{$request};

		print "-------------------- REQUEST (".($r++ + 1)."/".($#requests + 1).") --------------------\n";

		my $s = 0;
	
		foreach (@subrequests) {
			print "-------------------- SUBREQUEST (".($s++ + 1)."/".($#subrequests + 1).")--------------------\n";
			$this->print_request_result($_);
		}
	}
}



=item print_request_result($result);

Prints the specified request result.

=cut

sub print_request_result {
	my $this = shift;
	my ($doc) = @_;
	
	print $doc->toString();
}



=item merge_subrequests($request_index, $wrapper_name);

Merges the subrequest of the request (specified by C<$request_index>) in a new XML document which consists of a new root element (C<$wrapper_name>) and all the subrequests as children of this root element.

=cut

sub merge_subrequests {
	my $this = shift;
	my ($request_index, $wrapper_name) = @_;

	my $doc = $this->merge_xml_array($this->{request_results}->[$request_index], $wrapper_name);
	
	my @doc = ($doc);
	$this->{request_results}->[$request_index] = \@doc;
}



=item merge_xml_array($array, $wrapper_name)

Merges the XML documents in C<@{$array}> by building a new XML document with a new root element (C<$wrapper_name>) and the XML documents in C<@{$array}> as children of the root element.

=cut

sub merge_xml_array {
	my $this = shift;
	my ($array, $wrapper_name) = @_;

	my $root = XML::LibXML::Element->new($wrapper_name);

	foreach my $xml (@{$array}) {
		$root->appendChild($xml->documentElement());
	}

	my $doc = XML::LibXML->createDocument($XML_VERSION);
	$doc->setDocumentElement($root);

	return $doc;
}



=item parse_string($s, $r);

Recursively parses the string passed as C<$s> and writes the replacement results to C<@{$r}>, which will be an array containing all possible permutations, created by the replacement of the specified tokens.

=cut

sub parse_string {
	my $this = shift;
	my ($s, $r) = @_;

	if ($s =~ /(.*?)$XPATH_REGEXP(.*)/) {
		my $pre = $1;
		my $escape = $2;
		my $request_index = $3;
		my $subrequest_index = $4;
		my $xpath = $5;
		my $post = $6;

		my @subrequests = @{$this->{request_results}->[$request_index]};
				
		my @xml_docs = ();

		if ($subrequest_index =~ /^(\d*)-(\d*)$/) {
			my $start = $1;
			my $end = $2;
			
			if (!$start) {
				$start = 0;
			}
			if (!$end) {
				$end = $#subrequests;
			}
			
			for (my $i = $start; $i <= $end; $i++) {
				push(@xml_docs, $subrequests[$i]);
			}
		}
		elsif ($subrequest_index =~ /^(\d+)$/) {		
			my $index = $1;
			
			push(@xml_docs, $subrequests[$index]);
		}
		else {
			my $start = 0;
			my $end = $#subrequests;

			for (my $i = $start; $i <= $end; $i++) {
				push(@xml_docs, $subrequests[$i]);
			}			
		}

		foreach my $xml_doc (@xml_docs) {
			my $nodeset = $xml_doc->findnodes($xpath);
		
			my $i = 0;
		
			my @return = ();
		
			foreach my $node ($nodeset->get_nodelist()) {
				my $value = $node->string_value();
				
				if ($escape) {
					$value =~ s/[\s]*(.*?)[\s]*/uri_escape($1)/egs;
				}
				else {
					$value =~ s/[\s]*(.*?)[\s]*/$1/egs;
				}
				
				$this->parse_string($pre.$value.$post, $r, $escape);	
			}
		}
	}
	elsif ($s =~ /(.*?)$ARGS_REGEXP(.*)/) {
		my $pre = $1;
		my $escape = $2;
		my $arg = $3;
		my $post = $4;

		if ($escape) {
			$this->parse_string($pre.uri_escape($this->{args}->{$arg}).$post, $r, $escape);
		}
		else {
			$this->parse_string($pre.$this->{args}->{$arg}.$post, $r, $escape);
		}		
	}
	else {
		push(@{$r}, $s);
	}		
}



=item $callback = _read_callback($result_callback);

Reads the callback from the callbacks hash or from the XML file and returns a reference to it. If the callback can not be found 'undef' is returned. 

=cut

sub _read_callback {
	my $this = shift;
	my ($result_callback) = @_;
	
	if (ref($this->{callbacks}->{$result_callback}) eq 'CODE') {
		&{$this->{debug_callback}}(2, "read result callback \"".$result_callback."\" from callback hash") if $this->{debug};
		return $this->{callbacks}->{$result_callback};
	}
	else {
		my $perl = $this->{xml_doc}->findvalue($CALLBACK_XPATH."[\@".$CALLBACK_NAME_ATTRIBUTE." = '".$result_callback."']");	
		eval('$this->{callbacks}->{$result_callback} = '.$perl.';');

		if (ref($this->{callbacks}->{$result_callback}) eq 'CODE') {
			&{$this->{debug_callback}}(2, "installed result callback \"".$result_callback."\" from XML file in callback hash") if $this->{debug};
			return $this->_read_callback($result_callback);
		}
		else {
			&{$this->{debug_callback}}(2, "callback \"".$result_callback."\" was not found") if $this->{debug};
			return undef;
		}
	}
}



=item _debug($l, $msg);

Default debug-callback. Prints C<$msg> as a debugging message to STDERR. C<$l> gives information about the logging level. 

=cut

sub _debug {
	my ($l, $msg) = @_;	

	print STDERR "   " x $l;
	print STDERR "DEBUG: ".$msg."\n";
}



=item $doc = _result($doc);

Default result-doc-callback. Just returns C<$doc> as it was passed to the subroutine.

=cut

sub _result {
	my ($doc) = @_;	

	return $doc;
}



# Preloaded methods go here.

1;
__END__

=back

=head1 SEE ALSO

The DTD for the session description files can be found at:
  L<http://www.boksa.de/pub/xml/dtd/www-meta-xml-browser_v0.08.dtd>

Documentation and a HOWTO can be found at:
  L<http://www.boksa.de/perl/modules/www-meta-xml-browser/>

=head1 AUTHOR

Benjamin Boksa, E<lt>benjamin@boksa.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Benjamin Boksa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut