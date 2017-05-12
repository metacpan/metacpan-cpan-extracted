#!/usr/bin/perl

use strict;
use warnings;
my $url = 'http://localhost/';

use Benchmark qw/cmpthese timethese/;
use File::Basename qw(basename);

use WWW::Curl::Easy;
use LWP::Simple qw/get/;
use WWW::Curl::Simple;

sub curl {
    # Test with WWW::Curl::Easy
    # Setting the options
    my $curl = new WWW::Curl::Easy;

    $curl->setopt(CURLOPT_HEADER,1);
    $curl->setopt(CURLOPT_URL, $url);
    my $response_body;

    # NOTE - do not use a typeglob here. A reference to a typeglob is okay though.
    open (my $fileb, ">", \$response_body);
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);

    # Starts the actual request
    my $retcode = $curl->perform;
}

sub curl_simple {
    # Test with WWW::Curl::Simple
    my $curl = WWW::Curl::Simple->new();

    my $res = $curl->get($url);
    
}

sub lwp {
    # Test with LWP::Simple
    my $res = get($url);
    
}

my $results = timethese(shift || 100, {
    lwp => \&lwp,
    curl => \&curl,
    curl_simple => \&curl_simple,
});

cmpthese($results);



