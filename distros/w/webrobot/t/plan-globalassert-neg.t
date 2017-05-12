#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);


# This is a test plan where the test must fail.
# Use WWW::Webrobot::Print::NegativeTest.pm in the config.
# This test output class will invert all assertions, so that
# failing tests now succeed.

my $test_plan = <<'EOF';
<?xml version="1.0" encoding="iso-8859-1"?>
<plan>

    <sleep value="1"/>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <description>Normal test</description>
        <assert>
            <not>
                <status value='200'/>
            </not>
        </assert>
    </request>

    <global-assertion>
        <not>
            <regex value='^GET$'/>
        </not>
    </global-assertion>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <description>Test that the default test is NOT executed</description>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <assert>
            <status value='200'/>
        </assert>
        <description>Test this assertion and the global assertion.
        </description>
    </request>

</plan>
EOF

MAIN: {
    #exit RunTestplan(HttpdEcho, Config, $test_plan);
    exit RunTestplan(HttpdEcho, Config("NegativeTest"), $test_plan);
}
