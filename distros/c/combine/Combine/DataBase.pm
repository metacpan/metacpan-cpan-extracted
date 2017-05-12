# Copyright (c) 2004, 2005 Anders Ardö
## $Id: DataBase.pm 326 2011-05-27 07:44:58Z it-aar $

# 
# See the file LICENCE included in the distribution.

package Combine::DataBase;

use strict;
use Combine::MySQLhdb;
use Digest::MD5;
use Encode qw(encode_utf8);

sub new { 
    my ($class, $xwi, $sv, $loghandle) = @_;
    $xwi = new Combine::XWI unless ref $xwi;
    my $self = {};
    $self->{'xwi'} = $xwi;
    $self->{'databasehandle'} = $sv;
    $self->{'loghandle'} = $loghandle;
    bless $self, $class;
    return $self;
} 

#uses table recordurl with columns: recordid, urlid, lastchecked PRIMARY KEY (urlid), key recordid
#  recordid and urlid starts at 1 !!

sub delete {
    my ($self) = @_;
    my $xwi = $self->{'xwi'};
    return undef unless ref $xwi;
    
    my $urlid = $xwi->urlid;
    my ($recordid, $md5) = $self->{databasehandle}->selectrow_array(
              qq{SELECT recordid,md5 FROM recordurl WHERE urlid=$urlid;}); #Only one
    return if !defined($recordid);
    $self->{'loghandle'}->say("DataBase::delete $urlid, $recordid, $md5;");
#LOCK recordurl - needed?
    $self->{databasehandle}->prepare(qq{LOCK TABLES recordurl WRITE;})->execute();
    #delete URL from recordurl
    $self->{databasehandle}->prepare(qq{DELETE FROM recordurl WHERE urlid=?;})->execute($urlid);
    my ($ant) = $self->{databasehandle}->selectrow_array(
              qq{SELECT recordid FROM recordurl WHERE recordid=$recordid LIMIT 1;});
#UNLOCK recordurl - needed?
    $self->{databasehandle}->prepare(qq{UNLOCK TABLES;})->execute();
    if ( !defined($ant) || ($ant == 0) ) { Combine::MySQLhdb::DeleteKey($recordid,$md5); } #Should handle del's of non-existing recs

    $xwi->nofollow("true"); #?? check??
}

sub insert {
    my ($self) = @_;
    my $xwi = $self->{'xwi'};
    return undef unless ref $xwi;

    my $urlid = $xwi->urlid;
##    my $md5 = $xwi->md5;

    my $md5D = new Digest::MD5;
    $md5D->reset;
    if ( length($xwi->text) > 0 ) {
	my $text = ${$xwi->text} . $xwi->title;
	$text =~ s/[\s\n\r]+//g;
	$md5D->add(encode_utf8($text)); #use only visible text without whitespace
    } else {
	$md5D->add($xwi->url);
	$md5D->add($xwi->type());
    }
    $_ = $md5D->hexdigest;
    tr/a-z/A-Z/;
    $xwi->md5($_);
    my $md5 = $_;

    $self->{'loghandle'}->say("DataBase::insert $urlid, $md5;");

    #actions according the following truth table based presence in recordurl
    #urlid: there is a document in the database for this url
    #recordid: there is as documenent in the database with the same MD5 as the new page
#
    #              recordid       |        ! recordid
    #  urlid   if same md5        |    delete(urlid_recordid);
    #           update(lastcheck) |    update(urlid); insertRec
    #          else delete(urlid_recordid);|
    #           add(urlid)        |
    # -----------------------------------------------------------------------------
    # ! urlid  add(urlid)         |   add(urlid); insertRec

    my $existurlid = 0;
    my $existrecordid = 0;
    my $oldmd5='';
#LOCK recordurl
    $self->{databasehandle}->prepare(qq{LOCK TABLES recordurl WRITE;})->execute();
    ($existurlid,$oldmd5) = $self->{databasehandle}->selectrow_array(
			   qq{SELECT urlid,md5 FROM recordurl WHERE urlid=$urlid;});
    ($existrecordid) = $self->{databasehandle}->selectrow_array(
                           qq{SELECT recordid FROM recordurl WHERE md5='$md5';});

    if (!defined($existrecordid)) { $existrecordid = 0; }
    if (!defined($existurlid)) { $existurlid = 0; }
    if (!defined($oldmd5)) { $oldmd5 = ''; }
#Log not locked    $self->{'loghandle'}->say("DataBase:: $urlid, $md5; $existrecordid; $existurlid; $oldmd5;");

#CASE 1: There are documents for both the URL and the MD5 and they have the same md5
    if ( ($existrecordid && $existurlid) && ($md5 eq $oldmd5) ) {
        # updateLastCheck
	$self->{databasehandle}->prepare(
               qq{UPDATE recordurl SET lastchecked=NOW() WHERE urlid=?;})->execute($urlid);
	$self->{databasehandle}->prepare(qq{UNLOCK TABLES;})->execute(); #UNLOCK recordurl
	$self->{'loghandle'}->say("DataBase:: case 1: $existrecordid; $existurlid; $oldmd5;");

#CASE 2
    } elsif ( $existrecordid && $existurlid ) {
    #eg    } elsif ( ($existrecordid && $existurlid) && ($md5 ne $oldmd5) ) {
    #There are documents for both the URL and the MD5 and they have different md5
        # deleteOld
	my $oldrecordid = 0;
	($oldrecordid) = $self->{databasehandle}->selectrow_array(
                          qq{SELECT recordid FROM recordurl WHERE urlid=$urlid;});
	#delete URL from recordurl
	$self->{databasehandle}->prepare(qq{DELETE FROM recordurl WHERE urlid=?;})->execute($urlid);
	$self->{databasehandle}->prepare(
              qq{INSERT INTO recordurl SET urlid=?, recordid=?, md5=?, lastchecked=NOW();})->execute($urlid, $existrecordid, $md5);
	$self->{databasehandle}->prepare(qq{UNLOCK TABLES;})->execute(); #UNLOCK recordurl
	my ($ant) = $self->{databasehandle}->selectrow_array(
	          qq{SELECT recordid FROM recordurl WHERE recordid=$oldrecordid LIMIT 1;}); #Outside LOCK?
	if ( ! defined($ant) ) { $ant = 0; }
	$self->{'loghandle'}->say("DataBase::DelURL case 2: $oldrecordid; $ant;; $existrecordid; $existurlid; $oldmd5;");
	if ( $ant == 0 ) { Combine::MySQLhdb::DeleteKey($oldrecordid, $oldmd5); }

#CASE 3
    } elsif ( $existrecordid && ! $existurlid ) {
        # addUrlId
	$self->{databasehandle}->prepare(
              qq{INSERT INTO recordurl SET urlid=?, recordid=?, md5=?, lastchecked=NOW();})->execute($urlid, $existrecordid, $md5);
	$self->{databasehandle}->prepare(qq{UNLOCK TABLES;})->execute(); #UNLOCK recordurl
	$self->{'loghandle'}->say("DataBase:: case 3: $existrecordid; $existurlid; $oldmd5;");

#CASE 4
    } elsif ( ! $existrecordid && $existurlid ) {
        # deleteOld
	my $oldrecordid = 0;
	($oldrecordid) = $self->{databasehandle}->selectrow_array(
                          qq{SELECT recordid FROM recordurl WHERE urlid=$urlid;});

#	delete($self, $urlid, $oldrecordid); #Problem med LOCK!!! -> ny subrutin
	#delete URL from recordurl
	$self->{databasehandle}->prepare(qq{DELETE FROM recordurl WHERE urlid=?;})->execute($urlid);
        #ASSIGN NEW RECORDID done with auto_increment in SQL
	$self->{databasehandle}->prepare(
             qq{INSERT INTO recordurl SET urlid=?, md5=?, lastchecked=NOW();})->execute($urlid,$md5);
	$self->{databasehandle}->prepare(qq{UNLOCK TABLES;})->execute(); #UNLOCK recordurl
	my ($ant) = $self->{databasehandle}->selectrow_array(
              qq{SELECT recordid FROM recordurl WHERE recordid=$oldrecordid LIMIT 1;});
	if ( ! defined($ant) ) { $ant = 0; }
	$self->{'loghandle'}->say("DataBase::DelURL $oldrecordid; $ant;");
	if ( $ant == 0 ) { Combine::MySQLhdb::DeleteKey($oldrecordid, $oldmd5); }
	my ($recordid) = $self->{databasehandle}->selectrow_array(
              qq{SELECT recordid FROM recordurl WHERE urlid=$urlid;});
	$xwi->recordid($recordid);
	$self->{'loghandle'}->say("DataBase::Write $recordid case 4: $existrecordid; $existurlid; $oldmd5;");
	Combine::MySQLhdb::Write($xwi);

#CASE 5
    } elsif ( ! $existrecordid && ! $existurlid ) {
        #ASSIGN NEW RECORDID done with auto_increment in SQL
	$self->{databasehandle}->prepare(
             qq{INSERT INTO recordurl SET urlid=?, md5=?, lastchecked=NOW();})->execute($urlid,$md5);
	$self->{databasehandle}->prepare(qq{UNLOCK TABLES;})->execute(); #UNLOCK recordurl
	my ($recordid) = $self->{databasehandle}->selectrow_array(
              qq{SELECT recordid FROM recordurl WHERE urlid=$urlid;});
	$xwi->recordid($recordid);
	$self->{'loghandle'}->say("DataBase::Write $recordid case 5: $existrecordid; $existurlid; $oldmd5;");
	Combine::MySQLhdb::Write($xwi);
    }

#Should not happen
    else {
	$self->{'loghandle'}->say("DataBase::ERR $existrecordid; $existurlid; $oldmd5;");
	print "ERR DataBase impossible case\n";
    }

    $xwi->nofollow("false"); # was set to true by delete...???
    # my ($follow,$add,$replaced) = &COMB::Policy::url_accept($url,@urls);??? 
}

sub newLinks {
    my ($self) = @_;
    my $xwi = $self->{'xwi'};
    return undef unless ref $xwi;
    my $recordid = $xwi->recordid; #SANITY CHECK?
    $self->{databasehandle}->prepare(
       qq{INSERT IGNORE INTO newlinks SELECT urlid,netlocid FROM links WHERE recordid=?;})->execute($recordid);
}

sub newRedirect {
    my ($self) = @_;
    my $xwi = $self->{'xwi'};
    return undef unless ref $xwi;
    use Combine::selurl;
    my ($u, $netlocid, $urlid, $urlstr);
#    my $tl=$xwi->location; my $tb=$xwi->base; print "NL: $tl, $tb\n";
    if ( $u =  Combine::selurl->new_abs($xwi->location, $xwi->base) ) {
	$urlstr = $u->normalise();
#	print "NL: $urlstr\n";
	my $lsth = $self->{databasehandle}->prepare(qq{SELECT netlocid,urlid FROM urls WHERE urlstr=?;});
	$lsth->execute($urlstr);
	($netlocid,$urlid) = $lsth->fetchrow_array;
	if ( !defined($urlid) ) {
	    my $netlocstr = $u->authority;
	    my $path_query = $u->path_query;
#	    print "NL: $netlocstr, $path_query\n";
	    $self->{databasehandle}->prepare(qq{INSERT IGNORE INTO netlocs SET netlocstr=?;})->execute($netlocstr);
	    ($netlocid) =  $self->{databasehandle}->selectrow_array(qq{SELECT netlocid FROM netlocs WHERE netlocstr='$netlocstr';});
	    $self->{databasehandle}->prepare(qq{INSERT IGNORE INTO urls SET urlstr=?, netlocid=?, path=?;})->execute($urlstr,$netlocid,$path_query);
	    $lsth->execute($urlstr);
	    ($netlocid,$urlid) = $lsth->fetchrow_array;
	}
#	print "NL INS: $urlid,$netlocid\n";
#test if undefined
	$self->{databasehandle}->prepare(
	     qq{INSERT IGNORE INTO newlinks SET urlid=?, netlocid=?;})->execute($urlid,$netlocid);
    }
}

1;
