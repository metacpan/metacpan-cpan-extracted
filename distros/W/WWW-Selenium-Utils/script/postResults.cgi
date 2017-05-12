#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use WWW::Selenium::Utils::PostResults qw(write_results);

write_results(CGI->new, '/tmp/selenium-results');
               
