#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);

MAIN: {
    exit RunTestplan(HttpdEcho(charset=>"utf-8"),
        Config(qw/Test/) . "names=umlauta=\%C3\%A4\n",
        \"t/encode/plan-chinese-utf8.xml"
    );
}
