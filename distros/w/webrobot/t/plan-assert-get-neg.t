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

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <!--
            - the first predicate fails
        -->
        <assert>
            <not>
                <status value='200'/>
            </not>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <!--
            - the first predicate succeeds
            - the second predicate fails
            Now assert that the implicit <and> assertion fails
        -->
        <assert>
            <status value='200'/>
            <regex value='^RANDOM-STRING$'/>
        </assert>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config("NegativeTest"), $test_plan);
}
