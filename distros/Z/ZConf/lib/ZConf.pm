package ZConf;

use File::Path;
use File::BaseDir qw/xdg_config_home/;
use Chooser;
use warnings;
use strict;
use ZML;
use Sys::Hostname;
use Module::List qw(list_modules);
use base 'Error::Helper';

=head1 NAME

ZConf - A configuration system allowing for either file or LDAP backed storage.

=head1 VERSION

Version 6.1.0

=cut

our $VERSION = '6.1.0';

=head1 SYNOPSIS

    use ZConf;

	#creates a new instance
    my $zconf = ZConf->new;
    
    my @configs

=head1 METHODS

=head2 new

	my $zconf=ZConf->(\%args);

This initiates the ZConf object. If it can't be initiated, $zconf->error
will be set. This error should be assumed to be permanent.

When it is run for the first time, it creates a filesystem only config file.

=head3 args hash

=head4 file

The default is xdf_config_home."/zconf.zml", which is generally '~/.config/zconf.zml'.

This is incompatible with the sys option.

    my $zconf=ZConf->new();
    if($zconf->error){
		warn('error: '.$zconf->{error}."\n".$zconf->errorString);
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
	my $self = {
		conf=>{},
		args=>{%args},
		set=>{},
		zconf=>{},
		user=>{},
		perror=>undef,
		error=>undef,
		errorString=>"",
		meta=>{},
		comment=>{}, 
		module=>__PACKAGE__,
		revision=>{},
		locked=>{},
		autoupdateGlobal=>1,
		autoupdate=>{},
	};
	bless $self;

	#set the config file if it is not already set
	if(!defined($self->{args}{file})){
		$self->{args}{file}=xdg_config_home()."/zconf.zml";
		#Make the config file if it does not exist.
		#We don't create it if it is manually specified as we assume
		#that the caller manually specified it for some reason.
		if(!-f $self->{args}{file}){
			if(open("CREATECONFIG", '>', $self->{args}{file})){
				print CREATECONFIG "fileonly=1\nreadfallthrough=1\n";
				close("CREATECONFIG");
			}else{
				print "zconf new error: '".$self->{args}{file}."' could not be opened.\n";
				return undef;
			}
		}
	}

	my $zconfzmlstring="";#holds the contents of zconf.zml
	#returns undef if it can't read zconf.zml
	if(open("READZCONFZML", $self->{args}{file})){
		$zconfzmlstring=join("", <READZCONFZML>);
		my $tempstring;
		close("READZCONFZML");
	}else{
		print "zconf new error: Could not open'".$self->{args}{file}."\n";
		return undef;
	}

	#tries to parse the zconf.zml
	my $zml=ZML->new();
	$zml->parse($zconfzmlstring);
	if($zml->{error}){
		$self->{error}=28;
		$self->{errorString}="ZML\-\>parse error, '".$zml->{error}."', '".$zml->{errorString}."'";
		$self->warn;
		return $self;
	}
	$self->{zconf}=$zml->{var};

	#saves this for passing on to the backend
	$self->{args}{zconf}=$self->{zconf};

	#if defaultChooser is defined, use it to find what the default should be
	if(defined($self->{zconf}{defaultChooser})){
		#runs choose if it is defined
		my ($success, $choosen)=choose($self->{zconf}{defaultChooser});
		if($success){
			#check if the choosen has a legit name
			#if it does not, set it to default
			if(setNameLegit($choosen)){
				$self->{args}{default}=$choosen;
			}else{
				$self->{args}{default}="default";
			}
		}else{
			$self->{args}{default}="default";
		}
	}else{
		if(defined($self->{zconf}{default})){
			$self->{args}{default}=$self->{zconf}{default};
		}else{
			$self->{args}{default}="default";
		}
	}

	#get what the file only arg should be
	#this is a Perl boolean value
	if(!defined($self->{zconf}{fileonly})){
		$self->{zconf}->{args}{fileonly}="0";
	}else{
		$self->{args}{fileonly}=$self->{zconf}{fileonly};
	}

	if($self->{args}{fileonly} eq "0"){
		#gets what the backend should be using backendChooser
		#if not defined, check for backend and if that is not
		#defined, just use the file backend
		if(defined($self->{zconf}{backendChooser})){
			my ($success, $choosen)=choose($self->{zconf}{backendChooser});
			if($success){
				$self->{args}{backend}=$choosen;
			}else{
				if(defined{$self->{zconf}{backend}}){
					$self->{args}{backend}=$self->{zconf}{backend};
				}else{
					$self->{args}{backend}="file";
				}
			}
		}else{
			if(defined($self->{zconf}{backend})){
				$self->{args}{backend}=$self->{zconf}{backend};
			}else{
				$self->{args}{backend}="file";
			}
		}
	}else{
		$self->{args}{backend}="file";
	}
		
	#make sure the backend is legit
	my @modules=keys( %{list_modules("ZConf::backends::",{list_modules=>1})} );
	my $int=0;
	my $backendLegit=0;
	while ($modules[$int]) {
		my $beTest=$modules[$int];
		$beTest=~s/ZConf\:\:backends\:\://g;
		if ($beTest eq $self->{args}{backend}) {
			$backendLegit=1;
		}

		$int++;
	}

	if(!$backendLegit){
		$self->{error}=14;
		$self->{errorString}="The backend '".$self->{args}{backend}."' is not a recognized backend";
		$self->warn;
		return $self
	}

	#saves a copy of self to the backend
	$self->{args}{self}=$self;

	#inits the main backend
	my $backend=$self->initBackend($self->{args}{backend});
	my $error=0;
	if ($self->error || (!defined( $backend ))) {
		if ( $self->error ) {
			$self->warn;
		}else {
			$self->warn;
		}
		$self->warnString('Using file backend');
		$error=1;
	}else {
		if ($backend->error) {
			$self->warnString('Backend errored using. Using file backend');
			$error=1;
		}else {
			$self->{be}=$backend;
		}
	}

	#init the file backend
	if ( $self->{args}{backend} ne 'file' ) {
		$backend=$self->initBackend('file');
		if (
			$self->error ||
			$backend->error
			) {
			$self->{error}='11';
			$self->{errorStirng}='Failed to intiate file backend';
			$self->warn;
			return $self;
		}
		if (defined( $self->{be} )) {
			$self->{fbe}=$backend;
		}else {
			$self->{be}=$backend;
		}
	}
	

	return $self;
}

=head2 chooseSet

This chooses what set should be used using the associated chooser
string for the config in question.

This method does fail safely. If a improper configuration is returned by
chooser string, it uses the value the default set.

It takes one arguement, which is the configuration it is for.

If the chooser errors, is blank, or is just a newline, the default is
returned.

	my $set=$zconf->chooseSet("foo/bar");
    if($zconf->error){
		warn('error: '.$zconf->{error}."\n".$zconf->errorString);
    }

=cut

#the overarching method for getting available sets
sub chooseSet{
	my ($self, $config) = @_;

	$self->errorblank;

	my ($error, $errorString)=$self->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	my $chooserstring=$self->readChooser($config);

	#makes sure it is not blank
	if ($chooserstring eq '') {
		return $self->{args}{default};
	}
	#makes sure it is not just a new line
	if ($chooserstring eq "\n") {
		return $self->{args}{default};
	}
	
	my ($success, $choosen)=choose($chooserstring);
	
	if(!defined( $choosen )){
		return $self->{args}{default};
	}
	
	if (!$self->setNameLegit($choosen)){
		$self->{error}=27;
		$self->{errorString}='"'.$choosen."' is not a legit set name. Using the".
		                     " default of '".$self->{args}{default}."'.";
		$self->warn;
		return $self->{args}{default};
	}
	
	return $choosen;
}

=head2 configExists

This method is used for checking if a config exists or not.

It takes one option, which is the configuration to check for.

The returned value is a perl boolean value.

    $zconf->configExists("foo/bar")
	if($zconf->error){
		print 'error: '.$zconf->error."\n".$zconf->errorString."\n";
	}

=cut

#check if a config exists
sub configExists{
	my ($self, $config) = @_;

	$self->errorblank;

	my ($error, $errorString)=$self->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#run the checks
	my $returned=$self->{be}->configExists($config);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error && $self->{args}{readfallthrough} ) {
		$returned=$self->{fbe}->configExists($config);
		if ( $self->{fbe}->error ) {
			$self->{error}=11;
			$self->{errorString}='Backend errored. error="'.$self->{fbe}->error.'" errorString="'.$self->{fbe}->errorString.'"';
			$self->warn;
		}
	}elsif ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
	}

	return $returned;
}

=head2 configNameCheck

This checks if the name of a config is legit or not. See the section
CONFIG NAME for more info on config naming.

	my ($error, $errorString) = $zconf->configNameCheck($config);
	if($error){
		warn("ZConf configExists:".$error.": ".$errorString);
		$self->{error}=$error;
		$self->{errorString}=$errorString;
        $self->warn;
		return undef;
	};

=cut

#checks the config name
sub configNameCheck{
	my ($self, $name) = @_;

	$self->errorblank;

	#checks for undef
	if(!defined($name)){
		return("11", "config name is not defined.");
	}

	#checks for ,
	if($name =~ /,/){
		return("1", "config name,'".$name."', contains ','");
	}

	#checks for /.
	if($name =~ /\/\./){
		return("2", "config name,'".$name."', contains '/.'");
	}

	#checks for //
	if($name =~ /\/\//){
		return("3", "config name,'".$name."', contains '//'");
	}

	#checks for ../
	if($name =~ /\.\.\//){
		return("4", "config name,'".$name."', contains '../'");
	}

	#checks for /..
	if($name =~ /\/\.\./){
		return("5", "config name,'".$name."', contains '/..'");
	}

	#checks for ^./
	if($name =~ /^\.\//){
		return("6", "config name,'".$name."', matched /^\.\//");
	}

	#checks for /$
	if($name =~ /\/$/){
		return("7", "config name,'".$name."', matched /\/$/");
	}

	#checks for ^/
	if($name =~ /^\//){
		return("8", "config name,'".$name."', matched /^\//");
	}

	#checks for ^/
	if($name =~ /\n/){
		return("10", "config name,'".$name."', matched /\\n/");
	}

	return(undef, "");
}

=head2 createConfig

This method is used for creating a new config. 

One arguement is needed and that is the config name.

The returned value is a perl boolean.

    $zconf->createConfig("foo/bar")
	if($zconf->error){
		print 'error: '.$zconf->{error}."\n".$zconf->errorString."\n";
	};

=cut

#the overarching method for getting available sets
sub createConfig{
	my ($self, $config) = @_;

	$self->errorblank;

	my ($error, $errorString)=$self->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	my $returned=undef;

	#create the config
	$self->{be}->createConfig( $config );
	if ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
		return undef;
	}


	#attempt to sync the config locally if not using the file backend
	if( defined( $self->{fbe} ) ){
		#if it does not exist, add it
		if(!$self->{fbe}->configExists($config)){
			my $syncReturn=$self->{fbe}->createConfig($config);
			if ( $self->{fbe}->error ){
				$self->warn;
			}
		}
	}

	return 1;
}

=head2 defaultSetExists

This checks to if the default set for a config exists. It takes one arguement,
which is the name of the config. The returned value is a Perl boolean.

    my $returned=$zconf->defaultSetExists('someConfig');
    if($zconf->error){
		warn('error: '.$zconf->{error}."\n".$zconf->errorString);
    }
    if($returned){
        print "It exists.\n";
    }

=cut

sub defaultSetExists{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	#make sure the config name is legit
	my ($error, $errorString)=$self->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#makes sure it exists
	if (!$self->configExists($config)){
		$self->{error}=12;
		$self->{errorString}='The specified config, "'.$config.'" does not exist';
		$self->warn;
		return undef;
	}

	#figures out what to use for the set
	my $set=$self->chooseSet($config);
	if (defined($self->{error})){
		return undef;
	}

	#get the available sets to check if the default exists
	my @sets=$self->getAvailableSets($config);
	if ($self->error) {
		$self->warnString('getAvailableSets errored');
		return undef;
	}

	#check for one that matches...
	my $int=0;
	while (defined($sets[$int])) {
		if ($set eq $sets[$int]) {
			return 1;
		}
		$int++;
	}

	return undef;
}

=head2 delConfig

This removes a config. Any sub configs will need to removes first. If any are
present, this method will error.

    #removes 'foo/bar'
    $zconf->delConfig('foo/bar');
    if(defined($zconf->error)){
		warn('error: '.$zconf->{error}."\n".$zconf->errorString);
    }

=cut

sub delConfig{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;
	
	#return if no set is given
	if (!defined($config)) {
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;
	}

	#makes sure no subconfigs exist
	my @subs=$self->getSubConfigs($config);
	#return if this can't be completed
	if (defined($self->{error})) {
		return undef;		
	}
	if (defined($subs[0])) {
		$self->{error}=33;
		$self->{errorString}='Could not remove the config as it has sub configs.';
		$self->warn;
		return undef;
	}

	#delete the config
	$self->{be}->delConfig( $config );
	if ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
		return undef;
	}

	#attempt to sync the config locally if not using the file backend
	if( defined( $self->{fbe} ) ){
		#if it does exist, remove it
		if($self->{fbe}->configExists($config)){
			my $syncReturn=$self->{fbe}->createConfig($config);
			if ( $self->{fbe}->error ){
				$self->warn;
			}
		}
	}

	return 1;
}

=head2 delSet

This deletes a specified set.

Two arguements are required. The first one is the name of the config and the and
the second is the name of the set.

    $zconf->delSetFile("foo/bar", "someset");
    if($zconf->error){
		warn('error: '.$zconf->{error}."\n".$zconf->errorString);
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

	#makes sure it exists before continuing
	#This will also make sure the config exists.
	my $returned = $self->configExists($config);
	if (defined($self->{error})){
		$self->{error}=12;
		$self->{errorString}='The config "'.$config.'" does not exist';
		$self->warn;
		return undef;
	}

	#delete the config
	$self->{be}->delSet( $config, $set );
	if ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
		return undef;
	}

	#attempt to sync the config locally if not using the file backend
	if( defined( $self->{fbe} ) ){
		#if it does exist, remove it
		if ($self->{fbe}->setExists) {
			my $syncReturn=$self->{fbe}->delSet($config, $set);
			if ( $self->{fbe}->error ){
				$self->warnString('File backend sync failed. error="'.$self->{fbe}->error.
					 '" errorString="'.$self->{fbe}->errorString.'"');
			}
		}
	}

	return $returned;
}

=head2 dumpToZML

This dumps a loaded config to a ZML object.

One arguement is required and it is the name of the loaded config.

    my $zml=$foo->dumpToZML($config);
	if($zconf->error){
		warn('error: '.$zconf->{error}."\n".$zconf->errorString);
	}

=cut

sub dumpToZML{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	#return if no config is given
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;
	}

	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#create the ZML object
	my $zml=ZML->new();

	#process variables
	my $varhashkeysInt=0;#used for intering through the list of hash keys
	#builds the ZML object
	my @varhashkeys=keys(%{$self->{conf}{$config}});
	while(defined($varhashkeys[$varhashkeysInt])){
		#attempts to add the variable
		$zml->addVar($varhashkeys[$varhashkeysInt], 
					$self->{conf}{$config}{$varhashkeys[$varhashkeysInt]});
		#checks to verify there was no error
		#this is not a fatal error... skips it if it is not legit
		if(defined($zml->{error})){
			$self->warnString(':23: $zml->add() returned '.	$zml->{error}.
							  ", '".$zml->{errorString}."'. Skipping variable '".
							  $varhashkeys[$varhashkeysInt]."' in '".$config."'.");
		}

		$varhashkeysInt++;
	}

	#processes the meta variables
	$varhashkeysInt=0;#used for intering through the list of hash keys
	#builds the ZML object
	@varhashkeys=keys(%{$self->{meta}{$config}});
	while(defined($varhashkeys[$varhashkeysInt])){
		my @metahashkeys=keys( %{$self->{meta}{ $config }{ $varhashkeys[$varhashkeysInt] }} );
		my $metahashkeysInt=0;
		while (defined($metahashkeys[ $metahashkeysInt ])) {
			$zml->addMeta(
						  $varhashkeys[$varhashkeysInt],
						  $metahashkeys[$metahashkeysInt],
						  $self->{meta}{ $config }{ $varhashkeys[$varhashkeysInt] }{ $metahashkeys[$metahashkeysInt] }
						  );
			
			$metahashkeysInt++;
		}

		$varhashkeysInt++;
	}

	#processes the comment variables
	$varhashkeysInt=0;#used for intering through the list of hash keys
	#builds the ZML object
	@varhashkeys=keys(%{ $self->{comment}{$config} });
	while(defined($varhashkeys[$varhashkeysInt])){
		my @commenthashkeys=keys( %{$self->{self}->{comment}{ $config }{ $varhashkeys[$varhashkeysInt] }} );
		my $commenthashkeysInt=0;
		while (defined($commenthashkeys[ $commenthashkeysInt ])) {
			$zml->addComment(
						  $varhashkeys[$varhashkeysInt],
						  $commenthashkeys[$commenthashkeysInt],
						  $self->{comment}{ $config }{ $varhashkeys[$varhashkeysInt] }{ $commenthashkeys[$commenthashkeysInt] }
						  );
			
			$commenthashkeysInt++;
		}

		$varhashkeysInt++;
	}

	return $zml;
}

=head2 getAutoupdate

This gets if a config should be automatically updated or not.

One arguement is required and it is the config. If this is undefined
or a matching one is not found, the global is used.

The return value is a boolean.

    #fetches the global
    my $autoupdate=$zconf->getAutoupdate();

    #fetches it for 'some/config'
    my $autoupdate=$zconf->getAutoupdate('some/config');

=cut

sub getAutoupdate{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	if (!defined( $config )) {
		return $self->{autoupdateGlobal};
	}

	if (defined( $self->{autoupdate}{$config} )) {
		return $self->{autoupdate}{$config};
	}

	return $self->{autoupdateGlobal};
}

=head2 getAvailableSets

This gets the available sets for a config.

The only arguement is the name of the configuration in question.

	my @sets = $zconf->getAvailableSets("foo/bar");
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#the overarching method for getting available sets
sub getAvailableSets{
	my ($self, $config) = @_;

	$self->errorblank;

	#make sure the config name is legit
	my ($error, $errorString)=$self->configNameCheck($config);
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

	#run the checks
	my @returned=$self->{be}->getAvailableSets($config);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error &&
		 $self->{args}{readfallthrough} &&
		 defined( $self->{fbe} )
		) {
		@returned=$self->{fbe}->getAvailableSets($config);
		if ( $self->{fbe}->error ) {
			$self->{error}=11;
			$self->{errorString}='Backend errored. error="'.$self->{fbe}->error.'" errorString="'.$self->{fbe}->errorString.'"';
			$self->warn;
		}
	}elsif ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
	}

	return @returned;
}

=head2 getDefault

This gets the default set currently being used if one is not choosen.

	my $defaultSet = $zml->getDefault();

=cut
	
#gets what the default set is
sub getDefault{
	my ($self)= @_;

	$self->errorblank;

	return $self->{args}{default};
}

=head2 getComments

This gets a list of variables that have comments.

	my @keys = $zconf->getComments("foo/bar")
	if($zconf->error){
		print 'error: '.$zconf->error."\n".$zconf->errorString."\n";
	}

=cut

#get a list of keys for a config
sub getComments {
	my ($self, $config) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1});

	if(!defined($self->{comment}{$config})){
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{comment}{$config}});

	return @keys;
}

=head2 getConfigRevision

This fetches the revision for the speified config.

    my $revision=$zconf->getConfigRevision('some/config');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
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

	#run the checks
	my $returned=$self->{be}->getConfigRevision($config);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error &&
		 $self->{args}{readfallthrough} &&
		 defined( $self->{fbe} )
		) {
		$returned=$self->{fbe}->getConfigRevision($config);
		if ( $self->{fbe}->error ) {
			$self->{error}=11;
			$self->{errorString}='Backend errored. error="'.$self->{fbe}->error.'" errorString="'.$self->{fbe}->errorString.'"';
			$self->warn;
		}
	}elsif ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
	}

	return $returned;
}

=head2 getCtime

This fetches the mtime for a variable.

Two arguements are required. The first is the config
and the second is the variable.

The returned value is UNIX time value for when it was last
changed. If it is undef, it means the variable has not been
changed since ZConf 2.0.0 came out.

    my $time=$zconf->getMtime('some/config', 'some/var');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }
    if(defined($time)){
        print "variable modified at".$time." seconds past 1970-01-01.\n";
    }else{
        print "variable not modifined since ZConf 2.0.0 came out.\n";
    }

=cut

sub getCtime{
	my $self=$_[0];
	my $config=$_[1];
	my $var=$_[2];

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#no metas for this var
	if (!defined( $self->{meta}{$config}{$var} )) {
		return undef;
	}

	if (!defined( $self->{meta}{$config}{$var}{'ctime'} )) {
		return undef;
	}

	return $self->{meta}{$config}{$var}{'ctime'};
}

=head2 getKeys

This gets gets the keys for a loaded config.

	my @keys = $zconf->getKeys("foo/bar")
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#get a list of keys for a config
sub getKeys {
	my ($self, $config) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{conf}{$config}});

	return @keys;
}

=head2 getLoadedConfigRevision

This gets the revision of the specified config,
if it is loaded.

    my $rev=$zconf->getLoadedConfigRevision;
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub getLoadedConfigRevision{
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

	#make sure it is loaded
	if(! $self->isConfigLoaded($config) ){
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	return $self->{revision}{$config};
}

=head2 getLoadedConfigs

This gets gets the keys for a loaded config.

	my @configs = $zconf->getLoadedConfigs("foo/bar")
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#get a list loaded configs
sub getLoadedConfigs {
	my ($self, $config) = @_;

	$self->errorblank;

	my @keys=keys(%{$self->{conf}});

	return @keys;
}

=head2 getMetas

This gets a list of variables that have meta
variables.

	my @keys = $zconf->getComments("foo/bar")
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#get a list of keys for a config
sub getMetas {
	my ($self, $config) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{meta}{$config}});

	return @keys;
}

=head2 getMtime

This fetches the mtime for a variable.

Two arguements are required. The first is the config
and the second is the variable.

The returned value is UNIX time value for when it was last
changed. If it is undef, it means the variable has not been
changed since ZConf 2.0.0 came out.

    my $time=$zconf->getMtime('some/config', 'some/var');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }
    if(defined($time)){
        print "variable modified at".$time." seconds past 1970-01-01.\n";
    }else{
        print "variable not modifined since ZConf 2.0.0 came out.\n";
    }

=cut

sub getMtime{
	my $self=$_[0];
	my $config=$_[1];
	my $var=$_[2];

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#no metas for this var
	if (!defined( $self->{meta}{$config}{$var} )) {
		return undef;
	}

	if (!defined( $self->{meta}{$config}{$var}{'mtime'} )) {
		return undef;
	}

	return $self->{meta}{$config}{$var}{'mtime'};
}

=head2 getOverrideChooser

This will get the current override chooser for a config.

If no chooser is specified for the loaded config

One arguement is required it is the name of the config.

This method is basically a wrapper around regexMetaGet.

    my $orchooser=$zconf->getOverrideChooser($config);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub getOverrideChooser{
	my $self=$_[0];
	my $config=$_[1];

	#blank the any previous errors
	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		return undef;
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	my $chooser;

	if ( (defined( $self->{meta}{$config}{zconf} ))&&(defined( $self->{meta}{$config}{zconf}{'override/chooser'} )) ) {
		$chooser=$self->{meta}{$config}{zconf}{'override/chooser'};
	}

	return $chooser;
}

=head2 getSet

This gets the set for a loaded config.

	my $set = $zconf->getSet("foo/bar")
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#get the set a config is currently using
sub getSet{
	my ($self, $config)= @_;

	$self->errorblank;

	if ( ! defined( $config ) ){
		$self->{error}=25;
		$self->{errorString}='No config defined';
		$self->warn;
		return undef;
	}

	if(!defined($self->{set}{$config})){
		$self->{error}=26;
		$self->{errorString}="Set '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}
	
	return $self->{set}{$config};
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

	#blank any previous errors
	$self->errorblank;

	#make sure the config name is legit
	my ($error, $errorString)=$self->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#run the checks
	my @returned=$self->{be}->getSubConfigs($config);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error &&
		 $self->{args}{readfallthrough} &&
		 defined( $self->{fbe} )
		) {
		@returned=$self->{fbe}->getSubConfigs($config);
		if ( $self->{fbe}->error ) {
			$self->{error}=11;
			$self->{errorString}='Backend errored. error="'.$self->{fbe}->error.'" errorString="'.$self->{fbe}->errorString.'"';
			$self->warn;
		}
	}
	elsif( $self->{be}->error ){
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
	}

	return @returned;
}

=head2 getComment

This requires three arguments.

The first is the name of the config.

The second is the variable.

The third is the comment name.

If the comment does not exist, undef is returned. It is also possible it errored, but
a non-existant variable is not considered a error.

    my $value=$zconf->getVar($someConfig, $someVariable, $someComment);
    if($zconf->error){
        warn('error: '.$zconf->error.":".$zconf->errorString);
    }
    if(!defined($value)){
        print "'.$someVariable.' and/or '".$someComment."' does not exist\n";
    }

=cut

sub getComment{
	my ($self, $config, $var, $comment) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='No config specified';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#make sure we have a variable
	if (!defined($var)) {
		$self->{error}=18;
		$self->{errorString}='No variable specified';
		$self->warn;
		return undef;
	}

	#makes sure we have a comment specified
	if (!defined($comment)) {
		$self->{error}=41;
		$self->{errorString}='No comment specified';
		$self->warn;
		return undef;
	}

	#make sure it exists
	if (!defined( $self->{comment}{$config}{$var} )) {
		return undef;
	}
	if (!defined( $self->{comment}{$config}{$var}{$comment} )) {
		return undef;
	}

	return $self->{comment}{$config}{$var}{$comment};
}

=head2 getMeta

This requires three arguments.

The first is the name of the config.

The second is the variable.

The third is the meta name.

If the comment does not exist, undef is returned. It is also possible it errored, but
a non-existant variable is not considered a error.

    my $value=$zconf->getVar($someConfig, $someVariable, $someMeta);
    if($zconf->error){
        warn('error: '.$zconf->error.":".$zconf->errorString);
    }
    if(!defined($value)){
        print "'.$someVariable.' and/or '".$someMeta."' does not exist\n";
    }

=cut

sub getMeta{
	my ($self, $config, $var, $meta) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='No config specified';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#make sure we have a variable
	if (!defined($var)) {
		$self->{error}=18;
		$self->{errorString}='No variable specified';
		$self->warn;
		return undef;
	}

	#makes sure we have a meta specified
	if (!defined($meta)) {
		$self->{error}=42;
		$self->{errorString}='No meta specified';
		$self->warn;
		return undef;
	}

	#make sure it exists
	if (!defined( $self->{meta}{$config}{$var} )) {
		return undef;
	}
	if (!defined( $self->{meta}{$config}{$var}{$meta} )) {
		return undef;
	}

	return $self->{meta}{$config}{$var}{$meta};
}

=head2 getVar

This reqyures two arguments.

The first is the name of the config.

The second is the variable.

If the variable does not exist, undef is returned. It is also possible it errored, but
a non-existant variable is not considered a error.

    my $value=$zconf->getVar($someConfig, $someVariable);
    if($zconf->error){
        warn('error: '.$zconf->error.":".$zconf->errorString);
    }
    if(!defined($value)){
        print "'.$someVariable.' does not exist\n";
    }

=cut

sub getVar{
	my ($self, $config, $var) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='No config specified';
		$self->Warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#make sure we have a variable
	if (!defined($var)) {
		$self->{error}=18;
		$self->{errorString}='No variable specified';
		$self->warn;
		return undef;
	}

	#make sure it exists
	if (!defined( $self->{conf}{$config}{$var} )) {
		return undef;
	}

	return $self->{conf}{$config}{$var};
}

=head2 initBackend

This initializes a backend.

One arguement is required and it is the backend name.

    my $backend=$zconf->initBackend('file');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }else{
        if($backend->error){
		warn('backend error: '.$backend->error.":".$backend->errorString);
        }
    }

=cut

sub initBackend{
	my $self=$_[0];
	my $backend=$_[1];

	$self->errorblank;

	if (!defined( $backend )) {
		$self->{error}=15;
		$self->{errorString}='No backend specified';
		$self->warn;
		return undef;
	}

	#tries to load it
	my $torun='use ZConf::backends::'.$backend.
	          '; $be=ZConf::backends::'.$backend.
			  '->new( \%{ $self->{args} } );';
	my $be;
	eval($torun);
	if (!defined($be)) {
		$self->{error}=47;
		$self->{errorString}='Trying to initialize the backend failed. It returned undefined';
		$self->warn;
		return undef;
	}

	return $be;
}

=head2 isLoadedConfigLocked

This returns if the loaded config is locked or not.

Only one arguement is taken and that is the name of the config.

    my $returned=$zconf->isLoadedConfigLocked('some/config');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub isLoadedConfigLocked{
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

	#make sure it is loaded
	if(! $self->isConfigLoaded( $config ) ){
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	if (defined($self->{locked}{$config})) {
		return 1;
	}

	return undef;
}

=head2 isConfigLoaded

This checks if a config or not.

One argument is taken and that is if a config is loaded or not.

    $zconf->isConfigLoaded($config);
    if( $zconf->error ){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub isConfigLoaded{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	if (!defined($config)) {
		$self->{error}=25;
		$self->{errorString}="Config is undefined";
		$self->warn;
		return undef;
	}

	if ( defined( $self->{conf}{ $config } ) ) {
		return 1;
	}

	return undef;
}

=head2 isConfigLocked

This checks if a config is locked or not.

One arguement is required and it is the name of the config.

The returned value is a boolean value.

    my $locked=$zconf->isConfigLocked('some/config');
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

	#run the checks
	my $returned=$self->{be}->isConfigLocked($config);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error &&
		 $self->{args}{readfallthrough} &&
		 defined( $self->{fbe} )
		) {
		$returned=$self->{fbe}->isConfigLocked($config);
		if ( $self->{fbe}->error ) {
			$self->{error}=11;
			$self->{errorString}='Backend errored. error="'.$self->{fbe}->error.'" errorString="'.$self->{fbe}->errorString.'"';
			$self->warn;
		}
	}elsif ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
	}

	return $returned;
}

=head2 LDAPconnect

This generates a Net::LDAP object based on the LDAP backend.

    my $ldap=$zconf->LDAPconnect();
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub LDAPconnect{
	my $self=$_[0];

	$self->errorblank;

	my $returned;
	if (ref( $self->{be} ) eq "ZConf::backends::ldap"  ) {
		$returned=$self->{be}->LDAPconnect;
		if ($self->{be}->error) {
			$self->{error}=11;
			$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
			$self->warn;
		}
	}else {
		$self->{error}=13;
		$self->{errorString}='Backend is not "ZConf::backends::ldap"';
		$self->warn;
	}

	return $returned;
}

=head2 override

This runs the overrides for a config.

This overrides various variables in the config by
running the chooser stored in '#!zconf=override/chooser'.
If it fails, the profile 'default' is used.

Once a profile name has been picked, everything under
'#!zconf=override/profiles/<profile>/' has
/^override\/profiles\/<profile>\// removed and it is
set as a regular variable.

One arguement is taken and it is a hash.

If a value of undef is returned, but no error is set, no
'#!zconf=override/chooser' is not defined.

This method does not invoke the method updateIfNeeded.

=head3 args hash

=head4 config

This is the config to operate on.

=head4 profile

If this is not specified, the chooser stored
in the meta is '#!zconf=override/chooser'.

=cut

sub override{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	#blank the any previous errors
	$self->errorblank;

	#update if if needed
	#commenting this out as of currently as it results in a infinite loop for the file backend
	#$self->updateIfNeeded({config=>$args{config}, clearerror=>1, autocheck=>1});

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$args{config} not defined';
		$self->warn;
		return undef;			
	}

	#make sure the loaded config is not locked
	if (defined( $self->{locked}{ $args{config} } )) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$args{config}.'" is locked';
		$self->warn;
		return undef;
	}

	#make sure the config is loaded
	if(!defined( $self->{conf}{ $args{config} } )){
		$self->{error}=26;
		$self->{errorString}="Config '".$args{config}."' is not loaded.";
		$self->warn;
		return undef;
	}

	#if no profile is given, get one
	if (!defined( $args{profile} )) {
		if ( (defined( $self->{meta}{$args{config}}{zconf} ))&&
			 (defined( $self->{meta}{$args{config}}{zconf}{'override/chooser'} ))
			) {

			my $chooser=$self->{meta}{$args{config}}{zconf}{'override/chooser'};
			#if the chooser is not blank, run it
			if ($chooser ne '') {
				my ($success, $choosen)=choose($chooser);

				#if no choosen name is returned, use 'default'
				if ($success) {
					$args{profile}=$choosen;
				}else {
					$args{profile}='default';
				}
			}else {
				$args{profile}='default';
			}
		}else {
			#none to process
			return undef;
		}
	}

	#make sure it is legit
	if (!$self->setNameLegit($args{profile})){
		$self->{error}=27;
		$self->{errorString}='"'.$args{profile}.'" is not a valid set name';
		$self->warn;
		return undef;
	}

	#
	my %metas=$self->regexMetaGet({
									config=>$args{config},
									varRegex=>'^zconf$',
									metaRegex=>'^override\/profiles\/'.quotemeta($args{profile}).'\/',
									});

	#this does definitely exist as it would have returned previously.
	my @keys=keys( %{ $metas{zconf} } );

	#processes each one
	my $int=0;
	while (defined( $keys[$int] )) {
		my $override=$keys[$int];

		my $remove='^override\/profiles\/'.quotemeta($args{profile}).'\/';

		$override=s/$override//g;

		$self->{conf}{$args{config}}{$override}=$self->{meta}{$args{config}}{'zconf'}{$keys[$int]};

		$int++;
	}
	
	return 1;
}

=head2 read

This reads a config. The only accepted option is the config name.

It takes one arguement, which is a hash.

=head3 hash args

=head4 config

The config to load.

=head4 override

This specifies if override should be ran not.

If this is not specified, it defaults to 1, true.

=head4 set

The set for that config to load.

    $zconf->read({config=>"foo/bar"})
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#the overarching read
sub read{
	my $self=$_[0];
	my %args=%{$_[1]};

	$self->errorblank;

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='No config specified';
		$self->warn;
		return undef;
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->configNameCheck($args{config});
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#checks to make sure the config does exist
	if(!$self->configExists($args{config})){
		$self->{error}=12;
		$self->{errorString}="'".$args{config}."' does not exist.";
		$self->warn;
		return undef;			
	}

	#gets the set to use if not set
	if(!defined($args{set})){
		$args{set}=$self->chooseSet($args{config});
		if (defined($self->{error})) {
			$self->{error}='32';
			$self->{errorString}='Unable to choose a set';
			$self->warn;
			return undef;
		}
	}

	#reads the config
	my $returned=$self->{be}->read(\%args);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error &&
		 $self->{args}{readfallthrough} &&
		 defined( $self->{fbe} )
		) {
		$returned=$self->{fbe}->read(\%args);
		if ( $self->{fbe}->error ) {
			$self->{error}=11;
			$self->{errorString}='Backend errored. error="'.$self->{fbe}->error.'" errorString="'.$self->{fbe}->errorString.'"';
			$self->warn;
		}
	}elsif ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
	}
	#sync to the file backend
	if (
		defined( $self->{fbe} ) &&
		( ! $self->{be}->error )
		) {
		$self->{fbe}->writeSetFromLoadedConfig(\%args);
		if ($self->{fbe}->error) {
			$self->warnString('Failed to sync to the backend  error='.$self->{fbe}->error.' errorString='.$self->{fbe}->errorString);	
		}
	}

	return $returned;
}

=head2 readChooser

This reads the chooser for a config. If no chooser is defined "" is returned.

The name of the config is the only required arguement.

	my $chooser = $zconf->readChooser("foo/bar")
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#the overarching readChooser
#this gets the chooser for a the config
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
	my ($error, $errorString)=$self->configNameCheck($config);
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

	#reads the chooser
	my $returned=$self->{be}->readChooser($config);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error &&
		 $self->{args}{readfallthrough} &&
		 defined( $self->{fbe} )
		) {
		$returned=$self->{fbe}->readChooser($config);
		if ( $self->{fbe}->error ) {
			$self->{error}=11;
			$self->{errorString}='Backend errored. error="'.$self->{fbe}->error.'" errorString="'.$self->{fbe}->errorString.'"';
			$self->warn;
		}
	}elsif ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
	}
	#sync to the file backend
	if (
		defined( $self->{fbe} ) &&
		( ! $self->{be}->error )
		) {
		$self->{fbe}->writeChooser($config, $returned);
		if ($self->{fbe}->error) {
			$self->warnString('Failed to sync to the backend  error='.$self->{fbe}->error.' errorString='.$self->{fbe}->errorString);	
		}
	}

	return $returned;
}

=head2 regexCommentDel

This searches through the comments for variables in a loaded config for
any that match the supplied regex and removes them.

One arguement is taken and it is a hash.

A hash of hash containing copies of the deleted variables are returned.

=head3 args hash

=head4 config

This is the config search.

=head4 varRegex

The variable to search for matching comment names.

=head4 commentRegex

The regex use for matching comment names.

    my %deleted=$zconf->regexCommentDel({
                                         config=>"foo/bar",
                                         varRegex=>"^some/var$",
                                         commentRegex=>"^monkey\/";
                                        });
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#removes variables based on a regex
sub regexCommentDel{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$args{config}, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($args{config}) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$args{config}."' is not loaded.";
		$self->warn;
		return undef;
	}


	#return false if the config is not set
	if (!defined($args{varRegex})){
		$self->{error}=18;
		$self->{errorString}='$args{varRegex} not defined';
		$self->warn;
		return undef;
	}

	#make sure the loaded config is not locked
	if (defined($self->{locked}{$args{config}})) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$args{config}.'" is locked';
		$self->warn;
		return undef;
	}

	my @vars=keys(%{$self->{comment}{$args{config}}});

	my %returned;

	#run through checking it all
	my $varsInt=0;
	while(defined($vars[$varsInt])){
		#if the variable matches, it is ok
		if ($vars[$varsInt] =~ /$args{varRegex}/) {
			my @comments=keys(%{$self->{comment}{ $args{config} }{ $vars[$varsInt] }});
			my $commentsInt=0;
			#check the each meta
			while (defined($comments[$commentsInt])) {
				#remove any matches
				if ($self->{comment}{ $args{config} }{ $vars[$varsInt] }{ $comments[$commentsInt] } =~ /$args{commentRegex}/) {
					#copies the variable before it is deleted
					if (!defined( $returned{ $vars[$varsInt] } )) {
						$returned{ $vars[$varsInt] }={};
					}
					$returned{ $vars[$varsInt] }{ $comments[$commentsInt] }=
					                            $self->{comment}{ $args{config} }{ $vars[$varsInt] }{ $comments[$commentsInt] };
					delete($self->{comment}{ $args{config} }{ $vars[$varsInt] }{ $comments[$commentsInt] });
				}
				
				$commentsInt++;
			}
		}

		$varsInt++;
	}

	return %returned;
}

=head2 regexCommentGet

This searches through the comments for variables in a loaded config for
any that match the supplied regex and returns them.

One arguement is taken and it is a hash.

A hash of hash containing copies of the deleted variables are returned.

=head3 args hash

=head4 config

This is the config search.

=head4 varRegex

The variable to search for matching comment names.

=head4 commentRegex

The regex use for matching comment names.

    my %deleted=$zconf->regexCommentGet({
                                         config=>"foo/bar",
                                         varRegex=>"^some/var$",
                                         commentRegex=>"^monkey\/";
                                        });
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#removes variables based on a regex
sub regexCommentGet{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$args{config}, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($args{config})) {
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($args{config}) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$args{config}."' is not loaded.";
		$self->warn;
		return undef;
	}

	#return false if the config is not set
	if (!defined($args{varRegex})) {
		$self->{error}=18;
		$self->{errorString}='$args{varRegex} not defined';
		$self->warn;
		return undef;			
	}

	my @vars=keys(%{$self->{comment}{$args{config}}});

	my %returned;

	#run through checking it all
	my $varsInt=0;
	while (defined($vars[$varsInt])) {
		#if the variable matches, it is ok
		if ($vars[$varsInt] =~ /$args{varRegex}/) {
			my @comments=keys(%{$self->{comment}{ $args{config} }{ $vars[$varsInt] }});
			my $commentsInt=0;
			#check the each meta
			while (defined($comments[$commentsInt])) {
				#remove any matches
				if ($self->{comment}{ $args{config} }{ $vars[$varsInt] }{ $comments[$commentsInt] } =~ /$args{commentRegex}/) {
					#adds it to the returned hash
					if (!defined( $returned{ $vars[$varsInt] } )) {
						$returned{ $vars[$varsInt] }={};
					}
					$returned{ $vars[$varsInt] }{ $comments[$commentsInt] }=
					$self->{comment}{ $args{config} }{ $vars[$varsInt] }{ $comments[$commentsInt] };
				}
				
				$commentsInt++;
			}
		}

		$varsInt++;
	}

	return %returned;
}

=head2 regexMetaDel

This searches through the meta variables in a loaded config for any that match
the supplied regex and removes them.

One arguement is taken and it is a hash.

A hash of hash containing copies of the deleted variables are returned.

=head3 args hash

=head4 config

This is the config search.

=head4 varRegex

The variable to search for matching comment names.

=head4 metaRegex

The regex use for matching meta variables.

    my %deleted=$zconf->regexMetaDel({
                                      config=>"foo/bar",
                                      varRegex=>"^some/var$",
                                      metaRegex=>"^monkey\/";
                                     });
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#removes variables based on a regex
sub regexMetaDel{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$args{config}, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($args{config}) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$args{config}."' is not loaded.";
		$self->warn;
		return undef;
	}

	#return false if the config is not set
	if (!defined($args{varRegex})){
		$self->{error}=18;
		$self->{errorString}='$args{varRegex} not defined';
		$self->warn;
		return undef;			
	}

	#make sure the loaded config is not locked
	if (defined($self->{locked}{$args{config}})) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$args{config}.'" is locked';
		$self->warn;
		return undef;
	}

	my @vars=keys(%{$self->{meta}{$args{config}}});

	my %returned;

	#run through checking it all
	my $varsInt=0;
	while(defined($vars[$varsInt])){
		#if the variable matches, it is ok
		if ($vars[$varsInt] =~ /$args{varRegex}/) {
			my @metas=keys(%{$self->{meta}{ $args{config} }{ $vars[$varsInt] }});
			my $metasInt=0;
			#check the each meta
			while (defined($metas[$metasInt])) {
				#remove any matches
				if ($self->{meta}{ $args{config} }{ $vars[$varsInt] }{ $metas[$metasInt] } =~ /$args{metaRegex}/) {
					#copies the variable before it is deleted
					if (!defined( $returned{ $vars[$varsInt] } )) {
						$returned{ $vars[$varsInt] }={};
					}
					$returned{ $vars[$varsInt] }{ $metas[$metasInt] }=
					                            $self->{meta}{ $args{config} }{ $vars[$varsInt] }{ $metas[$metasInt] };
					delete($self->{meta}{ $args{config} }{ $vars[$varsInt] }{ $metas[$metasInt] });
				}
				
				$metasInt++;
			}
		}

		$varsInt++;
	}

	return %returned;
}

=head2 regexMetaGet

This searches through the meta variables in a loaded config for any that match
the supplied regex and removes them.

One arguement is taken and it is a hash.

A hash of hash containing copies of the deleted variables are returned.

=head3 args hash

=head4 config

This is the config search.

=head4 varRegex

The variable to search for matching comment names.

=head4 metaRegex

The regex use for matching meta variables.

    my %deleted=$zconf->regexMetaGet({
                                      config=>"foo/bar",
                                      varRegex=>"^some/var$",
                                      metaRegex=>"^monkey\/";
                                     });
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#removes variables based on a regex
sub regexMetaGet{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$args{config}, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($args{config}) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$args{config}."' is not loaded.";
		$self->warn;
		return undef;
	}

	#return false if the config is not set
	if (!defined($args{varRegex})){
		$self->{error}=18;
		$self->{errorString}='$args{varRegex} not defined';
		$self->warn;
		return undef;			
	}

	my @vars=keys(%{$self->{meta}{$args{config}}});

	my %returned;

	#run through checking it all
	my $varsInt=0;
	while(defined($vars[$varsInt])){
		#if the variable matches, it is ok
		if ($vars[$varsInt] =~ /$args{varRegex}/) {
			my @metas=keys(%{$self->{meta}{ $args{config} }{ $vars[$varsInt] }});
			my $metasInt=0;
			#check the each meta
			while (defined($metas[$metasInt])) {
				#add any matched
				if ($self->{meta}{ $args{config} }{ $vars[$varsInt] }{ $metas[$metasInt] } =~ /$args{metaRegex}/) {
					#copies the variable before it is deleted
					if (!defined( $returned{ $vars[$varsInt] } )) {
						$returned{ $vars[$varsInt] }={};
					}
					$returned{ $vars[$varsInt] }{ $metas[$metasInt] }=
					                            $self->{meta}{ $args{config} }{ $vars[$varsInt] }{ $metas[$metasInt] };
				}
				
				$metasInt++;
			}
		}

		$varsInt++;
	}

	return %returned;
}

=head2 regexVarDel

This searches through the variables in a loaded config for any that match
the supplied regex and removes them.

Two arguements are required. The first is the config to search. The second
is the regular expression to use.

	#removes any variable starting with the monkey
	my @deleted = $zconf->regexVarDel("foo/bar", "^monkey");
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#removes variables based on a regex
sub regexVarDel{
	my ($self, $config, $regex) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#make sure the loaded config is not locked
	if (defined($self->{locked}{$config})) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{conf}{$config}});

	my @returnKeys=();

	my $int=0;
	while(defined($keys[$int])){
		if($keys[$int] =~ /$regex/){
			delete($self->{conf}{$config}{$keys[$int]});
			push(@returnKeys, $keys[$int]);
		}

		$int++;
	}

	return @returnKeys;				
}

=head2 regexVarGet

This searches through the variables in a loaded config for any that match
the supplied regex and returns them in a hash.

Two arguements are required. The first is the config to search. The second
is the regular expression to use.

	#returns any variable begining with monkey
	my %vars = $zconf->regexVarGet("foo/bar", "^monkey");
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#returns a hash of regex matched vars
#return undef on error	
sub regexVarGet{
	my ($self, $config, $regex) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{conf}{$config}});

	my %returnKeys=();

	my $int=0;
	while(defined($keys[$int])){
		if($keys[$int] =~ /$regex/){
			$returnKeys{$keys[$int]}=$self->{conf}{$config}{$keys[$int]};
		}
			
		$int++;
	}

	return %returnKeys;
}

=head2 regexVarSearch

This searches through the variables in a loaded config for any that match
the supplied regex and returns a array of matches.

Two arguements are required. The first is the config to search. The second
is the regular expression to use.

	#removes any variable starting with the monkey
	my @matched = $zconf->regexVarSearch("foo/bar", "^monkey")
	if($zconf->error)){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#search variables based on a regex	
sub regexVarSearch{
	my ($self, $config, $regex) = @_;

	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{conf}{$config}});

	my @returnKeys=();

	my $int=0;
	while(defined($keys[$int])){
		if($keys[$int] =~ /$regex/){
			push(@returnKeys, $keys[$int]);
		}
			
		$int++;
	}

	return @returnKeys;
}

=head2 reread

This rereads the specified config file. This requires it to be already
loaded.

    $zconf->reread('some/config');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub reread{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#gets the set
	my $set=$self->getSet($config);
	if ($self->{error}) {
		$self->warn('getSet errored');
		return undef;
	}

	#reread it
	$self->read({config=>$config, set=>$set});
	if ($self->{error}) {
		$self->warn('read errored');
		return undef;
	}
	return 1;
}

=head2 setAutoupdate

This sets if a value for autoupdate.

It takes two optional arguements. The first is a
name for a config and second is a boolean value.

If a config name is not specified, it sets the
global value for it.

    #set the global auto update value to false
    $zconf->setAutoupdate(undef, '0');

    #sets it to true for 'some/config'
    $zconf->setAutoupdate('some/config', '1');

=cut

sub setAutoupdate{
	my $self=$_[0];
	my $config=$_[1];
	my $autoupdate=$_[2];

	$self->errorblank;

	if (!defined( $config )) {
		$self->{autoupdateGlobal}=$autoupdate;
	}

	$self->{autoupdate}{$config}=$autoupdate;

	return 1;
}

=head2 setComment

This sets a comment variable in a loaded config.

Four arguements are required. The first is the name of the config.
The second is the name of the variable. The third is the comment
variable. The fourth is the value.

	$zconf->setComment("foo/bar" , "somethingVar", "someComment", "eat more weazel\n\nor something"
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}


=cut

#sets a comment
sub setComment{
	my ($self, $config, $var, $comment, $value) = @_;

	#blank the any previous errors
	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#make sure the loaded config is not locked
	if (defined($self->{locked}{$config})) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	#return false if the config is not set
	if (!defined($comment)){
		$self->{error}=41;
		$self->{errorString}='No comment name defined';
		$self->warn;
		return undef;			
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#make sure the config name is legit
	($error, $errorString)=$self->varNameCheck($var);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#make sure the config name is legit
	($error, $errorString)=$self->varNameCheck($comment);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	if(!defined($self->{comment}{$config}{$var})){
		$self->{comment}{$config}{$var}={};
	}

	$self->{comment}{$config}{$var}{$comment}=$value;

	return 1;
}

=head2 setDefault

This sets the default set to use if one is not specified or choosen.

	my $returned = $zconf->setDefault("something")
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut
	
#sets the default set
sub setDefault{
	my ($self, $set)= @_;

	#blank any errors
	$self->errorblank;

	if($self->setNameLegit($set)){
		$self->{args}{default}=$set;
	}else{
		$self->{error}=27;
		$self->{errorString}="'".$set."' is not a legit set name.";
		$self->warn;
		return undef
	}

	return 1;
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
		if ($self->{error}) {
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

This unlocks or logs a config.

Two arguements are taken. The first is a
the config name, required, and the second is
if it should be locked or unlocked

    #lock 'some/config'
    $zconf->setLockConfig('some/config', 1);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

    #unlock 'some/config'
    $zconf->setLockConfig('some/config', 0);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

    #unlock 'some/config'
    $zconf->setLockConfig('some/config');
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
    if ($self->error) {
		warnSring('configExists errored');
		return undef;
	}
	if (!$exists) {
		$self->{error}=12;
		$self->{errorString}='The config, "'.$config.'", does not exist';
		$self->warn;
		return undef;
	}

	#reads the config
	my $returned=$self->{be}->setLockConfig($config, $lock);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
		return undef;
	}
	#sync to the file backend
	if ( defined( $self->{fbe} ) ) {
		$self->{fbe}->setLockConfig($config, $lock);
		if ($self->{fbe}->error) {
			$self->warnString('Failed to sync to the backend  error='.$self->{fbe}->error.' errorString='.$self->{fbe}->errorString);	
		}
	}

	return 1;
}

=head2 setMeta

This sets a meta variable in a loaded config.

Four arguements are required. The first is the name of the config.
The second is the name of the variable. The third is the meta
variable. The fourth is the value.

	$zconf->setMeta("foo/bar" , "somethingVar", "someComment", "eat more weazel\n\nor something"
	if($zconf->{error}){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}


=cut

#sets a comment
sub setMeta{
	my ($self, $config, $var, $meta, $value) = @_;

	#blank the any previous errors
	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1 });

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;
	}

	#make sure the loaded config is not locked
	if (defined($self->{locked}{$config})) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	#return false if the config is not set
	if (!defined($meta)){
		$self->{error}=41;
		$self->{errorString}='No comment name defined';
		$self->warn;
		return undef;			
	}

	#make sure the var name is legit
	my ($error, $errorString)=$self->varNameCheck($var);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#make sure the meta name is legit
	($error, $errorString)=$self->varNameCheck($meta);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->Warn;
		return undef;
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	if(!defined($self->{meta}{$config}{$var})){
		$self->{meta}{$config}{$var}={};
	}

	$self->{meta}{$config}{$var}{$meta}=$value;

	return 1;
}


=head2 setNameLegit

This checks if a setname is legit.

There is one required arguement, which is the set name.

The returned value is a perl boolean value.

	my $set="something";
	if(!$zconf->setNameLegit($set)){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#checks the setnames to make sure they are legit.
sub setNameLegit{
	my ($self, $set)= @_;

	$self->errorblank;

	if (!defined($set)){
		return undef;
	}

	#return false if it / is found
	if ($set =~ /\//){
		return undef;
	}
		
	#return undef if it begins with .
	if ($set =~ /^\./){
		return undef;
	}

	#return undef if it begins with " "
	if ($set =~ /^ /){
		return undef;
	}

	#return undef if it ends with " "
	if ($set =~ / $/){
		return undef;
	}

	#return undef if it contains ".."
	if ($set =~ /\.\./){
		return undef;
	}

	return 1;
}

=head2 setOverrideChooser

This will set the override chooser for a config.

If no chooser is specified for the loaded config

Two arguements are required. The first is the config
and th e second is the chooser string.

This method is basically a wrapper around setMeta.

    $zconf->setOverrideChooser($config, $chooser);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub setOverrideChooser{
	my $self=$_[0];
	my $config=$_[1];
	my $chooser=$_[2];

	#blank the any previous errors
	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#make sure the loaded config is not locked
	if (defined( $self->{locked}{ $config } )) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	#return false if the config is not set
	if (!defined($chooser)){
		$self->{error}=40;
		$self->{errorString}='$chooser not defined';
		$self->warn;
		return undef;			
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	#make sure the loaded config is not locked
	if (defined( $self->{locked}{ $config } )) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	if (!defined( $self->{meta}{$config}{zconf} )){
		$self->{meta}{$config}{zconf}={};
	}

	$self->{meta}{$config}{zconf}{'override/chooser'}=$chooser;

	return 1;
}

=head2 setVar

This sets a variable in a loaded config.

Three arguements are required. The first is the name of the config.
The second is the name of the variable. The third is the value.

	$zconf->setVar("foo/bar" , "something", "eat more weazel\n\nor something"
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}


=cut

#sets a variable
sub setVar{
	my ($self, $config, $var, $value) = @_;

	#blank the any previous errors
	$self->errorblank;

	#update if if needed
	$self->updateIfNeeded({config=>$config, clearerror=>1, autocheck=>1});

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#make sure the loaded config is not locked
	if (defined($self->{locked}{$config})) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->varNameCheck($var);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	if(!defined($var)){
		$self->{error}=18;
		$self->{errorString}="\$var is not defined.";
		$self->warn;
		return undef;
	}

	$self->{conf}{$config}{$var}=$value;

	#makes sure that the config var for it the meta info exists
	if (!defined( $self->{meta}{$config}{$var} )) {
		$self->{meta}{$config}{$var}={};
	}
	#set the mtime
	$self->{meta}{$config}{$var}{'mtime'}=time;
	#sets the ctime if needed
	if (!defined( $self->{meta}{$config}{$var}{'ctime'} )) {
		$self->{meta}{$config}{$var}{'ctime'}=time;
	}


	return 1;
}

=head2 unloadConfig

Unloads a specified configuration. The only required value is the
set name. The return value is a Perl boolean value.

    zconf->unloadConfig($config);
    if( $zconf->error )
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub unloadConfig{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	if (!defined($self->{conf}{$config})){
		$self->{error}=26;
		$self->{errorString}='The specified config, ".$config.", is not loaded';
		$self->warn;
		#even if it is not defined, check to see if this is defined and remove it
		if (defined($self->{set}{$config})){
			delete($self->{set}{$config});
		}
		return undef;
	}else {
		delete($self->{conf}{$config});
	}

	#removes the loaded set information
	if (defined($self->{set}{$config})){
		delete($self->{set}{$config});
	}

	#remove any lock info
	if (defined($self->{locked}{$config})) {
		delete($self->{locked}{$config});
	}

	#remove any meta info
	if (defined($self->{meta}{$config})) {
		delete($self->{meta}{$config});
	}

	#remove any comment info
	if (defined($self->{comment}{$config})) {
		delete($self->{comment}{$config});
	}

	#remove any revision info
	if (defined($self->{revision}{$config})) {
		delete($self->{revision}{$config});
	}

	return 1;
}

=head2 updatable

This checks if the loaded config on disk has a different revision ID than the 
saved one.

The return value is a boolean value. A value of true indicates the config has
been changed on the backend.

    my $updatable=$zconf->updatable('some/config');
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub updatable{
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

	#makes sure it is loaded
	if (! $self->isConfigLoaded($config) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$config."' is not loaded.";
		$self->warn;
		return undef;
	}

	my $backendRev=$self->getConfigRevision($config);
	if ($self->{error}) {
		$self->warnString('getConfigRevision failed');
		return undef;
	}

	#return false as if this is not defined, it means
	#that the config has no sets or has never been read
	#on a version of ZConf newer than 2.0.0
	if (!defined($backendRev)) {
		return undef;
	}

	#if we are here, it will no error so we don't check
	my $loadedRev=$self->getLoadedConfigRevision($config);

	if (!defined($loadedRev)) {
		$loadedRev='';
	}

	#they are not the same so a update is available
	if ($backendRev ne $loadedRev) {
		return 1;
	}

	#the are the same so no updates
	return undef;
}

=head2 updateIfNeeded

If a loaded config is updatable, reread it.

The returned value is a boolean value indicating
if it was updated or not. A value of true indicates
it was.

=head3 args hash

=head4 autocheck

This tells it to check getAutoupdate. If it returns false,
it will return.

=head4 clearerror

If $zconf->{error} is set, clear it. This is primarily
meant for being used internally.

=head4 config

This config to check.

This is required.

    my $updated=$zconf->updateIfNeeded({config=>'some/config'});
    if($zconf->{error}){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }
    if($updated){
        print "Updated!\n";
    }

=cut

sub updateIfNeeded{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	$self->errorblank;

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='No config specified';
		$self->warn;
		return undef;
	}

	#makes sure it is loaded
	if ( ! $self->isConfigLoaded( $args{config}) ) {
		$self->{error}=26;
		$self->{errorString}="Config '".$args{config}."' is not loaded.";
		$self->warn;
		return undef;
	}

	#checks the value for autoupdate
	if ($args{autocheck}) {
		my $autoupdate=$self->getAutoupdate($args{config});
		if(!$autoupdate){
			return undef;
		}
	}

	#check if it is updatable
	my $updatable=$self->updatable($args{config});
	if ($self->error) {
		$self->warn('updatable errored');
		return undef;
	}

	#not updatable
	if (!$updatable) {
		return undef;
	}

	#reread it
	$self->reread($args{config});
	if ($self->error) {
		$self->warnString('reread errored');
		#clear the error if needed
		if ($args{clearerror}) {
			$self->errorblank;
		}

		return undef;
	}

	return 1;
}

=head2 varNameCheck

This checks if a there if the specified variable name is a legit one or not.

	my ($error, $errorString) = $zconf->varNameCheck($config);
	if(defined($error)){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

sub varNameCheck{
        my ($self, $name) = @_;

		$self->errorblank;

		#makes sure it is defined
		if (!defined($name)) {
			return('10', 'variable name is not defined');
		}

        #checks for ,
        if($name =~ /,/){
                return("0", "variavble name,'".$name."', contains ','");
        }

        #checks for /.
        if($name =~ /\/\./){
                return("1", "variavble name,'".$name."', contains '/.'");
        }

        #checks for //
        if($name =~ /\/\//){
                return("2", "variavble name,'".$name."', contains '//'");
        }

        #checks for ../
        if($name =~ /\.\.\//){
                return("3", "variavble name,'".$name."', contains '../'");
        }

        #checks for /..
        if($name =~ /\/\.\./){
                return("4", "variavble name,'".$name."', contains '/..'");
        }

        #checks for ^./
        if($name =~ /^\.\//){
                return("5", "variavble name,'".$name."', matched /^\.\//");
        }

        #checks for /$
        if($name =~ /\/$/){
                return("6", "variavble name,'".$name."', matched /\/$/");
        }

        #checks for ^/
        if($name =~ /^\//){
                return("7", "variavble name,'".$name."', matched /^\//");
        }

        #checks for \\n
        if($name =~ /\n/){
                return("8", "variavble name,'".$name."', matched /\\n/");
        }

        #checks for =
        if($name =~ /=/){
                return("9", "variavble name,'".$name."', matched /=/");
        }

		return(undef, "");	
}

=head2 writeChooser

This writes a string into the chooser for a config.

There are two required arguements. The first is the
config name. The second is chooser string.

No error checking is done currently on the chooser string.

Setting this to '' or "\n" will disable the chooser fuction
and the default will be used when chooseSet is called.

	my $returned = $zconf->writeChooser("foo/bar", $chooserString)
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#the overarching read
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

	#return false if the config is not set
	if (!defined($chooserstring)){
		$self->{error}=40;
		$self->{errorString}='\$chooserstring not defined';
		$self->warn;
		return undef;			
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->configNameCheck($config);
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

	#checks if it is locked or not
	my $locked=$self->isConfigLocked($config);
	if ($self->{error}) {
		$self->warnString('isconfigLocked errored');
		return undef;
	}
	if ($locked) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	#writes the chooser
	my $returned=$self->{be}->writeChooser($config, $chooserstring);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
		return undef;
	}
	#sync to the file backend
	if ( defined( $self->{fbe} ) ) {
		$self->{fbe}->writeChooser($config, $chooserstring);
		if ($self->{fbe}->error) {
			$self->warnString('Failed to sync to the backend  error='.$self->{fbe}->error.' errorString='.$self->{fbe}->errorString);
		}
	}

	return 1;
}

=head2 writeSetFromHash

This takes a hash and writes it to a config. It takes two arguements,
both of which are hashes.

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

    $zconf->writeSetFromHash({config=>"foo/bar"}, \%hash);
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#the overarching writeSetFromHash
sub writeSetFromHash{
	my $self=$_[0];
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
	my ($error, $errorString)=$self->configNameCheck($args{config});
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
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
	if ($self->{error}) {
		$self->warnString('isconfigLocked errored');
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
		$args{set}=$self->{args}{default};
	}

	#update the revision if needed
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}

	#writes the chooser
	my $returned=$self->{be}->writeSetFromHash(\%args, \%hash);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
		return undef;
	}
	#sync to the file backend
	if ( defined( $self->{fbe} ) ) {
		$self->{fbe}->writeSetFromHash(\%args, \%hash);
		if ($self->{fbe}->error) {
			$self->warnString('Failed to sync to the backend  error='.$self->{fbe}->error.' errorString='.$self->{fbe}->errorString);
		}
	}

	return 1;
}

=head2 writeSetFromLoadedConfig

This method writes a loaded config to a to a set.

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

    $zconf->writeSetFromLoadedConfig({config=>"foo/bar"});
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#the overarching writeSetFromLoadedConfig
sub writeSetFromLoadedConfig{
	my $self=$_[0];
	my %args= %{$_[1]};

	$self->errorblank;

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	if(! $self->isConfigLoaded( $args{config} ) ){
		$self->{error}=25;
		$self->{errorString}="Config '".$args{config}."' is not loaded";
		$self->warn;
		return undef;
	}

	#checks if it is locked or not
	my $locked=$self->isConfigLocked($args{config});
	if ($self->{error}) {
		$self->warnString('isconfigLocked errored');
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
		if($self->setNameLegit($args{set})){
			$self->{args}{default}=$args{set};
		}else{
			$self->{error}=27;
			$self->{errorString}="'".$args{set}."' is not a legit set name.";
			$self->warn;
			return undef
		}
	}

	#update the revision if needed
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}

	#writes the chooser
	my $returned=$self->{be}->writeSetFromLoadedConfig(\%args);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
		return undef;
	}
	#sync to the file backend
	if ( defined( $self->{fbe} ) ) {
		$self->{fbe}->writeSetFromLoadedConfig(\%args);
		if ($self->{fbe}->error) {
			$self->warnString('Failed to sync to the backend  error='.$self->{fbe}->error.' errorString='.$self->{fbe}->errorString);
		}
	}

	return 1;
}

=head2 writeSetFromZML

This method writes a loaded config to a to a set.

One arguement is required.

=head2 args hash

=head3 config

The config to write it to.

This is required.

=head3 set

This is the set name to use.

If not defined, the one will be choosen.

=head3 zml

This is the ZML object to use.

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

#the overarching writeSetFromLoadedConfig
sub writeSetFromZML{
	my $self=$_[0];
	my %args= %{$_[1]};

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
		$self->{error}=16;
		$self->{errorString}='$args{zml} is not defined';
		$self->warn;
		return undef;
	}
	if ( ref($args{zml}) ne "ZML" ) {
		$self->{error}=16;
		$self->{errorString}='$args{zml} is not a ZML';
		$self->warn;
		return undef;
	}

	#checks if it is locked or not
	my $locked=$self->isConfigLocked($args{config});
	if ($self->{error}) {
		$self->warnString('isconfigLocked errored');
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
		if($self->setNameLegit($args{set})){
			$self->{args}{default}=$args{set};
		}else{
			$self->{error}=27;
			$self->{errorString}="'".$args{set}."' is not a legit set name.";
			$self->Warn;
			return undef
		}
	}

	#update the revision if needed
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}

	#writes the chooser
	my $returned=$self->{be}->writeSetFromZML(\%args);
	#if it errors and read fall through is turned on, try the file backend
	if ( $self->{be}->error ) {
		$self->{error}=11;
		$self->{errorString}='Backend errored. error="'.$self->{be}->error.'" errorString="'.$self->{be}->errorString.'"';
		$self->warn;
		return undef;
	}
	#sync to the file backend
	if ( defined( $self->{fbe} ) ) {
		$self->{fbe}->writeSetFromZML(\%args);
		if ($self->{fbe}->error) {
			$self->warnString('Failed to sync to the backend  error='.$self->{fbe}->error.' errorString='.$self->{fbe}->errorString);
		}
	}

	return 1;
}

=head1 CONFIG NAME

Any configuration name is legit as long as it does not match any of the following.

	undef
	/./
	/\/\./
	/\.\.\//
	/\/\//
	/\.\.\//
	/\/\.\./
	/^\.\//
	/\/$/
	/^\//
	/\n/

=head1 SET NAME

Any set name is legit as long as it does not match any of the following.

	undef
	/\//
	/^\./
	/^ /
	/ $/
	/\.\./

=head1 VARIABLE NAME

Any variable name is legit as long it does not match any of the following. This also
covers comments and meta variables.

	/,/
	/\/\./
	/\/\//
	\.\.\//
	/\/\.\./
	/^\.\//
	/\/$/	
	/^\//
	/\n/
	/=/

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

Backend errored.

=head2 12

config does not exist

=head2 13

Backend is not ZConf::backends::ldap.

=head2 14

The backend could not be found.

=head2 15

No backend specified.

=head2 16

ZML object not passed.

=head2 18

No variable name specified.

=head2 19

config key starts with a ' '

=head2 21

set not found for config

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

=head2 45

Config is locked.

=head2 46

LDAP entry update failed.

=head2 47

Failed to initialize the backend. It returned undef.

=head1 ERROR CHECKING

This can be done by checking $zconf->{error} to see if it is defined. If it is defined,
The number it contains is the corresponding error code. A description of the error can also
be found in $zconf->{errorString}, which is set to "" when there is no error.

=head1 zconf.zml

The default is 'xdf_config_home/zconf.zml', which is generally '~/.config/zconf.zml'. See perldoc
ZML for more information on the file format. The keys are listed below.

For information on the keys for the backends, please see perldoc for the backend in question.

The two included are 'file' and 'ldap'. See perldoc for 'ZConf::backends::file' and
'ZConf::backends::ldap' for their key values.

=head2 zconf.zml keys

=head3 backend

This is the backend to use for storage. Current values of 'file' and 'ldap' are supported.

=head3 backendChooser

This is a Chooser string that chooses what backend should be used.

=head3 defaultChooser

This is a chooser string that chooses what the name of the default to use should be.

=head3 fileonly

This is a boolean value. If it is set to 1, only the file backend is used.

This will override 'backend'.

=head2 readfallthrough

If this is set, if any of the methods below error when trying the any backend other than 'file'
, it will fall through to the file backend.

    configExists
    getAvailableSets
    getSubConfigs
    read
    readChooser

=head1 UTILITIES

There are several scripts installed with this module. Please see the perldocs for
the utilities listed below.

    zcchooser-edit
    zcchooser-get
    zcchooser-run
    zcchooser-set
    zccreate
    zcget
    zcls
    zcrm
    zcset
    zcvdel
    zcvls

=head1 Backend Requirements

Coming shortly.

This will be documented more shortly.

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
