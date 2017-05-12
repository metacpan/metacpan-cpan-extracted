# -*- mode: cperl -*-
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.  
# All Rights Reserved.
# 
# Contributor(s): Anselm Kruis
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
# use lib qw"../blib/lib ../blib/arch";

use vars qw ( $loaded );

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use strict;
use XML::Sablotron;
use XML::Sablotron::DOM;
use XML::Sablotron::DOM::DOMHandler DO_INJECT => 1;
use XML::Sablotron::Situation::DOMHandlerDispatcher;

# *XML::Sablotron::DOM::DOMHandler::_DHdumpNode = \&XML::Sablotron::DOM::DOMHandler::_DHdumpNode_debug;
# $XML::Sablotron::Situation::DOMHandlerDispatcher::_debug_ret=1;

$loaded = 1;
print "ok 1\n" if $loaded;

#### test documents

my $glob_sheet = <<_eof_;
<?xml version='1.0'?>
<xsl:stylesheet version='1.0'
		xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

  <xsl:output method='text' omit-xml-declaration='yes'/>

  <xsl:template match='/root'>
      <xsl:text>prefix: </xsl:text>
      <xsl:apply-templates select='data'/>
  </xsl:template>

  <xsl:template match='data'>
      <xsl:value-of select='text()'/>
  </xsl:template>

</xsl:stylesheet>
_eof_

my $glob_doc = <<_eof_;
<?xml version='1.0'?>
<root>
  <data>a</data>
  <data>b</data>
  <data>c</data>
</root>
_eof_


######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test = 1;
my $sit = new XML::Sablotron::Situation();

# test create the DomHandler
$test++;
$sit->regDOMHandler( new XML::Sablotron::Situation::DOMHandlerDispatcher() );

# test create new sablotron
my $sab    = new XML::Sablotron($sit);
# my $sab    = new XML::Sablotron();

print "ok $test\n";


################ test the processing of the parsed document
$test++;

my $sheet = XML::Sablotron::DOM::parseStylesheetBuffer($sit, $glob_sheet);
$sab->addArgTree($sit, "sheet", $sheet);

#parse and populate the document
my $pdoc = XML::Sablotron::DOM::parseBuffer($sit, $glob_doc);

my $ee = $pdoc->createElement("data");
my $tt = $pdoc->createTextNode("d");

$ee->appendChild($tt);
$pdoc->getFirstChild->appendChild($ee);

$pdoc->lockDocument();

# print STDERR "\n", $pdoc->toString($sit), "\n";

#process
$sab->process($sit, "arg:/sheet", $pdoc, "arg:/result");

my $ret = $sab->getResultArg("result");
# print STDERR "t3: ret:", $ret, "\n";
print ($ret eq "prefix: abcd" ? "ok $test\n" : "not ok $test\n");

# cleanup code
################ test cleanup
$test++;

$pdoc->freeDocument();
$pdoc=undef;
$sit->unregDOMHandler();

print "ok $test\n";

