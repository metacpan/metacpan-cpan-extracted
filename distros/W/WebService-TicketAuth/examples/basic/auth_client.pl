#!/usr/bin/perl -w

use Data::Dumper;
use Storable;
use SOAP::Lite;
use strict;

my $opt_authfile = "$ENV{HOME}/.webservice_auth";

my $soap = SOAP::Lite
    -> uri('http://localhost/Example/Service')
    -> proxy('http://localhost:8082/',
             options => {compress_threshold => 10000},
             );

my $service = $soap
    -> call(new => 0)
    -> result;

my $credentials = retrieve($opt_authfile);

# Convert into the Header
my $authInfo = SOAP::Header->name(authInfo => $credentials);

print "Header:  ", Dumper($authInfo), "\n";

# Call your custom authenticated routines...
my $result = $soap->protected($service, $authInfo, 'foobar');

if ($result->fault) {
    print join ', ',
    $result->faultcode,
    $result->faultstring;
    exit -1;
}

if (! $result->result) {
    warn "No results\n";
    exit 0;
}

print "All done\n";
exit 0;



