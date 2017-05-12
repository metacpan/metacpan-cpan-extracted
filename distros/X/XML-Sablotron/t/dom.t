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
# Contributor(s):
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

use vars qw ( $loaded );

BEGIN { $| = 1; print "1..39\n"; }
END {print "not ok 1\n" unless $loaded;}

require  XML::Sablotron;
require  XML::Sablotron::DOM;
use strict;

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

# test create the document
$test++;
my $doc = new XML::Sablotron::DOM::Document( SITUATION => $sit );
my $type = $doc->getNodeType();
print ($type == 9 ? "ok $test\n" : "not ok $test\n");

# test document type
$test++;
my $type2 = $doc->nodeType();
print ($type2 == 9 ? "ok $test\n" : "not ok $test\n");

# test document name
$test++;
my $name = $doc->getNodeName();
my $name2 = $doc->nodeName();
print ($name eq "#document" && $name eq $name2 ? "ok $test\n" : "not ok $test\n");

# test document value
$test++;
my $value = $doc->getNodeValue();
my $value2 = $doc->nodeValue();
print (! defined $value && ! defined $value ? "ok $test\n" : "not ok $test\n");

# test exception for setNodeName
## $test++;
## dumps core
##

# test parent node for document 
$test++;
my $parent = $doc->getParentNode();
my $parent2 = $doc->parentNode();
print (!defined $parent && !defined $parent2 ? "ok $test\n" : "not ok $test\n");

# test owner document for doc
$test++;
my $odoc = $doc->getOwnerDocument();
print (!defined $odoc ? "ok $test\n" : "not ok $test\n");

# test first child for empty doc
$test++;
my $child = $doc->getFirstChild();
my $child2 = $doc->firstChild();
print (!defined $child && !defined $child2 ? "ok $test\n" : "not ok $test\n");

# test last child for empty doc
$test++;
$child = $doc->getLastChild();
$child2 = $doc->lastChild();
print (!defined $child && !defined $child2 ? "ok $test\n" : "not ok $test\n");

############# Element tests ################

# test new element 
$test++;
my $e = $doc->createElement("boot");
$type = $e->getNodeType();
$type2 = $e->nodeType();
print ($type == 1 && $type2 == 1 ? "ok $test\n" : "not ok $test\n");;

# test node name #10
$test++;
$name = $e->getNodeName();
$name2 = $e->nodeName();
print ($name eq "boot" && $name2 eq "boot" ? "ok $test\n" : "not ok $test\n");;

# test rename node (element)
$test++;
$e->nodeName("root2");
$name2 = $e->nodeName();
$e->setNodeName("root");
$name = $e->getNodeName();
print ($name eq "root" && $name2 eq "root2" ? "ok $test\n" : "not ok $test\n");;

# test set attribute
$test++;
$e->setAttribute("att1", "att_value");
my $att = $e->getAttribute("att1");
print ($att eq "att_value" ? "ok $test\n" : "not ok $test\n");

# test simple tree
$test++;
$doc->insertBefore($e, undef);
my $e1 = $doc->getFirstChild();
print ($e->equals($e1) ? "ok $test\n" : "not ok $test\n");

# test parent node (15)
$test++;
my $doc1 = $e->getParentNode();
#print "+++> ", $doc->{_handle}, ", ", $doc1->{_handle}, "\n";
print ($doc->{_handle} == $doc1->{_handle} ? "ok $test\n" : "not ok $test\n");

# test owner document
$test++;
$doc1 = $e->getOwnerDocument();
my $doc2 = $e->ownerDocument();
#print "+++> $doc, $doc1\n";
print ($doc->equals($doc1) && $doc->equals($doc2) ? "ok $test\n" : "not ok $test\n");

############################################################
# test tree functions

# prepare tree
my $c1 = $doc->createElement("child1");
my $c2 = $doc->createElement("child2");
my $c3 = $doc->createElement("child3");
my $cx = $doc->createElement("childX");

my $cc1 = $e->appendChild($c1);
$e->appendChild($c3);
my $cc3 = $e->insertBefore($c2, $c3);

# test childNodes and childNodesArr
$test++;
my $nodes = $e->childNodes();
my $nodeArr = $e->childNodesArr();
my $i = 0;
my $mychild = $e->firstChild();
my $result = 1;
while ( defined($mychild) ) {
    $result = $result && ( $nodes->item($i)->equals($mychild) );
    $result = $result && ( $nodeArr->[$i]->equals($mychild) );
    $i++;
    $mychild = $mychild->nextSibling();
};
$result = $result && ( $nodes->length() == $i );
$result = $result && ( @$nodeArr == $i );
$result = $result && ( !defined($nodes->item($i)) );
#childNodes attributte is live:
my $tmp = $doc->createElement("tmp");
$e->appendChild($tmp);
$result = $result && ( $nodes->item($i)->equals($tmp) );
$e->removeChild($tmp);

print ($result ? "ok $test\n" : "not ok $test\n");

# test first child
$test++;
$e1 = $e->getFirstChild();
my $e2 = $e->firstChild();
print ($e1->equals($c1) && $e2->equals($c1) ? "ok $test\n" : "not ok $test\n");

#test last child
$test++;
$e1 = $e->getLastChild();
$e2 = $e->lastChild();
print ($e1->equals($c3) && $e2->equals($c3) ? "ok $test\n" : "not ok $test\n");

# test next sibling
$test++;
$e1 = $e->getFirstChild();
$e1 = $e1->getNextSibling();
$e2 = $e->firstChild();
$e2 = $e2->nextSibling();
print ($e1->equals($c2) && $e2->equals($c2) ? "ok $test\n" : "not ok $test\n");

# test previous sibling
$test++;
$e1 = $e->getLastChild();
$e1 = $e1->getPreviousSibling();
$e2 = $e->lastChild();
$e2 = $e2->previousSibling();
print ($e1->equals($c2) && $e2->equals($c2) ? "ok $test\n" : "not ok $test\n");

# test insert before child
$test++;
my $ct1 = $doc->createElement("temp1");
$e->appendChild($ct1);
my $ct2 = $doc->createElement("temp2");
my $cct2 = $e->insertBefore($ct2,$ct1);
print ($e->lastChild()->previousSibling()->equals($cct2) ? "ok $test\n" : "not ok $test\n");
$e->removeChild($ct1);
$e->removeChild($cct2);

# test replace child
$test++;
$e->replaceChild($cx, $c2);
$e1 = $e->getFirstChild();
$e1 = $e1->getNextSibling();
print ($e1->equals($cx) ? "ok $test\n" : "not ok $test\n");

# test remove child
$test++;
my $c3Name = $c3->nodeName();
my $removed = $e->removeChild($c3);
my $removedName = $removed->nodeName();
$e1 = $e->getLastChild();
print ($e1->equals($cx) && $c3Name eq $removedName ? "ok $test\n" : "not ok $test\n");

# test append child
$test++;
$ct1 = $doc->createElement("temp");
$ct2 = $e->appendChild($ct1);
print ($e->lastChild()->equals($ct2) ? "ok $test\n" : "not ok $test\n");
$e->removeChild($ct2);

# test hasChildNodes
$test++;
print ($e->hasChildNodes() && ! $e->firstChild()->hasChildNodes() ? "ok $test\n" : "not ok $test\n");

# test cloneNode
$test++;
$e->appendChild($e->lastChild()->cloneNode(1));
print ($e->lastChild()->nodeName() eq $e->lastChild()->previousSibling()->nodeName() ? "ok $test\n" : "not ok $test\n");
$e->removeChild($e->lastChild());

# test normalize
$test++;
# does nothing :)
$e->normalize();
print ("ok $test\n");

# test isSupported
$test++;
# returns false already
print ( !$e->isSupported("someFeature") ? "ok $test\n" : "not ok $test\n");

#test createElementNS #30
$test++;
$e->appendChild($doc->createElementNS("uri_a","a:name"));
print ($e->lastChild()->nodeName() eq "a:name" ? "ok $test\n" : "not ok $test\n");


# test namespaceURI
$test++;
print ($e->lastChild()->namespaceURI() eq "uri_a" ? "ok $test\n" : "not ok $test\n");

$e->removeChild($e->lastChild());

# test textual node
$test++;
my $t = $doc->createTextNode("my text");
$type = $t->getNodeType();
print ($type == 3 ? "ok $test\n" : "not ok $test\n");

# test get node value
$test++;
my $str = $t->getNodeValue();
my $str2 = $t->nodeValue();
print ($str eq "my text" && $str2 eq "my text" ? "ok $test\n" : "not ok $test\n");

# test set node value
$test++;
$t->nodeValue("new text 2");
$str2 = $t->nodeValue();
$t->setNodeValue("new text");
$str = $t->getNodeValue();
print ($str eq "new text" && $str2 eq "new text 2" ? "ok $test\n" : "not ok $test\n");

$c1->appendChild($t);

# test clone
$test++;
my $docc = new XML::Sablotron::DOM::Document( SITUATION => $sit );
my $cloned = $docc->cloneNode($c1, 1);
$docc->appendChild($cloned);
$str = $docc->getFirstChild->getFirstChild->getNodeValue;
print ($str eq "new text" ? "ok $test\n" : "not ok $test\n");

# test declaring namespace via element::setAttribute
$test++;
$ct1 = $doc->createElement("e_temp");
$ct2 = $doc->createElement("e2_temp");
my $ct3 = $doc->createElement("e3_temp");
$e->appendChild($ct1);
$ct1->appendChild($ct2);
$e->setAttribute("xmlns:tmp","uri_tmp");
$ct2->appendChild($ct3);
$ct3->setAttribute("tmp:attr","val");
$result = $ct3->getAttribute("xmlns:tmp") eq "uri_tmp";
my $attr2 = $doc->createAttribute("attr2");
$ct3->setAttributeNode($attr2);
$result = $result && $ct3->removeAttributeNode($attr2)->equals($attr2); 
$e->removeChild($ct1);
print ( $result ? "ok $test\n" : "not ok $test\n");

# test element::getAttributeNS
$test++;
$ct1 = $doc->createElement("e_temp");
$e->appendChild($ct1);
$ct1->setAttribute("xmlns:tmp","uri_tmp");
$ct1->setAttribute("tmp:attr","val");
$result = $ct1->getAttributeNS('uri_tmp',"attr") eq "val";
$result = $result && $ct1->getAttributeNS('http://www.w3.org/2000/xmlns/',"tmp") eq "uri_tmp";
$e->removeChild($ct1);
print ( $result ? "ok $test\n" : "not ok $test\n");




# # test get attributes
# $test++;
# $cx->setAttributes({ a =>"a1", 
# 		     b => "b1", 
# 		     c => "c1"});
# my $attrs = $cx->getAttributes();
# my $ok = $$attrs{a} eq "a1" && $$attrs{b} eq "b1" && $$attrs{c} eq "c1";
# print ($ok ? "ok $test\n" : "not ok $test\n");

# #test removeAttribute
# $test++;
# $cx->removeAttribute("c");
# $attrs = $cx->getAttributes();
# $ok = $$attrs{a} eq "a1" && $$attrs{b} eq "b1";
# print ($ok ? "ok $test\n" : "not ok $test\n");

# test xql
$test++;
$e1 = $doc->getFirstChild();
my $arr = $e1->xql("*");
print (scalar @$arr == 2 ? "ok $test\n" : "not ok $test\n");

################ test the processing of the parsed document
$test++;
my $sab = new XML::Sablotron();

#$sab->addArg($sit, "sheet", $glob_sheet);

my $sheet = XML::Sablotron::DOM::parseStylesheetBuffer($sit, $glob_sheet);
$sab->addArgTree($sit, "sheet", $sheet);

#parse and populate the document
my $pdoc = XML::Sablotron::DOM::parseBuffer($sit, $glob_doc);

my $ee = $pdoc->createElement("data");
my $tt = $pdoc->createTextNode("d");

$ee->appendChild($tt);
$pdoc->getFirstChild->appendChild($ee);

#process
$sab->addArgTree($sit, "data", $pdoc);
$sab->process($sit, "arg:/sheet", "arg:/data", "arg:/result");


my $ret = $sab->getResultArg("result");
print ($ret eq "prefix: abcd" ? "ok $test\n" : "not ok $test\n");


# cleanup code
#print $doc->toString($sit), "\n";
$doc->freeDocument();
undef $doc;
undef $doc1;


__END__
