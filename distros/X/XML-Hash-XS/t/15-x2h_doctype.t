package main;
use strict;
use warnings;

use Test::More tests => 15;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

{
    is
        xml2hash("<!DOCTYPE root><root>OK</root>"),
        "OK",
        'simple',
    ;
}

{
    is
        xml2hash("<!DOCTYPE\n\r\t root \n\r\t><root>OK</root>"),
        "OK",
        'with extra spaces',
    ;
}

{
    is
        xml2hash("<!-- comment --><!DOCTYPE root><!-- comment --><root>OK</root>"),
        "OK",
        'with comments',
    ;
}

{
    is
        xml2hash("<!DOCTYPE root SYSTEM \"dtd\"><root>OK</root>"),
        "OK",
        'with external system DTD',
    ;
}

{
    is
        xml2hash("<!DOCTYPE root SYSTEM 'dtd'><root>OK</root>"),
        "OK",
        'with external system DTD',
    ;
}

{
    is
        xml2hash('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"' .
                 ' "http://www.w3.org/TR/REC-html40/loose.dtd"><root>OK</root>'),
        "OK",
        'with external public DTD',
    ;
}

{
    is
        xml2hash(<<'XML'),
<!DOCTYPE root [
<!ELEMENT document
  (title*,subjectID,subjectname,prerequisite?,
  classes,assessment,syllabus,textbooks*)>
<!ELEMENT prerequisite (subjectID,subjectname)>
<!ELEMENT textbooks (author,booktitle)>
<!ELEMENT title (#PCDATA)>
<!ELEMENT subjectID (#PCDATA)>
<!ELEMENT subjectname (#PCDATA)>
<!ELEMENT classes (#PCDATA)>
<!ELEMENT assessment (#PCDATA)>
<!ATTLIST assessment assessment_type (exam | assignment) #IMPLIED>
<!ELEMENT syllabus (#PCDATA)>
<!ELEMENT author (#PCDATA)>
<!ELEMENT booktitle (#PCDATA)>
]>
<root>OK</root>
XML
        "OK",
        'with internal subset',
    ;
}

{
    eval { xml2hash("<!DOCTYPE><root>123</root>") };
    ok($@, 'missing root element type');
}

{
    eval { xml2hash("<!DOCTYPE root><!DOCTYPE root><root>123</root>") };
    ok($@, 'duplicate doctype');
}

{
    eval { xml2hash("<root><!DOCTYPE root></root>") };
    ok($@, 'misplaced doctype');
}

{
    eval { xml2hash("<!DOCTYPE root SYSTEM><root>123</root>") };
    ok($@, 'wrong external system DTD');
}

{
    eval { xml2hash('<!DOCTYPE root PUBLIC><root>123</root>') };
    ok($@, 'wrong external public DTD');
}

{
    eval { xml2hash('<!DOCTYPE root PUBLIC "name"><root>123</root>') };
    ok($@, 'wrong external public DTD2');
}

{
    eval { xml2hash('<!DOCTYPE root [><root>123</root>') };
    ok($@, 'wrong internal subset');
}

{
    eval { xml2hash('<!DOCTYPE root []]><root>123</root>') };
    ok($@, 'wrong internal subset');
}
