#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
use UNIVERSAL;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan2 HttpdEcho Config);
push @INC, "t/lib", "./lib";         # that is $SRC/t/lib/...


my $test_plan = <<'EOF';
<?xml version="1.0" encoding="iso-8859-1"?>
<plan>

    <request>
        <method value='GET'/>
        <url value='${application}/html_frame_0'/>
        <description value='recurse'/>
        <recurse>
            <WWW.Webrobot.Recur.Browser/>
        </recurse>
    </request>

</plan>
EOF

MAIN: {
    my ($exit, $webrobot) = RunTestplan2(HttpdEcho, "output=Tmp::Count\n", $test_plan);
    exit $exit;
}

1;
