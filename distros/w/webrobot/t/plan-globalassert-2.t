#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);


# Test wether multiple <global-assertion>s are commulated.


my $test_plan = <<'EOF';
<?xml version="1.0" encoding="iso-8859-1"?>
<plan>

    <global-assertion>
        <not>
        <string value="A_Static_Html_Page"/>
        </not>
    </global-assertion>

    <global-assertion>
        <string value="A simple text"/>
    </global-assertion>

    <request>
        <method value='GET'/>
        <url value='${application}/constant_html_0'/>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config("NegativeTest"), $test_plan);
}
