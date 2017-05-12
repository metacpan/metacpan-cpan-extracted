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
        <url value='${application}/method/any_directory'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <regex value='^GET$'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/content/any_directory'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <regex value='^$'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/headers/any_directory'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <string value='User-Agent: Webrobot'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/url/any_directory'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <regex value='^/url/any_directory$'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config, $test_plan);
}
