package WWW::Page;

use vars qw ($VERSION);
$VERSION = '2.2';

use XML::LibXML;
use XML::LibXSLT;
use File::Cache::Persistent;
use XSLT::Cache;

sub new {
	my $class = shift;
	my $args = shift;

	my $this = {
		charset	         => $args->{'charset'} || 'UTF-8',
		content_type     => $args->{'content-type'} || 'text/html',
		content          => '',
		source           => $args->{'source'} || $ENV{'PATH_TRANSLATED'},
		script_filename  => $args->{'script-filename'} || $ENV{'SCRIPT_FILENAME'},
		lib_root         => $args->{'lib-root'},
		document_root    => $args->{'document-root'} || $ENV{'DOCUMENT_ROOT'},
		xslt_root        => $args->{'xslt-root'} || "$ENV{'DOCUMENT_ROOT'}/xsl",
		request_uri      => $args->{'request-uri'} || $ENV{'REQUEST_URI'},

		xml              => undef,
		code             => undef,
		xml_cache        => new File::Cache::Persistent(
			reader  => \&xml_reader,
			timeout => $args->{'timeout'} || undef
		),
		xsl_cache        => new XSLT::Cache(
			timeout => $args->{'timeout'} || undef
		),
		xslt_path        => undef,
	};

	bless $this, $class;

	return $this;
}

sub run {
	my ($this, %args) = @_;

	$this->{'param'} = _read_params();
	
	$this->{'header'} = {
		'Content-Type' => "$this->{'content_type'}; charset=$this->{'charset'}"
	};

	for my $key (keys %args) {
		$this->{$key} = $args{$key};
	}

	$this->readSource();
	$this->appendInfo();

	$this->importCode();
	$this->executeCode();

	$this->readXSL();
	$this->transformXML();
}

sub as_string {
	my $this = shift;

	$this->run();

	return $this->response();
}

sub response {
	my $this = shift;

	return $this->header() . $this->content();
}

sub readSource {
	my $this = shift;

	my $cache = $this->{'xml_cache'}->get($this->{'source'});

	my $cache_dom = $cache->documentElement()->cloneNode(1);

	my $dom = new XML::LibXML::Document();
	$dom->setDocumentElement($cache_dom);
	$this->{'xml'} = $dom;
	
	my @contentType = $this->{'xml'}->findnodes('/page/@content-type');
	if (@contentType) {
		$this->{'header'}->{'Content-Type'} = $contentType[0]->firstChild->data;
	}
}

sub xml_reader {
	my $path = shift;

	my $xmlParser = new XML::LibXML();

	return $xmlParser->parse_file($path);
}

sub xsl_reader {
	my $path = shift;

	my $xslParser = new XML::LibXSLT();

	return $xslParser->parse_file($path);
}

sub appendInfo {
	my $this = shift;

	my @manifest = $this->{'xml'}->findnodes('/page/manifest');
	if (@manifest) {
		my $manifest = $manifest[0];

		my $request = new XML::LibXML::Element('request');
		$manifest->appendChild($request);
		
		$request->appendTextChild('server', $ENV{SERVER_NAME});
		my ($uri, $query_string) = split /\?/, $this->{'request_uri'}, 2;		
		$request->appendTextChild('uri', $uri);
		$request->appendTextChild('query-string', $query_string);

		my $source = $this->{'source'};
		$source =~ s{^$ENV{DOCUMENT_ROOT}}{};
		$request->appendTextChild('source', $source);

		my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime (time);
		my $dateNode = new XML::LibXML::Element('date');
		$manifest->appendChild($dateNode);
		$dateNode->setAttribute('year', 1900 + $year);
		$dateNode->setAttribute('day', $mday);
		$dateNode->setAttribute('month', $mon + 1);
		$dateNode->setAttribute('hour', $hour);
		$dateNode->setAttribute('min', $min);
		$dateNode->setAttribute('sec', $sec);
		$dateNode->setAttribute('wday', $wday);
	}
}

sub importCode {
	my $this = shift;

	my $base = $this->{'lib_root'};
	unless ($base) {
		$base = $this->{'script_filename'};
		($base) = $base =~ m{^(.*)/[^/]+$};
	}
	unshift @INC, $base;

	my @imports = $this->{'xml'}->findnodes('/page/@import');
	if (@imports) {
		my $module = $imports[0]->firstChild->data;
		my $pm = $module;
		$pm =~ s{::}{/}g;
		$pm .= '.pm';
		require "$base/$pm";
		$this->{'code'} = $module->import();
	}
}

sub readXSL {
	my $this = shift;

	if (defined $this->param('viewxml')) {
		$this->{'header'}->{'Content-Type'} = "text/xml; charset=$this->{'charset'}";
		return;
	}

	my $base = $this->{'xslt_root'};
	my @transforms = $this->{xml}->findnodes('/page/@transform');

	if (@transforms) {
		$this->{'xslt_path'} = "$base/" . $transforms[0]->firstChild->data;
	}
	else {
		$this->{'xslt_path'} = undef;
		$this->{'header'}->{'Content-Type'} = 'text/xml';
	}
}

sub executeCode {
	my $this = shift;

	my $context = new XML::LibXML::XPathContext;
	$context->registerNs('page', 'urn:www-page');

	my @codeNodes = $context->findnodes('/page//page:*', $this->{'xml'});
	foreach my $codeNode (@codeNodes) {
		my $nodeName = $codeNode->nodeName();
		$nodeName =~ s/^.*://;
		my $function = $nodeName;
		$function =~ s/-(\w)?/defined $1 ? uc $1 : '_'/ge;

		my @attributes = $codeNode->getAttributes();
		my %arguments = ();
		foreach my $attribute (@attributes){
			$arguments{$attribute->nodeName()} = $attribute->value();
		}

		my $newNode = new XML::LibXML::Element($nodeName);
		$newNode = $this->{'code'}->$function($this, $newNode, \%arguments);
		$codeNode->replaceNode ($newNode);
	}
}

sub transformXML {
	my $this = shift;

	if ($this->{'xslt_path'} && !defined $this->param('viewxml')) {
	    eval {
        	    $this->{'content'} = $this->{'xsl_cache'}->transform($this->{'xml'}, $this->{'xslt_path'});
	    };
	    if ($@) {
		$this->{'reader_error'} = $this->{'xsl_cache'}->reader_error();
	    }
	}
	else {
	    $this->{'content'} = $this->{'xml'}->toString();
	}
}

sub clearXSLcache {
    my $this = shift;
    
    $this->{'xsl_cache'}->remove($this->{'xslt_path'}) if defined $this->{'xslt_path'};
}

sub header {
	my $this = shift;

	my $ret = '';
	foreach my $key (keys %{$this->{'header'}}){
		my $value = $this->{'header'}->{$key};
		$ret .= "$key: $value\n";
	}

	return "$ret\n";
}

sub content {
	my $this = shift;

	return $this->{'content'};
}

sub error {
    my $this = shift;
    
    return $this->{'reader_error'};
}

sub param {
	my $this = shift;
	my $name = shift;

	return $this->{'param'}->{$name};
}

sub _read_params {
	my $params = '';

	my %param = ();
	if ($ENV{CONTENT_TYPE} =~ m/multipart\/form-data/){
		# parse_multipart();
		# to get uploaded files you should use either some kind of CGI module or future version of WWW::Page :-)
	}
	else {
		my $buf;
		my $BUFLEN = 4096;
		while (my $bytes = sysread STDIN, $buf, $BUFLEN) {
			if ($bytes == $BUFLEN) {
				$params .= $buf;
			}
			else {
				$params .= substr $buf, 0, $bytes;
			}
		}
	}

	$params .= '&' . $ENV{QUERY_STRING};
	foreach (split /&/, $params) {
		my ($name, $value) = (m/(.*)=(.*)/);
		if ($name =~ /\S/) {
			$param{$name} = _urldecode($value);
		}
	}

	return \%param;
}

sub _urldecode {
	my $val = shift;

	# Known limitation: currently does not support Unicode query strings. Use future versions.

	$val =~ s/\+/ /g;
	$val =~ s/%([0-9A-H]{2})/pack('C',hex($1))/ge;

	return $val;
}

1;

=head1 NAME

WWW::Page - XSLT-based and XML-configured website engine

=head1 SYNOPSIS

mod_perl custom handler

 use WWW::Page;

 my $page = new WWW::Page({
     'xslt-root' => "$ENV{DOCUMENT_ROOT}/../data/xsl",
     'lib-root'  => "$ENV{DOCUMENT_ROOT}/../lib",
     'timeout'   => 30,
 });

 sub handler {
    my $r = shift;

     $page->run(
         source      => "$ENV{DOCUMENT_ROOT}/index.xml",
         request_uri => $ENV{REQUEST_URI}
     );
     print $page->response();

     return Apache2::Const::OK;
 }

XML-based page description

 <?xml version="1.0" encoding="UTF-8"?>
 <page
     import="Import::Client"
     transform="view.xsl"
     xmlns:page="urn:www-page">

     <manifest>
         <title>My website</title>
         <locale>en-gb</locale>
         <page:keyword-list/>
     </manifest>

     <content>
         <page:month-calendar/>
     </content>
 </page>

Parts of imported controller script

 package Import::Client;
 use utf8;
 use XML::LibXML;

 sub keywordList
 {
     my ($this, $page, $node, $args) = @_;

     my $sth = $dbh->prepare("select keyword, uri from keywords order by keyword");
     $sth->execute();
     while (my ($keyword, $uri) = $sth->fetchrow_array())
     {
         my $item = $page->{'xml'}->createElement ('item');
         $item->appendText($keyword);
         $item->setAttribute('uri', $uri);
         $node->appendChild($item);
     }

     return $node;
 }

=head1 ABSTRACT

WWW::Page makes website built on XSLT technology easy to start. It provides simple mechanism to describe
behaviour of pages in XML files, adds external logic and applies XSL transformations. Both XML and XSLT files
are being transparently caching.

=head1 DESCRIPTION

This module provides a framework for organizing XSLT-based websites. It allows to put the process of
calling user subroutines and applying XSL transformations behind the scene. Wherever possible, XML and XSL
documents are cached which eliminates the need of useles reloading and re-parsing them.

=head1 EXAMPLE

Directory C<example> in the repository contains an example of sample website running under mod_perl and WWW::Page.

=head2 Known limitations

GET and POST parser cannot accept uploaded files and Unicode-encoded strings.

Example does allow only one editor user; only latin symbols may be in keyword list.

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENCE

WWW::Page module is a free software.
You may resistribute and (or) modify it under the same terms as Perl.

=cut
