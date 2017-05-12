#!/usr/bin/perl

use WWW::Curl::Easy;

# Setting the options
my $curl = new WWW::Curl::Easy;

$curl->setopt(CURLOPT_HEADER,1);
$curl->setopt(CURLOPT_URL, 'http://www.google.com');
my $response_body;

# NOTE - do not use a typeglob here. A reference to a typeglob is okay though.
open (my $fileb, ">", \$response_body);
$curl->setopt(CURLOPT_WRITEDATA,$fileb);

# Starts the actual request
my $retcode = $curl->perform;