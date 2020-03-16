use strict;
use warnings;

use Test::More 0.98;

use XML::Minify qw(minify);

my $maxi = << "END";
<?xml version="1.0"?>
<?xml-stylesheet href="my-style.css"?>
<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook V4.1.2//EN" "http://www.oasis-open.org/docbook/xml/4.0/docbookx.dtd" [<!ELEMENT element-name EMPTY>]>
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude">
<book/>
<!-- This is a comment-->
<![CDATA[ ...]]>
<?xml-stylesheet href="my-style.css"?>

<tag>
</tag>





</catalog>
END

my $keepcomments = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude"><book/>
<!-- This is a comment-->



<tag>
</tag></catalog>
END

my $keeppi = << "END";
<?xml-stylesheet href="my-style.css"?><catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude"><book/>


<?xml-stylesheet href="my-style.css"?>

<tag>
</tag></catalog>
END

my $keepdtd = << "END";
<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook V4.1.2//EN" "http://www.oasis-open.org/docbook/xml/4.0/docbookx.dtd" [<!ELEMENT element-name EMPTY>]><catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude"><book/><tag>
</tag></catalog>
END

my $keepcdata = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude"><book/>

<![CDATA[ ...]]>


<tag>
</tag></catalog>
END



# Question - Why pi and dtd are concatenated and why removed comment do not remove line ? 
# Answer   - PI and DTD are first level children and we always remove cr lf in and between first level children
#            Removed comment only remove comment, not text around therefore not the carriage return after it
#
# Question - We can have a pi not first level child ?
# Answer   - Nothing seems to say the contrary (neither xmllint nor doc... OK I only spent 5 mins to try to find doc about it xD)

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

