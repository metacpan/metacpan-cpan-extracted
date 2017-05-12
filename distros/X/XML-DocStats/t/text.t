# Before `make install' is performed this script should be runnable with
# `make test'.

#########################

use lib qw(t/lib);

use Test::Simple tests => 1 ;

use XML::DocStats;

my $xml = <<XML;
<?xml version='1.0' encoding='ISO-8859-1' ?>
<!DOCTYPE mytype PUBLIC "-//A//DTD MYTYPE 1.0 Transitional//EN"
    "http://www.some.org/TR/mytype/DTD/somewhere-transitional.dtd">
<?PROCESSTHIS "now" ?>
<!-- example of a comment -->
<start atthe="beginning">
<myelement>This is text</myelement>
<anotherone><![CDATA[<greeting>Hello, world!</greeting>]]></anotherone>
<myelement withan="entity">&anentity;That's an entity.</myelement>
</start>
XML

my $report=<<REPORT;
XML-DCL:  Version='1.0' Encoding='ISO-8859-1'
DOCTYPE:  Name='mytype' SystemId='http://www.some.org/TR/mytype/DTD/somewhere-transitional.dtd' PublicId='-//A//DTD MYTYPE 1.0 Transitional//EN'
PI:  Target='PROCESSTHIS' Data='"now" '
COMMENT:  'example of a comment'
ROOT: start
start atthe='beginning'
  myelement
    TEXT: myelement 'This is text'
  anotherone
    TEXT: anotherone '<greeting>Hello, world!</greeting>'
  myelement withan='entity'
    ENTITY: 'anentity'
    TEXT: myelement 'That's an entity.'

TOTALS:     2 ATTRIBUTE, 1 CDATA, 1 COMMENT, 1 DOCTYPE, 4 ELEMENT, 1 ENTITY, 1 PI, 3 TEXT, 1 XML-DCL
ELEMENTS:   1 anotherone, 2 myelement, 1 start
ATTRIBUTES: 1 atthe, 1 withan
ATTRVALUES: 1 'beginning', 1 'entity'
ENTITIES:   1 anentity
REPORT

my $parse = XML::DocStats->new(xmlsource=>{String => $xml});
my @report = split/\n/,$parse->analyze(format=>'text',output=>'return');

pop @report;
shift @report;

ok( $report eq join("\n",@report)."\n" , 'parses and reports text correctly' );


#########################

