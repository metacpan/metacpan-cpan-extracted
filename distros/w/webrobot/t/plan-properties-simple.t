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
        <description value="define values"/>
        <method value='GET'/>
        <url value='${application}/url/'/>
        <!-- 0 --> <property name='CONST' value='a_constant_value'/>
        <!-- 1 --> <property name='CT' header='content-type'/>
        <!-- 2 --> <property name='CODE' status='code'/>
        <!-- 3 --> <property name='MSG' status='message'/>
        <!-- 4 --> <property name='PROTO' status='protocol'/>
        <!-- 5 --> <property name='RAND' random='15'/>
    </request>

    <request>
        <description value="define values"/>
        <method value='POST'/>
        <url value='${application}/content/'/>
        <data>
            <parm name='CONST' value='${CONST}'/>
            <parm name='CONTENT_TYPE' value='${CT}'/>
            <parm name='CODE' value='${CODE}'/>
            <parm name='MSG' value='${MSG}'/>
            <parm name='PROTO' value='${PROTO}'/>
            <parm name='RANDOM' value='${RAND}'/>
        </data>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <!-- 0 --> <string value='a_constant_value'/>
                    <!-- 1 --> <string value='text%2Fplain'/>
                    <!-- 2 --> <string value='200'/>
                    <!-- 3 --> <regex value='(?i)ok'/>
                    <!-- 4 --> <string value='HTTP%2F'/>
                    <!-- 5 --> <regex value='[\d]{0,15}'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config, $test_plan);
}
