#!/usr/bin/perl

use strict;
use CGI;

my %xsids = (
    '@pw/eekim' => '1',
    '@pw/jim' => '2',
    '@pw/fen' => '3',
    '@pw/victor' => '4',
    '@pw/ian' => '5',
);

my $q = new CGI;

if ($q->param) {
    my $ename = $q->param('xri_ename');
    my $cmd = $q->param('xri_cmd');
    if ($cmd eq 'auth') {
        my $returnUrl = $q->param('xri_rtn');
        my $password = $q->param('password');
        if ($ename && $returnUrl && $password) {  # authenticated!
            if (&authenticate($ename, $password)) {
                print "Location: $returnUrl&xri_ename=$ename&xri_xsid=" .
                    &setXsid($ename) . "\n\n";
                exit;
            }
            else {  # login form/invalid password
                print $q->header .
                    $q->start_html('invalid password') .
                    $q->start_form(-method=>'POST', -action=>'idbroker.pl') .
                    $q->hidden('xri_cmd', 'auth') .
                    $q->hidden('xri_ename', $ename) .
                    $q->hidden('xri_rtn', $returnUrl) .
                    "<p>Invalid password for $ename.  Try again:" .
                    $q->password_field('password') .
                    $q->submit . "</p>" .
                    $q->end_form .
                    $q->end_html;
                exit;
            }
        }
        elsif ($ename && $returnUrl) {  # login form
            print $q->header .
                $q->start_html('enter password') .
                $q->start_form(-method => 'POST', -action => 'idbroker.pl') .
                $q->hidden('xri_cmd', 'auth') .
                $q->hidden('xri_ename', $ename) .
                $q->hidden('xri_rtn', $returnUrl) .
                "<p>Enter password for $ename:" .
                $q->password_field('password') .
                $q->submit . "</p>" .
                $q->end_form .
                $q->end_html;
            exit;
        }
    }
    elsif ($cmd eq 'verify') {
        my $xsid = $q->param('xri_xsid');
        if ($ename && $xsid) {
            if ($xsid eq $xsids{$ename}) {
                print $q->header(-type => 'text/plain') . "true\n";
            }
            else {
                print $q->header(-type => 'text/plain') . "false\n";
            }
            exit;
        }
    }
}

print $q->header . $q->start_html('go away!') .
    $q->h1('go away!') .
    $q->end_html;

### functions

sub authenticate {
    my ($ename, $password) = @_;
    my %passwords = (
        '@pw/eekim' => 'eekim',
        '@pw/jim' => 'jim',
        '@pw/fen' => 'fen',
        '@pw/victor' => 'victor',
        '@pw/ian' => 'ian',
    );
    ($password eq $passwords{$ename}) ? return 1 : return 0;
}

sub setXsid {
    my $ename = shift;
    my %xsids = (
        '@pw/eekim' => '1',
        '@pw/jim' => '2',
        '@pw/fen' => '3',
        '@pw/victor' => '4',
        '@pw/ian' => '5',
    );
    return $xsids{$ename};
}
