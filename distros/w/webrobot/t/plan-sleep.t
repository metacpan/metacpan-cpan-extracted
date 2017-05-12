#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);


my $test_plan = <<'EOF';
<?xml version="1.0" encoding="iso-8859-1"?>
<plan>

    <sleep value="1"/>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, Config, $test_plan);
    #exit RunTestplan(HttpdEcho, Config(qw/Html Test/), $test_plan);
}
