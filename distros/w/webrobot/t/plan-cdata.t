#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);


# .../constant_html_0 gives this HTML page
#
#<html>
#    <head>
#        <title>A_Static_Html_Page</title>
#    </head>
#    <body>
#        A simple text.
#    </body>
#</html>

my $test_plan = <<'EOF';
<?xml version="1.0" encoding="iso-8859-1"?>
<plan>

    <request>
        <method value='GET'/>
        <url value='${application}/constant_html_0'/>
        <assert>
            <string value="A_Static_Html_Page"/>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/constant_html_0'/>
        <description>Check values that are written as content of a tag (string)</description>
        <assert>
            <header name="Content-type" value="text/html"/>
            <string>A_Static_Html_Page</string>
            <string><![CDATA[A_Static_Html_Page]]></string>
            <string value="A_Static_Html_Page"/>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/constant_html_0'/>
        <assert> 
          <status value='2'/> 
          <string>
              <![CDATA[
<html>
    <head>
        <title>A_Static_Html_Page</title>
    </head>
    <body>
        A simple text.
    </body>
</html>
                ]]>
            </string> 
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/constant_html_1'/>
        <assert> 
          <status value='2'/> 
          <string>
              <![CDATA[
<html>
    <body>
        Confuse perl regular expressions: [a-z]
        HTMLish&nbsp;text
    </body>
</html>
                ]]>
            </string> 
        </assert>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config("Html", "Test"), $test_plan);
}
