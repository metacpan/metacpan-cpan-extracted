package WWW::Wikipedia::TemplateFiller::Source::PubmedcentralId;
use base 'WWW::Wikipedia::TemplateFiller::Source::PubmedId';

use WWW::Mechanize;
use XML::LibXML;

sub get {
  my( $self, $pmcid ) = @_;
  my $www = new WWW::Mechanize();
  $www->get(sprintf 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pmc&id=%s&db=pubmed', $pmcid );
  my $xml = $www->content;
  my $parser = new XML::LibXML();
  my $doc = $parser->parse_string($xml);
  my $pmid = $doc->findvalue('/eLinkResult/LinkSet/LinkSetDb[LinkName="pmc_pubmed"]/Link/Id');

  # Route through $self->filler->get rather than $self->SUPER::get()
  # so that we consistently use filler's get() as an entry point. This
  # was introduced during the fix for ticket #41053.
  return $self->filler->get( pubmed_id => $pmid );
}

1;
