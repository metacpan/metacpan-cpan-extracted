## $Id: SD_SQL.pm 325 2011-05-26 14:26:00Z it-aar $

# 2002-2006 Anders Ardö
# 
# See the file LICENCE included in the distribution.

package Combine::SD_SQL;

use Combine::Config;
use Combine::selurl;
use DBI;

sub new {
    my ($class) = @_;
    my $sv = Combine::Config::Get('MySQLhandle');
    my $recyclelinks = Combine::Config::Get('AutoRecycleLinks');
    my $waitIntervalHost = Combine::Config::Get('WaitIntervalHost');
    if (!defined($waitIntervalHost) || $waitIntervalHost < 0) {
	$waitIntervalHost=60;
    }
    my $self = {
	dbcon => $sv,
        recyclelinks => $recyclelinks,
        waitIntervalHost => $waitIntervalHost,
	};

# Prepare handles for all SQL statements and save them in %{$self}

#Statement handles for lock
    $self->{updateUrlsLock} = $sv->prepare(qq{UPDATE urldb SET urllock=UNIX_TIMESTAMP()+?, retries=LAST_INSERT_ID(retries) WHERE urlid=?;});
    $self->{updateHostLock} = $sv->prepare(qq{UPDATE urldb SET netloclock=UNIX_TIMESTAMP()+? WHERE netlocid=?;});
    $self->{updateHostUrlLock} = $sv->prepare(qq{UPDATE urldb SET urllock=GREATEST(urllock,UNIX_TIMESTAMP())+? WHERE netlocid=?;});

    $self->{updateRetries} = $sv->prepare(qq{UPDATE netlocs SET retries=? WHERE netlocid=?;});

#Statement handles for get
    $self->{getStatus} = $self->{dbcon}->prepare(qq{SELECT status,schedulealgorithm FROM admin;});
    $self->{updateAlg} = $self->{dbcon}->prepare(qq{UPDATE admin SET schedulealgorithm=?});

#    $self->{updateHosts} = $sv->prepare(qq{UPDATE urldb SET netloclock=UNIX_TIMESTAMP()+$waitIntervalHost WHERE netlocid=?;});
    $self->{updateUrls} = $sv->prepare(qq{UPDATE urldb SET urllock=UNIX_TIMESTAMP()+?, harvest=0 WHERE urlid=?;});
    $self->{setQueId} = $sv->prepare(qq{UPDATE admin SET queid=LAST_INSERT_ID(queid+1);});
#    $self->{getUrl} = $sv->prepare(qq{SELECT netlocid,urlid FROM que WHERE queid=LAST_INSERT_ID();});
# ($hostid,$urlid,$url_str, $netlocStr, $urlPath)=$self->{getUrl}->fetchrow_array;
    $self->{getUrl} = $sv->prepare(qq{SELECT que.netlocid,que.urlid,urlstr,netlocstr,path FROM que,urls,netlocs WHERE queid=LAST_INSERT_ID() AND netlocs.netlocid=que.netlocid AND urls.urlid=que.urlid;});
#    $self->{getUrlStr} = $sv->prepare(qq{SELECT urlstr FROM urls WHERE urlid=?;});
    $self->{getUrlId} = $sv->prepare(qq{SELECT urlid FROM urls where url=?;}); 
    $self->{getCheckedDate} = $sv->prepare(qq{SELECT UNIX_TIMESTAMP(lastchecked) FROM recordurl WHERE recordurl.urlid=?;});
    $self->{lockTables} = $sv->prepare(qq{LOCK TABLES admin WRITE, que WRITE, urldb READ LOCAL, urls READ LOCAL, netlocs READ LOCAL;});
    $self->{unlockTables} = $sv->prepare(qq{UNLOCK TABLES;});
    $self->{deleteQue} = $sv->prepare(qq{DELETE FROM que;});
    $self->{resetQueId} = $sv->prepare(qq{UPDATE admin SET queid=LAST_INSERT_ID(0);});
    $self->{resetId} = $sv->prepare(qq{ALTER TABLE que AUTO_INCREMENT=1;});

#fill que in URL scheduling order
    $self->{fillQue} = $sv->prepare(qq{INSERT INTO que SELECT netlocid,urlid,NULL
         FROM urldb WHERE netloclock < UNIX_TIMESTAMP() AND
         urllock < UNIX_TIMESTAMP() AND 
         harvest=1 GROUP BY netlocid;});
#SELECT host,hostlock,sum(1) as nbrhost FROM urldb WHERE hostlock < UNIX_TIMESTAMP() AND urllock < UNIX_TIMESTAMP() AND harvest=1 GROUP BY host ORDER BY nbrhost DESC;
#Ger en lista sorterad med den host som har flest URLer først

    $self->{fillBigQue} = $sv->prepare(qq{INSERT INTO que SELECT netlocid,urlid,NULL
         FROM urldb WHERE urllock < UNIX_TIMESTAMP() AND harvest=1 GROUP BY netlocid;});

#Statement handles for put
#    $self->{insertUrls} = $sv->prepare(qq{INSERT IGNORE INTO urldb SET netlocid=?, urlid=?, urllock=UNIX_TIMESTAMP(), netloclock=UNIX_TIMESTAMP();});# OK to fail!
    $self->{insertUrls} = $sv->prepare(qq{INSERT IGNORE INTO urldb SET netlocid=?, urlid=?;});# OK to fail!
    $self->{setHarvest} = $sv->prepare(qq{UPDATE urldb SET harvest=1 WHERE urlid=?;});

#print "INIT SD\n";
    bless $self, $class;
    return $self;
}

sub putNorm {
    my ($self, $urlstr, $doget) = @_;
    #Makes a URL normalized and eligeble for harvest, inserted into table urldb if needed.
    my $u =  new Combine::selurl($urlstr, undef, 'sloppy' => 1);
    if ( $u && $u->validate() ) {
	$urlstr = $u->normalise();
	$netlocstr = $u->authority;
	$path_query = $u->path_query;

	my $lsth = $self->{dbcon}->prepare(qq{SELECT netlocid,urlid FROM urls WHERE urlstr=?;});
	$lsth->execute($urlstr);
	my ($netlocid,$urlid) = $lsth->fetchrow_array;
	if ( !defined($urlid) ) {
	    $self->{dbcon}->prepare(qq{INSERT IGNORE INTO netlocs SET netlocstr=?;})->execute($netlocstr);
	    ($netlocid) =  $self->{dbcon}->selectrow_array(qq{SELECT netlocid FROM netlocs WHERE netlocstr='$netlocstr';});
	    $self->{dbcon}->prepare(qq{INSERT IGNORE INTO urls SET urlstr=?, netlocid=?, path=?;})->execute($urlstr,$netlocid,$path_query);
	    $lsth->execute($urlstr);
	    ($netlocid,$urlid) = $lsth->fetchrow_array;
	}

	$self->{insertUrls}->execute($netlocid,$urlid);
	$self->{setHarvest}->execute($urlid);
        if ($doget) {return ($netlocid,$urlid,$urlstr, $netlocstr, $path_query, 0); }
    }
    return 1; #Evt urlid?
}

sub get_url {
    my ($self) = @_;
#Extracts the next URL from the queue of ready URLs (table que)
#If no URLs in the queue, try to fill queue from table urls
    my $hostid=0;
    my $urlid=0;
    my ($url_str, $netlocStr, $urlPath);
    my $InProgress=60; # Needs to be parametrized??

    $self->{getStatus}->execute;
    my ($status,$schedAlg)=$self->{getStatus}->fetchrow_array;
#    print "In GetUrl ...";
##Combine getStatus and setQueId in one query??
    if ( $status eq 'open' ) {
	$self->{setQueId}->execute;
	$self->{getUrl}->execute;
	($hostid,$urlid,$url_str, $netlocStr, $urlPath)=$self->{getUrl}->fetchrow_array;
#	print "Got: ($hostid,$urlid,$url_str, $netlocStr, $urlPath)\n";
	if (!defined($hostid)) { ($hostid,$urlid,$url_str, $netlocStr, $urlPath)=generateQue($self,$schedAlg); }

	$self->{updateHostLock}->execute($self->{waitIntervalHost},$hostid);
	$self->{updateUrls}->execute($InProgress,$urlid);
    }
    if ( !defined($urlid) ) { 
#	print "getUrl returns fail \n";
      return (0,0,'','','');
    } else {
#	my $url_str =  $self->{getUrlStr}->execute($urlid);
#	print "getUrl returns OK ($hostid,$urlid,$url_str, $netlocStr, $urlPath)\n";
        $self->{getCheckedDate}->execute($urlid);
	my $checkedDate = $self->{getCheckedDate}->fetchrow_array;
	return ($hostid,$urlid,$url_str, $netlocStr, $urlPath, $checkedDate);
    }
}

sub generateQue {
    my ($self,$alg) = @_;
# Fills the queue of ready URLs (table que) from the table urls.
# Table que must be cleared first. queid in table admin must be reset.
# It should return (hostid,url) if possible

# It must be executed in mutual exclusion which is done by first
# locking tables, and when the lock is obtained checking that the
# queue still is empty. If empty try to fill it, otherwise just
# return the first url from the queue.

    my ($hostid,$urlid,$url_str, $netlocStr, $urlPath, $r);
    if ($self->{recyclelinks}) { RecycleNew($self); }
    $self->{lockTables}->execute;
    $self->{setQueId}->execute;
    $self->{getUrl}->execute;
    ($hostid,$urlid,$url_str, $netlocStr, $urlPath)=$self->{getUrl}->fetchrow_array;
    if ( !defined($hostid) ) { #still no URLs in que => OK to update it
	$self->{deleteQue}->execute;
	$self->{resetQueId}->execute;
	$self->{resetId}->execute;
        $self->{fillQue}->execute; #ORIG
#FIX SQL query dependent on configVar ScheduleAlgorithm!!!!!!!!!!

	# extract URL from que to return
	$self->{setQueId}->execute;
	$self->{getUrl}->execute;
	($hostid,$urlid,$url_str, $netlocStr, $urlPath)=$self->{getUrl}->fetchrow_array;
    }
    $self->{unlockTables}->execute;
    return ($hostid,$urlid,$url_str, $netlocStr, $urlPath);
}

sub UpdateLastCheckTime {
    # do this in lock by checking the code (304)??
    my ($self,$urlid) = @_;
    $self->{dbcon}->do(qq{UPDATE recordurl SET lastchecked=NOW() WHERE urlid='$urlid';});
}

sub lock {
    my ($self,$netlocid,$urlid,$time,$code) = @_;
#        my $sdqRetries = 10;
# lock $url for $time seconds
    $self->{updateUrlsLock}->execute($time,$urlid);

# Compatibility functions
#  handle deletions when to many retries (nrt=1000)???
#  handle $code ...
    if ( ($code eq '408') || &HTTP::Status::is_server_error($code) ) {
        my $RetryDelay=18000;
        #$self->{updateRetries}->execute($failcnt+1, $netlocid);
	# lock $netlocid for $RetryDelay seconds
	$self->{updateHostLock}->execute($RetryDelay, $netlocid);

# increase failcnt        
#       if ( $failcnt > $sqdRetries ) { #delete host
#?????????
#       }
    }

    return;
}

sub hostlock {
    my ($self,$netlocid,$time) = @_;
    # lock $netlocid for $time seconds
    $self->{updateHostLock}->execute($time, $netlocid);
#?    $self->{updateRetries}->execute($failcnt+1, $host);
    return;
}

#Recycling functions
sub RecycleNew {
#adds all valid entries in table newlinks to the harvest-database urldb
    my ($self) = @_;
    my ($netlocid,$urlid,$urlstr);
    my $sth = $self->{dbcon}->prepare(qq{SELECT newlinks.netlocid,newlinks.urlid,urlstr FROM newlinks,urls WHERE newlinks.urlid=urls.urlid;});
    $self->{dbcon}->prepare(qq{LOCK TABLES newlinks WRITE, urls READ LOCAL, urldb WRITE;})->execute;
    $sth->execute;
    my $ant=0; my $tot=0;
    while ( ($netlocid,$urlid,$urlstr)=$sth->fetchrow_array ) {
	$tot++;
	my $u = new Combine::selurl($urlstr);
	if ( $u && $u->validate() ) {
	    $self->{insertUrls}->execute($netlocid,$urlid);
	    $self->{setHarvest}->execute($urlid);
	    $ant++;
	}
    }
    $self->{dbcon}->prepare(qq{DELETE FROM newlinks;})->execute;
    $self->{dbcon}->prepare(qq{UNLOCK TABLES;})->execute;
    return "$ant links (out of $tot) recycled\n";
}

sub RecycleOld {
#marks all existing records for harvest
#use selurl to remove existing records not passing rules ??
    my ($self) = @_;
    my $sth = $self->{dbcon}->prepare(qq{UPDATE urldb,recordurl SET harvest=1 WHERE urldb.urlid=recordurl.urlid;})->execute();
    return "$sth old records marked for harvesting\n";
}
#End; Recycling functions

#Init (if needed) MEMORY SQL tables. Called from bin/start.pl
sub initMemoryTables {
    my ($self) = @_;
    $self->{getStatus}->execute;
    my ($status,$tmp)=$self->{getStatus}->fetchrow_array;
    if ( $status eq '' ) {
	$self->{dbcon}->do(qq{LOCK TABLES admin WRITE;});
	$self->{getStatus}->execute;
	($status,$tmp)=$self->{getStatus}->fetchrow_array;
	if ( $status eq '' ) {
#!#Use value from ConfigVar SchedulingAlgorithm
	    $self->{dbcon}->do(qq{INSERT INTO admin VALUES ('open','default',0);});
	    warn("Memory table 'admin' initialised to ('open','default',0)");
	}
	$self->{dbcon}->do(qq{UNLOCK TABLES;});
    }
}
#

sub hosts {
    my ($self) = @_;
    my $sth = $self->{dbcon}->prepare(qq{SELECT urldb.netlocid,netlocstr,netloclock-UNIX_TIMESTAMP(),sum(1) as ant FROM urldb,netlocs WHERE harvest=1 AND urllock<UNIX_TIMESTAMP() AND urldb.netlocid=netlocs.netlocid GROUP BY urldb.netlocid ORDER BY ant DESC;});

    $sth->execute;
    while ( ($netlocid,$netlocstr,$tid,$ant)=$sth->fetchrow_array ) {
	if ( $tid<0 ) { $t = 'READY'; } else { $t = "WAITING ($tid s)"; }
        $res .= "$netlocstr (ID=$netlocid)  $ant urls; $t\n";
    }
    return $res;
}

#Remove?
sub recordsNo {
    my ($self) = @_;
    my $sth = $self->{dbcon}->prepare(qq{SELECT count(*) FROM hdb;});

    $sth->execute;
    while ( ($ant)=$sth->fetchrow_array ) {
        $res = "There are $ant records in the database\n";
    }
    return $res;
}

sub howmany {
    my ($self) = @_;
    my ($tot) = $self->{dbcon}->selectrow_array(qq{SELECT count(urlid) FROM urldb WHERE harvest=1;});
    my ($ant) = $self->{dbcon}->selectrow_array(qq{SELECT max(queid) FROM que;});
    if (!defined($ant)) { $ant=0; }
    return "$tot waiting for harvest and $ant in ready queue\n";
}
sub algorithm {
    my ($self,$which) = @_;
    return "Not implemented yet.\n";
}
sub sort {
    my ($self) = @_;
    return "Not implemented yet.\n";
}
sub stat {
    my ($self) = @_;
    my ($stat,$present) = $self->{dbcon}->selectrow_array(qq{SELECT status,queid FROM admin;});
    my ($ant) = $self->{dbcon}->selectrow_array(qq{SELECT max(queid) FROM que;});
    if (!defined($ant)) { $ant=0; }
    if ($stat eq 'open') { $compat = "Stat: OPENED\n"; }
    return "Status: $stat; At $present of $ant in ready queue\n$compat";
}
sub reSchedule {
    my ($self) = @_;
    $self->{dbcon}->do(qq{UPDATE admin SET queid=99999999;});
}
sub open {
    my ($self) = @_;
    $self->{dbcon}->do(qq{UPDATE admin SET status='open';});
    return &stat($self);
}
sub stop {
    my ($self) = @_;
    $self->{dbcon}->do(qq{UPDATE admin SET status='stopped';});
    return &stat($self);
}
sub pause {
    my ($self) = @_;
    $self->{dbcon}->do(qq{UPDATE admin SET status='paused' WHERE status='open';});
    return &stat($self);
}
sub continue {
    my ($self) = @_;
    $self->{dbcon}->do(qq{UPDATE admin SET status='open' WHERE status='paused';});
    return &stat($self);
}

sub sd_close {
  my ($self) = @_;
  return undef;
}

sub destroy {
    my ($self) = @_;
    return undef;
}

1;

__END__

=head1 NAME

SD_SQL

=head1 DESCRIPTION

Reimplementation of sd.pl SD.pm and SDQ.pm using MySQL
 contains both recyc and guard

Basic idea is to have a table (urldb) that contains most URLs ever
inserted into the system together with a lock (the guard function) and
a boolean harvest-flag. Also in this table is the host part together with
its lock. URLs are selected from this table based on urllock, netloclock and
harvest and inserted into a queue (table que). URLs from this queue
are then given out to harvesters. The queue is implemented as:
# The admin table can be used to generate sequence numbers like this: 
#mysql> update admin set queid=LAST_INSERT_ID(queid+1);
# and used to extract the next URL from the queue
#mysql> select host,url from que where queid=LAST_INSERT_ID();
#
When the queue is empty it is filled from table urldb. Several different
algorithms can be used to fill it (round-robin, most urls, longest time
since harvest, ...). Since the harvest-flag and guard-lock are not updated
until the actual harvest is done it is OK to delete the queue and
regenerate it anytime.

##########################
#Questions, ideas, TODOs, etc
#Split table urldb into 2 tables - one for urls and one for hosts???
#Less efficient when filling que; more efficient when updating netloclock
#Datastruktur TABLE hosts:
create table hosts(
 host varchar(50) not null default '',
 netloclock int not null,
 retries int not null default 0,
 ant int not null default 0,
 primary key (host),
 key (ant), 
 key (netloclock)
 );

#############
Handle to many retries?

    algorithm takes an url from the host that was accessed longest ago
    ($hostid,$url)=SELECT host,url,id FROM hosts,urls WHERE 
	 hosts.hostlock < UNIX_TIMESTAMP()
	 hosts.host=urls.host AND 
         urls.urllock < UNIX_TIMESTAMP() AND 
	 urls.harvest=1 ORDER BY hostlock LIMIT 1;

    algorithm takes an url from the host with most URLs
    ($hostid,$url)=SELECT host,url,id FROM hosts,urls WHERE 
	 hosts.hostlock < UNIX_TIMESTAMP()
	 hosts.host=urls.host AND 
         urls.urllock < UNIX_TIMESTAMP() AND 
	 urls.harvest=1 ORDER BY host.ant DESC LIMIT 1;

    algorithm takes an url from any available host
    ($hostid,$url)=SELECT host,url,id FROM hosts,urls WHERE 
	 hosts.hostlock < UNIX_TIMESTAMP()
	 hosts.host=urls.host AND 
         urls.urllock < UNIX_TIMESTAMP() AND 
	 urls.harvest=1 LIMIT 1;

=head1 AUTHOR

Anders Ardö <anders.ardo@it.lth.se>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005,2006 Anders Ardö

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

See the file LICENCE included in the distribution at
 L<http://combine.it.lth.se/>

=cut
