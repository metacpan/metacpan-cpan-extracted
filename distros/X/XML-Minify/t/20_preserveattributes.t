use strict;
use warnings;

use Test::More 0.98;

use XML::Minify qw(minify);

my $maxi = << "END";
<?xml version="1.0"?>
<?xml-stylesheet href="my-style.css"?>
<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook V4.1.2//EN" "http://www.oasis-open.org/docbook/xml/4.0/docbookx.dtd" [<!ELEMENT element-name EMPTY>]>
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" foo="bar"> 
<book bar="baz"/>
<!-- This is a comment -->
<![CDATA[ ...]]>
<?xml-stylesheet href="my-style.css" att="value"?>

<tag key="value">
</tag>





</catalog>
END

my $keepcomments = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" foo="bar"><book bar="baz"/>
<!-- This is a comment -->



<tag key="value">
</tag></catalog>
END

my $keeppi = << "END";
<?xml-stylesheet href="my-style.css"?><catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" foo="bar"><book bar="baz"/>


<?xml-stylesheet href="my-style.css" att="value"?>

<tag key="value">
</tag></catalog>
END

my $keepdtd = << "END";
<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook V4.1.2//EN" "http://www.oasis-open.org/docbook/xml/4.0/docbookx.dtd" [<!ELEMENT element-name EMPTY>]><catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" foo="bar"><book bar="baz"/><tag key="value">
</tag></catalog>
END

my $keepcdata = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" foo="bar"><book bar="baz"/>

<![CDATA[ ...]]>


<tag key="value">
</tag></catalog>
END

chomp $maxi;
chomp $keepcomments;
chomp $keeppi;
chomp $keepdtd;
chomp $keepcdata;

is(minify($maxi, no_prolog => 1, keep_comments => 1, ignore_dtd => 1), $keepcomments, "Keep comments");
is(minify($maxi, no_prolog => 1, keep_pi => 1, ignore_dtd => 1), $keeppi, "Keep pi");
is(minify($maxi, no_prolog => 1, keep_dtd => 1, ignore_dtd => 1), $keepdtd, "Keep dtd");
is(minify($maxi, no_prolog => 1, keep_cdata => 1, ignore_dtd => 1), $keepcdata, "Keep cdata");

done_testing;

