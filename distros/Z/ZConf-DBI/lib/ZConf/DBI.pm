package ZConf::DBI;

use warnings;
use strict;
use ZConf;
use base 'Error::Helper';

=head1 NAME

ZConf::DBI - Stores DBI connection information in ZConf.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use ZConf::DBI;
    use DBI::Shell;

    my $foo=ZConf::DBI->new;

    my $ds=$foo->getDS('tigerline');
    my $user=$foo->getDSuser('tigerline');
    my $pass=$foo->getDSpass('tigerline');

    DBI::Shell->new($ds, $user, $pass)->run;

=head1 METHODS

=head2 new

This initiates the object.

=head3 hash values

=head4 zconf

If this is defined, it will be used instead of creating
a new ZConf object.

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={
		error=>undef,
		perror=>undef,
		errorString=>undef,
		zconfconfig=>'DBI',
	};
	bless $self;
	
	#get the ZConf object
	if (!defined($args{zconf})) {
		#creates the ZConf object
		$self->{zconf}=ZConf->new();
		if(defined($self->{zconf}->error)){
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="Could not initiate ZConf. It failed with '"
			                      .$self->{zconf}->error."', '".
			                      $self->{zconf}->errorString."'";
			$self->warn;
			return $self;
		}
	}else {
		$self->{zconf}=$args{zconf};
	}

	#check if the config exists
	my $returned = $self->{zconf}->configExists($self->{zconfconfig});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}="Checking if '".$self->{zconfconfig}."' exists failed. error='".
		                     $self->{zconf}->error."', errorString='".
		                     $self->{zconf}->errorString."'";
		$self->warn;
		return $self;
	}

	#initiate the config if it does not exist
	if (!$returned) {
		#create the config
		$self->{zconf}->createConfig($self->{zconfconfig});
		if ($self->{zconf}->error) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="Checking if '".$self."' exists failed. error='".
		                         $self->{zconf}->error."', errorString='".
		                         $self->{zconf}->errorString."'";
			$self->warn;
			return $self;
		}

		#init it
		$self->init;
		if ($self->{zconf}->error) {
			$self->{perror}=1;
			$self->{errorString}='Init failed.';
			$self->warn;
			return $self;
		}
	}else {
		#if we have a set, make sure we also have a set that will be loaded
		$returned=$self->{zconf}->defaultSetExists($self->{zconfconfig});
		if ($self->{zconf}->error) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="Checking if '".$self."' exists failed. error='".
		                         $self->{zconf}->error."', errorString='".
		                         $self->{zconf}->errorString."'";
			$self->warn;
			return $self;
		}

		#initiliaze a the default set if needed.
		if (!$returned) {
			#init it
			$self->init;
			if ($self->{zconf}->error) {
				$self->{perror}=1;
				$self->{errorString}='Init failed.';
				$self->warn;
				return $self;
			}
		}
	}


	#read the config
	$self->{zconf}->read({config=>$self->{zconfconfig}});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}="Checking if the default set for '".$self->{zconfconfig}."' exists failed. error='".
		                     $self->{zconf}->error."', errorString='".
		                     $self->{zconf}->errorString."'";
		$self->warn;
		return $self
	}

	return $self;
}

=head2 addDS

This adds a new data source.

=head3 args hash

The only required is 'ds'. Any thing else can be undef.

=head4 attr

This hash reference contains any attributes one wishes to pass to the
new connections.

=head4 ds

This is the data source string.

=head4 name

The name of the new data source.

=head4 pass

This is the password to use.

This can be undefined.

=head4 user

This is the the user to use.

This can be undefined.

    $foo->addDS({ds=>$datasource, user=>$user, pass=>$pass, name=>'some name'  });
    if($foo->error){
        print "Error!\n";
    }

=cut

sub addDS{
	my $self=$_[0];
	my %args;
	%args=%{$_[1]};

	#blanks any previous error
	if (!$self->errorblank) {
		return undef;
	}	

	if (!defined( $args{name} )) {
		$self->{error}=2;
		$self->{errorString}='No name specified';
		$self->warn;
		return undef;
	}

	if (!defined( $args{ds} )) {
		$self->{error}=3;
		$self->{errorString}='No data source specified';
		$self->warn;
		return undef;
	}

	#make sure it does not exist already
	my $dsExists=$self->dataSourceExists( $args{name} );
	if ($self->error) {
		$self->warnString('dataSourceExists errored');
		return undef;
	}
	if ($dsExists) {
		$self->{error}=4;
		$self->{errorString}='The data source "'.$args{name}.'" already exists';
		$self->warn;
		return undef;
	}

	#make sure the name does not have a / in it
	if ($args{name} =~ /\//) {
		$self->{error}=5;
		$self->{errorString}='The data source name, "'.$args{name}.'", contains a "/"';
		$self->warn;
		return undef;
	}

	#adds the datasource
	$self->{zconf}->setVar('DBI', 'datasources/'.$args{name}.'/ds', $args{ds});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf setVar failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#Adds the username if needed.
	#There is no need to error check this as it will work if the last setVar worked
	if (defined( $args{user} )) {
		$self->{zconf}->setVar('DBI', 'datasources/'.$args{name}.'/user', $args{user});
	}
	#Adds the password if needed.
	if (defined( $args{pass} )) {
		$self->{zconf}->setVar('DBI', 'datasources/'.$args{name}.'/pass', $args{pass});
	}

	#handles and attributes if specified
	if (defined( $args{attr} )) {

		#adds each key
		my @keys=keys( %{ $args{attr} } );
		my $int=0;
		while (defined( $keys[$int] )) {
			$self->{zconf}->setVar('DBI', 'datasources/'.$args{name}.'/attr/'.$keys[$int] , $args{attr}{$keys[$int]} );
			$int++;
		}
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>$self->{zconfconfig}});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf writeSetFromHash failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return 1;
}

=head2 connect

This connects and returns the database handle formed by DBI->connect.

This just returns the database handle and does not check if succedded or not.

Only one arguement is required and it is the name of the data source.

    my $dbh=$foo->connect('someDS');
    if($foo->error){
        print "Error!\n";
    }

=cut

sub connect{
	my $self=$_[0];
	my $dsName=$_[1];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#make sure it does not exist already
	my $dsExists=$self->dataSourceExists( $dsName );
	if ($self->error) {
		$self->warnString('dataSourceExists errored');
		return undef;
	}
	if (!$dsExists) {
		$self->{error}=7;
		$self->{errorString}='The data source "'.$dsName.'" does not exist';
		$self->warn;
		return undef;
	}

	#fetches the data source
	my $ds=$self->getDS($dsName);
	if ($self->error) {
		$self->warnString('getDS errored');
		return undef;
	}

	#fetches the user for the data source
	my $user=$self->getDSuser($dsName);
	if ($self->error) {
		$self->warnString('getDSuser errored');
		return undef;
	}

	#fetches the user for the data source
	my $pass=$self->getDSpass($dsName);
	if ($self->error) {
		$self->warnString('getDSuser errored');
		return undef;
	}

	#fetches the user for the data source
	my %attrs=$self->getDSattrs($dsName);
	if ($self->error) {
		$self->warnString('getDSattrs errored');
		return undef;
	}

	#connect and return the results
	use DBI;
	return DBI->connect($ds, $user, $pass, \%attrs);
}

=head2 dataSourceExists

This checks if the specified data source exists or not.

Only one arguement is taken and it is the name of data source
to check for.

The returned value is either a Perl boolean value.

    if(!$foo->dataSourceExists('bar')){
        print "The data source 'bar' does not exist\n";
    }

=cut

sub dataSourceExists{
	my $self=$_[0];
	my $datasource=$_[1];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure the data source exists
	if (!defined( $datasource )) {
		$self->{error}=2;
		$self->{errorString}='No name specified';
		$self->warn;
		return undef;
	}

	#gets a list of data sources
	my @datasources=$self->listDSs;
	if ($self->error) {
		$self->warnString('listDSs errored');
		return undef;
	}

	#run through checking for a match
	my $int=0;
	while (defined( $datasources[$int] )) {
		if ($datasources[$int] eq $datasource) {
			return 1;
		}

		$int++;
	}

	return undef;
}

=head2 delDS

This removes a data source.

=cut

sub delDS{
	my $self=$_[0];
	my $dsName=$_[1];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#make sure it does not exist already
	my $dsExists=$self->dataSourceExists( $dsName );
	if ($self->error) {
		$self->warnString('dataSourceExists errored');
		return undef;
	}
	if (!$dsExists) {
		$self->{error}=7;
		$self->{errorString}='The data source "'.$dsName.'" does not exist';
		$self->warn;
		return undef;
	}

	my @deleted=$self->{zconf}->regexVarDel( $self->{zconfconfig}, '^datasources\/'.quotemeta($dsName).'\/' );
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf regexVarDel failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>$self->{zconfconfig}});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf writeSetFromHash failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return 1;
}

=head2 delSet

This removes the specified ZConf set.

    $foo->delSet('someSet');
    if($foo->error){
        print "Error!\n";
    }

=cut

sub delSet{
	my $self=$_[0];
	my $set=$_[1];

	#blanks any previous errors
	if (!$self->errorblank) {
		$self->warn;
		return undef;
	}

	$self->{zconf}->delSet($self->{zconfconfg}, $set);
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf getAvailableSets failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 getDS

This gets the data source value for a data source.

Only one arguement is required and is the name of the data source.

    my $ds=$foo->getDS("someDS");
    if($foo->{error}){
        print "Error!\n";
    }

=cut

sub getDS{
	my $self=$_[0];
	my $dsName=$_[1];

	#blanks any previous error
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#fetches them
	my %vars=$self->{zconf}->regexVarGet( $self->{zconfconfig}, '^datasources/'.$dsName.'/ds$' );
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf regexVarGet failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#makes sure it it exists... if it does not it errors
	if (!defined( $vars{ 'datasources/'.$dsName.'/ds' } )) {
		$self->{error}=6;
		$self->{errorString}='The data source, "'.$dsName.'", does not exist';
		$self->warn;
		return undef;		
	}

	return $vars{ 'datasources/'.$dsName.'/ds' };
}

=head2 getDSattrs

This gets the pass for a data source.

This can potentially be undef.

Only one arguement is required and is the name of the data source.

    my %attrs=$foo->getDS("someDS");
    if($foo->error){
        print "Error!\n";
    }

=cut

sub getDSattrs{
	my $self=$_[0];
	my $dsName=$_[1];

	#blanks any previous errors
	if (!$self->errorblank){
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#fetches them
	my %vars=$self->{zconf}->regexVarGet( $self->{zconfconfig}, '^datasources/'.$dsName.'/' );
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf regexVarGet failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#makes sure it it exists... if it does not it errors
	if (!defined( $vars{ 'datasources/'.$dsName.'/ds' } )) {
		$self->{error}=6;
		$self->{errorString}='The data source, "'.$dsName.'", does not exist';
		$self->warn;
		return undef;		
	}

	#process each returned key
	my @keys=keys(%vars);
	my $int=0;
	my %toreturn;
	my $base='^datasources/'.$dsName.'/attr/';
	while (defined( $keys[$int] )) {
		if ($keys[$int] =~ /$base/) {
			my $newkey=$keys[$int];
			$newkey=~s/$base//;
			$toreturn{$newkey}=$vars{$keys[$int]};
		}

		$int++;
	}

	return %toreturn;
}

=head2 getDSpass

This gets the pass for a data source.

This can potentially be undef.

Only one arguement is required and is the name of the data source.

    my $ds=$foo->getDS("someDS");
    if($foo->error){
        print "Error!\n";
    }

=cut

sub getDSpass{
	my $self=$_[0];
	my $dsName=$_[1];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#fetches them
	my %vars=$self->{zconf}->regexVarGet( $self->{zconfconfig}, '^datasources/'.$dsName.'/' );
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf regexVarGet failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#makes sure it it exists... if it does not it errors
	if (!defined( $vars{ 'datasources/'.$dsName.'/ds' } )) {
		$self->{error}=6;
		$self->{errorString}='The data source, "'.$dsName.'", does not exist';
		$self->warn;
		return undef;		
	}

	#return undef if it does not exist
	if (!defined( $vars{ 'datasources/'.$dsName.'/pass' } )) {
		return undef;		
	}

	return $vars{ 'datasources/'.$dsName.'/pass' };
}

=head2 getDSuser

This gets the user for a data source.

This can potentially be undef.

Only one arguement is required and is the name of the data source.

    my $ds=$foo->getDS("someDS");
    if($foo->error){
        print "Error!\n";
    }

=cut

sub getDSuser{
	my $self=$_[0];
	my $dsName=$_[1];

	#blanks any previous error
	if ($self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#fetches them
	my %vars=$self->{zconf}->regexVarGet( $self->{zconfconfig}, '^datasources/'.$dsName.'/' );
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf regexVarGet failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#makes sure it it exists... if it does not it errors
	if (!defined( $vars{ 'datasources/'.$dsName.'/ds' } )) {
		$self->{error}=6;
		$self->{errorString}='The data source, "'.$dsName.'", does not exist';
		$self->warn;
		return undef;		
	}

	#return undef if it does not exist
	if (!defined( $vars{ 'datasources/'.$dsName.'/user' } )) {
		return undef;		
	}

	return $vars{ 'datasources/'.$dsName.'/user' };
}

=head2 init

This initiates a new set. If a set already exists, it will be overwritten.

If the set specified is undefined, the default will be used.

The set is not automatically read.

    $foo->init($set);
    if($foo->error){
        print "Error!\n";
    }

=cut

sub init{
	my $self=$_[0];
	my $set=$_[1];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#the that what will be used for creating the new ZConf config
	my %hash;

	$self->{zconf}->writeSetFromHash({config=>$self->{zconfconfig}, set=>$set},\%hash);
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf writeSetFromHash failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return 1;
}

=head2 listDSs

This lists the available data sources.

No arguements are taken.

The returned value is a array of available data sources.

    my @datasources=$foo->listDSs;
    if($foo->error){
        print "Error!\n";
    }else{
        use Data::Dumper;
        print Dumper(\@daasources);
    }

=cut

sub listDSs{
	my $self=$_[0];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#searches for datasources
	my @matched=$self->{zconf}->regexVarSearch($self->{zconfconfig}, '^datasources\/');
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf regexVarSearch failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	#process the found data sources
	my %found; #provides easy holding for ones found to prevent duplicates
	my $int=0; #used for running through each one
	while (defined( $matched[$int] )) {
		my @split=split( /\//, $matched[$int] );
		if (defined( $split[1] )) {
			$found{$split[1]}=1;
		}

		$int++;
	}

	#returns the found data sources, the keys in %found
	return keys(%found);
}

=head2 listSets

This lists the available sets for the ZConf config.

    my @sets=$foo->listSets;
    if($foo->error){
        print "Error!\n";
    }

=cut

sub listSets{
	my $self=$_[0];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	my @sets=$self->{zconf}->getAvailableSets($self->{zconfconfig});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf getAvailableSets failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return @sets;
}

=head2 readSet

This reads a specified ZConf set.

If no set is specified, the default is used.

    $foo->readSet('someSet');
    if($foo->error){
        print "Error!\n";
    }

=cut

sub readSet{
	my $self=$_[0];
	my $set=$_[1];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#read the config
	$self->{zconf}->read({config=>$self->{zconfconfig}, set=>$set});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='Failed to read the set. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return 1;
}

=head2 setDS

This changes the data source value for a already setup data source.

Two arguements are required. The first is the data source name and the
second is the data source.

    $foo->setDS('someDS', 'DBI:mysql:databasename');
    if($foo->error){
        print "Error!\n";
    }

=cut

sub setDS{
	my $self=$_[0];
	my $dsName=$_[1];
	my $ds=$_[2];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#makes sure a DS name was specified
	if (!defined( $ds )) {
		$self->{error}=3;
		$self->{errorString}='No data source specified';
		$self->warn;
		return undef;		
	}

	#make sure it does not exist already
	my $dsExists=$self->dataSourceExists( $dsName );
	if ($self->error) {
		$self->warnString('dataSourceExists errored');
		return undef;
	}
	if (!$dsExists) {
		$self->{error}=7;
		$self->{errorString}='The data source "'.$dsName.'" does not exist';
		$self->warn;
		return undef;
	}

	#set the variable
	my $var='datasources/'.$dsName.'/ds';
	$self->{zconf}->setVar($self->{zconfconfig}, $var, $ds);
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf setVar failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>$self->{zconfconfig}});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf writeSetFromHash failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return 1;
}

=head2 setDSattr

This changes the data source value for a already setup data source.

Three arguements are required. The first is the data source name, second
is the data source, and the third is the value.

If the value is undefined, the attribute is removed.

    $foo->setDS('someDS', 'someAttr', 'someValue');
    if($foo->error){
        print "Error!\n";
    }

=cut

sub setDSattr{
	my $self=$_[0];
	my $dsName=$_[1];
	my $attr=$_[2];
	my $value=$_[3];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#makes sure a DS name was specified
	if (!defined( $attr )) {
		$self->{error}=8;
		$self->{errorString}='No attribute specified';
		$self->warn;
		return undef;		
	}

	#make sure it does not exist already
	my $dsExists=$self->dataSourceExists( $dsName );
	if ($self->error) {
		$self->warnString('dataSourceExists errored');
		return undef;
	}
	if (!$dsExists) {
		$self->{error}=7;
		$self->{errorString}='The data source "'.$dsName.'" does not exist';
		$self->warn;
		return undef;
	}

	#removes it if the value is not defined...
	if (!defined( $value )) {
		my $rm='^datasources/'.$dsName.'/attr/'.$attr.'$';
		$self->{zconf}->regexVarDel($self->{zconfconfig}, $rm);
		if ($self->{zconf}->error) {
			$self->{error}=1;
			$self->{errorString}='ZConf setVar failed. error="'.
		                         $self->{zconf}->error.'", errorString="'.
		                         $self->{zconf}->errorString.'"';
			$self->warn;
			return undef;
		}

		return 1;
	}

	#set the variable
	my $var='datasources/'.$dsName.'/attr/'.$attr;
	$self->{zconf}->setVar($self->{zconfconfig}, $var, $value);
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf setVar failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>$self->{zconfconfig}});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf writeSetFromHash failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return 1;
}

=head2 setDSpass

This changes the password value for a already setup data source.

Two arguements are required. The first is the data source name and the
second is the password.

    $foo->setDS('someDS', 'somePass');
    if($foo->error){
        print "Error!\n";
    }

=cut

sub setDSpass{
	my $self=$_[0];
	my $dsName=$_[1];
	my $pass=$_[2];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#makes sure a user name is specified
	if (!defined( $pass )) {
		$self->{error}=11;
		$self->{errorString}='No pass specified';
		$self->warn;
		return undef;		
	}

	#make sure it does not exist already
	my $dsExists=$self->dataSourceExists( $dsName );
	if ($self->error) {
		$self->warnString('dataSourceExists errored');
		return undef;
	}
	if (!$dsExists) {
		$self->{error}=7;
		$self->{errorString}='The data source "'.$dsName.'" does not exist';
		$self->warn;
		return undef;
	}

	#set the variable
	my $var='datasources/'.$dsName.'/pass';
	$self->{zconf}->setVar($self->{zconfconfig}, $var, $pass);
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf setVar failed. error="'.
			$self->{zconf}->error.'", errorString="'.
			$self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>$self->{zconfconfig}});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf writeSetFromHash failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return 1;
}

=head2 setDSuser

This changes the user value for a already setup data source.

Two arguements are required. The first is the data source name and the
second is the user.

    $foo->setDS('someDS', 'someUser');
    if($foo->error){
        print "Error!\n";
    }

=cut

sub setDSuser{
	my $self=$_[0];
	my $dsName=$_[1];
	my $user=$_[2];

	#blanks any previous errors
	if (!$self->errorblank) {
		return undef;
	}

	#makes sure a DS name was specified
	if (!defined( $dsName )) {
		$self->{error}=2;
		$self->{errorString}='No DS name specified';
		$self->warn;
		return undef;		
	}

	#make sure it does not exist already
	my $dsExists=$self->dataSourceExists( $dsName );
	if ($self->{error}) {
		$self->warnString('dataSourceExists errored');
		return undef;
	}
	if (!$dsExists) {
		$self->{error}=7;
		$self->{errorString}='The data source "'.$dsName.'" does not exist';
		$self->warn;
		return undef;
	}

	#set the variable
	my $var='datasources/'.$dsName.'/user';
	$self->{zconf}->setVar($self->{zconfconfig}, $var, $user);
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf setVar failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>$self->{zconfconfig}});
	if ($self->{zconf}->error) {
		$self->{error}=1;
		$self->{errorString}='ZConf writeSetFromHash failed. error="'.
		                     $self->{zconf}->error.'", errorString="'.
		                     $self->{zconf}->errorString.'"';
		$self->warn;
		return $self;
	}

	return 1;
}

=head1 ERROR CODES/HANDLING

Error handling is provided by L<Error::Helper>. The error
codes are as below.

=head2 1

ZConf errored.

=head2 2

Data source name not specified.

=head2 3

Data source not defined.

=head2 4

The data source already exists.

=head2 5

The data source name contains a '/'.

=head2 6

The data source does not exist.

=head2 7

Data source does not exist.

=head2 8

No attribute specified.

=head2 9

No value specified.

=head2 10

No user specified.

=head2 11

No password specified.

=head1 ZCONF KEYS

=head2 datasources/<data source name>/ds

This is the data source string for a data source.

This is required.

=head2 datasources/<data source name>/user

This is the user for a data source.

This may not be defined.

=head2 datasources/<data source name>/pass

This is the password for a data source.

This may not be defined.

=head2 datasources/<data source name>/attr/<attribute name>

This contains any attributes for a data source.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-devtemplate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-DBI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::DBI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-DBI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-DBI>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-DBI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::DBI
