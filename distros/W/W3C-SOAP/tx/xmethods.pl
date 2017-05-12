#!/usr/bin/perl

use strict;
use warnings;
use Path::Tiny;
use Data::Dumper qw/Dumper/;
use WWW::Mechanize;

my $dir = path($0)->parent;
my $wsdls = $dir->child('wsdls.txt')->openw;

my $mech = WWW::Mechanize->new;
$mech->timeout(2);
$mech->get('http://www.xmethods.com/ve2/Directory.po');
my @links = $mech->links;

for my $link (@links) {
    next if $link->url_abs->as_string !~ m{/ve2/ViewListing[.]po.*[?]key=};
    my $url = $link->url_abs->as_string;
    $url =~ s/ViewListing[.]po.*[?]/ViewListing.po?/;

    eval { $mech->get($url) };
    warn $mech->uri . ': ' . $mech->res->code . ' ' . $mech->res->message . "\n" if $@;
    next if $@;

    my $wsdl = $mech->find_link(id => 'WSDLURL');
    die $mech->content if !$wsdl;
    next if !$wsdl;
    $wsdl = $wsdl->url_abs->as_string;
    print "$wsdl\n";
    eval { $mech->get($wsdl) };

    if ($@) {
        print {$wsdls} "#$wsdl\n";
    }
    else {
        print {$wsdls} "$wsdl\n";
    }
}

