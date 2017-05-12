#A class that encapsulates the Google Apps for Your Domain Provisioning API V1.0
#see http://code.google.com/apis/apps-for-your-domain/google_apps_provisioning_api_v1.0_reference.html
#(C) 2006 Johan Reinalda, johan at reinalda dot net
#
#skeleton generated with h2xs -AXc -n Google::ProvisioningAPI
#
package VUser::Google::ProvisioningAPI::V1_0;

use 5.008005;

use strict;
use warnings;
use vars qw($VERSION);

use Carp;
use LWP::UserAgent qw(:strict);
use HTTP::Request qw(:strict);
use Encode;
use XML::Simple;

#I don't see the need for this - JKR
#require Exporter;

#NOT NEEDED FOR THIS CLASS
#our @ISA = qw(Exporter AutoLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use VUser::Google::ProvisioningAPI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

#I don't see the need for this - JKR
#our %EXPORT_TAGS = ( 'all' => [ qw(
#
#) ] );
#
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#
#our @EXPORT = qw(
#
#);

our $VERSION = '0.11';
our $APIVersion = '1.0';

#some constants
#web agent identification
use constant GOOGLEAGENT => "Google_ProvisioningAPI-perl/$VERSION";

#url for Google API token login
use constant GOOGLEHOST => 'www.google.com';
use constant GOOGLETOKENURL => 'https://www.google.com/accounts/ClientLogin';
use constant MAXTOKENAGE => 24 * 60 * 60;	#24 hours, see API docs

#base url to the Google REST API
use constant GOOGLEBASEURL => 'https://www.google.com/a/services/v1.0/';

use constant SUCCESSCODE => 'Success(2000)';
use constant FAILURECODE => 'Failure(2001)';

#some size constants
use constant MAXNAMELEN => 40;
use constant MAXUSERNAMELEN => 30;


# Preloaded methods go here.

#the constructor
sub new
{
	#parse parameters, if any
	(@_ == 4) || croak 'Constructor takes 3 arguments: domain, admin, adminpassword';

	my $object = shift();
	my $class = ref($object) || $object;

	my $self = {
		#Google related variables
		domain => shift(),		#the Google hosted domain we are accessing
		admin => shift(),		#the account to use when authenticating
		password => shift(),	#the password to use when authenticating
		refreshtoken => 0,		#if set, will force a re-authentication
		authtoken => '',		#the authentication token returned from google
		authtime => 0,			#time when authentication happened; only valid for 24 hours
		requestcontent => '',	#the last http content posted to Google
		replyheaders => '',		#the http headers of the last reply
		replycontent => '',		#the http content of the last reply
		result => {},			#the resulting hash from the last reply data as parsed by XML::Simple
	
		#some other variables
		debug => 0,			#when turned on, will spit out debug info to STDERR
		
		#some statistics that are 'read-only'
		stats => {
			ctime =>  time,			#object creation time
			rtime => 0,				#time of last request
			requests => 0,			#number of API requests made
			success => 0,			#number of successes
			logins => 0,			#number of authentications performed
		}
	};
	#return object
	bless( $self, 'VUser::Google::ProvisioningAPI::V1_0');
	return $self;
	
}

#method used to (re)login to the API, either first time, or as token times out
sub Relogin
{
	
	#get object reference
	my $self = shift();

	$self->dprint("Relogin called\n");

	my $retval = 0;
	
	#adjust stats counter
	$self->{stats}->{logins}++;
	
	#clear last results
	$self->{replyheaders} = $self->{replycontent} = '';
	$self->{result} = {};
	
	# Create an LWP object to make the HTTP POST request
	my $lwp = LWP::UserAgent->new;

	if(defined($lwp)) {
		$lwp->agent(GOOGLEAGENT);
		$lwp->from($self->{admin}.'@'.$self->{domain});
		# Submit the request with values for
		# accountType, Email and Passwd variables.
		my $response = $lwp->post( GOOGLETOKENURL,
				[ 'accountType' => 'HOSTED',
				  'Email' => $self->{admin}.'@'.$self->{domain},
				  'Passwd' => $self->{password}
				]
			);
		#save reply page
		$self->{replyheaders} = $response->headers->as_string;
		$self->{replycontent} = $response->content;
	
		if ($response->is_success) {
			# Extract the authentication token from the response
			foreach my $line (split/\n/, $response->content) {
				#$self->dprint( "RECV'd: $line" );
				if ($line =~ m/^SID=(.+)$/) {
					$self->{authtoken} = $1;
					$self->{authtime} = time;
					$self->dprint("Token found: $self->{authtoken}\n");
					#clear refresh
					$self->{refreshtoken} = 0;
					$retval = 1;
					last;
				}
			}
		}
		else {
			$self->dprint("Error in login: " . $response->status_line . "\n");
			$self->{result}->{reason} = "Error in login: " . $response->status_line;

		}
	} else {
		$self->dprint("Error getting lwp object: $!\n");
		$self->{result}->{reason} = "Error getting lwp object: $!";
	}
	return $retval;
}



#check if we are authenticated. If not, try to re-login
sub IsAuthenticated {

	#get object reference
	my $self = shift();

	if( $self->{refreshtoken} or ( (time - $self->{authtime}) > MAXTOKENAGE ) ) {
		return $self->Relogin();
	}
	#we are still okay!
	return 1;
}

#generic request routine that handles most functionality
#requires 3 arguments: Type, Action, Body
#Type is the object type to action upon. ('Account', 'Alias', 'MailingList')
#Action is what needs to be done
#Body is the xml specific to the action
sub Request
{
	my $retval = 0;

	#get object reference
	my $self = shift();

	$self->dprint( "***REQUEST***\n");
	
	#clear last results
	$self->{replyheaders} = $self->{replycontent} = '';
	$self->{result} = {};
	
	if(@_ != 3) {
		$self->{result}->{reason} = 'Invalid number of arguments to request()';
		return 0;
	}
	
	#get parameters
	my($type,$action,$body) = @_;
	
	$self->dprint( "Type: $type\nAction: $action\n$body\n");
	
	#keep some stats
	$self->{stats}->{requests}++;
	$self->{stats}->{rtime} = time;
	
	#check if we are authenticated to google
	if(!$self->IsAuthenticated()) {
		$self->dprint( "Error authenticating\n");
		return 0;
	}

	#standard XML pre and post segments
	my $pre = <<"EOL";
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
	<hs:rest xmlns:hs=\"google:accounts:rest:protocol\"
		xmlns:xsi=\"http:\/\/www.w3.org\/2001\/XMLSchema-instance\">
	<hs:type>$type<\/hs:type>
	<hs:token>$self->{authtoken}</hs:token>
	<hs:domain>$self->{domain}</hs:domain>
EOL

	my $post = '</hs:rest>';


	#create to request body
	$body = $pre . $body . $post;
	#properly encode it
	$body = encode('UTF-8',$body);

	#save the request content
	$self->{requestcontent} = $body;
	
	# Create an LWP object to make the HTTP POST request over
	my($ua) = LWP::UserAgent->new;
	if(!defined($ua)) {
		$self->dprint("Cannot create LWP::UserAgent object: $!\n");
		$self->{result}->{reason} = "Cannot create LWP::UserAgent object in request(): $!";
		return $retval;
	}
	
	#and create the request object where are we connecting to
	my $url = GOOGLEBASEURL . $action;
	$self->dprint("URL: $url\n");
	my $req = HTTP::Request->new(POST => $url);
	if(!defined($req)) {
		$self->dprint("Cannot create HTTP::Request object: $!\n");
		$self->{result}->{reason} = "Cannot create HTTP::Request object in request(): $!";
		return $retval;
	}
	
	#set some user agent variables
	$ua->agent( GOOGLEAGENT );
	$ua->from( '<' . $self->{admin}.'@'.$self->{domain} . '>');

	# Submit the request with values for
	# accountType, Email and Passwd variables.
	#$req->header('ContentType' => 'application/x-www-form-urlencoded');
	$req->header('Content-Type' => 'application/xml');
	$req->header('Accept' => 'application/xml');
	$req->header('Content-Lenght' => length($body) );
	$req->header('Connection' => 'Keep-Alive');
	$req->header('Host' => GOOGLEHOST);
	#assign the data to the request
	$req->content($body);
	
	#execute the request
	my $response = $ua->request($req);
	#save reply page
	$self->{replyheaders} = $response->headers->as_string;
	$self->{replycontent} = $response->content;
	#check result
	if ($response->is_success) {
		$self->{stats}->{success}++;
		$self->dprint( "Success in post:\n");
		
		#delete all namespace elements to keep it simple (ie. remove "hs:")
		#this avoids the need to use XML::NameSpace
		my $xml = decode('UTF-8', $response->content);
		$xml =~ s/hs\://g;
		$self->dprint( $xml );
		
		#now go parse it using XML::Simple
		$self->{result} = XMLin($xml,ForceArray => 0);
		#include Data::Dumper above if you want to use this line:
		#$self->dprint( Dumper($self->{result}) );

		#see if this was a successful call
		if( defined($self->{result}->{status}) and $self->{result}->{status} eq SUCCESSCODE ) {
			$self->dprint("Google API success!");
			$retval = 1;
		} else {
			$self->dprint("Google API failure!");
			if(defined($self->{result}->{reason})) {
				$@ = "Google API failure: $self->{result}->{status} - $self->{result}->{reason}";
			} else {
				$@ = "Google API failure: reason not found!";
				$self->{result}->{reason} = "Google API failure: reason not found!";
			}
		}
	}
	else {
		$self->dprint( "Error in post: " . $response->status_line . "\n");
		$self->{result}->{reason} = "Error in http post: " . $response->status_line;
	}
	#show full response for now
	#$self->dprint( "Headers:\n" . $response->headers->as_string);
	#foreach my $line (split/\n/, $response->content) {
	#	$self->dprint( "RECV'd:   $line\n");
	#}
	
	return $retval;
}


######################################
### these are the actual API calls ###
### See the Google docs for more   ###
######################################


### HOSTED ACCOUNT routines ###

sub CreateAccountEmail
{
	#get object reference
	my $self = shift();

	$self->dprint( "CreateAccount called\n");

	#check remaining arguments
	if(@_ < 4) {
		$self->dprint( "CreateAccountEmail method requires at least 4 arguments!\n");
		$self->{result}->{reason} = "CreateAccountEmail method requires at least 4 arguments!";
		return 0;
	}

	#get arguments
    my $userName = shift();
	my $firstName = shift();
    my $lastName = shift();
    my $password = shift();
	my $quota = shift() if (@_);	#this one is optional

	my $body = <<"EOL";
	<hs:CreateSection>
		<hs:firstName>$firstName</hs:firstName>
		<hs:lastName>$lastName</hs:lastName>
		<hs:password>$password</hs:password>
		<hs:userName>$userName</hs:userName>
EOL

	if(defined($quota)) {
		$body .= "\t\t<hs:quota>$quota<\/hs:quota>\n";
	}

	#add the final end-of-section tab
	$body .= "\t<\/hs:CreateSection>\n";


	return $self->Request('Account','Create/Account/Email',$body);

}

#NOTE: this API call may be discontinued!
sub CreateAccount
{
	#get object reference
	my $self = shift();

	$self->dprint( "CreateAccount called\n");

	#check remaining arguments
	if(@_ != 4) {
		$self->dprint( "CreateAccount method requires 4 arguments!\n");
		$self->{result}->{reason} = "CreateAccount method requires 4 arguments!";
		return 0;
	}

	#get arguments
    my $userName = shift();
	my $firstName = shift();
    my $lastName = shift();
    my $password = shift();

	my $body = <<"EOL";
	<hs:CreateSection>
		<hs:firstName>$firstName</hs:firstName>
		<hs:lastName>$lastName</hs:lastName>
		<hs:password>$password</hs:password>
		<hs:userName>$userName</hs:userName>
	</hs:CreateSection>
EOL

	return $self->Request('Account','Create/Account',$body);

}

sub UpdateAccount
{
	#get object reference
	my $self = shift();

	$self->dprint( "UpdateAccount called\n");

	#check remaining arguments
	if(@_ != 4) {
		$self->dprint( "UpdateAccount method requires 4 arguments!\n");
		$self->{result}->{reason} = "UpdateAccount method requires 4 arguments!";
		return 0;
	}

	#get arguments
    my $userName = shift();
	my $firstName = shift();
    my $lastName = shift();
    my $password = shift();

	#build request body
	my $body = <<"EOL";
	<hs:queryKey>userName</hs:queryKey>
	<hs:queryData>$userName</hs:queryData>
	<hs:UpdateSection>
EOL

	if(defined($firstName)) {
		$body .= "\t\t<hs:firstName>$firstName<\/hs:firstName>\n";
	}
	if(defined($lastName)) {
		$body .= "\t\t<hs:lastName>$lastName<\/hs:lastName>\n";
	}
	if(defined($password)) {
		$body .= "\t\t<hs:password>$password<\/hs:password>\n";
	}

	#add the final end-of-section tab
	$body .= "\t<\/hs:UpdateSection>\n";


	return $self->Request('Account','Update/Account',$body);

}

sub UpdateAccountEmail
{
	#get object reference
	my $self = shift();

	$self->dprint( "UpdateAccountEmail called\n");

	#check remaining arguments
	if(@_ != 1) {
		$self->dprint( "UpdateAccount method requires 1 argument!\n");
		$self->{result}->{reason} = "CreateAccount method requires 1 argument!";
		return 0;
	}

	#get arguments
    my $userName = shift();

	my $body = <<"EOL";
	<hs:queryKey>userName</hs:queryKey>
	<hs:queryData>$userName</hs:queryData>
	<hs:UpdateSection>
		<hs:shouldEnableEmailAccount>1</hs:shouldEnableEmailAccount>
	</hs:UpdateSection>
EOL

	return $self->Request('Account','Update/Account/Email',$body);

}

sub UpdateAccountStatus
{
	#get object reference
	my $self = shift();

	$self->dprint( "UpdateAccountStatus called\n");

	#check remaining arguments
	if(@_ != 2) {
		$self->dprint( "UpdateAccount method requires 2 argument!\n");
		$self->{result}->{reason} = "CreateAccount method requires 2 arguments!";
		return 0;
	}

	#get arguments
    my $userName = shift();
	my $status = shift();

	if($status ne 'locked' and $status ne 'unlocked') {
		$self->dprint( "Error: status invalid!\n");
		$self->{result}->{reason} = 'Invalid status';
		return 0;
	}
	
	my $body = <<"EOL";
	<hs:queryKey>userName</hs:queryKey>
	<hs:queryData>$userName</hs:queryData>
	<hs:UpdateSection>
		<hs:accountStatus>$status</hs:accountStatus>
	</hs:UpdateSection>
EOL

	return $self->Request('Account','Update/Account/Status',$body);

}

sub RetrieveAccount
{
	#get object reference
	my $self = shift();
	
	$self->dprint( "RetrieveAccount called\n");

	#check remaining arguments
	if(@_ != 1) {
		$self->dprint( "RetrieveAccount method requires 1 argument!\n");
		$self->{result}->{reason} = "RetrieveAccount method requires 1 argument!";
		return 0;
	}

	#get argument
    my $userName = shift();

	my $body = <<"EOL";
	<hs:queryKey>userName</hs:queryKey>
	<hs:queryData>$userName</hs:queryData>
EOL

	return $self->Request('Account','Retrieve/Account',$body);
}


sub DeleteAccount
{
	#get object reference
	my $self = shift();

	$self->dprint( "DeleteAccount called\n");

	#check remaining arguments
	if(@_ != 1) {
		$self->dprint( "DeleteAccount method requires 1 argument!\n");
		$self->{result}->{reason} = "DeleteAccount method requires 1 argument!";
		return 0;
	}

	#get argument
    my $userName = shift();

	my $body = <<"EOL";
	<hs:queryKey>userName</hs:queryKey>
	<hs:queryData>$userName</hs:queryData>
EOL

	return $self->Request('Account','Delete/Account',$body);
}

sub RenameAccount
{
#This is derived from the Python sample code:
#-----
#Username change. Note that this feature must be explicitly
#   enabled by the domain administrator, and is not enabled by
#   default.
#
#   Args:
#     oldname: user to rename
#     newname: new username to set for the user
#     alias: if 1, create an alias of oldname for newname
#-----
#Ie. this may not work yet - JKR 20061204
	
	#get object reference
	my $self = shift();

	$self->dprint( "RenameAccount called\n");

	#check remaining arguments
	if(@_ != 3) {
		$self->dprint( "RenameAccount method requires 3 arguments!\n");
		$self->{result}->{reason} = "RenameAccount method requires 3 arguments!";
		return 0;
	}

	#get arguments
    my $oldName = shift();
    my $newName = shift();
    my $alias = shift();
	#check format of alias; default to 0
	$alias = lc($alias);
	if($alias ne '1') { $alias = '0'; }

	#build request format
	my $body = <<"EOL";
	<hs:queryKey>userName</hs:queryKey>
	<hs:queryData>$oldName</hs:queryData>
	<hs:UpdateSection>
		<hs:userName>$newName</hs:userName>
		<hs:shouldCreateAlias>$alias</hs:shouldCreateAlias>
	</hs:UpdateSection>
EOL

	return $self->Request('Account','Update/Account/Username',$body);
}


### ALIAS routines ###

sub CreateAlias
{
	#get object reference
	my $self = shift();

	$self->dprint( "CreateAlias called\n");

	#check remaining arguments
	if(@_ != 2) {
		$self->dprint( "CreateAlias method requires 2 arguments!\n");
		$self->{result}->{reason} = "CreateAlias method requires 2 arguments!";
		return 0;
	}

	#get argument
    my $userName = shift();
	my $alias = shift();
	
	#create the command format
	my $body = <<"EOL";
	<hs:CreateSection>
		<hs:userName>$userName</hs:userName>
		<hs:aliasName>$alias</hs:aliasName>
	</hs:CreateSection>
EOL

	return $self->Request('Alias','Create/Alias',$body);
}

sub RetrieveAlias
{
	#get object reference
	my $self = shift();
	
	$self->dprint( "RetrieveAlias called\n");

	#check remaining arguments
	if(@_ != 1) {
		$self->dprint( "RetrieveAlias method requires 1 argument!\n");
		$self->{result}->{reason} = "RetrieveAlias method requires 1 argument!";
		return 0;
	}

	#get argument
    my $userName = shift();

	my $body = <<"EOL";
	<hs:queryKey>aliasName</hs:queryKey>
	<hs:queryData>$userName</hs:queryData>
EOL

	return $self->Request('Alias','Retrieve/Alias',$body);
}

sub DeleteAlias
{
	#get object reference
	my $self = shift();

	$self->dprint( "DeleteAlias called\n");

	#check remaining arguments
	if(@_ != 1) {
		$self->dprint( "DeleteAlias method requires 1 argument!\n");
		$self->{result}->{reason} = "DeleteAlias method requires 1 argument!";
		return 0;
	}

	#get arguments
    my $alias = shift();

	my $body = <<"EOL";
	<hs:queryKey>aliasName</hs:queryKey>
	<hs:queryData>$alias</hs:queryData>
EOL

	return $self->Request('Alias','Delete/Alias',$body);
}


### Mailing List routines


sub CreateMailingList
{
	#get object reference
	my $self = shift();

	$self->dprint( "CreateMailingList called\n");

	#check remaining arguments
	if(@_ != 1) {
		$self->dprint( "CreateMailingList method requires 1 argument!\n");
		$self->{result}->{reason} = "CreateMailingList method requires 1 argument!";
		return 0;
	}

	#get arguments
	my $mailingListName = shift();

	my $body = <<"EOL";
	<hs:CreateSection>
		<hs:mailingListName>$mailingListName</hs:mailingListName>
	</hs:CreateSection>
EOL

	return $self->Request('MailingList','Create/MailingList',$body);

}


sub UpdateMailingList
{
	#get object reference
	my $self = shift();

	$self->dprint( "UpdateMailingList called\n");

	#check remaining arguments
	if(@_ != 3) {
		$self->dprint( "UpdateMailingList method requires 3 arguments!\n");
		$self->{result}->{reason} = 'UpdateMailingList method requires 3 arguments!';
		return 0;
	}

	#get arguments
    my $mailingListName = shift();
    my $userName = shift();
	my $listOperation = shift();

	my $body = <<"EOL";
	<hs:queryKey>mailingListName</hs:queryKey>
	<hs:queryData>$mailingListName</hs:queryData>
	<hs:UpdateSection>
		<hs:userName>$userName</hs:userName>
		<hs:listOperation>$listOperation</hs:listOperation>
	</hs:UpdateSection>
EOL

	return $self->Request('MailingList','Update/MailingList',$body);

}



sub RetrieveMailingList
{
	#get object reference
	my $self = shift();
	
	$self->dprint( "RetrieveMailingList called\n");

	#check remaining arguments
	if(@_ != 1) {
		$self->dprint( "RetrieveMailingList method requires 1 argument!\n");
		$self->{result}->{reason} = 'RetrieveMailingList method requires 1 arguments!';
		return 0;
	}

	#get argument
    my $mailingListName = shift();

	my $body = <<"EOL";
	<hs:queryKey>mailingListName</hs:queryKey>
	<hs:queryData>$mailingListName</hs:queryData>
EOL

	return $self->Request('MailingList','Retrieve/MailingList',$body);
}


sub DeleteMailingList
{
	#get object reference
	my $self = shift();

	$self->dprint( "DeleteMailingList called\n");

	#check remaining arguments
	if(@_ != 1) {
		$self->dprint( "DeleteMailingList method requires 1 argument!\n");
		$self->{result}->{reason} = 'DeleteMailingList method requires 1 argument!';
		return 0;
	}

	#get argument
    my $mailingListName = shift();

	my $body = <<"EOL";
	<hs:queryKey>mailingListName</hs:queryKey>
	<hs:queryData>$mailingListName</hs:queryData>
EOL

	return $self->Request('MailingList','Delete/MailingList',$body);
}


################################################################
# below are various subroutines to access local 'private' data #
################################################################

#the content of the request from and reply from Google API engine
sub requestcontent
{
	my $self = shift();

	return $self->{requestcontent};
}

sub replyheaders
{
	my $self = shift();

	return $self->{replyheaders};
}

sub replycontent
{
	my $self = shift();

	return $self->{replycontent};
}

		
#various access to local variables
sub debug
{
	my $self = shift();

	$self-> { debug } = shift() if (@_);
	
	return $self->{debug};
}

#change the admin account
sub admin
{
	my $self = shift();

	if (@_)
	{
		$self-> { admin } = shift();
		$self-> { refreshtoken } = 1;
	}
	
	return $self->{admin};
}

#password can only be set, not read!
sub password
{
	my $self = shift();


	if (@_)
	{
		$self-> { password } = shift();
		#force authentication update on next request
		$self-> { refreshtoken } = 1;
	}
	
	return '';
}

#the following can only be read!
sub authtime
{
	my $self = shift();

	return $self->{authtime};
}

#same for create time
sub ctime
{
	my $self = shift();

	return $self->{stats}->{ctime};
}

#and request time
sub rtime
{
	my $self = shift();

	return $self->{stats}->{rtime};
}

sub requests
{
	my $self = shift();

	return $self->{stats}->{requests};
}

sub logins
{
	my $self = shift();

	return $self->{stats}->{logins};
}

sub success
{
	my $self = shift();

	return $self->{stats}->{success};
}

sub version
{
	my $self = shift();

	return $APIVersion;
}

#several helper routines

#print out debugging to STDERR if debug is set
sub dprint
{
	my $self = shift();
	my($text) = shift if (@_);
	if( $self->{debug} and defined ($text) ) {
		print STDERR $text . "\n";
	}
}

1;
__END__

=pod

=head1 NAME

VUser::Google::ProvisioningAPI::V1_0 - Perl module that implements version 1.0 of the Google Apps for Your Domain Provisioning API

=head1 SYNOPSIS

  use VUser::Google::ProvisioningAPI;
  my $google = new VUser::Google::ProvisioningAPI($domain,$admin,$password);

  $google->CreateAccount($userName, $firstName, $lastName, $password);
  $google->RetrieveAccount($userName);

=head1 REQUIREMENTS

VUser::Google::ProvisioningAPI requires the following modules to be installed:

=over

=item

C<LWP::UserAgent>

=item

C<HTTP::Request>

=item

C<Encode>

=item

C<XML::Simple>

=back

=head1 DESCRIPTION

VUser::Google::ProvisioningAPI provides a simple interface to the Google Apps for Your Domain Provisioning API.
It uses the C<LWP::UserAgent> module for the HTTP transport, and the C<HTTP::Request> module for the HTTP request and response.

=head2 Examples

For a complete description of the meaning of the following methods, see the Google API documentation referenced in the SEE ALSO section.

	#create the object
	$google = new Google:ProvisioningAPI($domain,$admin,$password) || die "Cannot create google object";
	
	print 'Module version: ' . $google->VERSION . "\nAPI Version: " . $google->version() . "\n";
	
	#create a hosted account
	if( $google->CreateAccount( $userName, $firstName, $lastName, $password ) ) 
	{
		print "Account created!\N";
	}
	
	#add email services to the account
	$google->UpdateAccountEmail($userName);
	
	#retrieving account data
	if($google->RetrieveAccount($userName))
	{
		print 'Username: ' . $google->{result}->{RetrievalSection}->{userName} . "\n";
		print 'firstName: ' . $google->{result}->{RetrievalSection}->{firstName} . "\n";
		print 'lastName: ' . $google->{result}->{RetrievalSection}->{lastName} . "\n";
		print 'accountStatus: ' . $google->{result}->{RetrievalSection}->{accountStatus} . "\n";
		
	}
	
	#see what the result hash after a request looks like
	use Data::Dumper;
	print Dumper($google->{result});
	
	#delete an account
	$ret = DeleteAccount($userName);
	
	#accessing the HTML data as it was received from the Google servers:
	print $google->replyheaders();
	print $google->replycontent();


=head1 CONSTRUCTOR

new ( $domain, $admin, $adminpassword )

This is the constructor for a new VUser::Google::ProvisioningAPI object.
$domain is the domain name registered with Google Apps For Your Domain,
$admin is an account in the above domain that has the right to manage that domain, and
$adminpassword is the password for that account.

Note that the constructor will NOT attempt to perform the 'ClientLogin' call to the Google Provisioning API (see below).
Authentication happens automatically when the first API call is performed. The token will be remembered for the duration of the object, and will be automatically refreshed as needed.
If you want to verify that you can get a valid token before performing any operations, follow the constructor with a call to IsAuthenticated() as such:

	print "Authentication OK\n" unless not $google->IsAuthenticated();

=head1 METHODS

Below are all the methods available on the object. For the Google API specific methods, see the Google API documentation for more details.
When a request is properly handled by Google's API engine, the webpost to the API succeeds. This results in a valid page being returned. The content of this page then defines whether the request succeeded or not.
All pages returing the 'Success(2000)' status code will result in the API method succeeding, and returning a 1. All failures return 0.
Please see the section below on how to access the result data, and how to determine the reasons for errors.

If the web post fails (as determined by the C<HTTP::Request> method IsSuccess() ), the method returns 0, and the {reason} hash is set to a descriptive error.
You can then examine the raw data to get an idea of what went wrong.

=head2 Checking Authentication

IsAuthenticated()

=over

will check if the object has been able to authenticate with Google's api engine, and get an authentication ticket.
Returns 1 if successful, 0 on failure. To see why it may fail, see the $@ variable, and the $google->{results}->{reason} hash, and parse the returned page (see the 'content' and 'header' variables.)

=back

=head2 Methods to Create/Retrieve/Delete

=head3 'Hosted account' methods

CreateAccountEmail(  $userName, $firstName, $lastName, $password, $quota )

=over

Creates a hosted account with email services in your domains name space.
The first 4 arguments are required. The $quota argument is optional. If $quota is given, the <quota> tag will be sent with the request, otherwize is will be omitted.
See the Google API docs for the API call for more details.

=back

CreateAccount(  $userName, $firstName, $lastName, $password )

=over

Creates a hosted account in your domains name space. This account does NOT have email services by default.
You need to call UpdateAccountEmail() to add email services.
NOTE: this API call may be discontinued! See CreateAccountEmail() for a replacement.

=back

UpdateAccount( $username, $firstName, $lastName, $password )

=over

$username is the mandatory name of the hosted account. The remaining paramaters are optional, and can be set to 'undef' if you do not wish to change them
Eg. to change the password on an account, call this as;

=back

	UpdateAccount( $username, undef, undef, 'newpassword' );

=over

to change names only, you would call it as such:

=back

	UpdateAccount( $username, 'newfirstname', 'newlastname', undef );


UpdateAccountEmail( $userName )

=over

Adds email services to a hosted account created with CreateAccount().
NOTE: this API call may be discontinued! See CreateAccountEmail() for a replacement.

=back

UpdateAccountStatus( $userName, $status )

=over	

$status is either 'locked' or 'unlocked'

=back

RetrieveAccount( $userName )

DeleteAccount( $userName )

RenameAccount( $oldName, $newName, $alias )

=over

$alias is either '1' or '0'

WARNING: this method is derived from the Python sample code provided by Google:
(Ie. this may not work yet)
"Username change. Note that this feature must be explicitly enabled by the domain administrator, and is not enabled by default.
Args:

=over

oldname: user to rename
newname: new username to set for the user
alias: if 1, create an alias of oldname for newname"	

=back

=back


=head3 'Alias' methods

CreateAlias( $userName, $alias )

RetrieveAlias( $userName );

DeleteAlias( $alias );


=head3 'Mailing List' methods

CreateMailingList( $mailingListName )

UpdateMailingList( $mailingListName, $userName, $listOperation )

=over

$listOperation is either 'add' or 'remove'

=back

RetrieveMailingList( $mailingListName )

DeleteMailingList( $mailingListName )



=head2 Methods to set/get variables

After creating the object you can get/set the administrator account and set the password with these methods.
Note this will cause a re-authentication next time a Google API method is called.

admin( $admin )

=over	

set the administrative user, and will return administator username.

=back
	
password( $string )

=over

set the password, returns an empty string

=back

=head2 Miscelleaneous statistics methods

There are a few methods to access some statistics data that is collected while the object performing Google API calls.

authtime()

=over

returns the time of last authentication, as generated by the time() function

=back

ctime()

=over

returns the create time of the object, as generated by the time() function

=back

rtime()

=over

returns the time of the most recent request, as generated by the time() function

=back

logins()

=over

returns the number of API logins that have been performed

=back

requests()

=over

returns the numbers of API requests that have been submitted to Google

=back

success()

=over

returns the numbers of successful api request performed

=back

And finally,

version()

=over

returns a string with the api version implemented. This is currently '1.0'

=back


=head1 ACCESSING RESULTING DATA

Valid return data from Google is parsed into a hash named 'result', available through the object. In this hash you can find all elements as returned by Google.
This hash is produced by XML::Simple. See the Google API documentation in the SEE ALSO section for complete details.
Some of the more useful elements you may need to look at are:

	$google->{result}->{reason}		#this typically has the textual reason for a failure
	$google->{result}->{extendedMessage}	#a more extensive description of the failure reason may be here
	$google->{result}->{result}		#typically empty!
	$google->{result}->{type}		#should be same of query type, eg 'Account', 'Alias', 'MailingList'

The retrieval section contains data when you are querying. Here is what this section looks like when you call the RetrieveAccount method:

	$google->{result}->{RetrievalSection}->{firstName}
	$google->{result}->{RetrievalSection}->{lastName}
	$google->{result}->{RetrievalSection}->{accountStatus}
	$google->{result}->{RetrievalSection}->{aliases}->{alias}
	$google->{result}->{RetrievalSection}->{emailLists}->{emailList}


To see the structure of the result hash, use the Data::Dumper module as such:

	use Data::Dumper;
	print Dumper($google->{result});


=head1 ACCESSING RAW GOOGLE POST AND RESULT DATA

The data from the most recent post to the Google servers is available. You can access it as:

	print $google->requestcontent();

The most recent received HTML data is stored in two parts, the headers and the content. Both are strings. They can be accessed as such:

	print $google->replyheaders();
	print $google->replycontent();

Note the headers are new-line separated and can easily be parsed:

	foreach my $headerline ( split/\n/, $g->replyheaders() )
	{
		my ($header, $value) = split/:/, $headerline;
	}

=head1 EXPORT

None by default.


=head1 SEE ALSO

The official Google documentation can be found at
http://code.google.com/apis/apps-for-your-domain/google_apps_provisioning_api_v1.0_reference.html

For support, see the Google Group at
http://groups.google.com/group/apps-for-your-domain-apis

For additional support specific to this modules, email me at johan at reinalda dot net.

=head1 AUTHOR

Johan Reinalda, johan at reinalda dot net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Johan Reinalda, johan at reinalda dot net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

If you make useful modification, kindly consider emailing then to me for inclusion in a future version of this module.

=cut
