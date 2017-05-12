package ZConf::Mail;

use Email::Simple;
use Email::Simple::Creator;
use Mail::IMAPTalk;
use Mail::POP3Client;
use ZConf;
use Net::SMTP_auth;
use Net::SMTP::TLS;
use Mail::Box::Manager;
use IO::MultiPipe;
use warnings;
use strict;
use MIME::Lite;
use File::MimeInfo::Magic;
use Email::Date;
use Sys::Hostname;
use MIME::QuotedPrint;
use Text::Autoformat;

=head1 NAME

ZConf::Mail - Misc mail client functions backed by ZConf.

=head1 VERSION

Version 2.0.0

=cut

our $VERSION = '2.0.0';


=head1 SYNOPSIS

    use ZConf::Mail;

    my $zcmail = ZConf::Mail->new();
    ...

=head1 METHODES

Any time you see account name or account, referenced outside of 'createAccount',
it means that it should also include the type as well. So for a POP3 account named
'test' it would be 'pop3/test'.

=head2 new

This initiates the module. The one arguement is accepted and it is a hash.

=head3 hash keys

=head4 zconf

This can be allows one to pass ZConf a specific set of arguements to be initialized
with.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='new';
	
	my $self={
			  error=>undef,
			  set=>undef,
			  perror=>undef,
			  module=>'ZConf-Mail',
			  };
	bless $self;


	if (!defined( $args{zconf} )) {
		$self->{zconf}=ZConf->new({});
		if ($self->{zconf}->error) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="It failed with '".$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'";
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return $self;
		}
	}else {
		$self->{zconf}=$args{zconf};
	}

	#sets $self->{init} to a Perl boolean value...
	#true=config does exist
	#false=config does not exist
	$self->{init}=undef;

	if ($self->{zconf}->configExists('mail')){
		$self->{init}=1;
		$self->{zconf}->read({config=>'mail'});
		if ($self->{zconf}->error) {
			$self->{error}=18;
			$self->{perror}=1;
			$self->{errorString}='Failed to read the ZConf config "mail"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return $self;
		}
	}

	#this defines legal values for later use
	$self->{legal}{pop3}=['user', 'pass', 'auth', 'useSSL',
						  'deliverTo', 'deliverToFolder', 'fetchable',
						  'server', 'port'];
	$self->{legal}{imap}=['user', 'pass', 'useSSL','deliverTo', 'deliverToFolder',
						  'fetchable', 'inbox', 'server', 'port', 'timeout'];
	$self->{legal}{mbox}=['mbox', 'deliverTo', 'deliverToFolder', 'fetchable'];
	$self->{legal}{smtp}=['user', 'pass', 'auth', 'useSSL',
						  'server', 'port', 'name', 'from',
						  'name', 'timeout', 'saveTo', 'saveToFolder', 
						  'usePGP', 'pgpType', 'PGPkey', 'PGPdigestAlgo'];
	$self->{legal}{maildir}=['maildir','deliverTo', 'deliverToFolder', 'fetchable'];
	$self->{legal}{exec}=['deliver'];
	$self->{legal}{formatter}=['marginLeft', 'marginRight', 'squeeze', 'ignore', 'justify', 'tabspace'];

	#this defines the required values for later use
	$self->{required}{pop3}=['user', 'pass', 'auth', 'useSSL',
						  'deliverTo', 'fetchable', 'server', 'port'];
	$self->{required}{imap}=['user', 'pass', 'useSSL',
						  'fetchable', 'inbox', 'server', 'port'];
	$self->{required}{mbox}=['mbox', 'deliverTo', 'fetchable'];
	$self->{required}{smtp}=['user', 'pass', 'auth', 'useSSL',
							 'server', 'port', 'name', 'from',
							 'name', 'timeout', 'saveTo'];
	$self->{required}{maildir}=['maildir','deliverTo', 'fetchable'];
	$self->{required}{exec}=['deliver'];

	#This contains a list of account types that are fetchable.
	$self->{fetchable}=['pop3', 'imap', 'maildir', 'mbox'];

	#This contains a list of account types that are deliverable.
	$self->{deliverable}=['exec','imap'];

	#This contains a list of account types that are sendable.
	#Listed for possible future purposes.
	$self->{sendable}=['smtp'];

	return $self;
}

=head2 accountExists

Checks to make sure a accont exists. One arguement is taken and that is the account name.

    if($zcmail->accountExists('pop3/foo)){
        print "pop3/foo does exist";
    }

=cut

sub accountExists{
	my $self=$_[0];
	my $account=$_[1];
	my $method='accountExists';

	#blanks any prevous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that. It also makes sure that
	#nothing past the account name is refered to.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#searches and finds any variables for the account
	my @matched=$self->{zconf}->regexVarSearch('mail', '^accounts/'.$account.'/');

	#If no variables are found, we can assume that it does not exist.
	if (!defined($matched[0])) {
		return undef;
	}

	return 1;
}

=head2 connectIMAP

This connects Mail::IMAPTalk connection to a IMAP account.

    #connects to the IMAP account 'imap/foo'
    my $imap=$zcmail->connectIMAP('imap/foo');
    if($zcmail->error)(
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    )

=cut

sub connectIMAP{
	my $self=$_[0];
	my $account=$_[1];
	my $method='connectIMAP';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;;
	}

	#No need to verify the account exists as $self->getsAccountArgs will do that.

	#gets the account variables
	my %avars=$self->getAccountArgs($account);

	#checks to make sure all the required variables are present
	my $requiredInt=0;
	while (defined($self->{required}{$split[0]}[$requiredInt])) {
		if (!defined($avars{$self->{required}{imap}[$requiredInt]})) {
			$self->{error}=32;
			$self->{errorString}='"'.$self->{required}{$split[0]}[$requiredInt].
			                     '" is undefined for the account "'.$account.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$requiredInt++;
	}

	#created outside of the SSL if statement to allow it to be exported SSL if statement
	my $imap;

	if (!$avars{useSSL}) {
		$imap=Mail::IMAPTalk->new(Server=>$avars{server},
								  Username=>$avars{user},
								  Password=>$avars{pass},
								  Uid=>0);
	}else {
		#creates the socket that will be used connect to IMAP
		my $socket=IO::Socket::SSL->new(PeerAddr=>$avars{server},
										PeerPort=>$avars{port},
										Proto=>'tcp');

		#creates the IMAP connection use to previously created socket
		$imap=Mail::IMAPTalk->new(Socket=>$socket,
								  Username=>$avars{user},
								  Password=>$avars{pass},
								  Uid=>0);		
	}

	#checks to see if it connected or not
	if (!$imap) {
		$self->{error}=9;
		$self->{errorString}='Failed to connect to IMAP server or authenticate';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return $imap;
}

=head2 connectMaildir

Creates a new Mail::Box::Maildir object for accessing the maildir.

    #connects to the maildir account 'maildir/foo'
    my $imap=$zcmail->connectMaildir('maildir/foo');
    if($zcmail->error)(
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    )

=cut

sub connectMaildir{
	my $self=$_[0];
	my $account=$_[1];
	my $method='connectMaildir';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#No need to verify the account exists as $self->getsAccountArgs will do that.

	#gets the account variables
	my %avars=$self->getsAccontArgs($account);

	#checks to make sure all the required variables are present
	my $requiredInt=0;
	while (defined($self->{required}{$split[0]}[$requiredInt])) {
		if (!defined($avars{$self->{required}{maildir}[$requiredInt]})) {
			$self->{error}=32;
			$self->{errorString}='"'.$self->{required}{$split[0]}[$requiredInt].
			                     '" is undefined for the account "'.$account.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$requiredInt++;
	}

	my $mgr=Mail::Box::Manager->new;
	my $maildir=$mgr->open(folder=>$avars{maildir}, access=>'rw', lock_file=>'NONE');

	#checks for an error
	if (!$maildir) {
		$self->{error}=14;
		$self->{errorString}='Failed to access the maildir, "'.$avars{maildir}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
	}

	return $maildir;
}

=head2 connectMbox

Creates a new Mail::Box::Mbox object for accessing the mbox.

    #connects to the mbox account 'mbox/foo'
    my $imap=$zcmail->connectMbox('mbox/foo');
    if($zcmail->error)(
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    )

=cut

sub connectMbox{
	my $self=$_[0];
	my $account=$_[1];
	my $method='connectMbox';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#No need to verify the account exists as $self->getsAccountArgs will do that.

	#gets the account variables
	my %avars=$self->getAccountArgs($account);

	#checks to make sure all the required variables are present
	my $requiredInt=0;
	while (defined($self->{required}{$split[0]}[$requiredInt])) {
		if (!defined($avars{$self->{required}{mbox}[$requiredInt]})) {
			$self->{error}=32;
			$self->{errorString}='"'.$self->{required}{$split[0]}[$requiredInt].
			                     '" is undefined for the account "'.$account.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$requiredInt++;
	}

	my $mgr=Mail::Box::Manager->new;
	my $mbox=$mgr->open(folder=>$avars{mbox}, access=>'rw', lock_file=>'NONE');

	#checks for an error
	if (!$mbox) {
		$self->{error}=14;
		$self->{errorString}='Failed to access the mbox, "'.$avars{mbox}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
	}

	return $mbox;
}

=head2 connectPOP3

This connects Mail::POP3Client connection to a POP3 account.

    #connects to the mbox account 'pop3/foo'
    my $imap=$zcmail->connectPOP3('pop3/foo');
    if($zcmail->error)(
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    )

=cut

sub connectPOP3{
	my $self=$_[0];
	my $account=$_[1];
	my $method='connectPOP3';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
	}

	#No need to verify the account exists as $self->getsAccountArgs will do that.

	#gets the account variables
	my %avars=$self->getAccountArgs($account);

	#checks to make sure all the required variables are present
	my $requiredInt=0;
	while (defined($self->{required}{$split[0]}[$requiredInt])) {
		if (!defined($avars{$self->{required}{pop3}[$requiredInt]})) {
			$self->{error}=32;
			$self->{errorString}='"'.$self->{required}{$split[0]}[$requiredInt].
			                     '" is undefined for the account "'.$account.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$requiredInt++;
	}

	#creates the connection
	my $pop = new Mail::POP3Client( USER=>$avars{user},
									PASSWORD=>$avars{pass},
									HOST=>$avars{server},
									PORT=>$avars{port},
									USESSL=>$avars{useSSL},
									AUTH_MODE=>$avars{auth}
								   );

	#If the state is equal to authorization it means we did not authenticate properly.
	if ($pop->State eq 'AUTHORIZATION') {
		$self->{error}=7;
		$self->{errorString}='Failed to authenticate with the server.'.
                   			 ' Mail::POP3Client->State="'.$pop->State.'"'.
		                     ' Mail::POP3Client->Message returned "'.$pop->Message.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#If the state is it means it failed to connect to the server.
	if ($pop->State eq 'DEAD') {
		$self->{error}=8;
		$self->{errorString}='Failed to connect to the server.'.
                   			 ' Mail::POP3Client->State="'.$pop->State.'"'.
		                     ' Mail::POP3Client->Message returned "'.$pop->Message.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
	}

	return $pop;
}

=head2 connectSMTP

This connects Mail::POP3Client connection to a POP3 account.

    #connects to the SMTP account 'smtp/foo'
    my $imap=$zcmail->connectSMTP('smtp/foo');
    if($zcmail->error)(
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    )

=cut

sub connectSMTP{
	my $self=$_[0];
	my $account=$_[1];
	my $method='connectSMTP';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#No need to verify the account exists as $self->getsAccountArgs will do that.

	#gets the account variables
	my %avars=$self->getAccountArgs($account);

	#checks to make sure all the required variables are present
	my $requiredInt=0;
	while (defined($self->{required}{$split[0]}[$requiredInt])) {
		if (!defined($avars{$self->{required}{smtp}[$requiredInt]})) {
			$self->{error}=32;
			$self->{errorString}='"'.$self->{required}{$split[0]}[$requiredInt].
			                     '" is undefined for the account "'.$account.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$requiredInt++;
	}

	#created outside of the SSL if statement to allow it to be exported SSL if statement
	my $smtp;

	#Unfortunately the error checking can't be moved out from this if statement
	#as Net::SMTP_auth and Net::SMTP::TLS both work a little different in regards
	#authentication.
	if ($avars{useSSL}) {
		my $smtp=Net::SMTP::TLS->new($avars{server},
									 Port=>$avars{port},
									 User=>$avars{user},
									 Password=>$avars{pass},
									 Timeout=>$avars{timeout});
		if (!$smtp) {
			$self->{error}=13;
			$self->{errorString}='Failed to connect to SMTP server';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}else {
		$smtp=Net::SMTP_auth->new($avars{server}.':'.$avars{port}, Timeout=>$avars{timeout});

		#error it it did not connect
		if (!defined($smtp)) {
			$self->{error}=10;
			$self->{errorString}='Failed to connect to SMTP server, "'
			                     .$avars{server}.':'.$avars{port}.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}

		#authenticate and error if it does not
		if (!$smtp->auth($avars{auth}, $avars{user}, $avars{pass})){
			$self->{error}=11;
			$self->{errorString}='Failed to authenticate with the SMTP server.';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}

	#sends the from information
	if (!$smtp->mail($avars{from})){
		$self->{error}=12;
		$self->{errorString}='Failed to connect to SMTP server';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef
	}

	return $smtp;
}



=head2 createAccount

This creates a new account. The only arguement accepted, and required, is a
hash. More information can be found below.

=head3 args hash

The required variables for a account can be found in the VARIABLES section.
Those listed below are also required by this function.

The two common ones are 'type' and 'account'. You should consult 'VARIABLES'
for the various posibilities for each account type.

=head4 type

This is the type of a account it is. It is always lower case as can be seen
in the variables section.

=head4 account

This is the name of the account. It will be appended after the account type.
Thus for the account 'pop3/some account name' it will be 'some account name'.

    #adds a POP3 server
    $zcmail->createAccount({type=>'pop3',
                            account=>'some account name',
                            user=>'monkey',
                            pass=>'ape',
                            auth=>'auto',
                            useSSL=>'0',
                            SSLoptions=>'',
                            deliverTo=>'',
                            fetchable=>'0',
                            server=>'127.0.0.1',
                            });
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub createAccount{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='createAccount';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#make sure the type is defined
	if (!defined($args{type})) {
		$self->{error}='2';
		$self->{errorString}='$args{type} is undefined';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#make sure it is a known type
	if (!defined($self->{required}{$args{type}})) {
		$self->{error}='3';
		$self->{errorString}='$args{type}, "'.$args{type}.'", not a valid value';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#make sure it is a legit account name
	if (!$self->{zconf}->setNameLegit($args{account})){
		$self->{error}='3';
		$self->{errorString}='$args{account}, "'.$args{account}.'", not a legit account name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#makes sure they are all defined
	my $requiredInt=0;
	while (defined($self->{required}{$args{type}}[$requiredInt])) {
		#make sure it is defined
		if (!defined($args{$self->{required}{$args{type}}[$requiredInt]})) {
			$self->{error}='3';
			$self->{errorString}='$args{'.$self->{required}{$args{type}}[$requiredInt].' is not defined';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}

		$requiredInt++;
	}

	#adds them
	$requiredInt=0;
	while (defined($self->{required}{$args{type}}[$requiredInt])) {
		my $variable='accounts/'.$args{type}.'/'.$args{account}.'/'.$self->{required}{$args{type}}[$requiredInt];
		
		#sets the value
		#not doing any error checking as there is no reason to believe it will fail
		$self->{zconf}->setVar('mail', $variable, $args{$self->{required}{$args{type}}[$requiredInt]});

		$requiredInt++;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'mail'});
	if ($self->{zconf}->{error}) {
		$self->{error}=36;
		$self->{errorString}='ZConf failed to write the set out.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 createEmailSimple

Creates a new Email::Simple object.

=head3 function args

=head4 account

This is the account is being setup for. If this is not
specified, the default one is used.

=head4 to

An array of To addresses.

=head4 cc

An array of CC addresses.

=head4 subject

The subject of the message.

=head4 body

The body of the message.

=cut

sub createEmailSimple{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='createEmailSimple';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}


	if (!defined($args{account})) {
		$args{account}=$self->defaultSendableGet;
	}

	#makes sure the args for the account, subject, and body are defined
	if (!defined($args{account}) || (!defined($args{subject}) || !defined($args{body}))) {
		$self->{error}='5';
		$self->{errorString}='A required hash arguement was not defined.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	my %Aargs=$self->getAccountArgs($args{account});
	if ($self->{error}) {
		warn('ZConf-Mail createEmailSimple: getAccountArgs errors');
		return undef;
	}
	
	#makes sure that either to or cc is given
	if (!defined($args{cc}) && !defined($args{to})) {
		warn('ZConf-Mail createEmailSimple:5: Neither to or cc given' );
		$self->{error}=5;
		$self->{errorString}='Neither to or cc given.';
		return undef;
	}

	my $mail=Email::Simple->create(header=>[Subject=>$args{subject}], body=>$args{body});

	if (!$mail) {
		$self->{error}=31;
		$self->{errorString}='Failed to create an Email::Simple object.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#process the to stuff
	if (defined($args{to})){
		my $to=join(', ', @{$args{to}});
		$mail->header_set('To'=>$to);
	}

	#process the cc stuff
	if (defined($args{cc}[0])){
		my $to=join(', ', @{$args{cc}});
		$mail->header_set('CC'=>$to);
	}

	my $shost=hostname;
	$shost=~s/\..*//g;
	$mail->header_set('Message-ID'=>'<'.rand().'.'.time().'.ZConf::Mail'.'@'.$shost.'>');

	$mail->header_set('Subject'=>$args{subject});

	$mail->header_set('From'=>$Aargs{name}.' <'.$Aargs{from}.'>');

	return $mail;
}

=head2 createMimeLite

This create a new MIME::Lite object.

This will also sign it if needed be.

=head3 args hash reference

The three following are required.

    account
    subject
    body

=head4 account

This is the account is being setup for. If no account
is specified, the default on is used.

=head4 to

An array of To addresses.

=head4 cc

An array of CC addresses.

=head4 subject

The subject of the message.

=head4 body

The body of the message.

=head4 files

An array of files to attach.

=head4 in-reply-to

This will set the in-reply-to header value.

=head4 dontSign

If is set to true and the account is set to sign by default, it won't be.

=head4 quiet

When created, call the quiet method.

This defaults to on as it will throw errors when doing GPG signing.

=cut

sub createMimeLite{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='createMimeLite';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	if (!defined($args{account})) {
		$args{account}=$self->defaultSendableGet;
	}

	#makes sure the args for the account, subject, and body are defined
	if (!defined($args{account}) || (!defined($args{subject}) || !defined($args{body}))) {
		$self->{error}='5';
		$self->{errorString}='A required hash arguement was not defined.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	my %Aargs=$self->getAccountArgs($args{account});
	if ($self->{error}) {
		warn('ZConf-Mail createMimeLite: getAccountArgs errors');
		return undef;
	}

	#shut the damn thing up if not told otherwise
	if (!defined($args{quiet})) {
		$args{quiet}=1;
	}

	#makes sure that either to or cc is given
	if (!defined($args{cc}[0]) && !defined($args{to}[0])) {
		$self->{error}=5;
		$self->{errorString}='Neither to or cc given.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#don't sign it if requested not to
	if (defined($args{dontSign}) &&  $args{dontSign}) {
		$Aargs{usePGP}=0;
	}

	#sign the message if needed
	my $signed;
	if ($Aargs{usePGP}) {
		my $to='';
		$signed=$self->sign($args{account}, $args{body}, $to);
		if ($self->{error}) {
			warn('ZConf-Mail createMimeLite: Signing required and sign failed');
			return undef;
		}

		if ($Aargs{pgpType} eq 'clearsign') {
			$args{body}=$signed;
		}
		
		if ($Aargs{pgpType} eq 'signencrypt') {
			$args{body}='';
		}
	}

	my $email=undef;

	if ($Aargs{usePGP}) {
		if ($Aargs{pgpType} eq 'clearsign') {
			$email=MIME::Lite->new(Type=>'multipart/signed');
			if ($args{quiet}) {
				$email->quiet;
			}
			$email->attach('Content-Type'=>'text/plain', Data=>$signed);
		}

		if ($Aargs{pgpType} eq 'mimesign') {
			$email=MIME::Lite->new(Type=>'multipart/signed');
			if ($args{quiet}) {
				$email->quiet;
			}

			$email->attr('content-type.protocol'=>'application/pgp-signature');

			my $hash='SHA512';
			if (defined($Aargs{PGPdigestAlgo})) {
				$hash=$Aargs{PGPdigestAlgo};
			}

			$email->attr('content-type.micalg'=>'PGP-'.$hash);

			$email->attach('Content-Type'=>'text/plain',
						   Encoding=>'quoted-printable',
						   Data=>$args{body});

			$email->attach(Type=>'application/pgp-signature',
						   Filename=>'signature.asc', Disposition=>'attachment',
						   Encoding=>'7bit',Data=>$signed);
		}

		if ($Aargs{pgpType} eq 'signencrypt') {
			$email=MIME::Lite->new(Type=>'multipart/signed');

			$email->attr('content-type'=>'multipart/encrypted');
			$email->attr('content-type.protocol'=>'application/pgp-encrypted');
			$email->attach('Content-Type'=>'application/pgp-encrypted',
						Data=>"Version: 1.0\n");
			$email->attach('Content-Type'=>'application/octet-stream',
						   Data=>$signed);
		}
	}else {
		$email=MIME::Lite->new(Data=>$args{body});
		if ($args{quiet}) {
			$email->quiet;
		}
	}

	#process the to stuff
	if (defined($args{to})){
		my $to=join(', ', @{$args{to}});
		$email->add('To'=>$to);
	}

	#process the cc stuff
	if (defined($args{cc}[0])){
		my $to=join(', ', @{$args{cc}});
		$email->add('CC'=>$to);
	}

	if (defined($args{'in-reply-to'})) {
		$email->add('In-Reply-To'=>$args{'in-reply-to'});
	}

	$email->add('Subject'=>$args{subject});

	$email->add('From'=>$Aargs{from});

	my $shost=hostname;
	$shost=~s/\..*//g;
	$email->add('Message-ID'=>'<'.rand().'.'.time().'.ZConf::Mail'.'@'.$shost.'>');

	#attach all the files
	my $int=0;
	while ($args{files}[$int]) {
		if (! -e $args{files}[$int]) {
			$self->{error}=38;
			$self->{errorString}='"'.$args{files}[0].'" does not exist';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}

		my $mimetype=mimetype($args{files}[$int]);

		$email->attach(Type=>$mimetype, Path=>$args{files}[$int]);

		$int++;
	}

	return $email;
}

=head2 defaultFetchableGet

This sets the default sendable email address.

    my $defaultFetchable=$zcmail->defaultFetchableGet;
    if(!defined($defaultFetchable)){
        print "There is no default sendable account.\n";
    }
    
    print $defaultFetchable."\n";

=cut

sub defaultFetchableGet{
	my $self=$_[0];
	my $method='defaultFetchableGet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	my %var=$self->{zconf}->regexVarGet('mail', '^default/fetchable$');

	if (!defined($var{'default/fetchable'})) {
		return undef;
	}

	if ($var{'default/fetchable'} eq '') {
		return undef;
	}

	return $var{'default/fetchable'};
}

=head2 defaultFetchableSet

This sets the default fetchable account.

    $zcmail->defaultFechableSet('smtp/foo');
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub defaultFetchableSet{
	my $self=$_[0];
	my $account=$_[1];
	my $method='defaultFetchableSet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
	}

	#make sure we have a account
	if (!defined($account)) {
		$self->{errorString}='No account specified.';
		$self->{error}='5';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}
	
	my $fetchable=$self->fetchable($account);
	if ($self->{error}) {
		warn('ZConf-Mail defaultFetchableSet: fetchable errored');
		return undef;
	}

	if (!$fetchable) {
		$self->{error}=24;
		$self->{errorString}='The account, "'.$account.'", is not sendable.';
		warn('ZConf-Mail defaultFetchableSet:24: '.$self->{errorString});
		return undef;
	}

	#sets the value
	#not doing any error checking as there is no reason to believe it will fail
	$self->{zconf}->setVar('mail', 'default/fetchable', $account);

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'mail'});
	if ($self->{zconf}->{error}) {
		$self->{errorString}='ZConf failed to write the set out.';
		$self->{error}=36;
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 defaultSendableGet

This sets the default sendable email account.

    my $defaultSendable=$zcmail->defaultSendableGet;
    if(!defined($defaultSendable)){
        print "There is no default sendable account.\n";
    }
    
    print $defaultSendable."\n";

=cut

sub defaultSendableGet{
	my $self=$_[0];
	my $method='defaultSendableGet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	my %var=$self->{zconf}->regexVarGet('mail', '^default/sendable$');

	if (!defined($var{'default/sendable'})) {
		return undef;
	}

	if ($var{'default/sendable'} eq '') {
		return undef;
	}

	return $var{'default/sendable'};
}

=head2 defaultSendableSet

This sets the default sendable email address.

    $zcmail->defaultSendableSet('smtp/foo');
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub defaultSendableSet{
	my $self=$_[0];
	my $account=$_[1];
	my $method='defaultSendableSet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#make sure we have a account
	if (!defined($account)) {
		$self->{errorString}='Account not specified.';
		$self->{error}='5';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}
	
	my $sendable=$self->sendable($account);
	if ($self->{error}) {
		warn('ZConf-Mail defaultSendableSet: sendable errored');
		return undef;
	}

	if (!$sendable) {
		$self->{error}=24;
		$self->{errorString}='The account, "'.$account.'", is not sendable.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#sets the value
	#not doing any error checking as there is no reason to believe it will fail
	$self->{zconf}->setVar('mail', 'default/sendable', $account);

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'mail'});
	if ($self->{zconf}->{error}) {
		$self->{errorString}='ZConf failed to write the set out.';
		$self->{error}=36;
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 defaultImapGet

This gets what the default IMAP account is.

=cut

sub defaultImapGet{
	my $self=$_[0];
	my $method='defaultImapGet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	my %var=$self->{zconf}->regexVarGet('mail', '^default/imap$');

	if (!defined($var{'default/imap'})) {
		return undef;
	}

	if ($var{'default/imap'} eq '') {
		return undef;
	}

	return $var{'default/imap'};
}

=head2 defaultImapSet

This gets what the default IMAP account is.

=cut

sub defaultImapSet{
	my $self=$_[0];
	my $account=$_[1];
	my $method='defaultImapSet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#make sure we have a account
	if (!defined($account)) {
		$self->{errorString}='Account not specified.';
		$self->{error}='5';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}
	
	my $sendable=$self->sendable($account);
	if ($self->{error}) {
		warn('ZConf-Mail defaultSendableSet: sendable errored');
		return undef;
	}

	#sets the value
	#not doing any error checking as there is no reason to believe it will fail
	$self->{zconf}->setVar('mail', 'default/imap', $account);

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'mail'});
	if ($self->{zconf}->{error}) {
		$self->{errorString}='ZConf failed to write the set out.';
		$self->{error}=36;
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 delAccount

This is used for removed a account. One option is taken and that is the name of the account.

   #removes the account 'mbox/foo'
   $zcmail->delAccount('mbox/foo');
   if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
   }

=cut

sub delAccount{
	my $self=$_[0];
	my $account=$_[1];
	my $method='delAccount';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that. It also makes sure that
	#nothing past the account name is refered to.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#makes sure the account exists
	if (!$self->accountExists($account)) {
		$self->{error}=6;
		$self->{errorString}='"'.$account.'" does not exist';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#removes the variables
	#Off hand I can't think of a reason it should fail at this point.
	my @deleted=$self->{zconf}->regexVarDel('mail', '^accounts/'.$account.'/');

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'mail'});
	if ($self->{zconf}->{error}) {
		$self->{error}=36;
		$self->{errorString}='ZConf failed to write the set out.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 deliverable

This checks if a acocunt is deliverable or not.

    #check to see if the account is a account that can be delivered to
    if(!zcmail->deliverable('exec/foo')){
        print "Not deliverable.";
    }

=cut

sub deliverable{
	my $self=$_[0];
	my $account=$_[1];
	my $method='deliverable';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that. It also makes sure that
	#nothing past the account name is refered to.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#makes sure the account exists
	if (!$self->accountExists($account)) {
		$self->{error}=6;
		$self->{errorString}='The account "'.$account.'" does not exist';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#checks to make sure that is a account type that is deliverable
	my $int=0;
	while(defined($self->{deliverable}[$int])){
		#If it is matched set $matched to true.
		if ($self->{deliverable}[$int] eq $split[0]) {
			return 1;
		}

		$int++;
	}

	return undef;
}

=head2 deliver

This is a wrapper function to the other deliver functions. This is a
wrapper to the other delivery functions.

The first arguement is the account. The second is the message. The
third is the a hash that some deliver types optionally use.

=head3 args hash

=head4 folder

This can be used to specify a folder to deliver to. If it is not
defined, it will try to use what ever is the inbox for that account.

Currently this is only used by IMAP.

    #delivers the mail contained in $mail to 'exec/foo'
    $zcmail->deliver('exec/foo', $mail);
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

    #delivers the mail contained in $mail to 'imap/foo' to the 'foo.bar'
    $zcmail->deliver('imap/foo', $mail, {folder=>'foo.bar'});
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub deliver{
	my $self=$_[0];
	my $account=$_[1];
	my $mail=$_[2];
	my %args;
	if(defined($_[3])){
		%args= %{$_[3]};
	}
	my $method='deliver';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#makes sure the account can be delivered to
	if (!$self->deliverable($account)) {
		$self->{error}='15';
		$self->{errorString}='"'.$account.'" is not deliverable';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#delivers it to a exec account
	if ($account =~ /^exec\//) {
		if (!$self->deliverExec($account, $mail)) {
			warn('ZConf-Mail deliver:'.$self->{error}.': '.$self->{errorString});
			return undef;
		}		
	}

	#delivers it to a imap account
	if ($account =~ /^imap\//) {
		if (!$self->deliverIMAP($account, $mail, \%args)) {
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}

	return 1;
}

=head2 deliverExec

This is a delivers to a exec account.

It is generally not best to call it directly, but to let the deliver
function route it. This allows for more flexible delivery.

The first arguement is the account. The second is the message. The
third is the a optional args hash.

    #delivers the mail contained in $mail to 'exec/foo'
    $zcmail->deliverExec('exec/foo', $mail);
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub deliverExec{
	my $self=$_[0];
	my $account=$_[1];
	my $mail=$_[2];
	my $method='deliverExec';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#delivers it to a exec account
	if (!$account =~ /^exec\//) {
		$self->{error}=19;
		$self->{errorString}='"'.$account.'" is not a exec account';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#Make sure the command is defined.
	if (!defined($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/deliver'})) {
		$self->{error}=5;
		$self->{errorString}='"'.$account.'" is missing the variable "deliver"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;		
	}

	#sets up the pipe
	my $pipe=IO::MultiPipe->new;
	$pipe->set($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/deliver'});
	if ($pipe->{error}) {
		$self->{error}=20;
		$self->{errorString}='O::MultiPipe errored. $pipe->{error}="'
		                     .$pipe->{error}.'" $pipe->{errorString}="'
							 .$pipe->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#runs it
	$pipe->run($mail);
	if ($pipe->{error}) {
		$self->{error}=20;
		$self->{errorString}='O::MultiPipe errored. $pipe->{error}="'
		                     .$pipe->{error}.'" $pipe->{errorString}="'
							 .$pipe->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 deliverIMAP

This is a delivers to a IMAP account.

It is generally not best to call it directly, but to let the deliver
function route it. This allows for more flexible delivery.

    #delivers the mail contained in $mail to 'imap/foo' to the inbox
    $zcmail->deliverIMAP('imap/foo', $mail);
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

    #delivers the mail contained in $mail to 'imap/foo' to the 'foo.bar'
    $zcmail->deliverIMAP('imap/foo', $mail, {folder=>'foo.bar'});
    if($zcmail->{error}){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub deliverIMAP{
	my $self=$_[0];
	my $account=$_[1];
	my $mail=$_[2];
	my %args;
	if(defined($_[3])){
		%args= %{$_[3]};
	}
	my $method='deliverIMAP';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#delivers it to a exec account
	if (!$account =~ /^imap\//) {
		$self->{error}=19;
		$self->{errorString}='"'.$account.'" is not a IMAP account';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#connects to the IMAP server
	my $imap=$self->connectIMAP($account);
	if ($self->{error}) {
		warn('ZConf-Mail fetchIMAP:22: Failed to connect to the IMAP server.');
		return undef;
	}

	#make sure we have a folder
	if (!defined($args{folder})) {
		#Make sure the command is defined.
		if (!defined($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/inbox'})) {
			$self->{error}=33;
			$self->{errorString}='"'.$account.'" is missing the variable "inbox"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;		
		}
		
		$args{folder}=$self->{zconf}->{conf}{mail}{'accounts/'.$account.'/inbox'};
	}

	#make sure the folder exists
	my $select=$imap->select($args{folder});
	if (!$select) {
		$self->{error}=34;
		$self->{errorString}='Failed to select folder "'.$args{folder}.
		                     '"for account "'.$account.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	my $append=$imap->append($args{folder}, ['Literal', $mail]);
	if (!$append) {
		$self->{error}=35;
		$self->{errorString}='Failed to append to folder "'.$args{folder}.
		                     '"for account "'.$account.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 fetch

This is a wrapper function for the other accounts. The only accepted arg
is account name. If no account is specified, the default one is used.

It is then delivered to the account specified by variable 'deliverTo' for
the account.

    #fetches the mail for 'pop3/foo'
    $zcmail->fetch('pop3/foo');
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub fetch{
	my $self=$_[0];
	my $account=$_[1];
	my $method='fetch';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#gets the default fetchable account if no account is given
	if (!defined($account)) {
		$account=$self->defaultFetchableGet;
	}

	#if we get to this point it means the account does has not
	#been specified and no default account exists
	if (!defined($account)) {
		$self->{error}=5;
		$self->{errorString}='No account specified and there is no default fetchable account.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	if (!$self->fetchable($account)) {
		$self->{error}='15';
		$self->{errorString}='"'.$account.'" is not fetchable';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#used for returning the number fetched
	my $fetched;

	#Fetches a account if it is a POP3 account.
	if ($account =~ /^pop3\//) {
	    $fetched=$self->fetchPOP3($account);
		if (!defined($fetched)) {
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}

	#Fetches a account if it is a mbox account.
	if ($account =~ /^mbox\//) {
	    $fetched=$self->fetchMbox($account);
		if (!defined($fetched)) {
			warn('ZConf-Mail fetch:'.$self->{error}.': '.$self->{errorString});
			return undef;
		}
	}

	#Fetches a account if it is a maildir account.
	if ($account =~ /^maildir\//) {
	    $fetched=$self->fetchMaildir($account);
		if (!defined($fetched)) {
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}

	#Fetches a account if it is a maildir account.
	if ($account =~ /^imap\//) {
	    $fetched=$self->fetchIMAP($account);
		if (!defined($fetched)) {
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}

	return $fetched;
}

=head2 fetchable

This checks if a account is fetchable or not. The reason for the existance it
to make some things look neater.

=cut

sub fetchable{
	my $self=$_[0];
	my $account=$_[1];
	my $method='fetchable';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that. It also makes sure that
	#nothing past the account name is refered to.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#makes sure the account exists
	if (!$self->accountExists($account)) {
		$self->{error}=6;
		$self->{errorString}='The account "'.$account.'" does not exist';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	my $int=0;
	while(defined($self->{fetchable}[$int])){
		#If it is matched set $matched to true.
		if ($self->{fetchable}[$int] eq $split[0]) {
			return $self->{zconf}->{conf}{mail}{'accounts/'.$account.'/fetchable'};
		}
		$int++;
	}

	#Returns undef if the account type was not matched.
	return undef;
}


=head2 fetchIMAP

Fetches the messages from the inbox of a IMAP account.

    my $number=$mail->fetchIMAP('imap/foo');
    if($mail->error}){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }else{
        print 'Fetched '.$number."messages.\n";
    }

=cut

sub fetchIMAP{
	my $self=$_[0];
	my $account=$_[1];
	my $method='fetchIMAP';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#makes sure it is fetchable
	if (!$self->fetchable($account)) {
		$self->{error}='15';
		$self->{errorString}='"'.$account.'" is not fetchable';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#returns
	if (!defined($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/inbox'})) {
		$self->{error}=5;
		$self->{errorString}='No IMAP inbox defined';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#connects to the IMAP server
	my $imap=$self->connectIMAP($account);
	if ($self->{error}) {
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#selects the proper folder
	if (!$imap->select($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/inbox'})) {
#	if (!$imap->select('Inbox')) {
		$self->{error}=23;
		$self->{errorString}='Failed to select IMAP folder "'.
		    $self->{zconf}->{conf}{mail}{'accounts/'.$account.'/inbox'}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#gets the number of messages
	my $count=$imap->message_count($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/inbox'});

	#processes each one
	my $countInt=1;
	while ($countInt <= $count && $count > 0) {
		my $mail=$imap->fetch($countInt, 'rfc822');
		if ($?) {
			warn('ZConf-Mail fetchImap:22: $imap->fetch('.$countInt.', \'rfc822\') failed');
			$self->{error}=22;
			$self->{errorString}='$imap->fetch('.$countInt.', \'rfc822\') failed';
			return undef;
		}

		#delivers the fetched message.
		$self->deliver($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/deliverTo'},
					   $mail->{$countInt}{rfc822});
		if ($self->{error}) {
			warn('ZConf-Mail fetchIMAP:'.$self->{error}.': Delivery error');
			return undef;
		}

		#removes the old one
		if (!$imap->store($countInt, , '+flags', '(\\deleted)')) {
			$self->{error}=21;
			$self->{errorString}='$mbox->message('.$countInt.')->delete failed';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$imap->expunge();
		
		$countInt++;
	}

	return $count;
}

=head2 fetchMaildir

Fetches the messages from the inbox of a maildir account.

    my $number=$mail->fetchMaildir('maildir/foo');
    if($mail->{error}}){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }else{
        print 'Fetched '.$number."messages.\n";
    }

=cut

sub fetchMaildir{
	my $self=$_[0];
	my $account=$_[1];
	my $method='fetchMaildir';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#makes sure it is fetchable
	if (!$self->fetchable($account)) {
		$self->{error}='15';
		$self->{errorString}='"'.$account.'" is not fetchable';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	my $maildir=$self->connectMaildir($account);

	if ($self->{error}) {
		warn('ZConf-Mail fetchMaildir:16: Failed to connect to the maildir.');
		return undef;
	}

	#gets the number of messages
	my $count=$maildir->nrMessages;
	#This is done as the function above returns an extra one.
	$count--;

	#processes each one
	my $countInt=0;
	while ($countInt < $count && $count > 0) {
		my $mail=$maildir->message($countInt)->string;
		if ($?) {
			$self->{error}=22;
			$self->{errorString}='$mbox->message('.$countInt.')->print failed';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}

		#delivers the fetched message.
		$self->deliver($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/deliverTo'},
					   $mail);
		if ($self->{error}) {
			warn('ZConf-Mail fetchMbox:'.$self->{error}.': Delivery error');
			return undef;
		}

		#removes the old one
		if (!$maildir->message($countInt)->delete) {
			$self->{error}=21;
			$self->{errorString}='$mbox->message('.$countInt.')->delete failed';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		
		$countInt++;
	}

	return $count;
}

=head2 fetchMbox

Fetches the messages from the inbox of a mbox account.

    my $number=$mail->fetchMbox('mbox/foo');
    if($mail->{error}}){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }else{
        print 'Fetched '.$number."messages.\n";
    }

=cut

sub fetchMbox{
	my $self=$_[0];
	my $account=$_[1];
	my $method='fetchMbox';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#makes sure it is fetchable
	if (!$self->fetchable($account)) {
		$self->{error}='15';
		$self->{errorString}='"'.$account.'" is not fetchable';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	my $mbox=$self->connectMbox($account);

	if ($self->{error}) {
		warn('ZConf-Mail fetchMbox:16: Failed to connect to the mbox.');
		return undef;
	}

	#gets the number of messages
	my $count=$mbox->nrMessages;
	#This is done as the function above returns an extra one.
	$count--;

	#processes each one
	my $countInt=0;
	while ($countInt < $count && $count > 0) {

		my $mail=$mbox->message($countInt)->string;
		if ($?) {
			$self->{error}=22;
			$self->{errorString}='$mbox->message('.$countInt.')->print failed';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}

		#delivers the fetched message.
		$self->deliver($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/deliverTo'},
					   $mail);
		if ($self->{error}) {
			warn('ZConf-Mail fetchMbox:'.$self->{error}.': Delivery error');
			return undef;
		}

		#removes the old one
		if (!$mbox->message($countInt)->delete) {
			$self->{error}=21;
			$self->{errorString}='$mbox->message('.$countInt.')->delete failed';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		
		$countInt++;
	}

	return $count;
}

=head2 fetchPOP3

Fetches the messages from the inbox of a POP3 account.

    my $number=$mail->fetchPOP3('pop3/foo');
    if($mail->{error}}){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }else{
        print 'Fetched '.$number."messages.\n";
    }

=cut

sub fetchPOP3{
	my $self=$_[0];
	my $account=$_[1];
	my $method='fetchPOP3';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#makes sure it is fetchable
	if (!$self->fetchable($account)) {
		$self->{error}='15';
		$self->{errorString}='"'.$account.'" is not fetchable';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	my $pop=$self->connectPOP3($account);

	if ($self->{error}) {
		warn('ZConf-Mail fetchPOP3:16: Failed to connect to the POP3 server.');
		return undef;
	}

	#fetches the messages
	my $count=$pop->Count();
	my $countInt=1;
	while ($countInt <= $count && $count > 0) {

		my $mail=$pop->Retrieve($countInt);
		if ($?) {
			$self->{error}=17;
			$self->{errorString}='$pop->Retrieve failed. $?="'.$?.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}


		#delivers the fetched message.
		$self->deliver($self->{zconf}->{conf}{mail}{'accounts/'.$account.'/deliverTo'},
					   $mail);
		if ($self->{error}) {
			warn('ZConf-Mail fetchPOP3:'.$self->{error}.': Delivery error');
			return undef;
		}

		#removes the old one
		if (!$pop->Delete($countInt)) {
			$self->{error}=17;
			$self->{errorString}='$pop->Delete failed. $?="'.$?.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}

		$countInt++;
	}

	#returns the number of fetched messages
	return $count;
}

=head2 formatter

Automatically format a chunk of text against various settings,
primarily line wrapping.

    $text=$zcmail->formatter($text);
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub formatter{
	my $self=$_[0];
	my $text=$_[1];
	my $method='formatter';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	my %f=$self->{zconf}->regexVarGet('mail', '^formatter/');

	if (!defined($f{'formatter/marginLeft'})) {
		$f{'formatter/marginLeft'}=0;
	}

	if (!defined($f{'formatter/marginRight'})) {
		$f{'formatter/marginRight'}=72;
	}

	if (!defined($f{'formatter/squeeze'})) {
		$f{'formatter/squeeze'}=1;
	}

	if (!defined($f{'formatter/ignoree'})) {
		$f{'formatter/ignore'}='^[ \t]';
	}

	if (!defined($f{'formatter/justify'})) {
		$f{'formatter/justify'}='left';
	}

	if (!defined($f{'formatter/tabspace'})) {
		$f{'formatter/tabspace'}='4';
	}

	my $ignore=$f{'formatter/justify'};

	$text=autoformat($text, {left=>$f{'formatter/marginLeft'},
							 right=>$f{'formatter/marginRight'},
							 squeeze=>$f{'formatter/squeeze'},
							 justify=>$f{'formatter/justify'},
							 ignore=>qr/$ignore/,
							 all=>1});

	return $text;
}

=head2 formatterGetAll

Get all options for the formatter.

    my %formatterOptions=$zcmail->formatterGetAll;
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }else{
          print 'marginLeft:'.formatterOptions{marginLeft}."\n".
                'marginRight:'.formatterOptions{marginRight}."\n".
                'squeeze:'.formatterOptions{squeeze}."\n".
                'ignore:'.formatterOptions{ignore}."\n".
                'justify:'.formatterOptions{justify}."\n".
                'tabspace:'.formatterOptions{tabspace}."\n";
    }

=cut

sub formatterGetAll{
	my $self=$_[0];
	my $method='formatterGet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#gets all formatter variables that are defined
	my %returned=$self->{zconf}->regexVarSearch('mail', '^formatter\/');
	if ($self->{zconf}->error) {
		$self->{error}=36;
		$self->{errorString}='ZConf errored. error='.$self->{zconf}->error.' errorString='.$self->{zconf}->errorString;
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#this will be returned
	my %toreturn;

	#handle the marginLeft value
	if (defined( $returned{'formatter/marginLeft'} )) {
		$toreturn{'marginLeft'}=$returned{'formatter/marginLeft'};
	}else {
		$toreturn{'marginLeft'}=0;		
	}

	#handle the marginRight value
	if (defined( $returned{'formatter/marginRight'} )) {
		$toreturn{'marginRight'}=$returned{'formatter/marginRight'};
	}else {
		$toreturn{'marginRight'}=72;
	}

	#handle the squeeze value
	if (defined( $returned{'formatter/squeeze'} )) {
		$toreturn{'squeeze'}=$returned{'formatter/squeeze'};
	}else {
		$toreturn{'squeeze'}=1;
	}

	#handle the ignore value
	if (defined( $returned{'formatter/ignore'} )) {
		$toreturn{'ignore'}=$returned{'formatter/ignore'};
	}else {
		$toreturn{'ignore'}='^[ \t]';
	}

	#handle the justify value
	if (defined( $returned{'formatter/justify'} )) {
		$toreturn{'justify'}=$returned{'formatter/justify'};
	}else {
		$toreturn{'justify'}='left';
	}

	#handle the justify value
	if (defined( $returned{'formatter/tabspace'} )) {
		$toreturn{'tabspace'}=$returned{'formatter/tabspace'};
	}else {
		$toreturn{'tabspace'}='4';
	}

	return %toreturn;
}

=head2 formatterSet

Set some options for the formatter.

Two arguments are required.

The first is the option to operate on.

The second is the value. A value of undef will result it being removed,
there for the default being used when formatterGetAll is called.

    #set the text justification to the right
    $zcmail->formatterSet('justify', 'right');
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

    #set the text justification back to the default
    $zcmail->formatterSet('justify', undef);
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub formatterSet{
	my $self=$_[0];
	my $option=$_[1];
	my $value=$_[2];
	my $method='formatterGet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#make sure a option is specified
	if (!defined( $option )) {
		$self->{error}=5;
		$self->{errorString}='No option specified';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#makes sure it is a valid option
	my $int=0;
	my $matched=0;
	while (defined( $self->{legal}{formatter}[$int] )) {
		if ($self->{legal}{formatter}[$int] eq $option) {
			$matched=1;
		}

		$int++;
	}
	if (!$matched) {
		$self->{error}=45;
		$self->{errorString}='"'.$option.'" is not a valid formatter option';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#decides what to do with it
	if (!defined($value)) {
		$self->{zconf}->regexVarDel('mail', '^formatter\/'.$option.'$');
		if ($self->{zconf}->error) {
			$self->{errorString}='ZConf error. error='.$self->{zconf}->error.' errorString='.$self->{zconf}->errorString;
			$self->{error}=36;
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}else {
		$self->{zconf}->setVar('mail', 'formatter/'.$option, $value);
		if ($self->{zconf}->error) {
			$self->{errorString}='ZConf error. error='.$self->{zconf}->error.' errorString='.$self->{zconf}->errorString;
			$self->{error}=36;
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'mail'});
	if ($self->{zconf}->error) {
		$self->{errorString}='ZConf failed to write the set out.';
		$self->{error}=36;
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 getAccounts

Gets a array of the various accounts.

    my @accounts=$zcmail->getAccounts;
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub getAccounts{
	my $self=$_[0];
	my $method='getAccounts';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#searches the mail config for any thing under 'acounts/'
	my @matched=$self->{zconf}->regexVarSearch('mail', '^accounts/');

	my $matchedInt=0;

	my %accountsH;

	#goes through the list and splits it apart...
	#A hash is used for this as this operates on every key under a account... this means
	#it will be finding multiple hits for each account
	while (defined($matched[$matchedInt])) {
		my @split=split(/\//, $matched[$matchedInt],4);
		$accountsH{$split[1].'/'.$split[2]}='';
		
		$matchedInt++;
	}

	#returns a array of the accounts
	return keys(%accountsH);
}

=head2 getAccountArgs

This gets the various variables for a account, with 'accounts/*/*/' removed.

One arguement is required and that is the account name.

    #get the account args for 'pop3/foo'
    my %args=$zcmail->getAccountArgs('pop3/foo');
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub getAccountArgs{
	my $self=$_[0];
	my $account=$_[1];
	my $method='getAccountArgs';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that. It also makes sure that
	#nothing past the account name is refered to.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#
	if (!$self->accountExists($account)) {
		$self->{error}=6;
		$self->{errorString}='The account "'.$account.'" does not exist';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#gets the variables for the account.
	my %vars=$self->{zconf}->regexVarGet('mail', '^accounts/'.$account.'/');

	my @keys=keys(%vars);
	my $keysInt=0;
	while (defined($keys[$keysInt])) {
		my $newvar=$keys[$keysInt];
		#removes the prefixed stuff for the variables for the account
		$newvar=~s/^accounts\/$account\///;

		#copies it
		$vars{$newvar}=$vars{$keys[$keysInt]};

		#removes the original
		delete($vars{$keys[$keysInt]});

		$keysInt++;
	}

	return %vars;
}

=head2 getSet

This gets what the current set is.

    my $set=$zcmail->getSet;
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub getSet{
	my $self=$_[0];
	my $method='getSet';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	my $set=$self->{zconf}->getSet('mail');
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{errorString}='ZConf error getting the loaded set the config "mail".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return $set;
}

=head2 init

This is used for initiating the config used by ZConf.

    $zcmail->init;
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub init{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='init';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#creates the config if needed
	if (!$self->{zconf}->configExists("mail")){
		if ($self->{zconf}->createConfig('mail')){
			$self->{error}=8;
			$self->{errorString}='Could not create the config. $self->{zconf}->{error}="'.
			    $self->{zconf}->{error}.'" $self->{zconf}->{errorString}="'.
			    $self->{zconf}->{errorString}.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
	}

	return 1;
}

=head2 listSets

This lists the available sets.

    my @sets=$zcmail->listSets;
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub listSets{
	my $self=$_[0];
	my $method='listSets';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	my @sets=$self->{zconf}->getAvailableSets('mail');
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{errorString}='ZConf error listing sets for the config "mail".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return @sets;
}

=head2 modAccount

Modifies a account.

=head3 args hash

Outside of account type, the rest are variables that will be changed.

=head4 type

This is the type of a account it is. It is always lower case as can be
seen in the variables section.

=head4 account

This is the name of the account. It will be appended after the account
type. Thus for the account 'pop3/some account name' it will be
'some account name'.

=cut

sub modAccount{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='modAccount';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#make sure the type is defined
	if (!defined($args{type})) {
		$self->{error}='2';
		$self->{errorString}='$args{type} is undefined';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#make sure it is a known type
	if (!defined($self->{legal}{$args{type}})) {
		$self->{error}='3';
		$self->{errorString}='$args{type}, "'.$args{type}.'", not a valid value';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#make sure it is a legit account name
	if (!$self->{zconf}->setNameLegit($args{account})){
		$self->{error}='3';
		$self->{errorString}='$args{account}, "'.$args{account}.'", not a legit account name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#puts together the accountname
	my $account=$args{type}.'/'.$args{account};

	#makes sure the account exists
	if (!$self->accountExists($account)) {
		$self->{error}=6;
		$self->{errorString}='The account "'.$account.'" does not exist';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#adds them
	my $int=0;
	while (defined($self->{legal}{$args{type}}[$int])) {
		my $variable='accounts/'.$args{type}.'/'.$args{account}.'/'.$self->{legal}{$args{type}}[$int];

		#sets the value
		#not doing any error checking as there is no reason to believe it will fail
		$self->{zconf}->setVar('mail', $variable, $args{$self->{legal}{$args{type}}[$int]});

		$int++;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'mail'});
	if ($self->{zconf}->{error}) {
		$self->{error}=36;
		$self->{errorString}='ZConf failed to write the set out.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 readSet

This reads a specific set. If the set specified
is undef, the default set is read.

    #read the default set
    $zcmail->readSet();
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

    #read the set 'someSet'
    $zcmail->readSet('someSet');
    if($zcmail->error){
        warn('Error:'.$zcmail->error.': '.$zcmail->errorString);
    }

=cut

sub readSet{
	my $self=$_[0];
	my $set=$_[1];
	my $method='readSet';
	
	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	$self->{zconf}->read({config=>'mail', set=>$set});
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}='ZConf error reading the config "mail".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 send

This sends a email. One arguement is accepted and that is a hash.

=head3 args hash

=head4 account

This is the account it is sending for. If this is not specified,
the default sendable account is used.

=head4 to

This is a array of to addresses.

=head4 cc

This is a array of cc addresses.

=head4 bcc

This is a array of bcc addresses.

=head4 mail

This is the raw mail message to send.

=head4 save

This will override if a sent message will be saved or not.

=cut

sub send{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='send';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	if (!defined($args{account})) {
		$args{account}=$self->defaultSendableGet;
	}

	#makes sure we have mail
	if (!defined($args{mail})) {
		$self->{error}=5;
		$self->{errorString}='The hash arg "mail" is missing and thus nothing to send';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#creates the SMTP connection
	my $smtp=$self->connectSMTP($args{account});
	if ($self->{error}) {
		warn('ZConf-Mail send:'.$self->{error}.': Failed to establish an SMTP connection');
		return undef;
	}

	$smtp->mail($self->{zconf}->{conf}{mail}{'accounts/'.$args{account}.'/from'});

	#sends the to addresses
	my $int=0;
	while (defined($args{to}[$int])) {
		$smtp->to($args{to}[$int]);
		if ($?) {
			$self->{error}=26;
			$self->{errorString}='Failed to send the To address "'.$args{to}[$int].'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		}
		$int++;
	}

	#sends the cc addresses
	$int=0;
	while (defined($args{cc}[$int])) {
		$smtp->to($args{cc}[$int]);
		if ($?) {
			$self->{error}=26;
			$self->{errorString}='Failed to send the CC address "'.$args{cc}[$int].'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		}
		$int++;
	}

	#sends the bcc addresses
	$int=0;
	while (defined($args{bcc}[$int])) {
		$smtp->to($args{bcc}[$int]);
		if ($?) {
			$self->{error}=26;
			$self->{errorString}='Failed to send the BCC address "'.$args{bcc}[$int].'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		}
		$int++;
	}

	#tries to start the data session
	if (!$smtp->data) {
		$self->{error}=27;
		$self->{errorString}='Failed to start the data session.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
	}

	#sends the data
	if (!$smtp->datasend($args{mail})) {
		$self->{error}=28;
		$self->{errorString}='Failed to send the data.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
	}

	#ends the data session
	#Not currently doing error checking as this appears to error occasionally
	#with out any detectable reason.
	if (!$smtp->dataend) {
#		warn('ZConf-Mail send:29: Failed to end the data.');
#		$self->{error}=29;
#		$self->{errorString}='Failed to end the data session.';
	}

	#quits
	if (!$smtp->quit) {
		$self->{error}=30;
		$self->{errorString}='Failed to end the SMTP session.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
	}

	#we know it has args if we get this far so we don't have to check it
	my %acctArgs=$self->getAccountArgs($args{account});

	#saves it if asked
	if ($args{save}) {
		if (!defined($acctArgs{saveTo})) {
			$self->{error}=37;
			$self->{errorString}='saveTo is undefined and thus the mail can\'t be saved.';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}

		if ($acctArgs{saveTo}=~ /^$/) {
			$self->{error}=37;
			$self->{errorString}='saveTo is is set to "" and thus the mail can\'t be saved';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		
		$self->deliver($acctArgs{saveTo}, $args{mail},{folder=>$acctArgs{folder}});
		if ($self->{error}) {
			warn('ZConf-BGSet send: deliver errored');
			return undef;
		}

		return 1;
	}

	$self->deliver($acctArgs{saveTo}, $args{mail},{folder=>$acctArgs{saveToFolder}});
	if ($self->{error}) {
		warn('ZConf-BGSet send: deliver errored');
		return undef;
	}

	return 1;
}

=head2 sendable

Checks to see if a sendable.

    #checks to see if 'smtp/foo' is sendable
    if(!$zcmail->sendable('smtp/foo')){
        print 'not sendable'
    }

=cut

sub sendable{
	my $self=$_[0];
	my $account=$_[1];
	my $method='sendable';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#This implements a simple check to make sure no one passed
	#'pop3/' or something like that. It also makes sure that
	#nothing past the account name is refered to.
	my @split=split(/\//, $account);
	if (!defined($split[1]) || defined($split[3])) {
		$self->{error}=4;
		$self->{errorString}='"'.$account.'" is not a valid acocunt name';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#makes sure the account exists
	if (!$self->accountExists($account)) {
		$self->{error}=6;
		$self->{errorString}='The account "'.$account.'" does not exist';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#makes sure it is a smtp account
	if (!$account =~ /^smtp\//) {
		$self->{error}=24;
		$self->{errorString}='Account is not a sendable type.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	return 1;
}

=head2 sign

This signs the body.

There are three required arguements. The first is the
account name it will be sending from. The second the
body of the email. The third is the to address.

=cut

sub sign{
	my $self=$_[0];
	my $account=$_[1];
	my $body=$_[2];
	my $to=$_[3];
	my $method='sign';

	#blanks any previous errors
	$self->errorBlank;
	if ($self->error) {
		warn($self->{method}.' '.$method.': Failed to blank previous error');
		return undef;
	}

	#makes sure the account exists
	if (!$self->accountExists($account)) {
		$self->{error}=6;
		$self->{errorString}='"'.$account.'" does not exist';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#error if we don't have a body
	if (!defined($body)) {
		$self->{error}=5;
		$self->{errorString}='No body is defined';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#get the args for the account
	my %Aargs=$self->getAccountArgs($account);
	if ($self->{error}) {
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	if ($Aargs{pgpType} eq 'mimesign') {
		$body="Content-Disposition: inline\n".
		"Content-Transfer-Encoding: quoted-printable\n".
		"Content-Type: text/plain\n\n".encode_qp($body);
	}

	my $hash='SHA512';
	if (defined($Aargs{PGPdigestAlgo})) {
		$hash=$Aargs{PGPdigestAlgo};
	}

	#make sure the sign type is specified
	if (!defined($Aargs{pgpType})) {
		$self->{error}=41;
		$self->{errorString}='"pgpType" account arg is not defined';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#make sure a key is specified
	if (!defined($Aargs{PGPkey})) {
		$self->{error}=41;
		$self->{errorString}='"PGPkey" account arg is not defined';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#make sure the sign type is supported
	my @types=('clearsign', 'mimesign', 'signencrypt');
	my $int=0;
	my $matched=0;
	while($types[$int]){
		if ($types[$int] eq $Aargs{pgpType}) {
			$matched=1;
		}

		$int++;
	}
	if (!$matched) {
		$self->{error}=43;
		$self->{errorString}='The type, "'.$Aargs{pgpType}.'", is not a valid type';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#creates the body directory
	my $bodydir='/tmp/'.time().rand();
	if (!mkdir($bodydir)) {
		$self->{error}=39;
		$self->{errorString}='Faied to create the temporary directory,"'.
		                     $bodydir.'", for signing.';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}
	my $bodyfile=$bodydir.'/body';

	#if we are doing mimesigning, we need to 
	if ($Aargs{pgpType} eq 'mimesign') {
		$body=~s/\n/\r\n/g;
	}

	#open it and write to it
	if (!open(BODYWRITE, '>'.$bodyfile)) {
		rmdir($bodydir);
		$self->{error}=40;
		$self->{errorString}='Failed to write body to "'.$bodyfile.
		                     '", for signing';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}
	print BODYWRITE $body;

	#this is the file that will be read into $sign
	my $read=undef;

	#this is what will be returned
	my $sign=undef;

	#handles clear signing
	my $execstring='gpg -u '.$Aargs{PGPkey}.' --digest-algo '.$hash.' ';
	if ($Aargs{pgpType} eq 'clearsign') {
		$execstring=$execstring.' --clearsign '.$bodyfile;
		system($execstring);
		if ($? ne '0') {
			$sign->{error}=44;
			$sign->{errorString}='Signing failed. Command="'.$execstring.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$read=$bodyfile.'.asc';
	}

	#handles mime signing
	if ($Aargs{pgpType} eq 'mimesign') {
		$execstring=$execstring.' -a --detach-sign '.$bodyfile;
		system($execstring);
		if ($? ne '0') {
			$sign->{error}=44;
			$sign->{errorString}='Signing failed. Command="'.$execstring.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$read=$bodyfile.'.asc';
	}

	#handles sign and encrypt
	if ($Aargs{pgpType} eq 'signencrypt') {
		$execstring=$execstring.' -se -r '..' '.$bodyfile;
		system($execstring);
		if ($? ne '0') {
			$sign->{error}=44;
			$sign->{errorString}='Signing failed. Command="'.$execstring.'"';
			warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
			return undef;
		}
		$read=$bodyfile.'.gpg';
	}

	open(SIGNREAD, '<'.$read);
	$sign=join("", <SIGNREAD>);
	close(SIGNREAD);

	unlink($bodyfile);
	unlink($read);
	rmdir($bodydir);

	return $sign;
}

=head1 ERROR RELATED METHODS

=head2 error

Returns the current error code and true if there is an error.

If there is no error, undef is returned.

    if($zconf->error){
                warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub error{
    return $_[0]->{error};
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

	if ($self->{perror}){
		warn($self->{module}.' errorBlank; A permanent error is set');
		return undef;
	}

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head2 errorString

Returns the error string if there is one. If there is not,
it will return ''.

    if($zconf->error){
                warn('error: '.$zconf->error.":".$zconf->errorString);
    }

=cut

sub errorString{
    return $_[0]->{errorString};
}

=head1 VARIABLES

In the various sections below, '*' is used to represent the name of a account.
Account names can't match the following.

        undef
        /\//
        /^\./
        /^ /
        / $/
        /\.\./

=head2 POP3

=head3 accounts/pop3/*/user

This is the username for a POP3 account.

=head3 accounts/pop3/*/pass

This is the password for a POP3 account.

=head3 accounts/pop3/*/useSSL

If set to a boolean value of true, SSL will be used.

=head3 accounts/pop3/*/deliverTo

This is the account to deliver to.

=head3 accounts/imap/*/deliverToFolder

This is the folder in the account to deliver to.

=head3 accounts/pop3/*/fetchable

If this account should be considered fetchable. If this flag
is set, this will not be fetched my 'Mail::ZConf::Fetch'.

=head3 accounts/pop3/*/auth

This is the auth type to use with the POP3 server.

=head3 accounts/pop3/*/server

The POP3 server to use.

=head3 accounts/pop3/*/port

The port on the server to use.

=head2 IMAP

=head3 accounts/imap/*/

Any thing under here under here is a IMAP account.

=head3 accounts/imap/*/user

This is the username for a IMAP account.

=head3 accounts/imap/*/pass

This is the password for a IMAP account.

=head3 accounts/imap/*/useSSL

If set to a boolean value of true, SSL will be used.

=head3 accounts/imap/*/deliverTo

This is the account to deliver to.

=head3 accounts/imap/*/deliverToFolder

This is the folder in the account to deliver to.

=head3 accounts/imap/*/fetchable

If this account should be considered fetchable. If this flag
is set, this will not be fetched my 'ZConf::Mail::Fetch', not
written yet.

This should be set if you are planning on using it for storage.

=head3 accounts/imap/*/inbox

This is the inbox that the mail should be delivered to.

=head3 accounts/imap/*/server

The IMAP server to use.

=head3 accounts/imap/*/port

The port on the server to use.

=head2 MBOX

=head3 accounts/mbox/*/mbox

This is the MBOX file to use.

=head3 accounts/mbox/*/deliverTo

This is the account to deliver to.

=head3 accounts/mbox/*/fetchable

If this account should be considered fetchable. If this flag
is set, this will not be fetched my 'ZConf::Mail::Fetch', not
written yet.

=head2 Maildir

=head3 accounts/maildir/*/maildir

This is the MBOX file to use.

=head3 accounts/maildir/*/deliverTo

This is the account to deliver to.

=head3 accounts/imap/*/deliverToFolder

This is the folder in the account to deliver to.

=head3 accounts/maildir/*/fetchable

If this account should be considered fetchable. If this flag
is set, this will not be fetched my 'ZConf::Mail::Fetch', not
written yet.

=head2 SMTP

=head3 accounts/smtp/*/user

This is the username for a SMTP account.

=head3 accounts/smtp/*/pass

This is the password for a SMTP account.

=head3 accounts/smtp/*/auth

This is the auth type to use with the SMTP server.

=head3 accounts/smtp/*/server

The SMTP server to use.

=head3 accounts/smtp/*/port

The port on the server to use.

=head3 accounts/smtp/*/useSSL

If set to a boolean value of true, SSL will be used.

=head3 accounts/smtp/*/from

The from address to use for a account.

=head3 accounts/smtp/*/name

The name that will be used with the account.

=head3 accounts/smtp/*/saveTo

This is the account to save it to. If it not defined
or blank, it will not saved.

=head3 accounts/smtp/*/saveToFolder

This is the folder to save it to for the account.

=head3 accounts/smtp/*/timeout

The time out for connecting to the server.

=head3 accounts/smtp/*/usePGP

If PGP should be used or not for this account. This is a Perl boolean value.

=head3 accounts/smtp/*/pgpType

=head4 clearsign

Clear sign the message.

=head4 mimesign

Attach the signature as a attachment.

=head4 signencrypt

Sign and encrypt the message. Not yet implemented.

=head3 accounts/smtp/*/PGPkey

The PGP key to use.

=head3 accounts/smtp/*/PGPdigestAlgo

The digest algorithym to use. It will default to 'SHA512' if not specified.

To find what out what your version supports, run 'gpg --version'.

=head2 EXEC

=head3 deliver

This is the command to execute for delivering a mail message. A single message
will be delivered at a time by running the specified program and piping the message
into it. Only a single message is delivered at once.

A example would be setting this to '/usr/local/libexec/dovecot/deliver' to deliver a
message one's dovecot account.

=head2 FORMATTER

=head3 formatter/marginLeft

This is the left margin. The default is zero if this is not defined.

=head3 formatter/marginRight

This is the right margin. The default is 72 if this is not defined.

=head3 formatter/squeeze

Removes unneeded whitespace. This is on by default.

=head3 formatter/ignore

Don't reformat any paragraph that matches this line. The default is '^[ \t]'.

=head3 formatter/justify

How to justify the text. The default is left.

=head3 formatter/tabspace

This is the default spaces per tab. The default is '4'.

=head2 MISC

=head3 default/sendable

This is the default sendable account. If this key does not exist or set to '',
there is no default sendable account.

=head3 default/fetchable

This is the default fetchable account. If this key does not exist or set to '',
there is no default fetchable account.

=head2 INTERNAL VARIABLES

=head3 $zcmail->{init}

If this is false, '$zcmail->init' needs run.

=head3 $zcmail->{legal}

This hashes which contains the legal values for each type in a array. So for SMTP,
'$zcmail->{legal}{smtp}' contains the array of legal values for SMTP.

=head3 $zcmail->{required}

This hashes which contains the required values for each type in a array. So for SMTP,
'$zcmail->{required}{smtp}' contains the array of required values for SMTP.

=head3 $zcmail->{fetchable}

This contains a array of fetchable account types.

=head3 $zcmail->{deliverable}

This contains a array of deliverable account types.

=head3 $zcmail->{sendable}

This contains a array of sendable account types.

=head1 ERROR CODES

If any funtion errors, the error code is writen to '$zcmail->{error}', a error message
is printed to stderr, and a short description is put in '$zcmail->{errorString}'.

When no error is present '$zcmail->{error}' is false, specifically undef.

=head2 1

Could not create the config.

=head2 2

No account type specified.

=head2 3

Unknown account type specified.

=head2 4

Illegal account name.

=head2 5

A required variable is not defined.

=head2 6

Account does not exist.

=head2 7

Authenticating with the POP3 server failed.

=head2 8

Connecting to the POP3 server failed.

=head2 9

Failed to either connect to IMAP server or authenticate with it.

=head2 10

Failed to connect to SMTP server.

=head2 11

Failed to authenticate with the SMTP server.

=head2 12

Failed to send the from for the SMTP session.

=head2 13

Failed to authenticate or connect to the SMTP server.

=head2 14

Failed to access maildir.

=head2 15

Account is not fetchable.

=head2 16

Failed to connect to POP3.

=head2 17

POP3 fetch failed.

=head2 18

Failed to read a ZConf config.

=head2 19

Wrong account type.

=head2 20

IO::MultiPipe error. See the error string for detains on it.

=head2 21

Mbox message delete failed.

=head2 22

Mbox fetch failed.

=head2 23

IMAP folder select failed.

=head2 24

Account is not a sendable account type.

=head2 25

No To or CC defined.

=head2 26

Failed to send a To, CC, or BCC address.

=head2 27

Failed to start the data session.

=head2 28

Failed to send the data.

=head2 29

Failed to end the data session.

=head2 30

Failed to quit.

=head2 31

Failed to create a Email::Simple object.

=head2 32

The account has one or more missing variables.

=head2 33

No INBOX specified for the IMAP account.

=head2 34

Failed to selected IMAP folder.

=head2 35

Failed to append to the IMAP folder.

=head2 36

ZConf error.

=head2 37

'saveTo' is not enabled for this account. This means it is either
undefined or set to ''.

=head2 38

File does not exist.

=head2 39

Failed to create temporary directory for signing.

=head2 40

Failed to create temprorary body file for signing.

=head2 41

No pgpType is not specified.

=head2 42

PGPGkey is not specified.

=head2 43

Sign type is not valid.

=head2 44

Signing failed.

=head2 45

The specified option is not a valid option.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-mail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Mail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Mail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Mail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Mail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Mail>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Mail>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Mail
