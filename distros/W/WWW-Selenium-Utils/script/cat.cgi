#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/lukec/src/lukec/WWW-Selenium-Utils/lib';
use WWW::Selenium::Utils::CGI qw(cat);
use CGI;

print cat( CGI->new );
