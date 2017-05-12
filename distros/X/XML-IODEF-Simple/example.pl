#!/usr/bin/perl -w

use strict;

use lib './lib';
require XML::IODEF::Simple;

my $report = XML::IODEF::Simple->new({
    guid        => 'mygroup.example.com',
    source      => 'example.com',
    restriction => 'need-to-know',
    description => 'spyeye',
    impact      => 'botnet',
    address     => '1.2.3.4',
    protocol    => 'tcp',
    portlist    => '8080',
    contact     => {
        name        => 'root',
        email       => 'root@localhost',
    },
    purpose                     => 'mitigation',
    confidence                  => '85',
    alternativeid               => 'https://example.com/rt/Ticket/Display.html?id=1234',
    alternativeid_restriction   => 'private',
    sharewith                   => 'partners.example.com,leo.example.com', 
});
my $xml = $report->out(); 
my $hash = $report->to_tree();
warn $xml;
