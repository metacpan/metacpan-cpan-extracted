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

    <config>
        <property name="change" value="G"/>
    </config>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <assert>
            <regex value='^${change}ET$'/>
        </assert>
        <description>Check evaluation in &lt;config>.
        </description>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config, $test_plan);
}
