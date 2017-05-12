package Combine::Lucene;
use XML::LibXML;
sub update
{
  my($idxpath,$xwi) = @_;
  my $create = 0;
  unless (-e $idxpath) {
    $create = 1;
  }
  my $indexer = new LuceneIndexer($idxpath,$create,1000000);
  my $xml =  '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
     $xml .= "<documentCollection>\n";
     $xml .= Combine::XWI2XML::XWI2XML($xwi, 0, 0);
     $xml .= "</documentCollection>\n";

  my $parser = XML::LibXML->new();

  my $xmldoc = $parser->parse_string($xml);
#  printf "$xml\n";
  my @records = $xmldoc->getElementsByTagName('documentRecord');
  for my $rec (@records) {
    $recid = $rec->getAttribute('id');
#    printf "$recid\n";
    #delete exisit record
    $indexer->deleteDocuments("id",$recid);
    my $doc = $indexer->newDocument();
    $indexer->addField($doc,$indexer->newField("id",$recid,"YES","NOT_ANALYZED_NO_NORMS"));

    for my $child ($rec->getChildNodes()) {
      if ($child->nodeType == XML::LibXML::XML_ELEMENT_NODE)
      {
        my $chname = $child->nodeName();
#        printf "$chname\n";
        my $val, $subtag;
        if ($chname eq "modifiedDate") {
          $val = $child->textContent;
          $indexer->addField($doc,$indexer->newField("modifiedDate",$val,"YES","NOT_ANALYZED_NO_NORMS"));
                   
        } elsif ($chname eq "urls") {          
          for $subtag ($child->getChildNodes()) {
            if ($subtag->nodeType == XML::LibXML::XML_ELEMENT_NODE && $subtag->nodeName eq 'url') {
                $val = $child->textContent();
                $indexer->addField($doc,$indexer->newField("url",$val,"YES","NOT_ANALYZED_NO_NORMS"));
              }
          }
        } elsif ($chname eq "metaData") {
          for $subtag ($child->getChildNodes()) {
            if ($subtag->nodeType == XML::LibXML::XML_ELEMENT_NODE && $subtag->nodeName eq 'meta') {
              if ($subtag->getAttribute('name') eq 'title') {
                $val = $subtag->textContent();
                $indexer->addField($doc,$indexer->newField("title",$val,"NO","ANALYZED"));
              }
            }
          }
        } elsif ($chname eq "canonicalDocument") {
          for $subtag ($child->getChildNodes()) {
            if ($subtag->nodeType == XML::LibXML::XML_ELEMENT_NODE && $subtag->nodeName eq 'section') {
              $val = $subtag->textContent();           
              $indexer->addField($doc,$indexer->newField("canonicalDocument",$val,"NO","ANALYZED"));
            }
          }
        } elsif ($chname eq "links") {
        } elsif ($chname eq "property") {
          my $pname = $child->getAttribute('name');
          if ($pname eq 'country') {
            $val = $child->textContent();
            $indexer->addField($doc,$indexer->newField("country",$val,"YES","NOT_ANALYZED_NO_NORMS"));
          }
        }

      }
    }

    $indexer->addDocument($doc);
  }

  $indexer->close();
}
1;


