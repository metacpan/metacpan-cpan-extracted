#!/usr/bin/perl -w

require 'onsearch-utils.cgi';
require 'onsearch-error.cgi';

my ($scriptname, $error_request) = split /\?/, $ENV{REQUEST_URI}, 2;

if ($error_request =~ /searchterm/) {
	header_css ();
	    netscape_error ("error!", $ENV{'HTTP_REFERER'});
	    return 1;
    
}

1;

