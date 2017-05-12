#!/usr/bin/perl -w
#

package eBay::API::XML::t::TidyHelper;

use strict;
use warnings;

use XML::Tidy;

our @EXPORT = qw( tidyXml );


sub tidyXml {
  
  my $strXml = shift;

  my $pTidy = XML::Tidy->new('xml' => $strXml);
  $pTidy->tidy();
  my $tidyStrXml = $pTidy->toString();

  return $tidyStrXml;
}

1;
