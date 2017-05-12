#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);

MAIN: {
    # Test whether multiple charsets (from the HTTP header and from the HTML
    # document) work ok
    exit RunTestplan(HttpdEcho(charset=>"iso-8859-1"),
        Config(qw/Test/),
        \"t/encode/plan-assert-isolatin-meta.xml"
    );
}
