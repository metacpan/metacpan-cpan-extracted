#!/usr/local/bin/perl -w

 use strict;
 use lib '../.';
 use Tk;
 use Tk::IPEntry;
 use Tk::BrowseEntry;

 my $mw = MainWindow->new();

 
 # IpV4 ------------------------------
 my $ipadress;
 my $fr = $mw->Frame()->pack(-fill => 'x', -expand => 1);
 my $fa = $mw->Frame()->pack(-fill => 'x', -expand => 1);
 my $entry = $fr->IPEntry(
	-background => 'gray80',
	-variable  => \$ipadress,
	-type	   => 'ipv4',
 )->pack(-side => 'left');

 my $button1 = $fr->Button(
 		-text 	=> 'Get',
 		-command=> sub{
 			print $entry->get(), "\n";
		},
 )->pack(-side => 'left');

 my $button2 = $fr->Button(
 		-text 	=> 'Fetch',
 		-command=> sub{
 			print $ipadress , "\n";
		},
 )->pack(-side => 'left');

 $ipadress = '121.0/29';
 # ------------------------------------ 
    my $ips = '121.0/29';
    my $i = $fa->BrowseEntry(
    	-label => "Ip:", 
    	-variable => \$ips,
	-browsecmd => sub {
		$entry->set($ips);
		},
    	);
    $i->insert("end", "121.0/29");
    $i->insert("end", "196.168/24");
    $i->insert("end", "196.168/23");
    $i->insert("end", "196.168/22");
    $i->pack(-side => 'left');


    my $var = 'ip';
    my $b = $fa->BrowseEntry(
    	-label => "Methods:", 
    	-variable => \$var,
	-browsecmd => sub {
		print $entry->get($var), "\n";
		},
    	);
    $b->insert("end", "ip");
    $b->insert("end", "last_ip");
    $b->insert("end", "binip");
    $b->insert("end", "prefixlen");
    $b->insert("end", "version");
    $b->insert("end", "binmask");
    $b->insert("end", "mask");
    $b->insert("end", "prefix");
    $b->insert("end", "print");
    $b->insert("end", "short");
    $b->insert("end", "iptype");
    $b->insert("end", "reverse_ip");
    $b->pack(-side => 'left');



 MainLoop;

