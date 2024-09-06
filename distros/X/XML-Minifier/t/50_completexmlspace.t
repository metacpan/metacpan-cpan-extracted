use strict;
use warnings;

use Test::More 0.98;

my $dtdattr = << "END";
<?xml version="1.0"?>
<!DOCTYPE root [
<!ELEMENT root (elem)*>
<!ELEMENT elem EMPTY>
<!ATTLIST elem xml:space (default | preserve) "default">
]>
<root>
	<elem/>
</root>
END


my $completed = << "END";
<?xml version="1.0"?>
<!DOCTYPE root [
<!ELEMENT root (elem)*>
<!ELEMENT elem EMPTY>
<!ATTLIST elem xml:space (default | preserve) "default">
]>
<root>
	<elem xml:space="default"/>
</root>
END

my $notcompleted = << "END";
<?xml version="1.0"?>
<!DOCTYPE root [
<!ELEMENT root (elem)*>
<!ELEMENT elem EMPTY>
<!ATTLIST elem xml:space (default | preserve) "default">
]>
<root>
	<elem/>
</root>
END

use XML::LibXML;

my $parser = new XML::LibXML;
$parser->complete_attributes(1);

my $dom = $parser->load_xml(string => $dtdattr);
#is($dom . "", $completed, "Complete attributes from DTD with setter one key"); # Need a fix on XML::LibXML side

$parser->expand_entities(1);
$dom = $parser->load_xml(string => $dtdattr);
is($dom . "", $completed, "Complete attributes from DTD with setter two keys");

$dom = XML::LibXML->load_xml(string => $dtdattr, complete_attributes => 1, expand_entities => 1);
is($dom . "", $completed, "Complete attributes from DTD two keys");

$dom = XML::LibXML->load_xml(string => $dtdattr, complete_attributes => 1);
#is($dom . "", $completed, "Complete attributes from DTD one key"); # Need a fix on XML::LibXML side

$dom = XML::LibXML->load_xml(string => $dtdattr, expand_entities => 1, complete_attributes => 0);
is($dom . "", $notcompleted, "Do not complete attributes");

my $alreadycompleted = << "END";
<?xml version="1.0"?>
<!DOCTYPE root [
<!ELEMENT root (elem)*>
<!ELEMENT elem EMPTY>
<!ATTLIST elem xml:space (default | preserve) "default">
]>
<root>
	<elem xml:space="preserve"/>
</root>
END

$dom = XML::LibXML->load_xml(string => $alreadycompleted, complete_attributes => 1, expand_entities => 1);
is($dom . "", $alreadycompleted, "Already completed, do not complete it");


done_testing;
