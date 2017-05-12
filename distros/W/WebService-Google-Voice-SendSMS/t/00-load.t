#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('WebService::Google::Voice::SendSMS');
}

diag("Testing WebService::Google::Voice::SendSMS $WebService::Google::Voice::SendSMS::VERSION");
