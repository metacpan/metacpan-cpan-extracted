#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Data::Dumper;
use Test::More tests => 33;
use XML::IDMEF;

$| = 1;

my($idmef, $str_idmef, $idmef2, $type, $expect, $ST_IDMEF);

#
# dev tests
#

#$idmef = XML::IDMEF::in({}, "idmef.example.2");

$ST_IDMEF="<?xml version='1.0' encoding='UTF-8'?>\n<!DOCTYPE IDMEF-Message PUBLIC '-//IETF//DTD RFC XXXX IDMEF v1.0//EN' 'idmef-message.dtd'>\n<IDMEF-Message version='1.0'>\n<Alert messageid='abc123456789'>\n<Analyzer analyzerid='bc-fs-sensor13'>\n<Node category='dns'>\n<name>fileserver.example.com</name>\n</Node>\n</Analyzer>\n</Alert>\n</IDMEF-Message>";


##
## test: create new message
##

eval {
    $idmef = new XML::IDMEF();
};
is($@,'',"created new empty message OK");

$expect = '<?xml version="1.0" encoding="UTF-8"?>'."\n".'<!DOCTYPE IDMEF-Message PUBLIC "-//IETF//DTD RFC XXXX IDMEF v1.0//EN" "idmef-message.dtd">'."\n";
ok($idmef->out eq $expect, "check message header");

##
## test parsing idmef string
##

eval {
    $idmef = new XML::IDMEF();
    $idmef->in($ST_IDMEF);
};
is($@,'',"test parsing IDMEF message");

##
## test get_type & get_root
##

ok($idmef->get_root eq "IDMEF-Message", "checking root");
ok($idmef->get_type eq "Alert", "check message type");

##
## test: contain key
##

ok($idmef->contains("AlertAnalyzerNode") != 0,       "check contains() on existing node");
ok($idmef->contains("AlertNode") != 1,               "check contains() on non-existing node");
ok($idmef->contains("AlertAnalyzeranalyzerid") != 0, "check contains() on existing tag");
ok($idmef->contains("Alertid") != 1,                 "check contains() on non-existing tag");
    
##
## test: add attributes
##

$idmef = new XML::IDMEF;

eval {
    $idmef->add("AlertTargetNodecategory", "unknown");
    $idmef->add("AlertSourceNodeAddressident", "45");
    $idmef->add("AlertClassificationident", "1");
    $idmef->add("AlertClassificationReferenceorigin", "unknown");
};
is($@,'',"adding some attributes");

$expect = '<IDMEF-Message><Alert><Source><Node><Address ident="45"/></Node></Source><Target><Node category="unknown"/></Target><Classification ident="1"><Reference origin="unknown"/></Classification></Alert></IDMEF-Message>';
ok($idmef->out =~ /.*$expect.*/, "checking resulting message");

##
## test: add nodes
##

eval {
    $idmef->add("AlertAssessment");
    $idmef->add("AlertTargetFileListFileLinkage");
    $idmef->add("AlertTargetFileListFileLinkage");
    $idmef->add("AlertTargetFileList");
};
is($@,'',"adding some nodes");

$expect = '<Target><FileList/></Target><Target><Node category=\"unknown\"/><FileList><File><Linkage/><Linkage/></File></FileList></Target>';
ok($idmef->out =~ /$expect/, "checking resulting message");

##
## test: add content
##

eval {
    $idmef->add("AlertAdditionalData","some text");
    $idmef->add("AlertAdditionalDatatype","xml");
    $idmef->add("AlertAdditionalData","some other text");
};
is($@,'',"adding contents");

$expect = '<IDMEF-Message><Alert><Source><Node><Address ident="45"/></Node></Source><Target><FileList/></Target><Target><Node category="unknown"/><FileList><File><Linkage/><Linkage/></File></FileList></Target><Classification ident="1"><Reference origin="unknown"/></Classification><Assessment/><AdditionalData>some other text</AdditionalData><AdditionalData type="xml">some text</AdditionalData></Alert></IDMEF-Message>';
ok($idmef->out =~ /$expect/, "checking resulting message");

##
## test: adding id 
##

eval {
    $idmef->create_ident();
};
is($@,'',"adding id does not fail");
# TODO: make a real test here

##
## test to_hash
##

eval {
    $idmef->to_hash;
};
is($@,'',"to_hash does not fail");
# TODO: make a real test here

##
## test: create time
##

eval {
    $idmef = new XML::IDMEF;
    $idmef->create_time(125500);
};
is($@,'',"run create_time on new message");

$expect = '<IDMEF-Message><Alert><CreateTime ntpstamp="0x83ac68bc.0x0">1970-01-02-T10:51:40Z</CreateTime></Alert></IDMEF-Message>.*';
ok($idmef->out =~ /$expect/, "checking time returned");

##
## test additionaldata
##

$idmef = new XML::IDMEF;

eval {
    $idmef->add("AlertAdditionalData", "value0"); 
    $idmef->add("AlertAdditionalData", "value1");
    $idmef->add("AlertAdditionalDatameaning", "data1");
    $idmef->add("AlertAdditionalData", "value2", "data2");   
    $idmef->add("AlertAdditionalData", "value3", "data3", "string");
};
is($@,'','add AdditionalData node');

$expect = '<IDMEF-Message><Alert><AdditionalData meaning="data3" type="string">value3</AdditionalData><AdditionalData meaning="data2" type="string">value2</AdditionalData><AdditionalData meaning="data1">value1</AdditionalData><AdditionalData>value0</AdditionalData></Alert></IDMEF-Message>';
ok($idmef->out =~ /$expect/, "check messages");

##
## test set()
##

my $err;

# change existing tag
eval {
    $idmef->set("AlertAdditionalData", "this is a new value changed with set()");
};
is($@,'','set existing node content');

eval {
    $idmef->set("AlertAdditionalDatameaning", "this is a new meaning changed with set()");
};
is($@,'','set existing attribute value');

# changing non-existing tag
eval {
    $idmef->set("AlertTargetNodeAddressaddress", "blob");
};
isnt($@,'','set non-existing tag');

# changing non content node
eval {
    $idmef->set("Alert", "blob");
};
isnt($@,'','set non existing node content');

##
## test get()
##

my $v;

# get existing content
eval {
    $v =  $idmef->get("AlertAdditionalData");
};
is($@,'','get existing node content');
ok($v eq "this is a new value changed with set()", "check content");

# get existing attribute
eval {
    $v =  $idmef->get("AlertAdditionalDatameaning");
};
is($@,'','get existing node attribute');
ok($v eq "this is a new meaning changed with set()", "check attribute");

# get non existing content
eval {
    $v =  $idmef->get("AlertTargetNodeAddressaddress");
};
is($@,'','get non-existing node content');
ok(!defined($v), "get: returned no content when getting non existent content.");

##
## test encoding of special characters
##

my $string1 = "hi bob&\"&amp;&#x0065";

$idmef = new XML::IDMEF;

$idmef->add("AlertAdditionalData", "$string1");

$expect = '<IDMEF-Message><Alert><AdditionalData>hi bob&amp;&quot;&amp;amp;&amp;#x0065</AdditionalData></Alert></IDMEF-Message>';
ok($idmef->out =~ /$expect/, "add() handling of special characters according to XML specs");

##
## test adding 2 similar nodes
##

$idmef = new XML::IDMEF;

$idmef->add("AlertAnalyzerNodeAddresscategory", "ipv4-addr");
$idmef->add("AlertAnalyzerNodeAddressaddress",  "1.1.1.1");

$idmef->add("AlertAnalyzerNodeAddresscategory", "ipv4-addr");
$idmef->add("AlertAnalyzerNodeAddressaddress",  "2.2.2.2");

$expect = '<IDMEF-Message><Alert><Analyzer><Node><Address category="ipv4-addr"><address>2.2.2.2</address></Address><Address category="ipv4-addr"><address>1.1.1.1</address></Address></Node></Analyzer></Alert></IDMEF-Message>';

ok($idmef->out =~ /$expect/, "checking that multiple add() bug is solved");





