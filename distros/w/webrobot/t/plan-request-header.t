#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);


my $test_plan = <<'EOF';
<?xml version="1.0" encoding="iso-8859-1"?>
<plan>

    <request>
        <method value='GET'/>
        <url value='${application}/headers/any_directory'/>
        <http-header name="A-New-Name" value="a new value"/>
        <http-header name="Another-Name" value="is quite strange"/>
        <assert>
            <status value='200'/>
            <string value='A-New-Name: a new value'/>
            <string value='Another-Name: is quite strange'/>
            <!-- Test that the User-Agent header is set. -->
            <string value='User-Agent: Webrobot'/>
        </assert>
        <description>Set HTTP headers in a request</description>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/headers/any_directory'/>
        <http-header name="A-New-Name" value="a new value"/>
        <http-header name="User-Agent" value="overwrites the user agent"/>
        <assert>
            <status value='200'/>
            <string value='A-New-Name: a new value'/>
            <!-- Test that the User-Agent header is overwritten. -->
            <string value='User-Agent: overwrites the user agent'/>
        </assert>
        <description>Overwrite HTTP header</description>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config, $test_plan);
}
