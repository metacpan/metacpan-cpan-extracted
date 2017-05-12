# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package Uplug::Web::Corpus;

use strict;
use IO::File;
use POSIX qw(tmpnam);
use File::Copy;
use ExtUtils::Command;
use File::Basename;

use Uplug::Web;
use Uplug::Web::Config;
use Uplug::Web::Process;
use Uplug::Web::Process::Stack;
use Uplug::Web::User;
use Uplug::Config;



our $INDEXER=$ENV{UPLUGHOME}.'/web/bin/uplug-indexer.pl';
our $RECODE=$ENV{RECODE};

our $CorpusDir=$ENV{UPLUGDATA};

my $MAXFLOCKWAIT=3;

my $CorpusIndexFile=$ENV{UPLUGDATA}.'/.index';
my $CorpusIndex=Uplug::Web::Process::Stack->new($CorpusIndexFile);

sub GetIndexedCorpora{
    my $data=shift;
    if (ref($data) ne 'HASH'){return $CorpusIndex->read();}
    my @corpora=$CorpusIndex->read();
    foreach (@corpora){
	my ($user,$name,$lang,$alg,$enc)=split(/\:/,$_);
	$$data{$user}{$name}{$lang}{encoding}=$enc;
	if ($alg){
	    push (@{$$data{$user}{$name}{$lang}{align}},$alg);
	}
    }
    return keys %{$data};
}


sub IndexCorpus{
    my $owner=shift;
    my $corpus=shift;

    my $CorpusDir=&GetCorpusDir($owner,$corpus);
    my $CWBREG="$ENV{UPLUGCWB}/reg/$owner/$corpus";
    my $CWBDAT="$ENV{UPLUGCWB}/dat/$owner/$corpus";

    if (not -d $ENV{UPLUGCWB}){mkdir $ENV{UPLUGCWB};}
    if (not -d "$ENV{UPLUGCWB}/reg"){mkdir "$ENV{UPLUGCWB}/reg";}
    if (not -d "$ENV{UPLUGCWB}/dat"){mkdir "$ENV{UPLUGCWB}/dat";}
    if (not -d "$ENV{UPLUGCWB}/reg/$owner"){mkdir "$ENV{UPLUGCWB}/reg/$owner";}
    if (not -d "$ENV{UPLUGCWB}/dat/$owner"){mkdir "$ENV{UPLUGCWB}/dat/$owner";}

    if (not -d "$ENV{UPLUGCWB}/reg/$owner/$corpus"){
	mkdir "$ENV{UPLUGCWB}/reg/$owner/$corpus";
	system "chmod g+w $ENV{UPLUGCWB}/reg/$owner/$corpus";
    }
    if (not -d "$ENV{UPLUGCWB}/dat/$owner/$corpus"){
	mkdir "$ENV{UPLUGCWB}/dat/$owner/$corpus";
	system "chmod g+w $ENV{UPLUGCWB}/dat/$owner/$corpus";
    }

    my $process=time().'_'.$$;
    my $command="$INDEXER $CWBREG $CWBDAT $CorpusDir";
    &Uplug::Web::Process::AddProcess('todo',$owner,$process,'$bash',$command);
#    print "$command<hr>";

}



sub AddCorpusToIndex{
    my $user=shift;
    my $corpus=shift;
    my $srcenc=shift;
    my $trgenc=shift;
    my $alg=shift;
    my $info=&GetCorpusInfo($user,$corpus);
    if ($$info{format}=~/align/){
	my ($src,$trg)=split(/\-/,$$info{language});
	&AddCorpusToIndex($user,
			  &GetCorpusName($$info{corpus},$src),
			  $srcenc,$trgenc,
			  $trg);
	&AddCorpusToIndex($user,
			  &GetCorpusName($$info{corpus},$trg),
			  $trgenc,$srcenc,
			  $src);
    }
    else{
	$CorpusIndex->remove($user,$$info{corpus},$$info{language},$alg);
	$CorpusIndex->push($user,$$info{corpus},$$info{language},$alg,$srcenc);
    }
}




sub GetCorpusDataFileOld{
    my $user=shift;
    return "$CorpusDir/$user/ini/uplugUserStreams.ini";
}

sub GetCorpusDataFile{
    my $user=shift;
    my $corpus=shift;
    return "$CorpusDir/$user/$corpus/.documents";
}


sub GetCorpusDir{
    my $user=shift;
    my $corpus=shift;
    my $lang=shift;
    if (not defined $user){return $CorpusDir;}
    if (not defined $corpus){return "$CorpusDir/$user";}
    if (not -d "$CorpusDir/$user/$corpus"){mkdir "$CorpusDir/$user/$corpus";}
    if (not defined $lang){return "$CorpusDir/$user/$corpus";}
    if (not -d "$CorpusDir/$user/$corpus/$lang"){
	mkdir "$CorpusDir/$user/$corpus/$lang";
    }
    return "$CorpusDir/$user/$corpus/$lang";
}

sub GetRecycleDir{
    my $user=shift;
    my $corpus=shift;
    my $lang=shift;

    if (not -d "$CorpusDir/.recycled"){
	mkdir "$CorpusDir/.recycled",0755;
    }
    if (not defined $user){return "$CorpusDir/.recycled";}
    if (not -d "$CorpusDir/.recycled/$user"){
	mkdir "$CorpusDir/.recycled/$user",0755;
    }
    if (not defined $corpus){return "$CorpusDir/.recycled/$user";}
    if (not -d "$CorpusDir/.recycled/$user/$corpus"){
	mkdir "$CorpusDir/.recycled/$user/$corpus",0755;
    }
    if (defined $lang){
	if (not -d "$CorpusDir/.recycled/$user/$corpus/$lang"){
	    mkdir "$CorpusDir/.recycled/$user/$corpus/$lang",0755;
	}
	return "$CorpusDir/.recycled/$user/$corpus/$lang";
    }
    return "$CorpusDir/.recycled/$user/$corpus";
}

sub GetCorpusStreams{
    my $user=shift;
    my %para=@_;
    my %CorpusData=();
    &GetCorpusData(\%CorpusData,$user);
    my @streams=();
    foreach my $c (keys %CorpusData){
	my $match=1;
	foreach (keys %para){
	    if ($CorpusData{$c}{$_}!~/$para{$_}/){$match=0;last;}
	}
	if ($match){push (@streams,$c);}
    }
    return @streams;
}


#------------------------------------------------------------------
# MatchingDocuments
#    find all documents within a corpus with matching attributes
#    (%para=attribute-value pairs to be matched)

sub MatchingDocuments{
    my $user=shift;
    my $corpus=shift;
    my %para=@_;

    my $docs=&CorpusDocuments($user,$corpus);
    my @ok=();
    foreach my $c (keys %{$docs}){
	my $match=1;
	foreach (keys %para){
	    if ($$docs{$c}{$_}!~/$para{$_}/){$match=0;last;}
	}
	if ($match){push (@ok,$c);}
    }
    return @ok;
}

#------------------------------------------------------------------


sub GetCorpusData{

    my $CorpusData=shift;
    my $user=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user);
    if (ref($CorpusData) ne 'HASH'){return 0;}
    if (not -e $CorpusInfoFile){return 0;}
    &LoadIniData($CorpusData,$CorpusInfoFile);
    return keys %{$CorpusData};
}



sub RestoreDocument{
    my ($owner,$corpus,$doc)=@_;

    $CorpusDir.='/.recycled';                            # set recycle-dir
    my $ConfigFile=&CorporaConfigFile($owner);
    my $corpora=Uplug::Web::Config->new($ConfigFile);    # user corpora
    my $ConfigFile=&DocumentConfigFile($owner,$corpus);  # corpus configfile
    my $documents=Uplug::Web::Config->new($ConfigFile);  # corpus documents
    my $config=$documents->read();
    $CorpusDir=$ENV{UPLUGDATA};                          # restore data-dir

    if (defined $$config{$doc}){
	my $lang=$$config{$doc}{language};
	my $file=$$config{$doc}{file};
	my $RecycleDir=&GetRecycleDir($owner,$corpus,$lang);
	my $RemovedFile=$RecycleDir.'/'.&basename($file);
	if (-e $RemovedFile){
	    move ($RemovedFile,$file);
	}

	my $ConfigFile=&DocumentConfigFile($owner,$corpus);  # add the restored
	my $ResDoc=Uplug::Web::Config->new($ConfigFile);     # document to the
	my $ResConfig=$ResDoc->read();                       # corpus config
	$$ResConfig{$doc}=$$config{$doc};                    # file
	$ResDoc->write($ResConfig);                          # write configfile

	delete $$config{$doc};                               # delete doc-data
	$documents->write($config);                          # write configfile

	if (not keys %{$config}){               # if no more removed documents
	    my $corpconf=$corpora->read();      # in this corpus: read the 
	    delete $$corpconf{$corpus};         # config file and delete the
	    $corpora->write($corpconf);         # corpus and save
	}

    }
    $documents->close();
}


sub RemoveDocument{
    my ($owner,$corpus,$doc)=@_;

    my $ConfigFile=&DocumentConfigFile($owner,$corpus);
    my $documents=Uplug::Web::Config->new($ConfigFile);
    my $config=$documents->read();

    if (defined $$config{$doc}){
	my $lang=$$config{$doc}{language};
	my $file=$$config{$doc}{file};
#	my $corpus=$$config{$doc}{corpus};
	my $RecycleDir=&GetRecycleDir($owner,$corpus,$lang);
	if (-e $file){
	    move ($file,"$RecycleDir/");
	}

	$CorpusDir.='/.recycled';                            # set recycle-dir
	my $ConfigFile=&DocumentConfigFile($owner,$corpus);  # config-filename
	my $RemDoc=Uplug::Web::Config->new($ConfigFile);     # open config-file
	my $RemConfig=$RemDoc->read();                       # read it
	$$RemConfig{$doc}=$$config{$doc};                    # save doc-data
	$RemDoc->write($RemConfig);                          # write configfile

	my $ConfigFile=&CorporaConfigFile($owner);           # config-filename
	my $RemCorpora=Uplug::Web::Config->new($ConfigFile); # open config-file
	my $RemConfig=$RemCorpora->read();                   # read it
	$$RemConfig{$corpus}=1;                              # set corpus
	$RemCorpora->write($RemConfig);                      # write configfile

	delete $$config{$doc};                               # delete doc-data
	$documents->write($config);                          # write configfile
	$CorpusDir=$ENV{UPLUGDATA};                          # restore data-dir
    }
    $documents->close();
}

sub RemoveCorpus{
    my ($owner,$corpus)=@_;

    my $ConfigFile=&CorporaConfigFile($owner);
    my $corpora=Uplug::Web::Config->new($ConfigFile);
    my $config=$corpora->read();

    if (defined $$config{$corpus}){
	my $RecycleDir=&GetRecycleDir($owner);
	my $DataDir=&GetCorpusDir($owner,$corpus);

	if (-d "$RecycleDir/$corpus"){                  # quite a hack ...
	    system "rm -fr $RecycleDir/$corpus";        # and maybe dangerous!!
	}
	if (-e $DataDir){
	    system "mv $DataDir $RecycleDir/";          # requires UNIX!!
	}

	$CorpusDir.='/.recycled';                            # set recycle-dir
	my $ConfigFile=&CorporaConfigFile($owner);           # config-filename
	my $RemCorpora=Uplug::Web::Config->new($ConfigFile); # open config-file
	my $RemConfig=$RemCorpora->read();                   # read it
	$$RemConfig{$corpus}=$$config{$corpus};              # set corpus data
	$RemCorpora->write($RemConfig);                      # write configfile

	delete $$config{$corpus};                            # delete corpus
	$corpora->write($config);                            # from configfile
	$CorpusDir=$ENV{UPLUGDATA};                          # restore data-dir
    }
    $corpora->close();

    my $ConfigFile=&CorporaConfigFile('pub');          # delete from public
    my $corpora=Uplug::Web::Config->new($ConfigFile);  # corpora list
    my $config=$corpora->read();
    if (defined $$config{"../$owner/$corpus"}){
	delete $$config{"../$owner/$corpus"};
	$corpora->write($config);
    }
    $corpora->close();

}



sub RemoveCorpusOld{
    my ($user,$owner,$name)=@_;

    if ($owner ne $user){print "Cannot remove corpus $name!";return 0;}

    my $CorpusInfoFile=&GetCorpusDataFile($owner,$name);
    my %CorpusData;
    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (defined $CorpusData{$name}){
	my $lang=$CorpusData{$name}{language};
	my $file=$CorpusData{$name}{file};
	my $corpus=$CorpusData{$name}{corpus};
	my $RecycleDir=&GetRecycleDir($owner,$corpus);
	if (-e $file){
	    move ($file,"$RecycleDir/");
	}
	delete $CorpusData{$name};
	&WriteIniFile($CorpusInfoFile,\%CorpusData);
    }

}


sub GetCorpusName{
    my ($name,$lang)=@_;
    return "$name ($lang)";
}

sub SplitCorpusName{
    my ($name)=@_;
    if ($name=~/^(.*)\s\((.*)\)/){
	return ($1,$2);
    }
    return undef;
}


sub GetCorpusInfo{
    my $user=shift;
    my $corpus=shift;
    my $doc=shift;

    my $documents=&CorpusDocuments($user,$corpus);
    if (ref($$documents{$doc}) eq 'HASH'){return $$documents{$doc};}
    return {};
}

sub GetCorpusInfoOld{
    my $user=shift;
    my $CorpusName=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user,$CorpusName);
    my %CorpusData;
    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (ref($CorpusData{$CorpusName}) eq 'HASH'){
	return %{$CorpusData{$CorpusName}}
    }
    return undef;
}



#sub ReadCorpus{
#    my $user=shift;
#    my $name=shift;
#    my $start=shift;
#    my $nr=shift;
#
#    my %stream=&Uplug::Web::Corpus::GetCorpusInfo($user,$name);
#    if (not keys %stream){
#	print "Cannot find corpus data for $name\n";
#    }
#    my $corpus=new Uplug::IO::Any(\%stream);
#    if (not $corpus->open('read',\%stream)){
#	print "Cannot open $name\n";
#    }
#    my $html;
#    my @rows;
#    my $data=Uplug::Data::DOM->new();
#    my $count;
#    my $skipped;
#    while ($corpus->read($data)){
#	if ($skipped<$start){$skipped++;next;}
#	$count++;
#	if ($count>$nr){last;}
#	push(@rows,$data->toHtml());
#    }
#    $corpus->close();
#    return @rows;
#}
#


sub SendCorpus{
    my $to=shift;
    my $owner=shift;
    my $corpus=shift;
    my $doc=shift;

    my $data=&GetCorpusInfo($owner,$corpus,$doc);

    if (defined $$data{file}){
	&Uplug::Web::User::SendFile($to,'UplugWeb - '.$corpus,$$data{file});
	return 1;
    }
    return 0;
}

sub CorpusIsPrivate{
    my $owner=shift;
    my $corpus=shift;
    my $CorpusConfig=Uplug::Web::Config->new("$CorpusDir/$owner/.corpora");
    my $corpora=$CorpusConfig->read();
    return $$CorpusConfig{$corpus};
}

sub CorpusIsPublic{
    return not &CorpusIsPrivate(@_);
}


sub CorporaConfigFile{
    my $owner=shift;
    if (not -d "$CorpusDir/$owner"){mkdir "$CorpusDir/$owner";}
    return "$CorpusDir/$owner/.corpora";
}

sub DocumentConfigFile{
    my $owner=shift;
    my $corpus=shift;
    if (not -d "$CorpusDir/$owner/$corpus"){mkdir "$CorpusDir/$owner/$corpus";}
    return "$CorpusDir/$owner/$corpus/.documents";
}

sub Corpora{
    my $owner=shift;
    my $ConfigFile=&CorporaConfigFile($owner);
    my $CorpusConfig=Uplug::Web::Config->new($ConfigFile);
    return $CorpusConfig->read();
}


sub CorpusDocuments{
    my $owner=shift;
    my $corpus=shift;
    my $ConfigFile=&DocumentConfigFile($owner,$corpus);
    my $documents=Uplug::Web::Config->new($ConfigFile);
    return $documents->read();
}



sub AddCorpus{
    my $user=shift;
    my $corpus=shift;
    my $priv=shift;            # =1 --> private corpus (don't store in public)

    if ((defined $corpus) and ($corpus!~/^[a-zA-Z\_0-9]{1,10}$/)){
	return (0,"Corpus name $corpus is not valid!");
    }

    my $UserCorpusFile=&CorporaConfigFile($user);
    # "$CorpusDir/$user/.corpora";
    my $UserCorpora=Uplug::Web::Config->new($UserCorpusFile);
    my $corpora=$UserCorpora->read();

    if (defined $$corpora{$corpus}){
	return (0,"A corpus with the name '$corpus' exists already!");
    }

    $$corpora{$corpus}=1;
    if (not $UserCorpora->write($corpora)){
	return (0,"Could not add corpus info to $UserCorpusFile!");
    }
    $UserCorpora->close();

    if (not mkdir "$CorpusDir/$user/$corpus"){
	return (0,"Could not create corpus directory for '$corpus'!");
    }

    if (not $priv){
	my $PublicCorpusFile=&CorporaConfigFile('pub');
	my $PublicCorpora=Uplug::Web::Config->new($PublicCorpusFile);
	my $public=$PublicCorpora->read();
	$$public{"../$user/$corpus"}=1;
	if (not $PublicCorpora->write($public)){
	    return (0,"Could not add corpus info to $PublicCorpusFile!");
	}
	$PublicCorpora->close();
    }
    return (1,"Corpus '$corpus' sucessfully added!");
}

sub AddDocument{
    my ($user,$corpus,$name,$fh,$lang,$enc)=@_;

    if ((defined $name) and ($name!~/^[a-zA-Z\_\.0-9]{1,15}$/)){
	return (0,"Invalid document name '$name'! (use: [a-zA-Z_.]{1,15})");
    }

    my $documents=&CorpusDocuments($user,$corpus);
    my $CorpusName=&GetCorpusName($corpus,$lang);
    if (defined $$documents{$CorpusName}){
	return (0,"A document with the name '$CorpusName' exists already!");
    }

    my $dir="$CorpusDir/$user/$corpus/$lang";
    if (not -e $dir){
	if (not mkdir $dir){
	    return (0,"Could not create $lang language directory for '$corpus'!");
	}
    }
    my $file="$dir/$name";
#    my $tmpfile=&GetTempFileName;
#    open OUT, '>:encoding(utf8)',$tmpfile;
    open OUT, '>:encoding(utf8)',$file;
    binmode($fh);require Encode;

    #----------------------------------
    # read data and save them in tempfile
    #
    while (<$fh>){
	eval {$_=&Encode::decode($enc,$_,1); };
	if ($@){print $@;return undef;}
	print OUT $_;
    }
    close OUT;

#    move($tmpfile,$file);                # create the corpus file
#    my $lckfile="$file.lock";
#    open F,">$lckfile";close F;                  # create a lock file
    chmod 0664,$file;
#    chmod 0664,$lckfile;
#    unlink $tmpfile;

    &AddCorpusInfo($user,$corpus,$name,$lang,'text',
		   {file => $file,format => 'text'});
    return (1,"Document $fh successfully added to corpus $corpus!");
}


sub AddCorpusInfo{

    my $owner=shift;
    my $corpus=shift;
    my $name=shift;
    my $lang=shift;
    my $status=shift;
    my $para=shift;

    my $CorpusFile="$CorpusDir/$owner/$corpus/.documents";
    my $UserCorpora=Uplug::Web::Config->new($CorpusFile);
    my $corpora=$UserCorpora->read();

    my $CorpusName=&GetCorpusName($name,$lang);
    %{$$corpora{$CorpusName}}=('language' => $lang,
			       'corpus' => $name,
			       'status' => $status);
    if (ref($para) eq 'HASH'){
	foreach (keys %{$para}){
	    $$corpora{$CorpusName}{$_}=$$para{$_};
	}
    }
    if (not $UserCorpora->write($corpora)){
	return (0,"Could not add corpus info to $CorpusFile!");
    }
    $UserCorpora->close();
}


sub ChangeCorpusInfo{

    my $owner=shift;
    my $corpus=shift;
    my $doc=shift;    # either EXISTING doc-name or doc-base-name without lang!
    my $para=shift;

    my $CorpusFile="$CorpusDir/$owner/$corpus/.documents";
    my $UserCorpora=Uplug::Web::Config->new($CorpusFile);
    my $corpora=$UserCorpora->read();

    if (not defined $$corpora{$doc}){
	if ((ref($para) eq 'HASH') and (defined $$para{language})){
	    $doc=&GetCorpusName($doc,$$para{language});
	}
    }
    if (ref($para) eq 'HASH'){
	foreach (keys %{$para}){
	    $$corpora{$doc}{$_}=$$para{$_};
	}
    }
    if (not $UserCorpora->write($corpora)){
	return (0,"Could not add corpus info to $CorpusFile!");
    }
    $UserCorpora->close();
}

sub ChangeCorpusStatus{
    my $owner=shift;
    my $corpus=shift;
    my $doc=shift;
    my $status=shift;

    my $CorpusFile="$CorpusDir/$owner/$corpus/.documents";
    my $UserCorpora=Uplug::Web::Config->new($CorpusFile);
    my $corpora=$UserCorpora->read();

    if (not defined $$corpora{$doc}){return undef;}
    my $old=$$corpora{$doc}{status};
    $$corpora{$doc}{status}=$status;
    $UserCorpora->close();
    return $old;
}

sub ChangeCorpusInfoOld{

    my $user=shift;
    my $CorpusName=shift;
    my $para=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user,$CorpusName);
    my %CorpusData;
    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (not defined $CorpusData{$CorpusName}){
	if ((ref($para) eq 'HASH') and (defined $$para{language})){
	    $CorpusName=&GetCorpusName($CorpusName,$$para{language});
	}
    }
    if (ref($para) eq 'HASH'){
	foreach (keys %{$para}){
	    $CorpusData{$CorpusName}{$_}=$$para{$_};
	}
    }
    &WriteIniFile($CorpusInfoFile,\%CorpusData);
}

sub ChangeCorpusStatusOld{

    my $user=shift;
    my $CorpusName=shift;
    my $status=shift;

    my $CorpusInfoFile=&GetCorpusDataFile($user,$CorpusName);
    my %CorpusData;
    &LoadIniData(\%CorpusData,$CorpusInfoFile);
    if (not defined $CorpusData{$CorpusName}){return undef;}
    my $old=$CorpusData{$CorpusName}{status};
    $CorpusData{$CorpusName}{status}=$status;
    &WriteIniFile($CorpusInfoFile,\%CorpusData);
    return $old;
}


sub GetTempFileName{
    my $fh;
    my $file;
    do {$file=tmpnam();}
    until ($fh=IO::File->new($file,O_RDWR|O_CREAT|O_EXCL));
    $fh->close;
    return $file;
}



sub ChangeWordLinks{
    my $file=shift;
    my $links=shift;
    my $params=shift;

    my $sentLink=$params->{seg};
    print "change links is not implemented yet!<br>";
    print join '+',@{$links};
    print '<hr>';


#    if (not -e $file){return 0;}
#    if ($file=~/\.gz$/){open F,"$GUNZIP < $file |";}
#    else{open F,"< $file";}
#    my $sec=0;
#    while (not flock(F,2)){
#	$sec++;sleep(1);
#	if ($sec>$MAXFLOCKWAIT){
#	    close F;
#	    return 0;
#	}
#    }
#    local $/='<link ';
#    my @align=<F>;
#    print join '<hr>',@align;
#
#    close F;

}
