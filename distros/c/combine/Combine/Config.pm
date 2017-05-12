# Copyright (c) 2004, 2005 Anders Ardö

## $Id: Config.pm 326 2011-05-27 07:44:58Z it-aar $
# 
# See the file LICENCE included in the distribution.

package Combine::Config;

use strict;
use Config::General qw(SaveConfigString);

our $VERSION = '4.005';
our %serverbypreferred = ();
our %serverbyalias     = ();
our @allow = ();
our @exclude = ();

#Default values
my $jobname = 'alvistest';
my $dbname = 'alvistest';
my $baseConfigDir = '/etc/combine';
my %configValues;

sub _private_initConfig_ {
  #default values
    my $conf = new Config::General(-ConfigFile => "$baseConfigDir/default.cfg",
                   -BackslashEscape => 0,
                   -MergeDuplicateBlocks => 1,
                   -AutoTrue => 1
       );
        my %defConf = $conf->getall;
#use Data::Dumper; print "Dumping Default\n"; print Dumper(\%defConf);
    my $configDir = $baseConfigDir . '/' . $jobname;
    $conf = new Config::General(-ConfigFile => "$configDir/combine.cfg",
                   -BackslashEscape => 0,
                   -MergeDuplicateBlocks => 1,
                   -AutoTrue => 1
       );
    %configValues = $conf->getall;
#Merge
    foreach my $opt (keys(%defConf)) {
	my $c=$defConf{$opt};
	my $r = ref($c);
#	print "DefConf $opt: $r\n";
	if ( (ref($defConf{$opt}) eq '') && !defined($configValues{$opt})) {
#	    print "Assigning $opt Def\n";
	    $configValues{$opt} = $defConf{$opt};
	} elsif ( (ref($defConf{$opt}) eq 'ARRAY') ) {
	    warn("$opt not supported in default config");
	} elsif ( (ref($defConf{$opt}) eq 'HASH') ) {
	    if (!defined($configValues{$opt})) { 
		$configValues{$opt}=$defConf{$opt};
	    } elsif (ref($configValues{$opt}) eq 'HASH') {
		my $tmp1 = SaveConfigString(\%{$configValues{$opt}});
		my $tmp2 = SaveConfigString(\%{$defConf{$opt}});
		my $tconf = new Config::General(-String => $tmp1 . $tmp2,
					    -BackslashEscape => 0,
					    -MergeDuplicateBlocks => 1,
					    -AutoTrue => 1,
					    -IncludeRelative => 1
					    );
		%{$configValues{$opt}} = $tconf->getall;
	    }
	}
    }

    $configValues{'jobname'} = $jobname;
    $configValues{'configDir'} = $configDir;
    $configValues{'baseConfigDir'} = $baseConfigDir;
#    open CONF, "<$baseConfigDir/$jobname/$configFile" or
#	die "**ERROR: Can't open Combine's configuration file $baseConfigDir/$jobname/$configFile";
#use Data::Dumper; print "Dumping Merged\n"; print Dumper(\%configValues);

    use DBI;
    if ( defined($configValues{'DBItraceFile'}) ) {
	    DBI->trace(1,$configValues{'DBItraceFile'});
    }
    $dbname = $configValues{'MySQLdatabase'} if defined($configValues{'MySQLdatabase'});
#    print "Using database: $dbname\n";
#parse $dbname according to user@host:database
	my $dbhost='localhost';
	my $dbuser='combine';
	my $database='alvistest';
	if ($dbname =~ /^([^@]+)@([^:]+):(.+)$/) {
	    $dbuser=$1; $dbhost=$2; $database=$3; 
	} elsif ($dbname =~ /^([^:]+):(.+)$/) {
	    $dbhost=$1; $database=$2; 
	} elsif ($dbname =~ /^([^@]+)@(.+)$/) {
	    $dbuser=$1; $dbhost=$2;
	} else { $database=$dbname; }
#	print "  Parsed: host=$dbhost; user=$dbuser; db=$database\n";
     #!!Handle passwd in connect
     my $sv = DBI->connect("DBI:mysql:database=$database;host=$dbhost", $dbuser, "",
               {ShowErrorStatement => 1, RaiseError => 1, AutoCommit => 0 }) or
		   die("Fatal error, can't connect to MySQL: $DBI::errstr");

     ##Store handle as a config-var that can be reused
     $configValues{'MySQLhandle'} = $sv;
my $url = Combine::Config::Get('url');
my $servalias = ${$url}{'serveralias'};
foreach my $preferred (keys(%{$servalias}))
  {
      my @ALIAS;
      my $alias = ${$servalias}{$preferred};
        if(ref($alias) eq "ARRAY") {
            @ALIAS = @{$alias};
        } else {
            @ALIAS = ($alias);
        }

      $serverbypreferred{$preferred} = \@ALIAS;

    foreach my $host (@ALIAS)
    {
      $serverbyalias{$host} = $preferred;
#      print "$host -> $preferred\n";
    }
  }

  # config_allow
  # Here, we cannot allow end-of-line comments because they could clash
  # with regex patterns- however unlikely.
  # We will keep this info in an array of array refs like:
  # [ H|U precompiled-pattern original-line ]
  # where H or U specifies if this is a HOST or URL match.

#  open(CONF, "<etc/config_allow");
#  while(my $l = <CONF>)
#  {
#    chomp($l);
#    next if $l =~ /^\s*$/;
#    next if $l =~ /^\s*\#/;   # whole comment line
#
my $all = ${$url}{'allow'};
my $l;
if ( ref( ${$all}{'URL'} ) eq '' ) {
   $l = ${$all}{'URL'};
   if ($l) { push(@allow, [ 'U', qr/$l/, $l ] ); }
} else { foreach $l ( @{${$all}{'URL'}} ) { push(@allow, [ 'U', qr/$l/, $l ] ); } }
if ( ref( ${$all}{'HOST:'} ) eq '' ) {
   $l = ${$all}{'HOST:'};
   if ($l) { push(@allow, [ 'H', qr/$l/, 'HOST: ' . $l ] ); }
} else { foreach $l ( @{${$all}{'HOST:'}} ) { push(@allow, [ 'H', qr/$l/, 'HOST: ' . $l ] ); } }

#    my($hostind, $patt) = $l =~ /\s*(HOST:)?\s*(.*)$/;
#    # Is this a host or full URL match?
#    $hostind = defined $hostind ? 'H' : 'U';
#    push(@selurl::allow, [ $hostind, qr/$patt/, $l ] );
#
#  }
#  close(CONF);
#foreach my $l (@allow) { print join(' ',@{$l}) . "\n"; }

#
#  # config_exclude
#  # Same tea as config_allow in other porcelain.
#
#  open(CONF, "<etc/config_exclude");
#  while(my $l = <CONF>)
#  {
#    chomp($l);
#    next if $l =~ /^\s*$/;
#    next if $l =~ /^\s*\#/;   # whole comment line
#
my $excl = ${$url}{'exclude'};
if ( ref( ${$excl}{'URL'} ) eq '' ) {
   $l = ${$excl}{'URL'};
   if ($l) { push(@exclude, [ 'U', qr/$l/, $l ] ); }
} else { foreach $l ( @{${$excl}{'URL'}} ) { push(@exclude, [ 'U', qr/$l/, $l ] ); } }
if ( ref( ${$excl}{'HOST:'} ) eq '' ) {
   $l = ${$excl}{'HOST:'};
   if ($l) { push(@exclude, [ 'H', qr/$l/, 'HOST: ' . $l ] ); }
} else { foreach $l ( @{${$excl}{'HOST:'}} ) { push(@exclude, [ 'H', qr/$l/, 'HOST: ' . $l ] ); } }

#    my($hostind, $patt) = $l =~ /\s*(HOST:)?\s*(.*)$/;
#    # Is this a host or full URL match?
#    $hostind = defined $hostind ? 'H' : 'U';
#    push(@selurl::exclude, [ $hostind, qr/$patt/, $l ] );
#
#  }
#  close(CONF);
	
}

sub _sql_error {
    my $a; 
    warn "MySQLhdb; SQL ERROR\n";
    foreach $a (@_) {
        warn "$a\n"; 
    }
    return undef;
}

#Externaly available
sub Init {
    #Assign to $configFile or $dbname
    my ($jname, $baseDir) = @_;
    if (scalar(%configValues)) {
	warn  "**ERROR: JobName $jname discarded - config already initialized!\n";
	return;
    }
    $jobname=$jname;
    if (defined($baseDir)) { $baseConfigDir = $baseDir; }
}

sub Get {
    my ($name) = @_;

    if (!scalar(%configValues)) {
	_private_initConfig_();
    }
    my $value = $configValues{$name};
    if (!defined($value)) {
#	warn  "**ERROR: Undefined Combine configuration parameter $name\n";
        #Return undefined if value not available
	return undef;
    }

    return $value;
}

sub Set {
# Changes/Sets a config-value localy, in-memory
    my ($name, $value) = @_;
    $configValues{$name} = $value;
}

sub SetSQL {
# Changes/Sets a config-value globaly, in the SQL database
    my ($name, $value) = @_;
    warn "ConfigSQL::SetSQL is not implemented yet";
}

1;
