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
        <url value='${application}/constant_html_1'/>
        <assert> 
          <status value='2'/> 
          <file value="t/plan-assert-file/constant_html_1.txt"/>
        </assert>
    </request>

</plan>
EOF

MAIN: {
    #exit RunTestplan(HttpdEcho, Config("Html", "Test"), $test_plan);
    exit RunTestplan(HttpdEcho, Config, $test_plan);
}
