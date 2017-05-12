# MySql replacement for hdb
# AA0 2002-09-30
#    Modified Open to return DBI connection and HDB table name

package Combine::MySQLhdb;

use strict;
use Combine::XWI;
use HTTP::Date;
use Encode;

my $sv; # holds the mysql connection
my $table = ''; # holds the hdb table name
my $savehtml;
my $doOAI;

sub Open { #needed??
    use Combine::Config;
    $sv = Combine::Config::Get('MySQLhandle');
    $savehtml = Combine::Config::Get('saveHTML');
    $doOAI = Combine::Config::Get('doOAI');
    my $hdbd = 'hdb';
    return ($sv,$hdbd);
}

sub Close {
#    print "MySQLhdb::Close\n";
    $sv->disconnect ;
}

sub DESTROY {
    print STDERR "MySQLhdb::DESTROY\n";
    $sv->disconnect ;
}

sub Write {
    my ($xwi) = @_;
    return undef unless $xwi;
    if (!defined($sv)) { Open(); } #Init $sv CHANGE?
    my $md5 = $xwi->md5; 
    my $recordid = $xwi->recordid;  #Set by DataBase.pm
#OAI
     if ($doOAI) {
       $sv->prepare("REPLACE INTO oai SET status='created', recordid=?, md5=?")->execute($recordid, $md5);
     }
#OAI
#    $xwi->url_rewind; MORE THAN one URL??
#    my $url = $xwi->url_get;
    my $urlid = $xwi->urlid;
    my $my_netlocid = $xwi->netlocid;
    my $type = $xwi->type;
    my $title = $xwi->title;
#checkedDate is inserted/updated in DataBase.pm and harvpars.pl
    my $modifiedDate = $xwi->modifiedDate;
    if ( ! $modifiedDate) { $modifiedDate = $xwi->checkedDate; }
    my $expiryDate = $xwi->expiryDate;
#    if ($expiryDate) { $expiryDate = str2time($expiryDate) ; }
#    else { $expiryDate = 'NULL'; }
    my $length = $xwi->length;
    my $server = $xwi->server;
    my $etag = $xwi->etag;
    my $nheadings = $xwi->heading_count;
    my $headings='';
# headings
    $xwi->heading_rewind;
    while (1) {
        my $this = $xwi->heading_get or last; 
	$headings .= $this . '; ';
    }
    my $nlinks = $xwi->link_count;
    my $this = $xwi->text;
    my $ip;
    if ($this) {
      $this = $$this;
      if ($xwi->truncated()) {

        # IMPORTANT! This document was truncated. Therefore:
        #
        # 1) Discard it if no space characters in it, because then it
        #    could be binary.
        #
        # 2) If a space is found, then truncate after the last space,
        #    so as to avoid erroneous indexing (since the truncation
        #    most likely cut a word).

        my $last_blank = rindex($this,' ');
        if ($last_blank > 0) {
          $ip = substr($this, 0, $last_blank) ;
        }
      }
      else {
        $ip = $this ;
      }
    } else { my $t=''; $xwi->text(\$t); } #make sure xwi->text is defined
#??    if (length($ip)>250000) {$ip = substr($ip, 0, 250000);}

    $sv->prepare("REPLACE INTO hdb VALUES (?, ?, ?, FROM_UNIXTIME( ? ), FROM_UNIXTIME( ? ), ?, ?, ?, ?, ?, ?, COMPRESS(?))")->execute(
      $recordid, $type, Encode::encode('utf8',$title), $modifiedDate, $expiryDate, $length, $server, $etag, $nheadings, $nlinks, Encode::encode('utf8',$headings), Encode::encode('utf8',$ip));

    if ( $savehtml == 1 ) {
	my $html = $xwi->content;
	$sv->prepare("REPLACE INTO html SET html=COMPRESS(?), recordid=?")->execute(Encode::encode('utf8',$$html),$recordid);
    }

    my $res;

#save links
    my ( $urlstr, $anchor, $ltype);
    $xwi->link_rewind;
    my $link_count = 1;
    my $netlocid;
    $res = $sv->do(qq{DELETE FROM links WHERE recordid='$recordid';}); #needed?
    while(1) { #links
        ($urlstr, $netlocid, $urlid, $anchor, $ltype) = $xwi->link_get;
        if (defined($urlstr)) {
#Convert urlstr to urlid,netlocid if needed
	    if ( ($netlocid <= 0) || ($urlid <= 0) ) {
		if ( $urlstr eq '') { print STDERR "ERR MySQLhdb, save links, no info\n"; }  ## sanity check -> log error 
		use Combine::selurl;
		my $u;
		if ( $u = new Combine::selurl($urlstr) ) {
		    $urlstr = $u->normalise();
		    my $netlocstr = $u->authority;
		    my $path_query = $u->path_query;
		    my $lsth = $sv->prepare(qq{SELECT netlocid,urlid FROM urls WHERE urlstr=?;});
		    $lsth->execute($urlstr);
		    ($netlocid,$urlid) = $lsth->fetchrow_array;
		    if ( !defined($urlid) ) {
			$sv->prepare(qq{INSERT IGNORE INTO netlocs SET netlocstr=?;})->execute($netlocstr);
#			($netlocid) =  $sv->selectrow_array(qq{SELECT netlocid FROM netlocs WHERE netlocstr='$netlocstr';});
			my $nlsth =  $sv->prepare(qq{SELECT netlocid FROM netlocs WHERE netlocstr=?;});
			$nlsth->execute($netlocstr);
			($netlocid) =  $nlsth->fetchrow_array();
			$sv->prepare(qq{INSERT IGNORE INTO urls SET urlstr=?, netlocid=?, path=?;})->execute($urlstr,$netlocid,$path_query);
			$lsth->execute($urlstr);
			($netlocid,$urlid) = $lsth->fetchrow_array;
		    }
		    $sv->prepare("INSERT INTO links (recordid,mynetlocid,urlid,netlocid,anchor,linktype) VALUES (?, ?, ?, ?, ?, ?)")->execute($recordid,$my_netlocid,$urlid,$netlocid,Encode::encode('utf8',$anchor),$ltype);
		}
	    } else {
		$sv->prepare("INSERT INTO links (recordid,mynetlocid,urlid,netlocid,anchor,linktype) VALUES (?, ?, ?, ?, ?, ?)")->execute($recordid,$my_netlocid,$urlid,$netlocid,Encode::encode('utf8',$anchor),$ltype);
	    }
        } else { last; }
        last if ($link_count++ >= 500);  # limit on number of links
    }

#save metadata
     $xwi->meta_rewind;
    $res = $sv->do(qq{DELETE FROM meta WHERE recordid='$recordid';}); #needed?
     my ($name,$content);
     while (1) {
        ($name,$content) = $xwi->meta_get;
        last unless $name;
        $sv->prepare("INSERT INTO meta VALUES (?, ?, ?)")->execute($recordid, Encode::encode('utf8',$name), Encode::encode('utf8',$content));
     } 

#OLD
#save URLs
#    $xwi->url_rewind;
#    $res = $sv->do(qq{DELETE FROM urls WHERE recordid='$recordid';});
#    while (1) {
#        $this = $xwi->url_get or last;
##        $res = $sv->do(qq{INSERT INTO urls VALUES ('$recordid','$this');});
#	my $machine = $this;
#	$machine =~ s|http://([^:/]+)[:/]?.*|$1|;
#        $sv->prepare("INSERT INTO urls VALUES (?, ?, ?)")->execute($recordid, $this, $machine);
#    }

#save robot data in analys table (uses that URL is stored)
    $xwi->robot_rewind;
    $res = $sv->do(qq{DELETE FROM analys WHERE recordid='$recordid';}); #needed?
    while (1) {
        ($name,$content) = $xwi->robot_get;
        last unless $name;
        $sv->prepare("INSERT INTO analys VALUES (?, ?, ?)")->execute($recordid, $name, Encode::encode('utf8',$content));
     }
##    my $alinks = calclinks($recordid,$machine); #?
#What if link-stats are inserted double after a Get and following write?
    my $sth = $sv->prepare(qq{SELECT COUNT(DISTINCT(links.recordid)), COUNT(DISTINCT(mynetlocid)) FROM links,recordurl WHERE recordurl.recordid= ? AND
        links.urlid = recordurl.urlid AND mynetlocid<>links.netlocid;});
    $sth->execute($recordid);
    my ($inlinks,$hostinlinks)=$sth->fetchrow_array;
    $sv->prepare("INSERT INTO analys VALUES (?, ?, ?)")->execute($recordid, 'inlinks', $inlinks);
    $sv->prepare("INSERT INTO analys VALUES (?, ?, ?)")->execute($recordid, 'hostinlinks', $hostinlinks);
    $sth = $sv->prepare(qq{SELECT count(distinct(netlocid)) FROM links WHERE recordid=?;});
    $sth->execute($recordid);
    my ($outlinks)=$sth->fetchrow_array;
    $sv->prepare("INSERT INTO analys VALUES (?, ?, ?)")->execute($recordid, 'outlinks', $outlinks);

#save topic, ie result of autoclassification
    $xwi->topic_rewind;
    $res = $sv->do(qq{DELETE FROM topic WHERE recordid='$recordid';}); #needed?
    my ($cls,$absscore, $relscore, $terms, $alg);
    while (1) {
        ($cls,$absscore, $relscore,$terms, $alg) = $xwi->topic_get;
        last unless $cls;
        $sv->prepare("INSERT INTO topic VALUES (?, ?, ?, ?, ?, ?)")->execute($recordid, Encode::encode('utf8',$cls), $absscore, $relscore, Encode::encode('utf8',$terms), $alg);
     }
    if (my $zh = Combine::Config::Get('ZebraHost')) {
      require Combine::Zebra;
      Combine::Zebra::update($zh,$xwi);
    }
    if (Combine::Config::Get('MySQLfulltext')) {
      $sv->prepare("REPLACE INTO search VALUES (?, ?)")->execute($recordid, Encode::encode('utf8',$title .' '. $ip));
    }
    if (my $sh = Combine::Config::Get('SolrHost')) {
      require Combine::Solr;
      Combine::Solr::update($sh,$xwi);
    }
}

sub Delete { #Used??
    my ($xwi) = @_;
    return undef unless $xwi;

    my $recordid = $xwi->recordid; 
#print "MySQLhdb::DeleteMD5 $recordid\n";
    DeleteKey($recordid, $xwi->md5);
}

sub DeleteKey {
    my ($key, $md5) = @_;
    if (!defined($sv)) { Open(); } #Init $sv CHANGE?
#OAI
     if ($doOAI) {
#     $sv->prepare("REPLACE INTO oai SET status='deleted', recordid=?, md5=?")->execute($key,$md5);
##FEL recurdurl updaterad i Database.pm FIX!
       $sv->prepare("REPLACE INTO oai SELECT recordid,md5,NOW(),'deleted' FROM recordurl WHERE recordid=?")->execute($key);
     }
#OAI

#Zebra
    if (my $zh = Combine::Config::Get('ZebraHost')) {
      require Combine::Zebra;
#Not needed: if ($md5 eq '') { ($md5)=$sv->selectrow_array('SELECT md5 FROM recordurl WHERE recordid=$key'); }
      Combine::Zebra::delete($zh, $md5, $key);
    }
    if (my $sh = Combine::Config::Get('SolrHost')) {
      require Combine::Solr;
      Combine::Solr::delete($sh, $md5, $key);
    }

#print "MySQLhdb::DeleteKey $key\n";
    my $res = $sv->do(qq{DELETE FROM hdb WHERE recordid=$key;});
    $res = $sv->do(qq{DELETE FROM html WHERE recordid=$key;});
    $res = $sv->do(qq{DELETE FROM search WHERE recordid=$key;});
    $res = $sv->do(qq{DELETE FROM meta WHERE recordid=$key;});
    $res = $sv->do(qq{DELETE FROM analys WHERE recordid=$key});
    $res = $sv->do(qq{DELETE FROM links WHERE recordid=$key;});
    $res = $sv->do(qq{DELETE FROM topic WHERE recordid=$key;});
    $res = $sv->do(qq{DELETE FROM recordurl WHERE recordid=$key;});
}

sub Get {
    my ($key) = @_;
    #should return an initalized xwi-object
    if (!defined($sv)) { Open(); } #Init $sv CHANGE?

    my ($type, $title, $modifiedDate, $expiryDate, $length, $server, $etag, $nheadings, $nlinks, $headings, $ip) =
      $sv->selectrow_array(qq{SELECT type,title,
   UNIX_TIMESTAMP(mdate),IF(expiredate,UNIX_TIMESTAMP(expiredate),0),
   length,server,etag,nheadings,nlinks,headings,UNCOMPRESS(ip)
   FROM hdb WHERE recordid='$key';});

    my $xwi = new Combine::XWI ;
    $xwi->recordid($key);
#url Relies on that all urls are in table urls
    $xwi->type($type);
    $xwi->title(Encode::decode('utf8',$title));
    $xwi->modifiedDate($modifiedDate);
    if ($expiryDate>0) {$xwi->expiryDate($expiryDate)};
    $xwi->length($length);
    $xwi->server($server);
    $xwi->etag($etag);
    $xwi->nheadings($nheadings);
    $xwi->nlinks($nlinks);
    $headings =~ s/; $//;
    $xwi->heading_add(Encode::decode('utf8',$headings)) ;
    my $ip1=Encode::decode('utf8',$ip);
    $xwi->text(\$ip1);
    my ($html1) = $sv->selectrow_array(qq{SELECT UNCOMPRESS(html) FROM html WHERE recordid='$key';});
    my $html = Encode::decode('utf8',$html1);
    $xwi->content(\$html);

    my ($urlpath) = $sv->selectrow_array(qq{SELECT path FROM urls,recordurl WHERE recordid='$key' AND recordurl.urlid=urls.urlid;});
    $xwi->urlpath($urlpath);

    my ($url,$anchor,$lty,$name,$value,$heading);
#links
    my $sth = $sv->prepare(qq{SELECT urlid,netlocid,anchor,linktype from links WHERE recordid='$key';});
    $sth->execute;
    my ($urlid,$netlocid,$checkedDate,$md5,$fingerprint,$cls,$absscore,$relscore,$terms,$alg);
   while (($urlid,$netlocid,$anchor,$lty)=$sth->fetchrow_array) {
	$xwi->link_add('', $netlocid, $urlid, Encode::decode('utf8',$anchor), $lty) ; #no URLstr add?
    }

#meta
    $sth = $sv->prepare(qq{SELECT name,value from meta WHERE recordid='$key';});
    $sth->execute;
    while (($name,$value)=$sth->fetchrow_array) {
	$xwi->meta_add(Encode::decode('utf8',$name),Encode::decode('utf8',$value)) ;
    }

# analys -> robot
    $sth = $sv->prepare(qq{SELECT name,value FROM analys WHERE recordid='$key';});
    $sth->execute;
    while (($name,$value)=$sth->fetchrow_array) {
	$xwi->robot_add($name,Encode::decode('utf8',$value)) ;
    }

# topic
    $sth = $sv->prepare(qq{SELECT notation,abscore,relscore,terms,algorithm FROM topic WHERE recordid='$key';});
    $sth->execute;
    while (($cls,$absscore,$relscore,$terms,$alg)=$sth->fetchrow_array) {
	$xwi->topic_add(Encode::decode('utf8',$cls),$absscore,$relscore,Encode::decode('utf8',$terms),$alg) ;
    }

#recordurl
    $sth = $sv->prepare(qq{SELECT urlid,UNIX_TIMESTAMP(lastchecked),md5,fingerprint FROM recordurl WHERE recordid='$key';});
    $sth->execute;
    while (($urlid,$checkedDate,$md5,$fingerprint)=$sth->fetchrow_array) {
	$xwi->urlid($urlid);
	$xwi->checkedDate($checkedDate);
	$xwi->md5($md5);
        $xwi->fingerprint($fingerprint);
    }

    return $xwi;
}

1;
