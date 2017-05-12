#!/usr/bin/perl

use strict;
use Getopt::Long;
use Combine::Config;
use Combine::MySQLhdb;

my $configfile;
my $jobname;
my $help;
my %server2country;

GetOptions('jobname:s' => \$jobname, 'help' => \$help, 
	   'configfile:s' => \$configfile );
if (defined($help)) { Getopt::Long::HelpMessage('None so far :-('); }
if (defined($jobname)) { Combine::Config::Init($jobname); }
else { Getopt::Long::HelpMessage('No jobname suplied'); }
if (defined($configfile)) { warn "Switch 'configfile' not implemented"; } #Config::Init('',$configfile); }

my $sv =  Combine::Config::Get('MySQLhandle');
Combine::MySQLhdb::Open(); #Init???

my $configDir = Combine::Config::Get('configDir');
my $sthnl = $sv->prepare(qq{SELECT netlocstr FROM netlocs WHERE netlocstr like ?});
if ( open(TT,"<$configDir/server2country") ) {
    while (<TT>) {
	next if (/^\s*#/);
	next if (/^\s*$/);
	s/[\n\r\f]//g;
	if (/^([^\s]+)\s+(.*)\s*$/) {
	    my $server=$1;
	     my $country=$2;
	    $server =~ s|^([^/]+)/.*$|$1|;
	    #serveralias translation!!
	    print "Got: $server\n";
	    $server = $Combine::Config::serverbyalias{$server} || $server;
	    print "Alias: $server\n";

	    $sthnl->execute("%$server");
	    my $servOK='';
	    while ( my ($s)=$sthnl->fetchrow_array() ) {
		$servOK=$s;
		$server2country{$servOK}=$country;
	    }
	    if ($servOK eq '') { print "Dubious entry in server2country: $server\n"; }
	}
    }
    close(TT);
}

if    ($ARGV[0] eq 'updateCountry')    { &updateCountry(); }
elsif ($ARGV[0] eq 'guessCountry')    { &guessCountry(); }

exit;

sub updateCountry {
#Update the database
    my $sth = $sv->prepare(qq{SELECT DISTINCT(netlocstr),value FROM netlocs,urls,recordurl,analys WHERE netlocs.netlocid=urls.netlocid AND urls.urlid=recordurl.urlid AND recordurl.recordid=analys.recordid AND analys.name='country'});
    my $sthrid = $sv->prepare(qq{SELECT recordurl.recordid FROM netlocs,urls,recordurl WHERE netlocs.netlocid=urls.netlocid AND urls.urlid=recordurl.urlid AND netlocstr=?});

    $sth->execute;
    while ( my ($netlocstr,$country)=$sth->fetchrow_array() ) {
	if (defined($server2country{$netlocstr})) {
	    if ($server2country{$netlocstr} ne $country) {
		#always update in case of an inconsistency in the SQL database??
		print "Updating: :$netlocstr: from :$country: to :$server2country{$netlocstr}:\n";
		$sthrid->execute($netlocstr);
		while ( my ($rid)=$sthrid->fetchrow_array() ) {
		    $sv->do(qq{UPDATE analys SET value='$server2country{$netlocstr}' WHERE name='country' AND recordid=$rid});
		}
	    } # if ne
	}
    }
 }

sub guessCountry {
my $sth = $sv->prepare(qq{SELECT DISTINCT(netlocstr),value FROM netlocs,urls,recordurl,analys WHERE netlocs.netlocid=urls.netlocid AND urls.urlid=recordurl.urlid AND recordurl.recordid=analys.recordid AND analys.name='country'});
my $sthrid = $sv->prepare(qq{SELECT recordurl.recordid FROM netlocs,urls,recordurl WHERE netlocs.netlocid=urls.netlocid AND urls.urlid=recordurl.urlid AND netlocstr=?});

my $tot;
my $mapped;
my $diff;
my %combineCountry;

$sth->execute;
while ( my ($netlocstr,$country)=$sth->fetchrow_array() ) {
    $tot++;
    $combineCountry{$netlocstr}=$country;
    if (defined($server2country{$netlocstr})) {
	$mapped++;
	if ($server2country{$netlocstr} ne $country) {
	    $diff++;
	} # if ne
    }
}

my @sql;
my @points;
my %pat;

$sql[0] = q{SELECT netlocstr FROM netlocs,urls,recordurl,hdb WHERE 
  netlocs.netlocid=urls.netlocid  AND
  urls.urlid=recordurl.urlid      AND
  recordurl.recordid=hdb.recordid AND
    hdb.title like ?};
$points[0]=10;

$sql[1] = q{SELECT netlocstr FROM netlocs,urls,recordurl,hdb WHERE 
  netlocs.netlocid=urls.netlocid  AND
  urls.urlid=recordurl.urlid      AND
  recordurl.recordid=hdb.recordid AND
    hdb.headings like ?};
$points[1]=10;

$sql[2] = q{SELECT netlocstr FROM netlocs,urls,recordurl,meta WHERE 
  netlocs.netlocid=urls.netlocid  AND
  urls.urlid=recordurl.urlid      AND
  recordurl.recordid=meta.recordid AND
    meta.value like ?};
$points[2]=10;

$sql[3] = q{SELECT netlocstr FROM netlocs,urls,recordurl WHERE 
  netlocs.netlocid=urls.netlocid  AND
  urls.urlid=recordurl.urlid      AND
    urls.urlstr like ?};
$points[3]=10;
$pat{'3'}=1;

my @coun = (
  'germany',
  'sweden',
  'luxembourg',
  'australia',
  'switzerland',
  'france',
  'ireland',
  'netherlands',
#  'nl',
  'india',
  'taiwan',
  'canada',
  'singapore',
  'japan',
  'mauritius',
  'united kingdom',
 # 'uk',
  'united states',
 # 'us',
  'usa',
  'south africa',
  'new zealand',
  'christmas island',
  'hong kong',
  'spain',
  'finland'
    );

my %serv;

foreach my $i (0..$#sql) {
    my $st = $sv->prepare($sql[$i]);
    print "Doing $i $sql[$i]\n";
    foreach my $c (@coun) {
	if (defined($pat{$i})) {
	    $st->execute("%$c%");
	} else {
	    $st->execute("% $c %");
	}
	while ( my ($nl)=$st->fetchrow_array() ) {
	    $serv{$nl}->{$c} += $points[$i];
	}
    }
}

#Check text
my $q = $sv->prepare(q{SELECT netlocstr,UNCOMPRESS(ip) FROM netlocs,urls,recordurl,hdb WHERE 
  netlocs.netlocid=urls.netlocid  AND
  urls.urlid=recordurl.urlid      AND
  recordurl.recordid=hdb.recordid});
$q->execute();
while (my ($nl,$ip) = $q->fetchrow_array() ) {
#location address contact + $c
    foreach  my $c (@coun) {
	if ($ip =~ /\b$c\b/i) {$serv{$nl}->{$c} += 1;}
	if ($ip =~ /(location|address|contact).*\b$c\b/i) {$serv{$nl}->{$c} += 20;}
    }
}

my $agrgeoip;
my $disagrgeoip;
my $agrexc;
my $disagrexc;

#res
foreach my $h (keys(%serv)) {
    print "$h= $combineCountry{$h}; $server2country{$h};\n";
    my $done=0;
    foreach my $c (sort {$serv{$h}->{$b} <=> $serv{$h}->{$a};} keys(%{$serv{$h}})) {
	print "  $c $serv{$h}->{$c}\n";
	if ($done==0) {
	    my $geoip=$combineCountry{$h};
	    if ($c =~ /$geoip/i) { $agrgeoip++; }
	    else  { $disagrgeoip++; }
	    if (defined($server2country{$h})){
		my $exc=$server2country{$h};
		if ($c =~ /$exc/i) { $agrexc++; }
		else  { $disagrexc++; }
	    }
	}
	$done=1;
    }
}

print "Total: $tot; Mapped: $mapped; Diff: $diff\n";
    
print "GeoIP(agr/disagr): $agrgeoip/$disagrgeoip\n";
print "Exclusion(agr/disagr): $agrexc/$disagrexc\n";

}
