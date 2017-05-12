#!/usr/bin/perl

use strict;
use CGI;
use URI::Escape;
use XDI::SPIT;

my $returnUrl = 'http://localhost:8080/cgi-bin/login.pl?';

my $q = new CGI;

if ($q->param) {
    my $ename = $q->param('ename');
    # SPIT is Fen's cute acronym for Service Provider Interface Toolkit
    my $spit = new XDI::SPIT;
    my $idBroker = $spit->resolveBroker($ename);
    if (my $xsid = $q->param('xsid')) { # authenticate
        if ($spit->validateSession($idBroker, $ename, $xsid)) {
            print $q->header . $q->start_html('success!') .
                $q->h1('success!') .
                $q->end_html;
        }
        else {
            print $q->header . $q->start_html('failure!') .
                $q->h1('failure!') .
                $q->end_html;
        }
    }
    else {
        my $redirectUrl = $spit->getAuthUrl($idBroker, $ename, $returnUrl);
        print "Location: $redirectUrl\n\n";
    }
}
else { # print form
    print $q->header .
        $q->start_html('login') .
        $q->start_form(-method => 'GET', -action => 'login.pl') .
        "<p>Ename: " . $q->textfield('ename') .
        $q->submit . "</p>" .
        $q->end_form .
        $q->end_html;
}
