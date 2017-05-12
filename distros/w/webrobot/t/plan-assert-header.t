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
        <url value='${application}/constant_html_0'/>
        <assert>
            <header name="Content-type" value="text/html"/>
            <not><header name="xxx" value="bla"/></not>
        </assert>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config, $test_plan);
}
