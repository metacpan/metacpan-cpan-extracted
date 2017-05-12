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
        <method value='POST'/>
        <url value='${application}/content'/>
        <description value='POST: test parameters'/>
        <data>
            <parm name='first' value='firstvalue'/>
            <parm name='second' value='secondvalue'/>
        </data>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <string value="first=firstvalue&amp;second=secondvalue"/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

    <request>
        <method value='POST'/>
        <url value='${application}/headers'/>
        <description value='POST: test Content-Type'/>
        <data>
            <parm name='first' value='firstvalue'/>
            <parm name='second' value='secondvalue'/>
        </data>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <string value="Content-Type: application/x-www-form-urlencoded"/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config(qw/Test/), $test_plan);
}
