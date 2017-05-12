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
</font><font color="teal">XML-DCL: </font><font color="olive"> Version='1.0' Encoding='ISO-8859-1'
</font><font color="navy">DOCTYPE: </font><font color="olive"> Name='mytype' SystemId='http://www.some.org/TR/mytype/DTD/somewhere-transitional.dtd' PublicId='-//A//DTD MYTYPE 1.0 Transitional//EN'
</font><font color="maroon">PI: </font><font color="purple"></font><font color="olive"> Target='PROCESSTHIS' Data='"now" '
</font><font color="green">COMMENT: </font><font color="purple"></font> 'example of a comment'
<font color="fuchsia">ROOT: start
</font><font color="purple">start</font><font color="olive"> atthe='beginning'</font>
  <font color="purple">myelement</font>
    <font color="blue">TEXT: </font><font color="purple">myelement</font> 'This is text'
  <font color="purple">anotherone</font>
    <font color="blue">TEXT: </font><font color="purple">anotherone</font> '&lt;greeting&gt;Hello, world!&lt;/greeting&gt;'
  <font color="purple">myelement</font><font color="olive"> withan='entity'</font>
    <font color="fuchsia">ENTITY: </font>'anentity'
    <font color="blue">TEXT: </font><font color="purple">myelement</font> 'That's an entity.'

<font color="fuchsia">TOTALS:     </font><font color="olive">2 ATTRIBUTE, 1 CDATA, 1 COMMENT, 1 DOCTYPE, 4 ELEMENT, 1 ENTITY, 1 PI, 3 TEXT, 1 XML-DCL</font>
<font color="fuchsia">ELEMENTS:   </font><font color="olive">1 anotherone, 2 myelement, 1 start</font>
<font color="fuchsia">ATTRIBUTES: </font><font color="olive">1 atthe, 1 withan</font>
<font color="fuchsia">ATTRVALUES: </font><font color="olive">1 'beginning', 1 'entity'</font>
<font color="fuchsia">ENTITIES:   </font><font color="olive">1 anentity</font>
REPORT

my $parse = XML::DocStats->new(xmlsource=>{String => $xml});
$parse->print_htmlpage('no');
my @report = split/\n/,$parse->analyze(format=>'html',output=>'return');

pop @report;
shift @report;

ok( $report eq join("\n",@report)."\n" , 'parses and reports html correctly' );

#########################
