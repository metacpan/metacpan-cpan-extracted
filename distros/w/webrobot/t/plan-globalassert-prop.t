#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);


# Test wether <global-assertion> are evaluated each time it is used.


my $test_plan = <<'EOF';
<?xml version="1.0" encoding="iso-8859-1"?>
<plan>

    <global-assertion>
        <status value="${status}"/>
    </global-assertion>

    <config>
        <property name="status" value="200"/>
    </config>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
    </request>

    <config>
        <property name="status" value="500"/>
    </config>

    <request>
        <method value='GET'/>
        <url value='${application}/500/'/>
        <!--
        <assert>
            <status regex="${status}"/>
        </assert>
        -->
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/500/'/>
        <assert>
            <status value="5"/>
        </assert>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config("Test", "Html"), $test_plan);
}
