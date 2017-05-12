package ZConf::backends::ldap;

use Net::LDAP;
use Net::LDAP::LDAPhash;
use Net::LDAP::Makepath;
use Chooser;
use warnings;
use strict;
use ZML;
use Sys::Hostname;
use Net::LDAP::AutoDNs;
use Net::LDAP::AutoServer;
use base 'Error::Helper';

=head1 NAME

ZConf::backends::ldap - This provides LDAP backend for ZConf.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 METHODS

=head2 new

	my $zconf=ZConf->(\%args);

This initiates the ZConf object. If it can't be initiated, a value of undef
is returned. The hash can contain various initization options.

When it is run for the first time, it creates a filesystem only config file.

=head3 args hash

=head4 sys

This turns system mode on. And sets it to the specified system name.

This is incompatible with the file option.

=head4 self

This is the copy of the ZConf object intiating it.

=head4 zconf

This is the variables found in the ~/.config/zconf.zml.

    my $backend=ZConf::backends::ldap->new( \%args );
    if($zconf->{error}){
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

	#if defaultChooser is defined, use it to find what the default should be
	if(defined($self->{zconf}{defaultChooser})){
		#runs choose if it is defined
		my ($success, $choosen)=choose($self->{zconf}{defaultChooser});
		if($success){
			#check if the choosen has a legit name
			#if it does not, set it to default
			if($self->{self}->setNameLegit($choosen)){
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

	#figures out what profile to use
	if (defined($self->{zconf}{LDAPprofileChooser})) {
		#run the chooser to get the LDAP profile to use
		my ($success, $choosen)=choose($self->{zconf}{LDAPprofileChooser});
		#if the chooser fails, set the profile to default
		if (!$success) {
			$self->{args}{LDAPprofile}="default";
		} else {
			$self->{args}{LDAPprofile}=$choosen;
		}
	} else {
		#if LDAPprofile is defined, use it, if not set it to default
		if (defined($self->{zconf}{LDAPprofile})) {
			$self->{args}{LDAPprofile}=$self->{zconf}{LDAPprofile};
		} else {
			$self->{args}{LDAPprofile}="default";
		}
	}

	#will be used for auto population
	my $autoDNs=Net::LDAP::AutoDNs->new;
	my $autoserver=Net::LDAP::AutoServer->new;

	#gets the host
	if(defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/host"})){
		$self->{args}{"ldap/host"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/host"};
	}else{
		#sets it to localhost if not defined
		if (defined( $autoserver->{server} )) {
			$self->{args}{'ldap/host'}=$autoserver->{server};
		}else {
			$self->{args}{'ldap/host'}='127.0.0.1';
		}
	}
	
	#gets the capath
	if(defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/capath"})){
		$self->{args}{"ldap/capath"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/capath"};
	}else{
		#sets it to localhost if not defined
		if (defined( $autoserver->{CApath} )) {
			$self->{args}{"ldap/capath"}=$autoserver->{CApath};
		}else {
			$self->{args}{"ldap/capath"}=undef;
		}
	}
	
	#gets the cafile
	if(defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/cafile"})){
		$self->{args}{"ldap/cafile"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/cafile"};
	}else{
		#sets it to localhost if not defined
		if (defined( $autoserver->{CAfile} )) {
			$self->{args}{"ldap/cafile"}=$autoserver->{CAfile};
		}else {
			$self->{args}{"ldap/cafile"}=undef;
		}
	}
	
	#gets the checkcrl
	if(defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/checkcrl"})){
		$self->{args}{"ldap/checkcrl"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/checkcrl"};
	}else{
		#sets it to localhost if not defined
		if (defined( $autoserver->{checkCRL} )) {
			$self->{args}{"ldap/checkcrl"}=$autoserver->{checkCRL};
		}else {
			$self->{args}{"ldap/checkcrl"}=undef;
		}
	}
	
	#gets the clientcert
	if(defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/clientcert"})){
		$self->{args}{"ldap/clientcert"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/clientcert"};
	}else{
		#sets it to localhost if not defined
		if (defined( $autoserver->{clientCert} )) {
			$self->{args}{"ldap/clientcert"}=$autoserver->{clientCert};
		}else {
			$self->{args}{"ldap/clientcert"}=undef;
		}
	}

	#gets the clientkey
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/clientkey"})) {
		$self->{args}{"ldap/clientkey"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/clientkey"};
	} else {
		#sets it to localhost if not defined
		if (defined( $autoserver->{clientKey} )) {
			$self->{args}{"ldap/clientkey"}=$autoserver->{clientKey};
		} else {
			$self->{args}{"ldap/clientkey"}=undef;
		}
	}

	#gets the starttls
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/starttls"})) {
		$self->{args}{"ldap/starttls"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/starttls"};
	} else {
		#sets it to localhost if not defined
		if (defined( $autoserver->{startTLS} )) {
			$self->{args}{"ldap/starttls"}=$autoserver->{startTLS};
		} else {
			$self->{args}{"ldap/starttls"}=undef;
		}
	}

	#gets the TLSverify
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/TLSverify"})) {
		$self->{args}{"ldap/TLSverify"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/TLSverify"};
	} else {
		#sets it to localhost if not defined
		$self->{args}{"ldap/TLSverify"}='none';
	}

	#gets the SSL version to use
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/SSLversion"})) {
		$self->{args}{"ldap/SSLversion"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/SSLversion"};
	} else {
		#sets it to localhost if not defined
		$self->{args}{"ldap/SSLversion"}='tlsv1';
	}

	#gets the SSL ciphers to use
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/SSLciphers"})) {
		$self->{args}{"ldap/SSLciphers"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/SSLciphers"};
	} else {
		#sets it to localhost if not defined
		$self->{args}{"ldap/SSLciphers"}='ALL';
	}

	#gets the password value to use
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/password"})) {
		$self->{args}{"ldap/password"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/password"};
	} else {
		#sets it to localhost if not defined
		if (defined( $autoserver->{pass} )) {
			$self->{args}{"ldap/password"}=$autoserver->{pass};
		} else {
			$self->{args}{"ldap/password"}="";
		}
	}

	#gets the password value to use
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/passwordfile"})) {
		$self->{args}{"ldap/passwordfile"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/passwordfile"};
		if (open( PASSWORDFILE,  $self->{args}{"ldap/passwordfile"} )) {
			$self->{args}{"ldap/password"}=join( "\n", <PASSWORDFILE> );
			close(PASSWORDFILE);
		} else {
			$self->warnString('Failed to open the password file, "'.
				 $self->{args}{"ldap/passwordfile"}.'",');
		}
	}

	#gets the home DN
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/homeDN"})) {
		$self->{args}{"ldap/homeDN"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/homeDN"};
	} else {
		if (defined( $autoDNs->{home} )) {
			$self->{args}{"ldap/homeDN"}='ou='.$ENV{USER}.','.$autoDNs->{home};
		} else {
			$self->{args}{"ldap/homeDN"}=`hostname`;
			chomp($self->{args}{"ldap/bind"});
			#the next three lines can result in double comas.
			$self->{args}{"ldap/homeDN"}=~s/^.*\././ ;
			$self->{args}{"ldap/homeDN"}=~s/\./,dc=/g ;
			$self->{args}{"ldap/homeDN"}="ou=".$ENV{USER}.",ou=home,".$self->{args}{"ldap/bind"};
			#remove any double comas if they crop up
			$self->{args}{"ldap/homeDN"}=~s/,,/,/g;
		}
	}

	#get the LDAP base
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/base"})) {
		$self->{args}{"ldap/base"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/base"};
	}else {
		$self->{args}{"ldap/base"}="ou=zconf,ou=.config,".$self->{args}{"ldap/homeDN"};
	}

	#gets bind to use
	if (defined($self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/bind"})) {
		$self->{args}{"ldap/bind"}=$self->{zconf}{"ldap/".$self->{args}{LDAPprofile}."/bind"};
	} else {
		if (defined( $autoserver->{bind} )) {
			$self->{args}{"ldap/bind"}=$autoserver->{bind};
		} else {
			$self->{args}{"ldap/bind"}=hostname;
			chomp($self->{args}{"ldap/bind"});
			#the next three lines can result in double comas.
			$self->{args}{"ldap/bind"}=~s/^[0-9a-zA-Z\-\_]*\././ ;
			$self->{args}{"ldap/bind"}=~s/\./,dc=/g ;
			$self->{args}{"ldap/bind"}="uid=".$ENV{USER}.",ou=users,".$self->{args}{"ldap/bind"};
			#remove any double comas if they crop up
			$self->{args}{"ldap/bind"}=~s/,,/,/g;
		}
	
		#tests the connection
		my $ldap=$self->LDAPconnect;
		if ($self->error) {
			$self->warnString('LDAPconnect errored');
			return $self;
		}
	
		#tests if "ou=.config,".$self->{args}{"ldap/homeDN"} exists or nnot...
		#if it does not, try to create it...
		my $ldapmesg=$ldap->search(scope=>"base", base=>"ou=.config,".$self->{args}{"ldap/homeDN"},
								   filter => "(objectClass=*)");
		my %hashedmesg=LDAPhash($ldapmesg);
		if (!defined($hashedmesg{"ou=.config,".$self->{args}{"ldap/homeDN"}})) {
			my $entry = Net::LDAP::Entry->new();
			$entry->dn("ou=.config,".$self->{args}{"ldap/homeDN"});
			$entry->add(objectClass => [ "top", "organizationalUnit" ], ou=>".config");
			my $result = $ldap->update($entry);
			if ($ldap->error()) {
				$self->{error}=16;
				$self->{errorString}="Unable to create one of the required entries for initializing this backend.  error: ".$self->{args}{"ldap/base"}." ".$ldap->error."; code ",$ldap->errcode;
				$self->warn;
				return $self;
			}
		}
	
		#tests if "ldap/base" exists... try to create it if it does not
		$ldapmesg=$ldap->search(scope=>"base", base=>$self->{args}{"ldap/base"},filter => "(objectClass=*)");
		%hashedmesg=LDAPhash($ldapmesg);
		if (!defined($hashedmesg{$self->{args}{"ldap/base"}})) {
			my $entry = Net::LDAP::Entry->new();
			$entry->dn($self->{args}{"ldap/base"});
			$entry->add(objectClass => [ "top", "organizationalUnit" ], ou=>"zconf");
			my $result = $ldap->update($entry);
			if ($ldap->error()) {
				$self->{error}=16;
				$self->{errorString}="Unable to create one of the required entries for initializing this backend.  error: ".$self->{args}{"ldap/base"}." ".$ldap->error."; code ",$ldap->errcode;
				$self->warn;
				return $self;
			}
		}
	
		#disconnects from the LDAP server
		$ldap->unbind;
	}

	return $self;
}

=head2 config2dn

This method converts the config name into part of a DN string. IT
is largely only for internal use and is used by the LDAP backend.

	my $partialDN = $zconf->config2dn("foo/bar");
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

#converts the config to a DN
sub config2dn(){
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

	if ($config eq '') {
		return '';
	}

	my ($error, $errorString)=$self->{self}->configNameCheck($config);
	if(defined($error)){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#splits the config at every /
	my @configSplit=split(/\//, $config);

	my $dn=undef; #stores the DN

	my $int=0; #used for intering through @configSplit
	#does the conversion
	while(defined($configSplit[$int])){
		if(defined($dn)){
			$dn="cn=".$configSplit[$int].",".$dn;
		}else{
			$dn="cn=".$configSplit[$int];
		}
			
		$int++;
	}
		
	return $dn;
}

=head2 configExists

This method methods exactly the same as configExists, but
for the LDAP backend.

No config name checking is done to verify if it is a legit name or not
as that is done in configExists. The same is true for calling errorBlank.

    $zconf->configExistsLDAP("foo/bar")
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#check if a LDAP config exists
sub configExists{
	my ($self, $config) = @_;

	$self->errorblank;

	my @lastitemA=split(/\//, $config);
	my $lastitem=$lastitemA[$#lastitemA];

	#gets the LDAP message
	my $ldapmesg=$self->LDAPgetConfMessage($config);
	#return upon error
	if (defined($self->{error})) {
		return undef;
	}

	my %hashedmesg=LDAPhash($ldapmesg);
#	$ldap->unbind;
	my $dn=$self->config2dn($config);
	$dn=$dn.",".$self->{args}{"ldap/base"};

	if(!defined($hashedmesg{$dn})){
		return undef;
	}

	return 1;
}

=head2 createConfig

This methods just like createConfig, but is for the LDAP backend.
This is not really meant for external use. The config name passed
is not checked to see if it is legit or not.

    $zconf->createConfigLDAP("foo/bar")
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	};

=cut

#creates a new LDAP enty if it is not defined
sub createConfig{
	my ($self, $config) = @_;

	$self->errorblank;

	#converts the config name to a DN
	my $dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};

	my @lastitemA=split(/\//, $config);
	my $lastitem=$lastitemA[$#lastitemA];

	#connects up to LDAP
	my $ldap=$self->LDAPconnect();
	if ($self->error) {
		$self->warnString('LDAPconnect errored');
		return undef;
	}

	#gets the LDAP message
	my $ldapmesg=$self->LDAPgetConfMessage($config, $ldap);
	#return upon error
	if (defined($self->error)) {
		$self->warnString('LDAPgetConfMessage errored');
		return undef;
	}

	my %hashedmesg=LDAPhash($ldapmesg);
	if(!defined($hashedmesg{$dn})){
		my $path=$config; #used with for with LDAPmakepathSimple
		$path=~s/\//,/g; #converts the / into , as required by LDAPmakepathSimple
		my $returned=LDAPmakepathSimple($ldap, ["top", "zconf"], "cn",
					$path, $self->{args}{"ldap/base"});
		if(!$returned){
			$self->{errorString}="zconf createLDAPConfig:22: Adding '".$dn."' failed when executing LDAPmakepathSimple.\n";
			$self->{error}=22;
			$self->warn;
			return undef;
		}
	}else{
		$self->{error}=11;
		$self->{errorString}=" DN '".$dn."' already exists.";
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
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub delConfig{
	my $self=$_[0];
	my $config=$_[1];

	$self->errorblank;

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
	if (defined($self->{error})){
		$self->{error}='12';
		$self->{errorString}='The config, "'.$config.'", does not exist';
		$self->warn;
		return undef;
	}

	#connects up to LDAP... will be used later
	my $ldap=$self->LDAPconnect;
	
	#gets the DN and use $ldap since it is already setup
	my $entry=$self->LDAPgetConfEntry($config, $ldap);

	#if $entry is undefined, it was not found
	if (!defined($entry)){
		$self->{error}='13';
		$self->{errorString}='The expected DN was not found';
		$self->warn;
		return undef;
	}

	#remove it
	$entry->delete();
	my $results=$entry->update($ldap);

	#return if it could not be removed
	if($results->is_error){
		$self->{error}='34';
		$self->{errorString}=' Could not delete the LDAP entry, "'.
							$entry->dn.'". LDAP return an error of "'.$results->is_error.
							'" and an error code of "'.$ldap->errcode.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 delSet

This deletes a specified set, for the LDAP backend.

Two arguements are required. The first one is the name of the config and the and
the second is the name of the set.

    $zconf->delSet("foo/bar", "someset");
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }


=cut

sub delSet{
	my $self=$_[0];
	my $config=$_[1];
	my $set=$_[2];

	$self->errorblank;

	#return if no config is given
	if (!defined($config)){
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;
	}

	#creates the DN from the config
	my $dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};

	#connects up to LDAP
	my $ldap=$self->LDAPconnect();
	if (defined($self->{error})) {
		$self->warnString('LDAPconnect errored');
		return undef;
	}

	#gets the entry
	my $entry=$self->LDAPgetConfEntry($config, $ldap);
	#return upon error
	if ($self->error) {
		$self->warnString('LDAPgetConfEntry errored');
		return undef;
	}

	if(!defined($entry->dn)){
		$self->{error}=13;
		$self->{errorString}="Expected DN, '".$dn."' not found.";
		$self->warn;
		return undef;
	}else{
		if($entry->dn ne $dn){
			$self->{error}=13;
			$self->{errorString}="Expected DN, '".$dn."' not found.";
			$self->warn;
			return undef;
		}
	}
		
	#makes sure the zconfSet attribute is set for the config in question
	my @attributes=$entry->get_value('zconfSet');
	#if the 0th is not defined, it means this config does not have any sets or it is wrong
	if(defined($attributes[0])){
		#if $attributes dues contain enteries, make sure that one of them is the proper set
		my $attributesInt=0;
		my $setFound=0;#set to one if the loop finds the set
		while(defined($attributes[$attributesInt])){
			if($attributes[$attributesInt] eq $set){
				$setFound=1;
				$entry->delete(zconfSet=>[$attributes[$attributesInt]]);
			}
			$attributesInt++;
		}
	}

	#
	@attributes=$entry->get_value('zconfData');
	#if the 0th is not defined, it means there are no sets
	if(defined($attributes[0])){
		#if $attributes dues contain enteries, make sure that one of them is the proper set
		my $attributesInt=0;
		my $setFound=undef;#set to one if the loop finds the set
		while(defined($attributes[$attributesInt])){
			if($attributes[$attributesInt] =~ /^$set\n/){
				$setFound=1;
				$entry->delete(zconfData=>[$attributes[$attributesInt]]);
			};
			$attributesInt++;
		};
		#if the config is not found, add it
		if(!$setFound){
			$self->{error}=31;
			$self->{errorString}='The specified set, "'.$set.'" was not found for "'.$config.'".';
			$self->warn;
			return undef;
		}
	}else{
		$self->{error}=30;
		$self->{errorString}='No zconfData attributes exist for "'.$dn.'" and thus no sets exist.';
		$self->warn;
		return undef;
	}

	#write the entry to LDAP
	my $results=$entry->update($ldap);

	return 1;
}

=head2 getAvailableSets

This is exactly the same as getAvailableSets, but for the file back end.
For the most part it is not intended to be called directly.

	my @sets = $zconf->getAvailableSetsLDAP("foo/bar");
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

sub getAvailableSets{
	my ($self, $config) = @_;

	$self->errorblank;

	#converts the config name to a DN
	my $dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};

	#gets the message
	my $ldapmesg=$self->LDAPgetConfMessage($config);
	#return upon error
	if ($self->error) {
		$self->warnString('LDAPgetConfMessage errored');
		return undef;
	}

	my %hashedmesg=LDAPhash($ldapmesg);
	if(!defined($hashedmesg{$dn})){
		$self->{error}=13;
		$self->{errorString}="Expected DN, '".$dn."' not found.";
		$self->warn;
		return undef;
	}
		
	my $setint=0;
	my @sets=();
	while(defined($hashedmesg{$dn}{ldap}{zconfSet}[$setint])){
		$sets[$setint]=$hashedmesg{$dn}{ldap}{zconfSet}[$setint];
		$setint++;
	}
		
	return @sets;
}

=head2 getConfigRevision

This fetches the revision for the speified config using
the LDAP backend.

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

	#gets the LDAP entry
	my $entry=$self->LDAPgetConfEntry($config);
	#return upon error
	if ($self->error) {
		$self->warnString('LDAPgetConfEntry errored');
		return undef;
	}

	#gets the revisions
	my @revs=$entry->get_value('zconfLock');
	if (!defined($revs[0])) {
		return undef;
	}

	return $revs[0];
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

	my $dn;
	#converts the config name to a DN
	if ($config eq "") {
		#this is done as using config2dn results in an error
		$dn=$self->{args}{"ldap/base"};
	}else{
		$dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};
	}

	#gets the message
	my $ldapmesg=$self->LDAPgetConfMessageOne($config);
	#return upon error
	if (defined($self->{error})) {
		return undef;
	}

	my %hashedmesg=LDAPhash($ldapmesg);

	#
	my @keys=keys(%hashedmesg);

	#holds the returned sets
	my @sets;

	my $keysInt=0;
	while ($keys[$keysInt]){
		#only process ones that start with 'cn='
		if ($keys[$keysInt] =~ /^cn=/) {
			#remove the begining config DN chunk
			$keys[$keysInt]=~s/,$dn$//;
			#removes the cn= at the begining
			$keys[$keysInt]=~s/^cn=//;
			#push the processed key onto @sets
			push(@sets, $keys[$keysInt]);
	    }
		
		$keysInt++;
	}

	return @sets;
}

=head2 isConfigLocked

This checks if a config is locked or not for the LDAP backend.

One arguement is required and it is the name of the config.

The returned value is a boolean value.

    my $locked=$zconf->isConfigLockedLDAP('some/config');
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

	my $entry=$self->LDAPgetConfEntry($config);
	#return upon error
	if ($self->error) {
		$self->warnString('LDAPgetConfEntry errored');
		return undef;
	}

	#check if it is locked or not
	my @locks=$entry->get_value('zconfLock');
	if (defined($locks[0])) {
		#it is locked
		return 1;
	}

	#it is not locked
	return undef;
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

	#connects up to LDAP
	my $ldap=Net::LDAP->new(
							$self->{args}{"ldap/host"},
							port=>$self->{args}{"ldap/port"},
							);

	#make sure we connected
	if (!$ldap) {
		$self->{error}=1;
		$self->{errorString}='Failed to connect to LDAP';
		$self->warn;
		return undef;
	}

	#start tls stuff if needed
	my $mesg;
	if ($self->{args}{"ldap/starttls"}) {
		$mesg=$ldap->start_tls(
							   verify=>$self->{args}{'larc/TLSverify'},
							   sslversion=>$self->{args}{'ldap/SSLversion'},
							   ciphers=>$self->{args}{'ldap/SSLciphers'},
							   cafile=>$self->{args}{'ldap/cafile'},
							   capath=>$self->{args}{'ldap/capath'},
							   checkcrl=>$self->{args}{'ldap/checkcrl'},
							   clientcert=>$self->{args}{'ldap/clientcert'},
							   clientkey=>$self->{args}{'ldap/clientkey'},
							   );

		if (!$mesg->{errorMessage} eq '') {
			$self->{error}=1;
			$self->{errorString}='$ldap->start_tls failed. $mesg->{errorMessage}="'.
			                     $mesg->{errorMessage}.'"';
			$self->warn;
			return undef;
		}
	}

	#bind
	$mesg=$ldap->bind($self->{args}{"ldap/bind"},
					  password=>$self->{args}{"ldap/password"},
					  );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=13;
		$self->{errorString}='Binding to the LDAP server failed. $mesg->{errorMessage}="'.
		                     $mesg->{errorMessage}.'"';
		$self->warn;
		return undef;
	}

	return $ldap;
}

=head2 LDAPgetConfMessage

Gets a Net::LDAP::Message object that was created doing a search for the config with
the scope set to base.

    #gets it for 'foo/bar'
    my $mesg=$zconf->LDAPgetConfMessage('foo/bar');
    #gets it using $ldap for the connection
    my $mesg=$zconf->LDAPgetConfMessage('foo/bar', $ldap);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub LDAPgetConfMessage{
	my $self=$_[0];
	my $config=$_[1];
	my $ldap=$_[2];

	$self->errorblank;

	#only connect to LDAP if needed
	if (!defined($ldap)) {
		#connects up to LDAP
		$ldap=$self->LDAPconnect;
		#return upon error
		if (defined($self->{error})) {
			return undef;
		}
	}

	#creates the DN from the config
	my $dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};

	#gets the message
	my $ldapmesg=$ldap->search(scope=>"base", base=>$dn,filter => "(objectClass=*)");

	return $ldapmesg;
}

=head2 LDAPgetConfMessageOne

Gets a Net::LDAP::Message object that was created doing a search for the config with
the scope set to one.

    #gets it for 'foo/bar'
    my $mesg=$zconf->LDAPgetConfMessageOne('foo/bar');
    #gets it using $ldap for the connection
    my $mesg=$zconf->LDAPgetConfMessageOne('foo/bar', $ldap);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub LDAPgetConfMessageOne{
	my $self=$_[0];
	my $config=$_[1];
	my $ldap=$_[2];

	$self->errorblank;

	#only connect to LDAP if needed
	if (!defined($ldap)) {
		#connects up to LDAP
		$ldap=$self->LDAPconnect;
		#return upon error
		if ($self->error) {
			$self->warnString('LDAPconnect errored');
			return undef;
		}
	}

	#creates the DN from the config
	my $dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};

	$dn =~ s/^,//;

	#gets the message
	my $ldapmesg=$ldap->search(scope=>"one", base=>$dn,filter => "(objectClass=*)");

	return $ldapmesg;
}

=head2 LDAPgetConfEntry

Gets a Net::LDAP::Message object that was created doing a search for the config with
the scope set to base.

It returns undef if it is not found.

    #gets it for 'foo/bar'
    my $entry=$zconf->LDAPgetConfEntry('foo/bar');
    #gets it using $ldap for the connection
    my $entry=$zconf->LDAPgetConfEntry('foo/bar', $ldap);
    if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub LDAPgetConfEntry{
	my $self=$_[0];
	my $config=$_[1];
	my $ldap=$_[2];

	$self->errorblank;

	#only connect to LDAP if needed
	if (!defined($ldap)) {
		#connects up to LDAP
		$ldap=$self->LDAPconnect;
		#return upon error
		if (defined($self->{error})) {
			return undef;
		}
	}

	#creates the DN from the config
	my $dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};

	#gets the message
	my $ldapmesg=$ldap->search(scope=>"base", base=>$dn,filter => "(objectClass=*)");
	my $entry=$ldapmesg->entry;

	return $entry;
}

=head2 read

readFile methods just like read, but is mainly intended for internal use
only. This reads the config from the LDAP backend.

=head3 hash args

=head4 config

The config to load.

=head4 override

This specifies if override should be ran not.

If this is not specified, it defaults to 1, true.

=head4 set

The set for that config to load.

    $zconf->readLDAP({config=>"foo/bar"})
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

	#creates the DN from the config
	my $dn=$self->config2dn($args{config}).",".$self->{args}{"ldap/base"};

	#gets the LDAP entry
	my $entry=$self->LDAPgetConfEntry($args{config});
	#return upon error
	if ($self->error) {
		$self->warnString('LDAPgetConfEntry errored');
		return undef;
	}

	if(!defined($entry->dn())){
		$self->{error}=13;
		$self->{errorString}="Expected DN, '".$dn."' not found";
		$self->warn;
		return undef;
	}else{
		if($entry->dn ne $dn){
			$self->{error}=13;
			$self->{errorString}="Expected DN, '".$dn."' not found";
			$self->warn;
			return undef;			
		}
	}

	my @attributes=$entry->get_value('zconfData');
	my $data=undef;#unset from undef if matched
	if(defined($attributes[0])){
		#if @attributes has entries, go through them looking for a match
		my $attributesInt=0;
		my $setFound=undef;#set to one if the loop finds the set
		while(defined($attributes[$attributesInt])){
			if($attributes[$attributesInt] =~ /^$args{set}\n/){
				#if a match is found, save it to data for continued processing
				$data=$attributes[$attributesInt];
			};
			$attributesInt++;
		}
	}else{
		#If we end up here, it means it is a bad LDAP enty
		$self->{error}=13;
		$self->{errorString}="No zconfData entry found in '".$dn."'";
		$self->warn;
		return undef;	
	}

	#error out if $data is undefined
	if(!defined($data)){
		$self->{error}=13;
		$self->{errorString}="No matching sets found in '".$args{config}."'";
		$self->warn;
		return undef;	
	}

	#removes the firstline from the data
	$data=~s/^$args{set}\n//;
	
	#parse the ZML stuff
	my $zml=ZML->new;
	$zml->parse($data);
	if ($zml->{error}) {
		$self->{error}=28;
		$self->{errorString}='$zml->parse errored. $zml->{error}="'.$zml->{error}.'" '.
		                     '$zml->{errorString}="'.$zml->{errorString}.'"';
		$self->warn;
		return undef;
	}
	$self->{self}->{conf}{$args{config}}=\%{$zml->{var}};
	$self->{self}->{meta}{$args{config}}=\%{$zml->{meta}};
	$self->{self}->{comment}{$args{config}}=\%{$zml->{comment}};

	#sets the loaded config
	$self->{self}->{set}{$args{config}}=$args{set};

	#gets the revisions
	my @revs=$entry->get_value('zconfRev');
	if (!defined($revs[0])) {
		my $revision=time.' '.hostname.' '.rand();
		$self->{revision}{$args{config}}=$revision;
		$entry->add(zconfRev=>[$revision]);

		#connects to LDAP
		my $ldap=$self->LDAPconnect();
		if ($self->error) {
			$self->warnString('LDAPconnect failed for the purpose of updating');
			return $self->{revision}{$args{config}};
		}

		$entry->update($ldap);
	}else {
		$self->{revision}{$args{config}}=$revs[0];
	}

	#checks if it is locked or not and save it
	my $locked=$self->isConfigLocked($args{config});
	if ($locked) {
		$self->{self}->{locked}{$args{config}}=1;
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

This methods just like readChooser, but methods on the LDAP backend
and only really intended for internal use.

	my $chooser = $zconf->readChooserLDAP("foo/bar");
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#this gets the chooser for a the config... for the file backend
sub readChooser{
	my ($self, $config)= @_;

	$self->errorblank;

	#return false if the config is not set
	if (!defined($config)) {
		$self->{error}=25;
		$self->{errorString}='$config not defined';
		$self->warn;
		return undef;			
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->{self}->configNameCheck($config);
	if ($error) {
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#checks to make sure the config does exist
	if (!$self->configExists($config)) {
		$self->{error}=12;
		$self->{errorString}="'".$config."' does not exist.";
		$self->warn;
		return undef;			
	}

	#creates the DN from the config
	my $dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};

	#gets the LDAP mesg
	my $ldapmesg=$self->LDAPgetConfMessage($config);
	#return upon error
	if ($self->error) {
		return undef;
	}

	my %hashedmesg=LDAPhash($ldapmesg);
	if (!defined($hashedmesg{$dn})) {
		$self->{error}=13;
		$self->{errorString}="Expected DN, '".$dn."' not found.";
		$self->warn;
		return undef;
	}

	if (defined($hashedmesg{$dn}{ldap}{zconfChooser}[0])) {
		return($hashedmesg{$dn}{ldap}{zconfChooser}[0]);
	} else {
		return("");
	}
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
	if ($self->error) {
		$self->warnString('getAvailableSets errored');
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

This unlocks or logs a config for the LDAP backend.

Two arguements are taken. The first is a
the config name, required, and the second is
if it should be locked or unlocked

    #lock 'some/config'
    $zconf->setLockConfigLDAP('some/config', 1);
    if($zconf->{error}){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

    #unlock 'some/config'
    $zconf->setLockConfigLDAP('some/config', 0);
    if($zconf->{error}){
		warn('error: '.$zconf->error.":".$zconf->errorString);
    }

    #unlock 'some/config'
    $zconf->setLockConfigLDAP('some/config');
    if($zconf->{error}){
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
		$self->warnString('configExists errored');
		return undef;
	}
	if (!$exists) {
		$self->{error}=12;
		$self->{errorString}='The config, "'.$config.'", does not exist';
		$self->warn;
		return undef;
	}

	my $entry=$self->LDAPgetConfEntry($config);
	#return upon error
	if ($self->error) {
		$self->warnString('LDAPgetConfEntry errored');
		return undef;
	}

	#adds a lock
	if ($lock) {
		$entry->add(zconfLock=>[time."\n".hostname]);
	}

	#removes a lock
	if (!$lock) {
		$entry->delete('zconfLock');
	}
	
	#connects to LDAP
	my $ldap=$self->LDAPconnect;
	if ($self->{error}) {
		$self->warnString('LDAPconnect errored... returning...');
		return undef;
	}

	$entry->update($ldap);

	return 1;
}

=head2 writeChooser

This method is a internal method and largely meant to only be called
writeChooser, which it methods the same as. It works on the LDAP backend.

    $zconf->writeChooserLDAP("foo/bar", $chooserString)
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

	#return false if the config is not set
	if (!defined($chooserstring)){
		$self->{error}=40;
		$self->{errorString}='\$chooserstring not defined';
		$self->warn;
		return undef;
	}

	#make sure the config name is legit
	my ($error, $errorString)=$self->{self}->configNameCheck($config);
	if($error){
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
	if ($self->error) {
		$self->warnString('isconfigLockedLDAP errored');
		return undef;
	}
	if ($locked) {
		$self->{error}=45;
		$self->{errorString}='The config "'.$config.'" is locked';
		$self->warn;
		return undef;
	}

	#creates the DN from the config
	my $dn=$self->config2dn($config).",".$self->{args}{"ldap/base"};

	#connects to LDAP
	my $ldap=$self->LDAPconnect;
	if ($self->error) {
		$self->warnString('LDAPconnect errored... returning...');
		return undef;
	}

	#gets the LDAP entry
	my $entry=$self->LDAPgetConfEntry($config, $ldap);
	#return upon error
	if ($self->error) {
		return undef;
	}

	if(!defined($entry->dn)){
		$self->{error}=13;
		$self->{errorString}="Expected DN, '".$dn."' not found.";
		$self->warn;
		return undef;
	}else{
		if($entry->dn ne $dn){
			$self->{error}=13;
			$self->{errorString}="Expected DN, '".$dn."' not found.";
			$self->warn;
			return undef;				
		}
	}

	#replace the zconfChooser entry and updated it
	$entry->replace(zconfChooser=>$chooserstring);
	$entry->update($ldap);

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

    $zconf->writeSetFromHashLDAP({config=>"foo/bar"}, \%hash);
	if($zconf->error){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#write out a config from a hash to the LDAP backend
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
	if($error){
		$self->{error}=$error;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#sets the set to default if it is not defined
	if (!defined($args{set})){
		$args{set}=$self->chooseSet($args{set});
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
		$self->warnString('isConfigLocked errored');
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
		$args{set}="default";
	}
		
	#sets the set to default if it is not defined
	if (!defined($args{autoCreateConfig})){
		$args{autoCreateConfig}="0";
	}

	#update the revision if needed
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}

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
					if($zml->error){
						$self->warnString(':23: $zml->addMeta() returned '.
							 $zml->error.", '".$zml->errorString."'. Skipping variable '".
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
					if($zml->error){
						$self->warnString(':23: $zml->addComment() returned '.
							 $zml->error.", '".$zml->errorString."'. Skipping variable '".
							 $hashkeys[$hashkeysInt]."' in '".$args{config}."'.");
					}
					$metaInt++;
				}
			}
		}else {
			$zml->addVar($hashkeys[$hashkeysInt], $hash{$hashkeys[$hashkeysInt]});
			#checks to verify there was no error
			#this is not a fatal error... skips it if it is not legit
			if($zml->error){
				$self->warnString(':23: $zml->addVar returned '.
					 $zml->error.", '".$zml->errorString."'. Skipping variable '".
					 $hashkeys[$hashkeysInt]."' in '".$args{config}."'.");
			}
		}
			
		$hashkeysInt++;
	};

	#update the revision
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}

	#write out the ZML config
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
for the LDAP backend.

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

    $zconf->writeSetFromLoadedConfigLDAP({config=>"foo/bar"});
	if(defined($zconf->error)){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#write a set out to LDAP
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
	if ($self->error) {
		$self->warnString('isconfigLockedLDAP errored');
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

	#update the revision if needed
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}

	#get the config in a ZML format
	my $zml=$self->{self}->dumpToZML($args{config});
	if ($self->{self}->error) {
			$self->{error}=14;
			$self->{errorString}='Failed to dump to ZML. error='.$self->{self}->error.' errorString='.$self->{self}->errorString;
			$self->warn;
			return undef		
	}
	$args{zml}=$zml;
	
	#write out the config
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

=head3 zml

This is the ZML object to use.

=head3 revision

This is the revision string to use.

This is primarily meant for internal usage and is suggested
that you don't touch this unless you really know what you
are doing.

    $zconf->writeSetFromZML({config=>"foo/bar", zml=>$zml});
	if(defined($zconf->error)){
		warn('error: '.$zconf->error.":".$zconf->errorString);
	}

=cut

#write a set out to LDAP
sub writeSetFromZML{
	my $self = $_[0];
	my %args=%{$_[1]};

	$self->errorblank;

	#return false if the config is not set
	if (!defined($args{config})){
		$self->{error}=25;
		$self->{errorString}='$args{config} not defined';
		$self->warn;
		return undef;
	}

	#makes sure ZML is passed
	if (!defined( $args{zml} )) {
		$self->{error}=15;
		$self->{errorString}='$args{zml} is not defined';
		$self->warn;
		return undef;
	}
	if ( ref($args{zml}) ne "ZML" ) {
		$self->{error}=15;
		$self->{errorString}='$args{zml} is not a ZML';
		$self->warn;
		return undef;
	}

	#checks if it is locked or not
	my $locked=$self->isConfigLocked($args{config});
	if ($self->error) {
		$self->warnString('isconfigLockedLDAP errored');
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



	#small hack as this was copied writeSetFromLoadedConfig
	my $zml=$args{zml};

	my $setstring=$args{set}."\n".$zml->string;

	#creates the DN from the config
	my $dn=$self->config2dn($args{config}).",".$self->{args}{"ldap/base"};

	#connects to LDAP
	my $ldap=$self->LDAPconnect;
	if ($self->error) {
		warn('zconf writeSetFromLoadedConfigLDAP: LDAPconnect errored... returning...');
		return undef;
	}

	#gets the LDAP entry
	my $entry=$self->LDAPgetConfEntry($args{config}, $ldap);
	#return upon error
	if ($self->error) {
		$self->warnString('LDAPgetConfEntry errored');
		return undef;
	}

	if(!defined($entry->dn)){
		$self->{error}=13;
		$self->{errorString}="Expected DN, '".$dn."' not found.";
		$self->warn;
		return undef;
	}else{
		if($entry->dn ne $dn){
			$self->{error}=13;
			$self->{errorString}="Expected DN, '".$dn."' not found.";
			$self->warn;
			return undef;				
		}
	}

	#makes sure the zconfSet attribute is set for the config in question
	my @attributes=$entry->get_value('zconfSet');
	#if the 0th is not defined, it this zconf entry is borked and it needs to have the set value added 
	if(defined($attributes[0])){
		#if $attributes dues contain enteries, make sure that one of them is the proper set
		my $attributesInt=0;
		my $setFound=0;#set to one if the loop finds the set
		while(defined($attributes[$attributesInt])){
			if($attributes[$attributesInt] eq $args{set}){
				$setFound=1;
			};
			$attributesInt++;
		}
		#if the set was not found, add it
		if(!$setFound){
			$entry->add(zconfSet=>$args{set});
		}
	}else{
		$entry->add(zconfSet=>$args{set});
	}

	#
	@attributes=$entry->get_value('zconfData');
	#if the 0th is not defined, it this zconf entry is borked and it needs to have it added...  
	if(defined($attributes[0])){
		#if $attributes dues contain enteries, make sure that one of them is the proper set
		my $attributesInt=0;
		my $setFound=undef;#set to one if the loop finds the set
		while(defined($attributes[$attributesInt])){
			if($attributes[$attributesInt] =~ /^$args{set}\n/){
				#delete it the attribute and readd it, if it has not been found yet...
				#if it has been found it means this entry is borked and the duplicate
				#set needs removed...
				if(!$setFound){
					$entry->delete(zconfData=>[$attributes[$attributesInt]]);
					$entry->add(zconfData=>[$setstring]);
				}else{
					if($setstring ne $attributes[$attributesInt]){
						$entry->delete(zconfData=>[$attributes[$attributesInt]]);
					}
				}
				$setFound=1;
			}
			$attributesInt++;
		}
		#if the config is not found, add it
		if(!$setFound){
			$entry->add(zconfData=>[$setstring]);
		}
	}else{
		$entry->add(zconfData=>$setstring);
	}

	#update the revision
	if (!defined($args{revision})) {
		$args{revision}=time.' '.hostname.' '.rand();
	}
	$entry->delete('zconfRev');
	$entry->add(zconfRev=>[$args{revision}]);

	my $results=$entry->update($ldap);

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

LDAP entry already exists

=head2 12

config does not exist

=head2 13

Expected LDAP DN not found

=head2 14

ZML dump failed.

=head2 15

ZML object not passed.

=head2 16

Unable to create some of the required DN entries.

=head2 18

No variable name specified.

=head2 19

config key starts with a ' '

=head2 20

LDAP entry has no sets

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

LDAP entry update failed.

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

=head2 zconf.zml LDAP backend keys

=head3 backend

This should be set to 'ldap' to use this backend.

=head3 LDAPprofileChooser

This is a chooser string that chooses what LDAP profile to use. If this is not present, 'default'
will be used for the profile.

=head3 ldap/<profile>/bind

This is the DN to bind to the server as.

=head3 ldap/<profile>/cafile

When verifying the server's certificate, either set capath to the pathname of the directory containing
CA certificates, or set cafile to the filename containing the certificate of the CA who signed the
server's certificate. These certificates must all be in PEM format.

=head3 ldap/<profile>/capath

The directory in 'capath' must contain certificates named using the hash value of the certificates'
subject names. To generate these names, use OpenSSL like this in Unix:

    ln -s cacert.pem `openssl x509 -hash -noout < cacert.pem`.0

(assuming that the certificate of the CA is in cacert.pem.)

=head3 ldap/<profile>/checkcrl

If capath has been configured, then it will also be searched for certificate revocation lists (CRLs)
when verifying the server's certificate. The CRLs' names must follow the form hash.rnum where hash
is the hash over the issuer's DN and num is a number starting with 0.

=head3 ldap/<profile>/clientcert

This client cert to use.

=head3 ldap/<profile>/clientkey

The client key to use.

Encrypted keys are not currently supported at this time.

=head3 ldap/<profile>/homeDN

This is the home DN of the user in question. The user needs be able to write to it. ZConf
will attempt to create 'ou=zconf,ou=.config,$homeDN' for operating out of.

=head3 ldap/<profile>/host

This is the server to use for LDAP connections.

=head3 ldap/<profile>/password

This is the password to use for when connecting to the server.

=head3 ldap/<profile>/passwordfile

Read the password from this file. If both this and password is set,
then this will write over it.

=head3 ldap/<profile>/starttls

This is if it should use starttls or not. It defaults to undefined, 'false'.

=head3 ldap/<profile>/SSLciphers

This is a list of ciphers to accept. The string is in the standard OpenSSL
format. The default value is 'ALL'.

=head3 ldap/<profile>/SSLversion

This is the SSL versions accepted.

'sslv2', 'sslv3', 'sslv2/3', or 'tlsv1' are the possible values. The default
is 'tlsv1'.

=head3 ldap/<profile>/TLSverify

The verify mode for TLS. The default is 'none'.

=head1 ZConf LDAP Schema

    # 1.3.6.1.4.1.26481 Zane C. Bowers
    #  .2 ldap
    #   .7 zconf
    #    .0 zconfData
    #    .1 zconfChooser
    #    .2 zconfSet
    #    .3 zconfRev
    #    .4 zconfLock
    
    attributeType ( 1.3.6.1.4.1.26481.2.7.0
	    NAME 'zconfData'
        DESC 'Data attribute for a zconf entry.'
	    SYNTAX 1.3.6.1.4.1.1466.115.121.1.15
	    EQUALITY caseExactMatch
        )
    
    attributeType ( 1.3.6.1.4.1.26481.2.7.1
        NAME 'zconfChooser'
        DESC 'Chooser attribute for a zconf entry.'
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.15
        EQUALITY caseExactMatch
        )
    
    attributeType ( 1.3.6.1.4.1.26481.2.7.2
        NAME 'zconfSet'
        DESC 'A zconf set name available in a entry.'
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.15
        EQUALITY caseExactMatch
        )
    
    attributeType ( 1.3.6.1.4.1.26481.2.7.3
        NAME 'zconfRev'
        DESC 'The revision number for a ZConf config. Bumped with each update.'
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.15
        EQUALITY caseExactMatch
        )
    
    attributeType ( 1.3.6.1.4.1.26481.2.7.4
        NAME 'zconfLock'
        DESC 'If this is present, this config is locked.'
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.15
        EQUALITY caseExactMatch
        )
    
    objectclass ( 1.3.6.1.4.1.26481.2.7
        NAME 'zconf'
        DESC 'A zconf entry.'
        MAY ( cn $ zconfData $ zconfChooser $ zconfSet $ zconfRev $ zconfLock )
        )

=head1 SYSTEM MODE

This is for deamons or the like. This will read
'/var/db/zconf/$sys/zconf.zml' for it's options and store
the file backend stuff in '/var/db/zconf/$sys/'.

It will create '/var/db/zconf' or the sys directory, but not
'/var/db'.

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
