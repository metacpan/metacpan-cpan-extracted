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
        <url value='${application}/url/${_id}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <regex value='^/url/1$'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="A single webrobot process must have the _id property set to '1'"/>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config, $test_plan);
}
