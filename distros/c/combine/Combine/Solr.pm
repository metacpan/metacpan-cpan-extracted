package Combine::Solr;

#Direct integration with a running instance of Solr - http://lucene.apache.org/solr/

#Uses the Solr standard example schema ver 1.1 (no changes made)
# with mappings from the standard Combine XML-profile combine to this
# Solr example schema.

#The conversion is done by the XSLT script in /etc/combine/solr.xsl

#Set Combine configuration variable 'SolrHost' to point to the
# update URL for the running instance of your solr installation
# e.g. if your admin interface is http://mymachine.foo.bar:8180/solr/admin/
# then update is at http://mymachine.foo.bar:8180/solr/update

use strict;
use Combine::XWI2XML;
use XML::LibXSLT;
use XML::LibXML;
use LWP::UserAgent;
use HTTP::Request::Common;
use Encode;

sub update {
  my ($solrhost, $xwi) = @_;
  my $xml .= Combine::XWI2XML::XWI2XML($xwi, 0, 0, 1, 1);

  my $parser = XML::LibXML->new();
  my $xslt = XML::LibXSLT->new();
  my $source = $parser->parse_string(Encode::encode('utf8',$xml));
  my $style_doc = $parser->parse_file('/etc/combine/solr.xsl'); #!!!!????
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  my $results = $stylesheet->transform($source);
  $xml = '<add>' . $stylesheet->output_as_bytes($results) .'</add>';

  my $ua = LWP::UserAgent->new;
  my $url = $solrhost;

  my $res = $ua->request(POST $url,  Content_Type => 'text/xml', Content => $xml);

  $res = $ua->request(POST $url,  Content_Type => 'text/xml', Content => '<commit/>');

  return;
}

sub delete {
  my ($solrhost, $md5, $rid) = @_;

  my $ua = LWP::UserAgent->new;
  my $url = $solrhost;
  my $xml ="<delete><id>$rid</id></delete>";

  my $res = $ua->request(POST $url,  Content_Type => 'text/xml', Content => $xml);

  $res = $ua->request(POST $url,  Content_Type => 'text/xml', Content => '<commit/>');

  return;
}

##########################
1;
