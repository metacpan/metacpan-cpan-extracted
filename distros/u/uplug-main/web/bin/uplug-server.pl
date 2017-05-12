#!/usr/bin/perl
#---------------------------------------------------------------------------
# server.pl
#
#---------------------------------------------------------------------------
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
#---------------------------------------------------------------------------

require 5.002;
use strict;

use FindBin qw($Bin);
use POSIX qw(uname);
use CGI qw/:standard/;
use Fcntl qw(:DEFAULT :flock);
use vars qw($UPLUGHOME $UPLUGDATA $UPLUGCWB $UPLUG $LogFile);

######################################################################

BEGIN{
    setpgrp(0,0);              # become leader of the process group

    $UPLUGDATA = '/corpora/OPUS/UPLUG';
    $UPLUGCWB  = $UPLUGDATA.'/cwb/';
    $LogFile   = "$UPLUGDATA/.process/.serverlog";
    $UPLUGHOME = "$Bin/../..";
    $UPLUG=$UPLUGHOME.'/uplug';

    $ENV{UPLUGHOME}=$UPLUGHOME;
    $ENV{UPLUGDATA}=$UPLUGDATA;
    #$SIG{TERM} = \&interrupt;
    #$SIG{INT} = \&interrupt;
}

######################################################################

use lib $UPLUGHOME;
use Uplug::Web::Process;
use Uplug::Web::Corpus;
use Uplug::Web::User;
use Uplug::Web::Process::Lock;


my $HOST=(uname)[1];
my $ME=(getpwuid($>))[0];

our $OUTPUT;       # file to store stdout
our $LOCK;         # lock file for $OUTPUT
our $TempDir;      # temporary directory for running processes

######################################################################

END{
    if (-d $TempDir){
	chdir '/';
	system "rm -fr $TempDir";
    }
    local $SIG{HUP}='IGNORE';  # ignore HANGUP signal for right now
    kill ('HUP',-$$);          # kill child processes before you die
}

######################################################################

# don't start if already running or if not alone!!

if (&nmbr_running('uplug-server.pl')){&my_die("already running!");}
my @u=`w | sed '1,2d' | cut -f1 -d ' ' | sort | uniq | grep -v '$ME'`;
if (@u){&my_die("I'm not alone!");}


######################################################################


my @data=();
my $pid=fork();                              # create a new child process


#----------------------------------------------------------------------------
# this is the parent:
#   * check if I'm alone anbd die if not
#----------------------------------------------------------------------------

if ($pid){
    local $SIG{HUP}= sub { &my_die("$$: got hangup signal!") };
    local $SIG{CHLD}= sub { if (wait() eq $pid){&my_die("server stopped!");} };
    while (1){
	my @u=`w | sed '1,2d' | cut -f1 -d ' ' | sort | uniq | grep -v '$ME'`;
	if (@u){&my_die("I'm not alone!");}
	sleep(2);
    }
}



#----------------------------------------------------------------------------
# this is the child process (the actual server):
#     * get the next process
#     * run it and check the return value
#     * move process to 'failed' if there were any problems!
#----------------------------------------------------------------------------

else{

    local $SIG{HUP} = \&interrupt;

    &my_log("server started!");
    while (not -e "$UPLUGDATA/STOPSERVER"){
	@data=&Uplug::Web::Process::GetNextProcess('todo');
	if (not @data){@data=&Uplug::Web::Process::GetNextProcess('failed');}

	if (@data){
	    $data[4]='('.$HOST.')';
	    &Uplug::Web::Process::AddProcess('queued',@data);
	    if ($data[2] eq '$bash'){
		&RunCommand(@data);
#		if (not &RunCommand(@data)){
#		    &my_log("problems! -> Re-schedule process!");
#		    &Uplug::Web::Process::MoveJobTo($data[0],    # user-name
#						    $data[1],    # process-ID
#						    'failed');   # failed-stack
#		}
	    }
	    else{
		&RunUplug(@data);
#		if (not &RunUplug(@data)){
#		    &my_log("problems! -> Re-schedule process!");
#		    &Uplug::Web::Process::MoveJobTo($data[0],    # user-name
#						    $data[1],    # process-ID
#						    'failed');   # failed-stack
#		}
	    }
	    @data=();
	}
	sleep(1);
    }              # found STOPSERVER: stop the server!
    &my_die("server stopped!");
}



# end of the main part .....
######################################################################




#--------------------------
# check if the server is running already on this client

sub nmbr_running {
    my $prog = $_[0];
    $prog =~ s/^(.*\/)*//;
#    my $who=`whoami`;
#    chomp $who;
#     my $nmbr=grep(/\s$who\s/,`/usr/sbin/lsof | grep 'cwd' | grep '^$prog '`);
    my @nmbr=`ps ax | grep '$prog' | grep -v 'grep '`;

    return $#nmbr;
}



sub interrupt{ 
    if(@data){
	&Uplug::Web::Process::MoveJobTo($data[0],$data[1],'todo');
    }
    &my_die("server interrupted!");
}





sub my_log{
    my $message=shift;
    if (-e $LogFile){open F,">>$LogFile";}
    else{open F,">$LogFile";}
#    while (not flock(F,2)){sleep(1);}
    if (nflock($LogFile,5)){
	chomp($message);
	my $time=localtime();
	print F "[$HOST:$time] ",$message,"\n";
    }
    nunflock($LogFile);
    close F;
}

sub my_die{
    my $message=shift;
    if (-e $LogFile){open F,">>$LogFile";}
    else{open F,">$LogFile";}
#    while (not flock(F,2)){sleep(1);}
    if (nflock($LogFile,5)){
	chomp($message);
	my $time=localtime();
	print F "[$HOST:$time] ",$message,"\n";
    }
    nunflock($LogFile);
    close F;
    exit();
}


##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################
#
# RunCommand: run arbitrary command
#             (possibly dangerous ...)

sub RunCommand{

    my ($user,$process,$type,$command)=@_;

    if (not $user){return 0;}
    if (not $process){return 0;}

    &my_log("running job $process for user $user");

    if (not &Uplug::Web::Process::MoveJobTo($user,$process,'working')){
	&my_log("Cannot find job $process for user $user!");
	return 0;
    }

#    my $UserDir=
#	&Uplug::Web::Corpus::GetCorpusDir($user); # the user's home directory
#    my $ConfigDir=$UserDir.'/'.$process;          # the process home dir
#    my $LogFile="$ConfigDir/uplugweb.log";
    #----------------------------------------------------------
#    if (my $sig=system "$command"){
#    if (my $sig=system "$command >/tmp/uplugweb$$.out 2>/tmp/uplugweb$$.err"){
#    if (my $sig=system "$command >$LogFile 2>>$LogFile"){
    if (my $sig=system "$command >/dev/null 2>/dev/null"){
	&Uplug::Web::Process::MoveJobTo($user,$process,'failed');
	&my_log("Got exit-signal $? from $command!");
	return 0;
    }
    #----------------------------------------------------------

    if (not &Uplug::Web::Process::MoveJob($user,$process,'working','done')){
	&my_log("Couldn't move job $process of user $user to done-stack!");
	return 0;
    }
    return 1;
}


##########################################################################


sub RunUplug{

    my ($user,$process,$corpus,$config)=@_;

    if (not $user){return 0;}
    if (not $process){return 0;}

    &my_log("running job $process for user $user");

    my $TempDir='/tmp/uplugweb'.$process;        # run the program in a tmp-dir
    my $UserDir=
	&Uplug::Web::Corpus::GetCorpusDir($user); # the user's home directory
    my $ConfigDir=$UserDir.'/'.$process;          # the process home dir

    if (not -e "$ConfigDir/$config"){
	&my_log("Cannot find config file: $config!");
	return 0;
    }

    if (not &Uplug::Web::Process::MoveJobTo($user,$process,'working')){
	&my_log("Cannot find job $process for user $user!");
	return 0;
    }

    system "cp -R $ConfigDir $TempDir";
    if (-e "$UserDir/ini"){system "cp -R $UserDir/ini $TempDir/";}
    if (-e "$UserDir/lang"){system "cp -R $UserDir/lang $TempDir/";}
    chdir $TempDir;

#    print "do pre-processing ...\n";
    &PreProcessing($user,$config);
    #----------------------------------------------------------
    my $LogFile="$ConfigDir/uplugweb.log";
    if (my $sig=system "$UPLUG $config >uplugweb.out 2>$LogFile"){
	&Uplug::Web::Process::MoveJobTo($user,$process,'failed');
	&my_log("Got exit-signal $? from $UPLUG!");
	return 0;
    }
    #----------------------------------------------------------
#    print "do post-processing ...\n";
    &PostProcessing($user,$corpus,$config);

    if (not &Uplug::Web::Process::MoveJob($user,$process,'working','done')){
	&my_log("Couldn't move job $process of user $user to done-stack!");
	return 0;
    }
    chdir '/';
    system "rm -fr $TempDir";
#    system "rm -fr $ConfigDir";
    return 1;
}



#-----------------------------------------
# lock output file that will be overwritten by this modules STDOUT
# (other processes should not be allowed to do anything with it
#  as long as the process is not finished!)


sub PreProcessing{
    my $user=shift;
    my $config=shift;

    my %data;
    &Uplug::Web::Process::UplugSystemIni(\%data,$user,$config);
    my $stdout;
    if (ref($data{module}) eq 'HASH'){    # is there a STDOUT stream?
	$stdout=$data{module}{stdout};
    }
    if (not $stdout){return;}             # no! --> return

    # yes:
    #   if there's no file defined for stdout-output
    #   and if there is a file for an input stream with the same name
    #   --> this will be the location of stdout! (check PostProcessing)

    if (ref($data{output}) eq 'HASH'){
	if (ref($data{output}{$stdout}) eq 'HASH'){
	    if (not defined $data{output}{$stdout}{file}){
		if (ref($data{input}) eq 'HASH'){
		    if (ref($data{input}{$stdout}) eq 'HASH'){
			if (defined $data{input}{$stdout}{file}){
			    $OUTPUT=$data{input}{$stdout}{file};
			}
		    }
		}
	    }
	}
    }

##
## forget about locking for the time being, because
##   - flock does not work on nfs
##   - nflock has problems with write-permission in this setting
##
#    if (-e $OUTPUT){
#	&nflock($OUTPUT,30) or &my_die("can't lock $OUTPUT: $!");
##	$LOCK=$OUTPUT.'.lock';
##	sysopen(LCK,$LOCK,O_RDONLY|O_CREAT) or &my_die("can't open $LOCK: $!");
##	while (not flock(LCK,LOCK_EX)){sleep 1;}
#    }

}




sub PostProcessing{
    my $user=shift;
    my $corpus=shift;
    my $config=shift;

    my %data;
    &Uplug::Web::Process::UplugSystemIni(\%data,$user,$config);
    my $stdout;
    if (ref($data{module}) eq 'HASH'){
	$stdout=$data{module}{stdout};
    }
    if (ref($data{output}) eq 'HASH'){
	foreach my $s (keys %{$data{output}}){
	    #---------------------
	    # copy input stream attributes to output streams
	    # for data streams with identical names!!
	    # (if the attributes are not set already)
	    # - sets e.g. the file attribute for STDOUT streams
	    # - copies STDOUT to the new file attribute (dangerous!!)
	    #    ----> overwrites input files!!!!!

	    if (ref($data{input}{$s}) eq 'HASH'){
		foreach $a (keys %{$data{input}{$s}}){
		    if (not defined $data{output}{$s}{$a}){
			if (($s eq $stdout) and ($a eq 'file')){
			    if ($data{input}{$s}{file}=~/\.gz$/){
				system "gzip uplugweb.out";
				system "cp uplugweb.out.gz $data{input}{$s}{file}";
			    }
			    else{
				system "cp uplugweb.out $data{input}{$s}{file}";
			    }
			}
			$data{output}{$s}{$a}=$data{input}{$s}{$a};
		    }
		}
	    }

	    #-----------------------
	    # register output streams for which the 'corpus' attribute is set!

	    if ((ref($data{output}{$s}) eq 'HASH') and 
		(defined $data{output}{$s}{corpus})){
		if (not defined $data{output}{$s}{status}){
		    $config=~s/^.*[\\\/]([^\\\/]+)$/$1/;      # set status attr
		    $data{output}{$s}{status}=$config;        # (=config name)
		}
		&RegisterCorpus($user,$corpus,$data{output}{$s});
	    }
	}
    }
    if ($config=~/align\/word\/(..\-..|basic|advanced|giza)$/){
	my $dir=&Uplug::Web::Corpus::GetCorpusDir($user);
	if ((-d "$dir/data/runtime") and (-d "data/runtime")){
	    `cp data/runtime/*.dbm* $dir/data/runtime/`;
	}
    }

##
## locking is not used right now ....
##
#    if (-e $OUTPUT){
#	&nunflock($OUTPUT) or &my_die("can't unlock $OUTPUT: $!");
#    }
}

sub RegisterCorpus{
    my $user=shift;
    my $corpus=shift;
    my $config=shift;

    if (defined $$config{file}){
	&Uplug::Web::User::SendFile($user,"UplugWeb result",$$config{file});
    }
    my $name=$$config{corpus};
    delete $$config{'stream name'};
    delete $$config{'write_mode'};
    &Uplug::Web::Corpus::ChangeCorpusInfo($user,$corpus,$name,$config);
}






#sub interrupt{
#    print STDERR "client interrupted!\n";
#    &UplugProcess::MoveJobTo($user,$process,'failed');
#    exit;
#}

