package ZConf::backends::file;

use File::Path;
use File::BaseDir qw/xdg_config_home/;
use Chooser;
use warnings;
use strict;
use ZML;
use Sys::Hostname;
use base 'Error::Helper';

=head1 NAME

ZConf::backends::file - A configuration system allowing for either file or LDAP backed storage.

=head1 VERSION

Version 2.1.0

=cut

our $VERSION = '2.1.0';

=head1 SYNOPSIS

    use ZConf;

	#creates a new instance
    my $zconf = ZConf->new();
    ...

=head1 METHODS

=head2 new

	my $zconf=ZConf->(\%args);

This initiates the ZConf object. If it can't be initiated, a value of undef
is returned. The hash can contain various initization options.

When it is run for the first time, it creates a filesystem only config file.

=head3 args hash

=head4 self

This is the copy of the ZConf object intiating it.

=head4 zconf

This is the variables found in the ~/.config/zconf.zml.

    my $zconfbe=ZConf::backends::file->new(\%args);
    if($zconfbe->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

#create it...
sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#The thing that will be returned.
	#conf holds configs
	#args holds the arguements passed to new as well as runtime parameters
	#set contains what set is in use for any loaded config
	#zconf contains the parsed contents of zconf.zml
	#user is space reserved for what ever the user of this package may wish to
	#     use it for... if they ever find the need to or etc... reserved for
	#     the prevention of poeple shoving stuff into $self->{} where ever
	#     they please... probally some one still will... but this is intented
	#     to help minimize it...
	#error this is undef if, otherwise it is a integer for the error in question
	#errorString this is a string describing the error
	#meta holds meta variable information
	my $self = {conf=>{}, args=>\%args, set=>{}, zconf=>{}, user=>{}, error=>undef,
				errorString=>"", meta=>{}, comment=>{}, module=>__PACKAGE__,
				revision=>{}, locked=>{}, autoupdateGlobal=>1, autoupdate=>{}};
	bless $self;
	$self->{module}=~s/\:\:/\-/g;

	#####################################
	#real in the stuff from the arguments
	#make sure we have a ZConf object
	if (!defined( $args{self} )) {
		$self->{error}=47;
		$self->{errorString}='No ZConf object passed';
		$self->warn;
		return $self;
	}
	if ( ref($args{self}) ne 'ZConf' ) {
		$self->{error}=47;
		$self->{errorString}='No ZConf object passed. ref returned "'.ref( $args{self} ).'"';
		$self->warn;
		return $self;
	}
	$self->{self}=$args{self};
	if (!defined( $args{zconf} )) {
		$self->{error}=48;
		$self->{errorString}='No zconf.zml var hash passed';
		$self->warn;
		return $self;		
	}
	if ( ref($args{zconf}) ne 'HASH' ) {
		$self->{error}=48;
		$self->{errorString}='No zconf.zml var hash passed. ref returned "'.ref( $args{zconf} ).'"';
		$self->warn;
		return $self;
	}
	$self->{zconf}=$args{zconf};
	#####################################

	if (!defined( $self->{zconf}{'file/base'} )) {
		$self->{args}{base}=xdg_config_home()."/zconf/";
	}else {
		$self->{args}{base}=$self->{zconf}{'file/base'};
	}

	#do something if the base directory does not exist
	if(! -d $self->{args}{base}){
		#if the base diretory can not be created, exit
		if(!mkdir($self->{args}{base})){
			$self->{error}=46;
			$self->{errorString}="'".$self->{args}{base}."' does not exist and could not be created.\n";
			$self->warn;
			return $self;
		}
	}

	#get what the file only arg should be
	#this is a Perl boolean value
	if(!defined($self->{zconf}{fileonly})){
		$self->{zconf}->{args}{fileonly}="0";
	}else{
		$self->{args}{fileonly}=$self->{zconf}{fileonly};
	}

	return $self;
}

=head2 configExists

This method methods exactly the same as configExists, but
for the file backend.

No config name checking is done to verify if it is a legit name or not
as that is done in configExists. The same is true for calling errorblank.

    $zconfbe->configExistsFile("foo/bar");
	if($zconf->error){
		warn('error: '.$zconf->{error}.":".$zconf->errorString);
	}

=cut

#checks if a file config exists 
sub configExists{
	my ($self, $config) = @_;

	$self->errorblank;

	#makes the path if it does not exist
	if(!-d $self->{args}{base}."/".$config){
		return 0;
	}

	return 1;
}

=head2 createConfig

This methods just like createConfig, but is for the file backend.
This is not really meant for external use. The config name passed
is not checked to see if it is legit or not.

    $zconf->createConfigFile("foo/bar");
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#creates a new config file as well as the default set
sub createConfig{
	my ($self, $config) = @_;

	$self->errorblank;

	#makes the path if it does not exist
	if(!mkpath($self->{args}{base}."/".$config)){
		$self->{error}=16;
		$self->{errorString}="'".$self->{args}{base}."/".$config."' creation failed.";
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 delConfig

This removes a config. Any sub configs will need to removes first. If any are
present, this method will error.

    #removes 'foo/bar'
    $zconf->delConfig('foo/bar');
    if(defined($zconf->error)){
		warn('error: '.$zconf->error."\n".$zconf->errorString);
    }

=cut

sub delConfig{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorlank;

	#return if this can't be completed
	if (defined($self->{error})) {
		return undef;		
	}

	my @subs=$self->getSubConfigs($config);
	#return if there are any sub configs
	if (defined($subs[0])) {
		$self->{error}='33';
		$self->{errorString}='Could not remove the config as it has sub configs';
		$self->warn;
		return undef;
	}

	#makes sure it exists before continuing
	#This will also make sure the config exists.
	my $returned = $self->configExists($config);
	if (defined($self->error)){
		$self->{error}='12';
		$self->{errorString}='The config, "'.$config.'", does not exist';
		$self->warn;
		return undef;
	}

	my @sets=$self->getAvailableSets($config);
	if (defined($self->error)) {
		$self->warnString('getAvailableSetsFile set an error');
		return undef;
	}

	#goes through and removes each set before deleting
	my $setsInt='0';#used for intering through @sets
	while (defined($sets[$setsInt])) {
		#removes a set
		$self->delSet($config, $sets[$setsInt]);
		if ($self->{error}) {
			$self->warnString('delSetFileset an error');
			return undef;
		}
		$setsInt++;
	}

	#the path to the config
	my $configpath=$self->{args}{base}."/".$config;

	if (!rmdir($configpath)) {
		$self->{error}=29;
		$self->{errorString}='"'.$configpath.'" could not be unlinked.';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 delSet

This deletes a specified set, for the filesystem backend.

Two arguements are required. The first one is the name of the config and the and
the second is the name of the set.

    $zconf->delSetFile("foo/bar", "someset");
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub delSet{
	my $self=$_[0];
	my $config=$_[1];
	my $set=$_[2];

	$self->errorblank;

	#return if no set is given
	if (!defined($set)){
		$self->{error}=24;
		$self->{errorString}='$set not defined';
		$self->warn;
		return undef;
	}

	#return if no config is given
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;
	}

	#the path to the config
	my $configpath=$self->{args}{base}."/".$config;

	#returns with an error if it could not be set
	if (!-d $configpath) {
		$self->{error}=14;
		$self->{errorString}='"'.$config.'" is not a directory or does not exist';
		$self->warn;
		return undef;
	}
	
	#the path to the set
	my $fullpath=$configpath."/".$set.'.set';

	if (!unlink($fullpath)) {
		$self->{error}=29;
		$self->{errorString}='"'.$fullpath.'" could not be unlinked.';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 getAvailableSets

This is exactly the same as getAvailableSets, but for the file back end.
For the most part it is not intended to be called directly.

	my @sets = $zconf->getAvailableSets("foo/bar");
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#this gets a set for a given file backed config
sub getAvailableSets{
	my ($self, $config) = @_;

	$self->errorblank;

	#returns 0 if the config does not exist
	if (!-d $self->{args}{base}."/".$config) {
		$self->{error}=14;
		$self->{errorString}="'".$self->{args}{base}."/".$config."' does not exist.";
		$self->warn;
		return undef;
	}

	if (!opendir(CONFIGDIR, $self->{args}{base}."/".$config)) {
		$self->{error}=15;
		$self->{errorString}="'".$self->{args}{base}."/".$config."' open failed.";
		$self->warn;
		return undef;
	}
	my @direntries=readdir(CONFIGDIR);
	closedir(CONFIGDIR);

	#remove hidden files and directory recursors from @direntries
	@direntries=grep(!/^\./, @direntries);
	@direntries=grep(!/^\.\.$/, @direntries);
	@direntries=grep(!/^\.$/, @direntries);

	my @sets=();

	#go though the list and return only files
	my $int=0;
	while (defined($direntries[$int])) {
		if (
			( -f $self->{args}{base}."/".$config."/".$direntries[$int] ) &&
			( $direntries[$int] =~ /\.set$/ )
			){
			$direntries[$int] =~ s/\.set$//g;
			push(@sets, $direntries[$int]);
		}
		$int++;
	}

	return @sets;
}

=head2 getConfigRevision

This fetches the revision for the speified config using
the file backend.

A return of undef means that the config has no sets created for it
yet or it has not been read yet by 2.0.0 or newer.

    my $revision=$zconf->getConfigRevision('some/config');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }
    if(!defined($revision)){
        print "This config has had no sets added since being created or is from a old version of ZConf.\n";
    }

=cut

sub getConfigRevision{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='No config specified';
		$self->warn;
		return undef;
	}

	#checks to make sure the config does exist
	if(!$self->configExists($config)){
		$self->{error}=12;
		$self->{errorString}="'".$config."' does not exist.";
		$self->warn;
		return undef;			
	}

	#
	my $revisionfile=$self->{args}{base}."/".$config."/.revision";

	my $revision;
	if ( -f $revisionfile) {
		if(!open("THEREVISION", '<', $revisionfile)){
			$self->warnString("'".$revisionfile."' open failed");
		}
		$revision=join('', <THEREVISION>);
		close(THEREVISION);
	}

	return $revision;
}

=head2 getSubConfigs

This gets any sub configs for a config. "" can be used to get a list of configs
under the root.

One arguement is accepted and that is the config to look under.

    #lets assume 'foo/bar' exists, this would return
    my @subConfigs=$zconf->getSubConfigs("foo");
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

#gets the configs under a config
sub getSubConfigs{
	my ($self, $config)= @_;

	$self->errorblank;

	#returns 0 if the config does not exist
	if(!-d $self->{args}{base}."/".$config){
		$self->{error}=14;
		$self->{errorString}="'".$self->{args}{base}."/".$config."' does not exist.";
		$self->warn;
		return undef;
	}

	if(!opendir(CONFIGDIR, $self->{args}{base}."/".$config)){
		$self->{error}=15;
		$self->{errorString}="'".$self->{args}{base}."/".$config."' open failed.";
		$self->warn;
		return undef;
	}
	my @direntries=readdir(CONFIGDIR);
	closedir(CONFIGDIR);

	#remove, ""^."" , ""."" , and "".."" from @direntries
	@direntries=grep(!/^\./, @direntries);
	@direntries=grep(!/^\.\.$/, @direntries);
	@direntries=grep(!/^\.$/, @direntries);

	my @sets=();

	#go though the list and return only files
	my $int=0;
	while(defined($direntries[$int])){
		if(-d $self->{args}{base}."/".$config."/".$direntries[$int]){
			push(@sets, $direntries[$int]);
		};
		$int++;
	}

	return @sets;
}

=head2 isConfigLocked

This checks if a config is locked or not for the file backend.

One arguement is required and it is the name of the config.

The returned value is a boolean value.

    my $locked=$zconf->isConfigLockedFile('some/config');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }
    if($locked){
        print "The config is locked\n";
    }

=cut

sub isConfigLocked{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='No config specified';
		$self->warn;
		return undef;
	}

	#makes sure it exists
	my $exists=$self->configExists($config);
    if ($self->{error}) {
		$self->warnString('configExists errored');
		return undef;
	}
	if (!$exists) {
		$self->{error}=12;
		$self->{errorString}='The config, "'.$config.'", does not exist';
		$self->warn;
		return undef;
	}

	#checks if it is
	my $lockfile=$self->{args}{base}."/".$config."/.lock";
	if (-e $lockfile) {
		#it is locked
		return 1;
	}

	return 0;
}

=head2 read

readFile methods just like read, but is mainly intended for internal use
only. This reads the config from the file backend.

=head3 hash args

=head4 config

The config to load.

=head4 override

This specifies if override should be ran not.

If this is not specified, it defaults to 1, true.

=head4 set

The set for that config to load.

    $zconf->readFile({config=>"foo/bar"})
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#read a config from a file
sub read{
	my $self=$_[0];
	my %args=%{$_[1]};

	$self->errorblank;

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#return false if the config is not set
	if (!defined($args{set})){
		$self->{error}=24;
		$self->{errorString}='$arg{set} not defined';
		$self->warn;
		return undef;
	}

	#default to overriding
	if (!defined($args{override})) {
		$args{override}=1;
	}

	my $fullpath=$self->{args}{base}."/".$args{config}."/".$args{set}.'.set';

	#return false if the full path does not exist
	if (!-f $fullpath){
		return 0;
	}

	#retun from a this if a comma is found in it
	if( $args{config} =~ /,/){
		return 0;
	}

	if(!open("thefile", $fullpath)){
		return 0;
	};
	my @rawdataA=<thefile>;
	close("thefile");
	
	my $rawdata=join('', @rawdataA);
	
	#gets it
	my $zml=ZML->new;

	#parses it
	$zml->parse($rawdata);
	if ($zml->{error}) {
		$self->{error}=28;
		$self->{errorString}='$zml->parse errored. $zml->{error}="'.$zml->{error}.'" '.
		                     '$zml->{errorString}="'.$zml->{errorString}.'"';
		$self->warn;
		return undef;
	}

	#at this point we save the stuff in it
	$self->{self}->{conf}{$args{config}}=\%{$zml->{var}};
	$self->{self}->{meta}{$args{config}}=\%{$zml->{meta}};
	$self->{self}->{comment}{$args{config}}=\%{$zml->{comment}};

	#sets the set that was read		
	$self->{self}->{set}{$args{config}}=$args{set};

	#updates the revision
	my $revisionfile=$self->{args}{base}."/".$args{config}."/.revision";
	#opens the file and returns if it can not
	#creates it if necesary
	if ( -f $revisionfile) {
		if(!open("THEREVISION", '<', $revisionfile)){
			$self->warnString(':43: '."'".$revisionfile."' open failed");
			$self->{revision}{$args{config}}=time.' '.hostname.' '.rand();
		}
		$self->{revision}{$args{config}}=join('', <THEREVISION>);
		close(THEREVISION);
	}else {
		$self->{revision}{$args{config}}=time.' '.hostname.' '.rand();
		#tag it with a revision if it does not have any...
		if(!open("THEREVISION", '>', $revisionfile)){
			$self->{error}=43;
			$self->{errorString}="'".$revisionfile."' open failed";
			$self->warn;
			return undef;
		}
		print THEREVISION $self->{revision}{$args{config}};
		close("THEREVISION");
	}

	#checks if it is locked or not and save it
	my $locked=$self->isConfigLocked($args{config});
	if ($locked) {
		$self->{locked}{$args{config}}=1;
	}

	#run the overrides if requested tox
	if ($args{override}) {
		#runs the override if not locked
		if (!$locked) {
			$self->{self}->override({ config=>$args{config} });
		}
	}

	return $self->{self}->{revision}{$args{config}};
}

=head2 readChooser

This methods just like readChooser, but methods on the file backend
and only really intended for internal use.

	my $chooser = $zconf->readChooserFile("foo/bar");
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#this gets the chooser for a the config... for the file backend
sub readChooser{
	my ($self, $config)= @_;

	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->{self}->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}
		
	#checks to make sure the config does exist
	if(!$self->configExists($config)){
		$self->{error}=12;
		$self->{errorString}="'".$config."' does not exist.";
		$self->warn;
		return undef;			
	}

	#the path to the file
	my $chooser=$self->{args}{base}."/".$config."/.chooser";

	#if the chooser does not exist, turn true, but blank 
	if(!-f $chooser){
		return "";
	}

	#open the file and get the string error on not being able to open it 
	if(!open("READCHOOSER", $chooser)){
		$self->{error}=15;
		$self->{errorString}="'".$self->{args}{base}."/".$config."/.chooser' read failed.";
		$self->warn;
		return undef;
	}
	my $chooserstring=<READCHOOSER>;
	close("READCHOOSER");		

	return ($chooserstring);
}

=head2 setExists

This checks if the specified set exists.

Two arguements are required. The first arguement is the name of the config.
The second arguement is the name of the set. If no set is specified, the default
set is used. This is done by calling 'defaultSetExists'.

    my $return=$zconf->setExists("foo/bar", "fubar");
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }else{
        if($return){
            print "It exists.\n";
        }
    }

=cut

sub setExists{
	my ($self, $config, $set)= @_;

	#blank any errors
	$self->errorblank;

	#this will get what set to use if it is not specified
	if (!defined($set)) {
		return $self->defaultSetExists($config);
		if ($self->error) {
			$self->warnString('No set specified and defaultSetExists errored');
			return undef;
		}
	}

	#We don't do any config name checking here or even if it exists as getAvailableSets
	#will do that.

	my @sets = $self->getAvailableSets($config);
	if (defined($self->{error})) {
		return undef;
	}


	my $setsInt=0;#used for intering through $sets
	#go through @sets and check for matches
	while (defined($sets[$setsInt])) {
		#return true if the current one matches
		if ($sets[$setsInt] eq $set) {
			return 1;
		}

		$setsInt++;
	}

	#if we get here, it means it was not found in the loop
	return undef;
}

=head2 setLockConfig

This unlocks or logs a config for the file backend.

Two arguements are taken. The first is a
the config name, required, and the second is
if it should be locked or unlocked

    #lock 'some/config'
    $zconf->setLockConfigFile('some/config', 1);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

    #unlock 'some/config'
    $zconf->setLockConfigFile('some/config', 0);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

    #unlock 'some/config'
    $zconf->setLockConfigFile('some/config');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub setLockConfig{
	my $self=$_[0];
	my $config=$_[1];
	my $lock=$_[2];

	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='No config specified';
		$self->warn;
		return undef;
	}

	#makes sure it exists
	my $exists=$self->configExists($config);
    if ($self->{error}) {
		$self->warnString('configExists errored');
		return undef;
	}
	if (!$exists) {
		$self->{error}=12;
		$self->{errorString}='The config, "'.$config.'", does not exist';
		$self->warn;
		return undef;
	}

	#locks the config
	my $lockfile=$self->{args}{base}."/".$config."/.lock";

	#handles locking it
	if ($lock) {
		if(!open("THELOCK", '>', $lockfile)){
			$self->{error}=44;
			$self->{errorString}="'".$lockfile."' open failed";
			$self->warn;
			return undef;
        }
        print THELOCK time."\n".hostname;
        close("THELOCK");
		#return now that it is locked
		return 1;
	}

	#handles unlocking it
	if (-e $lockfile) { #don't error if it is already unlocked
		if (!unlink($lockfile)) {
			$self->{error}=44;
			$self->{errorString}='"'.$lockfile.'" could not be unlinked.';
			$self->warn;
			return undef;
		}
	}

	return 1;
}

=head2 writeChooser

This method is a internal method and largely meant to only be called
writeChooser, which it methods the same as. It works on the file backend.

	$zconf->writeChooserFile("foo/bar", $chooserString)
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

sub writeChooser{
	my ($self, $config, $chooserstring)= @_;

	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;
	}

	#checks if it is locked or not
	my $locked=$self->isConfigLocked($config);
	if ($self->{error}) {
		$self->warnString('isconfigLockedFile errored');
		return undef;
	}
	if ($locked) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	#return false if the config is not set
	if (!defined($chooserstring)){
		$self->{error}=40;
		$self->{errorString}='\$chooserstring not defined';
		$self->warn;
		return undef;			
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->{self}->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	my $chooser=$self->{args}{base}."/".$config."/.chooser";

	#open the file and get the string error on not being able to open it 
	if(!open("WRITECHOOSER", ">", $chooser)){
		$self->{error}=15;
		$self->{errorString}="'".$self->{args}{base}."/".$config."/.chooser' open failed.";
		$self->warn;
	}
	print WRITECHOOSER $chooserstring;
	close("WRITECHOOSER");		

	return (1);
}

=head2 writeSetFromHash

This takes a hash and writes it to a config for the file backend.
It takes two arguements, both of which are hashes.

The first hash contains

The second hash is the hash to be written to the config.

=head2 args hash

=head3 config

The config to write it to.

This is required.

=head3 set

This is the set name to use.

If not defined, the one will be choosen.

=head3 revision

This is the revision string to use.

This is primarily meant for internal usage and is suggested
that you don't touch this unless you really know what you
are doing.

    $zconf->writeSetFromHashFile({config=>"foo/bar"}, \%hash);
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#write out a config from a hash to the file backend
sub writeSetFromHash{
	my $self = $_[0];
	my %args=%{$_[1]};
	my %hash = %{$_[2]};

	$self->errorblank;

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->{self}->configNameCheck($args{config});
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#sets the set to default if it is not defined
	if (!defined($args{set})){
		$args{set}=$self->{self}->chooseSet($args{set});
	}else{
		if($self->{self}->setNameLegit($args{set})){
			$self->{args}{default}=$args{set};
		}else{
			$self->{error}=27;
			$self->{errorString}="'".$args{set}."' is not a legit set name.";
			$self->warn;
			return undef
		}
	}
		
	#checks to make sure the config does exist
	if(!$self->configExists($args{config})){
		$self->{error}=12;
		$self->{errorString}="'".$args{config}."' does not exist.";
		$self->warn;
		return undef;			
	}

	#checks if it is locked or not
	my $locked=$self->isConfigLocked($args{config});
	if ($self->error) {
		$self->warnString('isconfigLockedFile errored');
		return undef;
	}
	if ($locked) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$args{config}.'" is locked';
		$self->warn;
		return undef;
	}
		
	#the path to the file
	my $fullpath=$self->{args}{base}."/".$args{config}."/".$args{set};

	#update the revision
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}
	
	#used for building it
	my $zml=ZML->new;

	my $hashkeysInt=0;#used for intering through the list of hash keys
	#builds the ZML object
	my @hashkeys=keys(%hash);
	while(defined($hashkeys[$hashkeysInt])){
		#attempts to add the variable
		if ($hashkeys[$hashkeysInt] =~ /^\#/) {
			#process a meta variable
			if ($hashkeys[$hashkeysInt] =~ /^\#\!/) {
				my @metakeys=keys(%{$hash{ $hashkeys[$hashkeysInt] }});
				my $metaInt=0;
				while (defined( $metakeys[$metaInt] )) {
					$zml->addMeta($hashkeys[$hashkeysInt], $metakeys[$metaInt], $hash{ $hashkeys[$hashkeysInt] }{ $metakeys[$metaInt] } );
					#checks to verify there was no error
					#this is not a fatal error... skips it if it is not legit
					if(defined($zml->error)){
						$self->warnString('23: $zml->addMeta() returned '.
							 $zml->{error}.", '".$zml->{errorString}."'. Skipping variable '".
							 $hashkeys[$hashkeysInt]."' in '".$args{config}."'.");
					}
					$metaInt++;
				}
			}
			#process a meta variable
			if ($hashkeys[$hashkeysInt] =~ /^\#\#/) {
				my @metakeys=keys(%{$hash{ $hashkeys[$hashkeysInt] }});
				my $metaInt=0;
				while (defined( $metakeys[$metaInt] )) {
					$zml->addComment($hashkeys[$hashkeysInt], $metakeys[$metaInt], $hash{ $hashkeys[$hashkeysInt] }{ $metakeys[$metaInt] } );
					#checks to verify there was no error
					#this is not a fatal error... skips it if it is not legit
					if(defined($zml->{error})){
						$self->warnString('23: $zml->addComment() returned '.
							 $zml->{error}.", '".$zml->{errorString}."'. Skipping variable '".
							 $hashkeys[$hashkeysInt]."' in '".$args{config}."'.");
					}
					$metaInt++;
				}
			}
		}else {
			$zml->addVar($hashkeys[$hashkeysInt], $hash{$hashkeys[$hashkeysInt]});
			#checks to verify there was no error
			#this is not a fatal error... skips it if it is not legit
			if(defined($zml->error)){
				$self->warnString('23: $zml->addVar returned '.
					 $zml->{error}.", '".$zml->{errorString}."'. Skipping variable '".
					 $hashkeys[$hashkeysInt]."' in '".$args{config}."'.");
			}
		}
			
		$hashkeysInt++;
	}

	#writes the config out
	$args{zml}=$zml;
	$self->writeSetFromZML(\%args);
	if ($self->error) {
			$self->warnString('writeSetFromZML failed');
			return undef		
	}

	return $args{revision};
}

=head2 writeSetFromLoadedConfig

This method writes a loaded config to a to a set,
for the file backend.

One arguement is required.

=head2 args hash

=head3 config

The config to write it to.

This is required.

=head3 set

This is the set name to use.

If not defined, the one will be choosen.

=head3 revision

This is the revision string to use.

This is primarily meant for internal usage and is suggested
that you don't touch this unless you really know what you
are doing.

    $zconf->writeSetFromLoadedConfigFile({config=>"foo/bar"});
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#write a set out
sub writeSetFromLoadedConfig{
	my $self = $_[0];
	my %args=%{$_[1]};

	$self->errorblank;

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	if(! $self->{self}->isConfigLoaded( $args{config} ) ){
		$self->{error}=25;
		$self->{errorString}="Config '".$args{config}."' is not loaded";
		$self->warn;
		return undef;
	}

	#checks if it is locked or not
	my $locked=$self->isConfigLocked($args{config});
	if ($self->{error}) {
		$self->warnString('isconfigLockedFile errored');
		return undef;
	}
	if ($locked) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$args{config}.'" is locked';
		$self->warn;
		return undef;
	}

	#sets the set to default if it is not defined
	if (!defined($args{set})){
		$args{set}=$self->{set}{$args{config}};
	}else{
		if($self->{self}->setNameLegit($args{set})){
			$self->{args}{default}=$args{set};
		}else{
			$self->{error}=27;
			$self->{errorString}="'".$args{set}."' is not a legit set name.";
			$self->warn;
			return undef
		}
	}

	#the path to the file
	my $fullpath=$self->{args}{base}."/".$args{config}."/".$args{set};

	#update the revision
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}

	my $zml=$self->{self}->dumpToZML($args{config});
	if ($self->{self}->error) {
			$self->{error}=14;
			$self->{errorString}='Failed to dump to ZML. error='.$self->{self}->error.' errorString='.$self->{self}->errorString;
			$self->warn;
			return undef		
	}
	$args{zml}=$zml;

	#writes out the config
	$self->writeSetFromZML(\%args);
	if ($self->error) {
			$self->warnString('writeSetFromZML failed');
			return undef		
	}

	return $args{revision};
}

=head2 writeSetFromZML

This writes a config set from a ZML object.

One arguement is required.

=head2 args hash

=head3 config

The config to write it to.

This is required.

=head3 set

This is the set name to use.

If not defined, the one will be choosen.

=head3 revision

This is the revision string to use.

This is primarily meant for internal usage and is suggested
that you don't touch this unless you really know what you
are doing.

    $zconf->writeSetFromZML({config=>"foo/bar", zml=>$zml});
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#write a set out
sub writeSetFromZML{
	my $self = $_[0];
	my %args=%{$_[1]};

	$self->errorblank;

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure ZML is passed
	if (!defined( $args{zml} )) {
		$self->{error}=20;
		$self->{errorString}='$args{zml} is not defined';
		$self->warn;
		return undef;
	}
	if ( ref($args{zml}) ne "ZML" ) {
		$self->{error}=20;
		$self->{errorString}='$args{zml} is not a ZML';
		$self->warn;
		return undef;
	}

	#checks if it is locked or not
	my $locked=$self->isConfigLocked($args{config});
	if ($self->error) {
		$self->warnString('isconfigLockedFile errored');
		return undef;
	}
	if ($locked) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$args{config}.'" is locked';
		$self->warn;
		return undef;
	}

	#sets the set to default if it is not defined
	if (!defined($args{set})){
		$args{set}=$self->{set}{$args{config}};
	}else{
		if($self->{self}->setNameLegit($args{set})){
			$self->{args}{default}=$args{set};
		}else{
			$self->{error}=27;
			$self->{errorString}="'".$args{set}."' is not a legit set name.";
			$self->warn;
			return undef
		}
	}

	#the path to the file
	my $fullpath=$self->{args}{base}."/".$args{config}."/".$args{set}.'.set';

	#update the revision
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}

	#small hack as this was copied writeSetFromLoadedConfig
	my $zml=$args{zml};

	#opens the file and returns if it can not
	#creates it if necesary
	if(!open("THEFILE", '>', $fullpath)){
		$self->{error}=15;
		$self->{errorString}="'".$self->{args}{base}."/".$args{config}."/.chooser' open failed.";
		$self->warn;
		return undef;
	}
	print THEFILE $zml->string();
	close("THEFILE");

	#updates the revision
	my $revisionfile=$self->{args}{base}."/".$args{config}."/.revision";
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}
	
	#opens the file and returns if it can not
	#creates it if necesary
	if(!open("THEREVISION", '>', $revisionfile)){
		$self->{error}=43;
		$self->{errorString}="'".$revisionfile."' open failed";
		$self->warn;
		return undef;
	}
	print THEREVISION $args{revision};
	close("THEREVISION");
	#save the revision info
	$self->{self}->{revision}{$args{config}}=$args{revision};

	return $args{revision};
}

=head1 ERROR HANDLING/CODES

This module uses L<Error::Helper> for error handling. Below are the
error codes returned by the error method.

=head2 1

config name contains ,

=head2 2

config name contains /.

=head2 3

config name contains //

=head2 4

config name contains ../

=head2 5

config name contains /..

=head2 6

config name contains ^./

=head2 7

config name ends in /

=head2 8

config name starts with /

=head2 9

could not sync to file

=head2 10

config name contains a \n

=head2 11

ZML dump failed.

=head2 12

config does not exist

=head2 14

file/dir does not exist

=head2 15

file/dir open failed

=head2 16

file/dir creation failed

=head2 17

file write failed

=head2 18

No variable name specified.

=head2 19

config key starts with a ' '

=head2 20

ZML object not specified.

=head2 21

set not found for config

=head2 22

LDAPmakepathSimple failed

=head2 23

skilling variable as it is not a legit name

=head2 24

set is not defined

=head2 25

Config is undefined.

=head2 26

Config not loaded.

=head2 27

Set name is not a legit name.

=head2 28

ZML->parse error.

=head2 29

Could not unlink the unlink the set.

=head2 30

The sets exist for the specified config.

=head2 31

Did not find a matching set.

=head2 32

Unable to choose a set.

=head2 33

Unable to remove the config as it has sub configs.

=head2 34

LDAP connection error

=head2 35

Can't use system mode and file together.

=head2 36

Could not create '/var/db/zconf'. This is a permanent error.

=head2 37

Could not create '/var/db/zconf/<sys name>'. This is a permanent error.

=head2 38

Sys name matched /\//.

=head2 39

Sys name matched /\./.

=head2 40

No chooser string specified.

=head2 41

No comment specified.

=head2 42

No meta specified.

=head2 43

Failed to open the revision file for the set.

=head2 44

Failed to open or unlink lock file.

=head2 45

Config is locked.

=head2 46

The base does not exist or could not be created.

=head2 47

No ZConf object passed.

=head2 48

No zconf.zml var hash passed.

=head1 ERROR CHECKING

This can be done by checking $zconf->{error} to see if it is defined. If it is defined,
The number it contains is the corresponding error code. A description of the error can also
be found in $zconf->{errorString}, which is set to "" when there is no error.

=head1 zconf.zml

The default is 'xdf_config_home/zconf.zml', which is generally '~/.config/zconf.zml'. See perldoc
ZML for more information on the file format. The keys are listed below.

=head2 keys

=head3 backend

This should be set to 'file' to use this backend.

=head3 fileonly

This is a boolean value. If it is set to 1, only the file backend is used.

This will override 'backend'.

Basically the same as using the backend to 'file'.

=head3 file/base

This is the base directory to use for storing the configs in.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf>

=item * Subversion Repository

L<http://eesdp.org/svnweb/index.cgi/pubsvn/browse/Perl/ZConf>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2011 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of ZConf
