#!/usr/bin/perl

use strict;
use CGI;

my $idBrokerUrl = 'http://localhost:8080/cgi-bin/idbroker.pl';

my %registeredEnames = (
    '@pw/eekim' => 'xri:@:1002:/:1000:1',
    '@pw/jim' => 'xri:@:1002:/:1000:2',
    '@pw/fen' => 'xri:@:1002:/:1000:3',
    '@pw/victor' => 'xri:@:1002:/:1000:4',
    '@pw/ian' => 'xri:@:1002:/:1000:5'
);

my $q = new CGI;

if ($q->param) {
    my $ename = $q->param('xri_ename');
    if ($registeredEnames{$ename}) {
        print $q->header(-type => 'text/xml') .
            &xriDescriptor($ename);
        exit;
    }
    else { # return 404
        print $q->header(-status => '404 XRI unknown',
                         -type => 'text/xml') .
            &notFound;
        exit;
    }
}

print $q->header . $q->start_html('go away!') .
    $q->h1('go away!') .
    $q->end_html;

sub xriDescriptor {
    my $ename = shift;
    return <<EOM;
<?xml version="1.0" encoding="iso-8859-1"?>
<XRIDescriptor xmlns="xri:\$r.s/XRIDescriptor">
    <Resolved>$ename</Resolved>
    <LocalAccess>
        <Service>xri:.a/RDB</Service>
        <URI>$idBrokerUrl</URI>
    </LocalAccess>
    <Mapping>$registeredEnames{$ename}</Mapping>
</XRIDescriptor>
EOM
}

sub notFound {
    return <<EOM;
<?xml version="1.0" encoding="iso-8859-1"?>
<XRIDescriptor xmlns="xri:\$r.s/XRIDescriptor">
    <error xmlns="http://registry.idcommons.net/errors">xri unknown</error>
</XRIDescriptor>
EOM
}
