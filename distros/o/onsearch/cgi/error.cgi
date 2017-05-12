#!/usr/bin/perl -w 
$Id: error.cgi,v 1.1.1.1 2005/07/03 06:02:18 kiesling Exp $

BEGIN { use Config; unshift @INC, ("./lib", "./lib/$Config{archname}"); }

use warnings;
use OnSearch::Templates qw/:all/;
use OnSearch::Utils;

my ($scriptname, $error_request) = split /\?/, $ENV{REQUEST_URI}, 2;

if ($error_request =~ /searchterm/) {
#    error_form ("The, \"Search Term,\" field is empty.", 
#		    $ENV{'HTTP_REFERER'});
}

if ($error_request =~ /nodaemon/) {
#    error_dialog ("OnSearch couldn't find the index daemon process.",
#		  $ENV{'HTTP_REFERER'});
}

1;

