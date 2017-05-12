#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('WWW::Google::Contacts');
}

diag(
"Testing WWW::Google::Contacts $WWW::Google::Contacts::VERSION, Perl $], $^X"
);

1;
