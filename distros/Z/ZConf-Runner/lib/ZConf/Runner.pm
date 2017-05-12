package ZConf::Runner;

use warnings;
use strict;
use File::MimeInfo::Magic;
use File::MimeInfo::Applications;
use ZConf;
use String::ShellQuote;

=head1 NAME

ZConf::Runner - Run a file using a choosen methode, desktop entry or mimetype.

=head1 VERSION

Version 2.1.4

=cut

our $VERSION = '2.1.4';

=head1 SYNOPSIS

The purpose of this module is to figure out what to do with an object based
on it's mimetype. Currently only files are supported.

    use ZConf::Runner;

    my $zcr=ZConf::Runner->new();
   if($zcr->{error}){
       print "Error!\n";
   }

=head1 METHODS

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head4 zconf

This is a zconf object to use instead of initiating a new one.

   my $zcr=ZConf::Runner->new();
   if($zcr->{error}){
       print "Error!\n";
   }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='new';

	my $self={error=>undef, errorString=>undef, module=>'ZConf-Runner', perror=>undef};
	bless $self;

	if (!defined($args{zconf})) {
		#creates the ZConf object
		$self->{zconf}=ZConf->new(%{$args{zconfargs}});
		if(defined($self->{zconf}->{error})){
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="Could not initiate ZConf. It failed with '"
			                  .$self->{zconf}->{error}."', '".
							  $self->{zconf}->{errorString}."'";
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}else {
		$self->{zconf}=$args{zconf};
	}

	#make sure it exists
	my $returned = $self->{zconf}->configExists('runner');
	#if we can't do this we definitely can't continue
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{perror}=1;
		$self->{errorString}='Could not verify if "runner" exists or not. ZConf error="'.
			                 $self->{zconf}->{error}.'" ZConf errorString="'.
							 $self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#create the config if it has not been initialized yet.
	if (!$returned) {
		$self->{zconf}->createConfig('runner');
		if ($self->{zconf}->{error}) {
			$self->{error}=3;
			$self->{perror}=1;
			$self->{errorString}='Could not create the ZConf config "runner". ZConf error with "'.
			                     $self->{zconf}->{error}.'" ZConf errorString="'.
								 $self->{zconf}->{errorString}.'"';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
 			return $self;
		}
	}

	#create the new set if needed
	$returned=$self->{zconf}->defaultSetExists('runner');
	if (!$returned) {
		#
		$self->{zconf}->writeSetFromHash({config=>'runner'}, {});
		if ($self->{zconf}->{error}) {
			$self->{error}=2;
			$self->{perror}=1;
			$self->{errorString}='ZConf error. error="'.$self->{zconf}->{error}.'" '.
			                     ' errorString="'.$self->{zconf}->{errorString}.'"';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}

	#
	$self->{zconf}->read({config=>'runner'});
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{perror}=1;
		$self->{errorString}='ZConf error. error="'.$self->{zconf}->{error}.'" '.
		                     ' errorString="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}
		
	return $self;
}

=head2 actionIsSetup

This checks to see if a specific action is setup for a mimetype.

Two arguements are accepted. The first is the mimetype. The
second is the action.

    my $mimetype='image/jpeg';
    my $returned=$zcr->actionIsSetup($mimetype, 'edit');
    if($zcr->{error}){
        print "Error!\n";
        if($zcr->{error} eq '7'){
            print "Mimetype is not setup.\n";
        }
    }
    if($returned){
        print $mimtetype." is configured already";
    }

=cut

sub actionIsSetup{
	my $self=$_[0];
	my $mimetype=$_[1];
	my $action=$_[2];
	my $function='acionIsSetup';

	#blanks any previous errors
	$self->errorBlank;	
	if ($self->{error}) {
		return undef;
	}

	#makes sure a mimetype to check for is specified.
	if (!defined($mimetype)) {
		$self->{error}=4;
		$self->{errorString}='No mimetype specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure a action to check for is specified.
	if (!defined($action)) {
		$self->{error}=4;
		$self->{errorString}='No action specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	if (!$self->validActionName($action)) {
		$self->{error}=5;
		$self->{errorString}='"'.$action.'" is not a valid action name';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
	}

	#check to make sure the mimetype is setup
	my $returned=$self->mimetypeIsSetup($mimetype);
	#return if it errored
	if ($self->{error}) {
		warn('ZConf-Runner actionIsSetup: mimetypeIsSetup errored');
		return undef;
	}

	#return if it if the mimetype is not setup
	if (!$returned) {
		$self->{error}=7;
		$self->{errorString}='"'.$mimetype.'" is not setup';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#gets the list of actions
	my @actions=$self->listActions($mimetype);
	#return if the previous funtion errored
	if ($self->{error}) {
		warn('ZConf-Runner actionIsSetup: listActions failed');
		return undef;
	}

	#runs through the list and return true if it is found
	my $int=0;
	while (defined($actions[$int])) {
		#if it is found it is setup and thus return true
		if ($actions[$int] eq $action) {
			return 1;
		}

		$int++;
	}

	#if we get here, it has not been found
	return undef;
	
}

=head2 ask

This is creates a Curses::UI asking what to do.

The first agruement is the action to be performed. The
second is the file it is to be performed on. The third
is an optional hash. It's accepted keys are as below.

    my $returned=$zcr->ask('view', '/tmp/test.rdf', {useX=>0});
    if($zcr->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "Action setup.\n";
        }
    }

=cut

sub ask{
	my $self=$_[0];
	my $action=$_[1];
	my $object=$_[2];
	my %args;
	if (defined($_[3])) {
		%args= %{$_[3]};
	}
	my $function='ask';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#gets the mimetype for the object
	my $mimetype=mimetype($object);

	#this makes sure we got a mimetype
	if (!defined($mimetype)) {
		$self->{error}=12;
		$self->{errorString}='Could not determime the mimetype for "'.$object.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;;
	}

	#figures out if it should use X or not if it is not set
	if (!defined($args{useX})) {
		$args{useX}=$self->Xavailable();
	}else {
		#if it is already set to true, see if it can be used
		if ($args{useX}) {
			$args{useX}=$self->Xavailable();
		}
	}

	my $terminal='xterm -rv -e ';
	#if the enviromental variable 'TERMINAL' is set, use 
	if(defined($ENV{TERMINAL})){
		$terminal=$ENV{TERMINAL};
	}

	#escapes it for executing it
	my $eAction=$action;
	$eAction=~s/\"/\\\"/g;
	my $eObject=$object;
	$eObject=~s/\"/\\\"/g;

	my $askcommand='perl -e \'use ZConf::Runner; my $zcr=ZConf::Runner->new(); '.
			   '$zcr->askGUI("'.$eAction.'", "'.$eObject.'");\'';

	if ($args{useX}) {
		system($terminal.' '.$askcommand);
		if ($? == -1) {
			$self->{error}=15;
			$self->{errorString}="Failed to '".$terminal.' '.$askcommand."'";
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		 	return undef;
		}

		#we reread it to get any changes
		$self->{zconf}->read({config=>'runner'});
		if ($self->{zconf}->{error}) {
			warn('ZConf-Runner ask:2: ZConf errored with "'.$self->{zconf}->{error}.
				 '" when trying to reread the ZConf config "runner". errorString="'.
				 $self->{zconf}->{errorString}.'"');
			return undef;
		}

		my $returned=$self->actionIsSetup($mimetype, $action);
		if ($self->{error}) {
			warn('ZConf-Runner ask: actionIsSetup("'.$mimetype.'", "'
				 .$action.'") failed');
			return undef;
		}

		#we just assume yes was pushed right now as it is impossible to get
		#the exit status from something executed using xterm
		return $returned;
	}else {
		system($askcommand);
		my $exitcode=$? >> 8;
		if ($? == -1) {
			$self->{error}=15;
			$self->{errorString}="Failed to '".$askcommand."'";
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}

		#if Quit was selected, just return undef, but don't error
		if ($exitcode == 14) {
			return undef;
		}

		#if ok was selected and it added with out issue
		if ($exitcode == 15) {
			return 1;
		}

		#if we get here, it means we errored
		$self->{error}=16;
		$self->{errorString}="'".$askcommand."' failed with a exit of '".$exitcode."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

}

=head2 do

This runs takes an file and runs it.

The first agruement is the action to be performed.

The second is the file it is to be performed on.

The third is an optional hash. It's accepted keys are as below.

=head3 args hash

still needs implemented

=head4 exec

If this is set to true, exec is used instead of system.

=head4 ask

If this is set to true, it will

=cut

sub do{
	my $self=$_[0];
	my $action=$_[1];
	#I am calling this variable object as I could not choose a name.
	#Right now I am just doing files, but I plan to implement URL handling
	#at some point in time.
	my $object=$_[2];
	my %args;
	if (defined($_[3])) {
		%args= %{$_[3]};
	}
	my $function='do';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#makes sure a object to operate on is specified.
	if (!defined($object)) {
		$self->{error}=4;
		$self->{errorString}='No object specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#if ask is not defined, set it to ask be default
	if (!defined($args{ask})) {
		$args{ask}=1;
	}

	#set it to use system instead of exec by default
	if (!defined($args{exec})) {
		$args{exec}=0;
	}

	#makes sure an action is specified.
	if (!defined($action)) {
		$self->{error}=4;
		$self->{errorString}='No action specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#gets the mimetype for the object
	my $mimetype=mimetype($object);

	#this makes sure we got a mimetype
	if (!defined($mimetype)) {
		$self->{error}=12;
		$self->{errorString}='Could not determime the mimetype for "'.$object.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $returned=$self->validAction($mimetype, $action);
	if ($self->{error}) {
		#if it is set to ask, 
		if (!$args{ask}) {
			warn('ZConf-Runner do:12: validAction("'.$mimetype.'", "'.$action.'") errored');
			return undef;		
		}
		use ZConf::Runner::GUI;
		$self->errorBlank;
		my $zcrg=ZConf::Runner::GUI->new({zcrunner=>$self, zconf=>$self->{zconf}});
		if ($zcrg->{error}){
			my $error='ZConf::Runner::GUI->new errored. error="'.
			          $zcrg->{error}.'" errorString="'.$zcrg->{errorString}.'"';
			$self->{error}=18;
			$self->{errorString}=$error;
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}
		$returned=$zcrg->ask({object=>$object, action=>$action});
		if (!$returned) {
			warn('ZConf-Runner do: $zcrg->ask({ action=>"'.$action.'", object=>"'.$object.
				 '" }) failed or user quit it');
			return undef;
		}
	}

	#this is the base name for the the variables
	my $baseVar='mimetypes/'.$mimetype.'/'.$action.'/';

	#gets the variables for the action
	my %vars=$self->{zconf}->regexVarGet('runner', '^'.$baseVar);
	if($self->{zconf}->{error}){
		$self->{error}=1;
		$self->{errorString}='ZConf error when doing regexVarGet for "^'.$baseVar
		                     .'". ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $type=$vars{$baseVar.'type'};
	my $do=$vars{$baseVar.'do'};

	#
	if ($type eq 'exec') {
		#make the object safe to exchange with %f
		my $sobject=shell_quote($object);

		#replace %f with the file
		$do=~s/\%f/$sobject/g;

		print "\n\n".$do."\n\n";
		
		if($args{exec}){
			exec($do);
		}else {
			system($do);
		}
		return 1;
	}

	#
	if ($type eq 'desktop') {
		#verify it is a good desktop entry
		if (!$self->validDesktopEntry($do)) {
			$self->{error}=13;
			$self->{errorString}='$entry->lookup("'.$do.'") failed';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}

		#We trust this should work as the check above worked.
		my $entry = File::DesktopEntry->new($do);

		$entry->system($object);
	}
	return 1;
}

=head2 getAction

This fetches an action for a mimetype and returns the do and type
as an hash.

The are two required arguements. The first is the mimetype and the
second is the action.

    my %action=$zcr->getAction('application/vnd.oasis.opendocument.text', 'view');
    if($zcr->{error}){
        print "Error!\n";
    }else{
        print "do: '".$action{do}."'\n".
              "type: '".$action{type}."'\n";
    }

=cut

sub getAction{
	my $self=$_[0];
	my $mimetype=$_[1];
	my $action=$_[2];
	my $function='getAction';

	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}


	if (!defined($self->validAction($mimetype, $action))) {
		#we don't need to set any errors or etc here as validAction will
		warn('ZConf-Runner getAction: validAction errored errored.');
		return undef;
	}

	#this is the base name for the the variables
	my $baseVar='mimetypes/'.$mimetype.'/'.$action.'/';

	#We don't need to check the error here as it will be fine if validAction
	#uses this exact same function and will error on it.
	#gets the variables for it
	my %vars=$self->{zconf}->regexVarGet('runner', '^'.$baseVar);

	#
	my %returnH;
	$returnH{do}=$vars{$baseVar.'do'};
	$returnH{type}=$vars{$baseVar.'type'};

	return %returnH;
}

=head2 getSet

This gets what the current set is.

    my $set=$zcr->getSet;
    if($zcr->{error}){
        print "Error!\n";
    }

=cut

sub getSet{
	my $self=$_[0];
	my $function='getSet';

	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	my $set=$self->{zconf}->getSet('runner');
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{errorString}='ZConf error getting the loaded set the config "runner".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $set;
}

=head2 listActions

This gets a list of actions for a specific mimetype.

There is one required arguement and it is the mimetype.

    my @actions=$zcr->listActions('application/vnd.oasis.opendocument.text');
    if($zcr->{error}){
        print "Error!\n";
    }

=cut

sub listActions{
	my $self=$_[0];
	my $mimetype=$_[1];
	my $function='listActions';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#makes sure a type to check for is specified.
	if (!defined($mimetype)) {
		$self->{error}=4;
		$self->{errorString}='No mimetype specified to get actions for.';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure the mimetype is setup
	my $returned=$self->mimetypeIsSetup($mimetype);
	if ($self->{error}) {
		warn('ZConf-Runner listActions: mimetypeIsSetup("'.$mimetype.'") errored');
		return undef;
	}

	#error if the mimetype is not setup
	if (!$returned) {
		$self->{error}=7;
		$self->{errorString}='Mimetype "'.$mimetype.'" is not setup';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#finds any thing under 'mimetypes/'.$mimetype.'/'
	my @actionSearch=$self->{zconf}->regexVarSearch('runner', '^mimetypes/'.$mimetype.'/');
	if($self->{zconf}->{error}){
		$self->{error}=1;
		$self->{errorString}=' ZConf error when searching for vars matching'.
		                     ' "^mimetypes/". ZConf error="'.$self->{zconf}->{error}.'" '.
		                     'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#
	my $int=0;
	#the types are stored as an hash
	my %actions;
	while (defined($actionSearch[$int])) {
		#splits the ZConf string apart
		my @actionA=split(/\//, $actionSearch[$int]);
		#puts the split back together
		#0='mimtetypes'
		#1=type
		#2=subtype
		#3=action
		#4='do' or 'type'
		my $action=$actionA[3];

		$actions{$action}=$action;
		
		$int++;
	}

	#returns an array of the hash keys
	return keys(%actions);
}

=head2 listMimetypes

This fetches a list of currently setup mimetypes.

The are no arguements for this.

    my @mimetypes=$zcr->listMimetypes();
    if($zcr->{error}){
        print "Error!\n";
    }

=cut

sub listMimetypes{
	my $self=$_[0];
	my $function='listMimetypes';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#
	my @mimetypes=$self->{zconf}->regexVarSearch('runner', '^mimetypes/');
	if($self->{zconf}->{error}){
		$self->{error}=1;
		$self->{errorString}=' ZConf error when searching for vars matching'.
		                     ' "^mimetypes/". ZConf error="'.$self->{zconf}->{error}.'" '.
		                     'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#
	my $mimetypesInt=0;
	#the types are stored as an hash
	my %mimehash;
	while (defined($mimetypes[$mimetypesInt])) {
		#splits the ZConf string apart
		my @mtA=split(/\//, $mimetypes[$mimetypesInt]);
		#puts the split back together
		#0='mimtetypes'
		#1=type
		#2=subtype
		#3=action
		#4='do' or 'type'
		my $mt=$mtA[1].'/'.$mtA[2];

		$mimehash{$mt}=$mt;
		
		$mimetypesInt++;
	}

	#returns an array of the hash keys
	return keys(%mimehash);
}

=head2 listSets

This lists the available sets.

    my @sets=$zcr->listSets;
    if($zcr->{error}){
        print "Error!";
    }

=cut

sub listSets{
	my $self=$_[0];
	my $function='listSets';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	my @sets=$self->{zconf}->getAvailableSets('runner');
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{errorString}='ZConf error listing sets for the config "runner".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return @sets;
}

=head2 newRunner

This creates a new runner. The only required arguement
is an hash. Please see the section below for the required
hash values.

=head3 hash args

=head4 mimetype

This is the mimetype for the new runner.

=head4 action

This action that will be done.

=head4 type

This is either 'exec' or 'desktop'.

=head4 do

If the 'exec' is specified as the type the specified program is used to run it. '%f' will
be replaced by the filename when it is ran.

If the 'desktop' is specified as the type 'File::MimeInfo::Applications' is used to run it.

    $zcr->newRunner({mimetye=>'application/pdf', action=>'view', type=>'exec', do=>'xpdf %f'})
    if($zcr->{error}){
        print "Error!\n";
    }

=cut

sub newRunner{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='newRunner';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#the required arguements
	my @reqArgs=('mimetype', 'action', 'type', 'do');

	#makes sure they are all defined
	my $reqArgsInt=0;
	while (defined($reqArgs[$reqArgsInt])) {
		#error if it is not defined
		if (!defined($args{$reqArgs[$reqArgsInt]})) {
			warn('ZConf-Runner newRunner:4: The arg "'.
				 $reqArgs[$reqArgsInt].'" is not defined.');
			$self->{error}=4;
			$self->{errorString}='The arg "'.$reqArgs[$reqArgsInt].'" is not defined.';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}

		$reqArgsInt++;
	}

	#make type is a legit value
	if ((!$args{type} eq 'desktop') && (!$args{type} eq 'exec')) {
		$self->{error}=6;
		$self->{errorString}='Type is not equal to "desktop" or "exec"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure that the action is a valid name
	if (!$self->validActionName($args{action})) {
		$self->{error}=5;
		$self->{errorString}='"'.$args{action}.'" is not a valid name';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#sets the type
	$self->{zconf}->setVar('runner', 'mimetypes/'.$args{mimetype}.'/'.
						   $args{action}.'/type', $args{type});
	if($self->{zconf}->{error}){
		$self->{error}=1;
		$self->{errorString}='ZConf error when writing the config "runner".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#sets the do
	$self->{zconf}->setVar('runner', 'mimetypes/'.$args{mimetype}.'/'.
						   $args{action}.'/do', $args{do});
	if($self->{zconf}->{error}){
		$self->{error}=1;
		$self->{errorString}='ZConf error when writing the config "runner".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
 		return undef;
	}

	#writes it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'runner'});
	if($self->{zconf}->{error}){
		$self->{error}=1;
		$self->{errorString}='ZConf error when writing the config "runner".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}


	return 1;
}

=head2 mimetypeIsSetup

This checks if a mimetype has been setup already. One arguement
is accepted. It is a string containing the name of mimetype.

    my $mimetype='image/jpeg';
    my $returned=$zcr->mimetypeIsSetup($mimetype);
    if($zcr->{error}){
        print "Error!\n";
    }
    if($returned){
        print $mimtetype." is configured already";
    }

=cut

sub mimetypeIsSetup{
	my $self=$_[0];
	my $mimetype=$_[1];
	my $function='mimetypeIsSetup';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#makes sure a type to check for is specified.
	if (!defined($mimetype)) {
		$self->{error}=4;
		$self->{errorString}='No mimetype specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#gets the list of mimetypes
	my @mimetypes=$self->listMimetypes();
	#return if the previous funtion errored
	if ($self->{error}) {
		warn('ZConf-Runner mimetypeIsSetup: listMimetypes failed');
		return undef;
	}

	#runs through the list and return true if it is found
	my $int=0;
	while (defined($mimetypes[$int])) {
		#if it is found it is setup and thus return true
		if ($mimetypes[$int] eq $mimetype) {
			return 1;
		}

		$int++;
	}

	#if we get here, it has not been found
	return undef;
}

=head2 readSet

This reads a specific set. If the set specified
is undef, the default set is read.

    #read the default set
    $zcr->readSet();
    if($zcr->{error}){
        print "Error!\n";
    }

    #read the set 'someSet'
    $zcr->readSet('someSet');
    if($zcr->{error}){
        print "Error!\n";
    }

=cut

sub readSet{
	my $self=$_[0];
	my $set=$_[1];
	my $function='readSet';
	
	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	$self->{zconf}->read({config=>'runner', set=>$set});
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}='ZConf error reading the config "runner".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 removeAction

This removes an action for a mimetype.

Two arguements are required. The first is the mimetype and
the second is the action.

    $zcr->removeAction('application/pdf', 'view');
    if($self->{error}){
        print "Error!\n";
    }

=cut

sub removeAction{
	my $self=$_[0];
	my $mimetype=$_[1];
	my $action=$_[2];
	my $function='removeAction';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#makes sure a mimetype to check for is specified.
	if (!defined($mimetype)) {
		$self->{error}=4;
		$self->{errorString}='No mimetype specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure a action to check for is specified.
	if (!defined($action)) {
		$self->{error}=4;
		$self->{errorString}='No action specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#this is the base name for the the variables
	my $baseVar='mimetypes/'.$mimetype.'/'.$action.'/';

	#We don't need to check the error here as it will be fine if validAction
	#uses this exact same function and will error on it.
	#gets the variables for it
	my %vars=$self->{zconf}->regexVarDel('runner', '^'.$baseVar);
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}='ZConf error for '.
		                     '$self->{zconf}->regexVarDel("runner", "^'.$baseVar.'). '.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#writes it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'runner'});
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{errorString}='ZConf error when writing the config "runner".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 validAction

This makes sure an action is valid. See the error code
for the reason it is not valid.

    $zcr->validAction('application/pdf', 'view');
    if($self->{error}){
        print 'Error:'.$self->{error}.': Action is not valid';
    }

=cut

sub validAction{
	my $self=$_[0];
	my $mimetype=$_[1];
	my $action=$_[2];
	my $function='validAction';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#makes sure a mimetype to check for is specified.
	if (!defined($mimetype)) {
		$self->{error}=4;
		$self->{errorString}='No mimetype specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure a action to check for is specified.
	if (!defined($action)) {
		$self->{error}=4;
		$self->{errorString}='No action specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#we don't need to check if the mimetype is setup as the following will do it as well
	#check if the action is setup
	my $returned=$self->actionIsSetup($mimetype, $action);
	if ($self->{error}) {
		warn('ZConf-Runner validAction: actionIsSetup("'.$mimetype.'","'.$action.'") errored');
		return undef;
	}

	#if it is false then the action is not setup
	if (!$returned) {
		$self->{error}=8;
		$self->{errorString}='"'.$action.'" is not configured';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#this is the base name for the the variables
	my $baseVar='mimetypes/'.$mimetype.'/'.$action.'/';

	#gets the variables for it
	my %vars=$self->{zconf}->regexVarGet('runner', '^'.$baseVar);
	if($self->{zconf}->{error}){
		$self->{error}=1;
		$self->{errorString}='ZConf error when doing regexVarGet for "^'.$baseVar
		                     .'". ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure type is defined
	if (!defined($vars{$baseVar.'type'})) {
		$self->{error}=9;
		$self->{errorString}='"'.$baseVar.'type" is not defined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure type is a valid value
	if (($vars{$baseVar.'type'} ne 'exec') &&
		($vars{$baseVar.'type'} ne 'desktop')) {
		$self->{error}=10;
		$self->{errorString}='"'.$baseVar.'type" is not a valid type';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure type is defined
	if (!defined($vars{$baseVar.'do'})) {
		$self->{error}=11;
		$self->{errorString}='"'.$baseVar.'do" is not defined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 validActionName

This makes sure that the action name is valid.

There is no reason to ever check $zcr->{error} with
this as this function will not set it. It just returns
a boolean value.

    if($zcr->validActionName('some/test')){
        print "Error\n";
    }

=cut

sub validActionName{
	my $self=$_[0];
	my $name=$_[1];
	my $function='validActionName';

	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#Makes sure it does not contain any forward slashes.
	if ($name =~ /\//) {
		return undef;
	}

	#Makes sure it does not begin with any spaces.
	if ($name =~ /^ /) {
		return undef;
	}

	#Makes sure it does not end with any spaces.
	if ($name =~ / $/) {
		return undef;
	}

	return 1;
}

=head2 validDesktopEntry

This checks to see if a desktop entry is valid. One value is accept
and that is file id name.

There is no reason to ever check $zcr->{error} with
this as this function will not set it. It just returns
a boolean value.

    if($zcr->validDesktopEntry('xemacs')){
        print "xeamcs is not a valid desktop entry\n";
    }

=cut

sub validDesktopEntry{
	my $self=$_[0];
	my $app=$_[1];
	my $function='validDesktopEntry';

	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#we don't pass any thing to new to prevent it from erroring...
	#File::DesktopEntry is buggy and will exit upon a failure in the new function...
	#fragging annoying...
	my $entry = File::DesktopEntry->new();

	#If it is defined it the entry exists.
	my $returned=$entry->lookup($app);

	#if it is defined, then an entry exists
	if (defined($returned)) {
		return 1
	}

	return undef;
}

=head2 Xavailable

This checks if X is available. This is checked for by trying to run
'xhost > /dev/null' and is assumed if a non-zero exit code is returned
then it failed and thus X is not available.

There is no reason to ever check $zcr->{error} with
this as this function will not set it. It just returns
a boolean value.

    if($zcr->Xavailable()){
        print "X is available\n";
    }

=cut

sub Xavailable{
	my $self=$_[0];
	my $function='Xavailable';

	$self->errorBlank;
	if ($self->{error}) {
		return undef;
	}

	#exists non-zero if it fails
	system('xhost > /dev/null');
	#if xhost exits with a non-zero then X is not available
	my $exitcode=$? >> 8;
	if ($exitcode ne '0'){
		return undef;
	}

	return 1;
}

=head2 errorBlank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorBlank{
        my $self=$_[0];
		my $function='errorBlank';

		if ($self->{perror}) {
			warn($self->{error}.' '.$function.': A permanent error is set. error="'.
				 $self->{error}.'" errorString="'.$self->{errorSting}.'"');
			return undef;
		}

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 ERROR CODES

The error code is contianed in $zcr->{error} and a extended description can be
found in $zcr->{errorString}. If any module ever sets $zcr->{perror} then the error
is permanent and none of the methods are usable.

=head2 1

Could not initialize ZConf.

=head2 2

ZConf error.

=head2 3

Failed to create the ZConf config 'runner'.

=head2 4

Missing function arguements.

=head2 5

Invalid action name.

=head2 6

Invalid type.

=head2 7

Mimetype not configured.

=head2 8

Action is not configured.

=head2 9

Missing type for an action.

=head2 10

Invalid action for an type.

=head2 11

'do' is not defined for the action.

=head2 12

Could not determine mimetype.

=head2 13

Desktop entry does not appear to be valid. It could not be found by 'lookup' in
'File::DesktopEntry'.

=head2 14

No desktop entry specified or none exists for this mimetype.

=head2 15

Curses::UI start problem

=head2 16

Curses::UI failed in some manner.

=head1 EXIT CODES

=head2 14

Quit selected.

=head2 15

The OK has been selected and the new runner has been added.

=head2 16

Error Code 14 happened when OK was selected.

=head2 17

'newRunner' errored.

=head2 18

Ask errored.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-runner at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Runner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Runner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Runner>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Runner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Runner>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Runner>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Runner
