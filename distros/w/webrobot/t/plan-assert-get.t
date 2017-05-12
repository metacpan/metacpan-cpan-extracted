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
        <url value='${application}/method/any_directory'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <or>
                        <regex value='^cannot-find-regex$'/>
                        <regex value='^GET$'/>
                    </or>
                    <regex value='^GET$'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <assert>
            <WWW.Webrobot.Assert>
                <status value='200'/>
                <regex value='^GET$'/>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <assert>
            <WWW.Webrobot.Assert>
                <status value='200'/>
                <or>
                    <regex value='^cannot-find-regex$'/>
                    <regex value='^GET$'/>
                </or>
                <regex value='^GET$'/>
            </WWW.Webrobot.Assert>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <assert>
            <status value='200'/>
            <regex value='^GET$'/>
        </assert>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/method/any_directory'/>
        <recurse>
            <WWW.Webrobot.Recur.Browser>
                <and>
                    <url value="{application}"/>
                    <scheme value="http"/>
                </and>
            </WWW.Webrobot.Recur.Browser>
        </recurse>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config, $test_plan);
}
