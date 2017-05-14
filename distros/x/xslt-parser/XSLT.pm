################################################################################
#
# Perl module: XSLT
#
# By Geert Josten, gjosten@sci.kun.nl
# and Egon Willighagen, egonw@sci.kun.nl
#
################################################################################

######################################################################
package XSLT;
######################################################################
use strict;
push (@INC, ".");

BEGIN {
  use XML::XSLTParser;
  use Exporter ();
  use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK);

  do "version.h";

  @ISA         = qw( Exporter );
  @EXPORT_OK   = qw( $Parser $debug);

  use vars @EXPORT_OK;
  $XSLT::Parser = "";
  $XSLT::Parser = new XSLTParser;
}

use vars qw ( $xsl $xml $result $DOMparser $outputstring);

1;
