package VUser::Google::ProvisioningAPI::V2_0;
use 5.008005;
use warnings;
use strict;

#(C) 2007 Randy Smith, perlstalker at vuser dot org
#(C) 2006 Johan Reinalda, johan at reinalda dot net

use vars qw($VERSION);

our $VERSION = '0.25';

use Carp;
use LWP::UserAgent qw(:strict);
use HTTP::Request qw(:strict);
use Encode;
use XML::Simple;

use Data::Dumper;

use base qw(VUser::Google::ProvisioningAPI);

use VUser::Google::ProvisioningAPI::V2_0::EmailListEntry;
use VUser::Google::ProvisioningAPI::V2_0::EmailListRecipientEntry;
use VUser::Google::ProvisioningAPI::V2_0::NicknameEntry;
use VUser::Google::ProvisioningAPI::V2_0::UserEntry;

our $APIVersion = '2.0';

#some constants
#web agent identification
use constant GOOGLEAGENT => "Google_ProvisioningAPI-perl/0.20";

#url for Google API token login
use constant GOOGLEHOST => 'www.google.com';
use constant GOOGLETOKENURL => 'https://www.google.com/accounts/ClientLogin';
use constant MAXTOKENAGE => 24 * 60 * 60;	#24 hours, see API docs

#base url to the Google REST API
use constant GOOGLEBASEURL => 'https://www.google.com/a/feeds/';

use constant GOOGLEAPPSSCHEMA => 'http://schemas.google.com/apps/2006';

use constant SUCCESSCODE => 'Success(2000)';
use constant FAILURECODE => 'Failure(2001)';

#some size constants
use constant MAXNAMELEN => 40;
use constant MAXUSERNAMELEN => 30;

sub DESTROY { };

# Preloaded methods go here.

=pod

=head1 NAME

VUser::Google::ProvisioningAPI::V2_0 - Perl module that implements version 2.0 of the Google Apps for Your Domain Provisioning API

=head1 SYNOPSIS

 use VUser::Google::ProvisioningAPI;
 my $google = new VUser::Google::ProvisioningAPI($domain, $admin, $passwd, '2.0');
 
 $google->CreateUser($userName, $givenName, $familyName, $password, $quotaMB);
 my $user = $google->RetrieveUser($userName);

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

Adding a user:

 use VUser::Google::ProvisioningAPI;
 my $google = VUser::Google::ProvisioningAPI->new('yourdomain.com',
					  'admin',
					  'your password',
					  '2.0');

 my $entry = $google->CreateUser('joeb', 'Joe', 'Blow', 'joespassword');
 if (defined $entry) {
   print $entry->User, " created\n";
 } else {
   die "Add failed: ".$google->{result}{reason};
 }

Updating a user:

 my $new_entry = VUser::Google::ProvisioningAPI::V2_0::UserEntry->new();
 $new_entry->Password('heresmynewpassword');
 $new_entry->GivenName('Joseph');
 my $entry = $google->UpdateUser('joeb', $new_entry);

Delete a user:

 my $rc = $google->DeleteUser('joeb');
 if (not $rc) {
   die "Can't delete user: ".$google->{result}{reason};
 }

=head1 CONSTRUCTOR

new ($domain, $admin, $adminpasswd)

This is the constructor for a new VUser::Google::ProvisioningAPI object.
$domain is the domain name registered with Google Apps For Your Domain,
$admin is an account in the above domain that has the right to manage that domain, and
$adminpassword is the password for that account.

Note that the constructor will NOT attempt to perform the 'ClientLogin' call to the Google Provisioning API (see below).
Authentication happens automatically when the first API call is performed. The token will be remembered for the duration of the object, and will be automatically refreshed as needed.
If you want to verify that you can get a valid token before performing any operations, follow the constructor with a call to IsAuthenticated() as such:

	print "Authentication OK\n" unless not $google->IsAuthenticated();

=cut

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
	bless( $self, 'VUser::Google::ProvisioningAPI::V2_0');
	return $self;
	
}

=pod

=head1 METHODS

Below are all the methods available on the object. For the Google API specific methods, see the Google API documentation for more details.

When a request is properly handed by Google's API engine, the results of the
action are returned as the content of the request.

If the request fails (as determined by the C<HTTP::Request> method
is_success()), it could mean a couple of things. If it's a failure within
the Google API, the content will contain an XML encoded error message. All
other HTTP errors are still possible.

=head2 Checking Authentication

IsAuthenticated()

=over

will check if the object has been able to authenticate with Google's api engine, and get an authentication ticket.
Returns 1 if successful, 0 on failure. To see why it may fail, see the $@ variable, and the $google->{results}->{reason} hash, and parse the returned page (see the 'content' and 'header' variables.)

=back

=cut

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

=pod

Relogin()

=over

Performs a login if required. Relogin() will be called but the API methods
and IsAuthenticated(). You should not need to call this directly.

=back

=cut

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
				  'Passwd' => $self->{password},
				  'service' => 'apps'
				]
			);
		#save reply page
		$self->{replyheaders} = $response->headers->as_string;
		$self->{replycontent} = $response->content;
	
		if ($response->is_success) {
			# Extract the authentication token from the response
			foreach my $line (split/\n/, $response->content) {
				#$self->dprint( "RECV'd: $line" );
				if ($line =~ m/^Auth=(.+)$/) {
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

#generic request routine that handles most functionality
#requires 3 arguments: Method, URL, Body
#Method is the HTTP method to use. ('GET', 'POST', etc)
#URL is the API URL to talk to.
#Body is the xml specific to the action.
# This is not used on 'GET' or 'DELETE' requests.
sub Request
{
	my $retval = 0;

	#get object reference
	my $self = shift();

	$self->dprint( "***REQUEST***\n");
	
	#clear last results
	$self->{replyheaders} = $self->{replycontent} = '';
	$self->{result} = {};
	
	if(@_ != 2 and @_ != 3) {
		$self->{result}->{reason} = 'Invalid number of arguments to request()';
		return 0;
	}
	
	#get parameters
	my($method,$url,$body) = @_;
	
	#$self->dprint( "Type: $type\nAction: $action\n$body\n");
	$self->dprint("Method: $method; URL: $url\n");
	$self->dprint("Body: $body\n") if $body;
	
	#keep some stats
	$self->{stats}->{requests}++;
	$self->{stats}->{rtime} = time;
	
	#check if we are authenticated to google
	if(!$self->IsAuthenticated()) {
		$self->dprint( "Error authenticating\n");
		return 0;
	}

	#standard XML pre and post segments
	# TODO: this changes in 2.0

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
	# v2.0 uses a diffent url based what's being done.
	# The API methods will construct the URL becuase action specific
	# information, such as domain and user, is embedded with it.
	# v2.0 use different methods depending on the action
	# It's up to the API methods to know which method to use
	my $req = HTTP::Request->new($method => $url);
	if(!defined($req)) {
		$self->dprint("Cannot create HTTP::Request object: $!\n");
		$self->{result}->{reason} = "Cannot create HTTP::Request object in request(): $!";
		return $retval;
	}
	
	#set some user agent variables
	$ua->agent( GOOGLEAGENT );
	$ua->from( '<' . $self->{admin}.'@'.$self->{domain} . '>');

	# Submit the request
	$req->header('Accept' => 'application/atom+xml');
	$req->header('Content-Type' => 'application/atom+xml');
	if ($body) {
	    $req->header('Content-Length' => length($body) );
	}
	$req->header('Connection' => 'Keep-Alive');
	$req->header('Host' => GOOGLEHOST);
	$req->header('Authorization' => 'GoogleLogin auth='.$self->{authtoken});
	#assign the data to the request
	# Perhaps if $method eq 'GET' or 'DELETE' would be better
	if ($body) {
	    $req->content($body);
	}
	
	#$self->dprint(Data::Dumper::Dumper($req));

	#execute the request
	my $response = $ua->request($req);
	$self->dprint(Data::Dumper::Dumper($response));
	#save reply page
	$self->{replyheaders} = $response->headers->as_string;
	$self->{replycontent} = $response->content;
	#check result
	if ($response->is_success) {
		$self->{stats}->{success}++;
		$self->dprint( "Success in post:\n");
		
		#delete all namespace elements to keep it simple (ie. remove "hs:")
		#this avoids the need to use XML::NameSpace
		# v2.0 uses a couple namespaces now, instead of just one.
		# I'm not sure that we can avoid using XML::NameSpace
		my $xml = decode('UTF-8', $response->content);
		#$xml =~ s/hs\://g;
		$self->dprint( $xml );
		
		if ($xml) {
		    #now go parse it using XML::Simple
		    my $simple = XML::Simple->new(ForceArray => 1);
		    #my $parser = XML::SAX::ParserFactory->new(Handler => $simple);
		    #$self->{result} = $parser->parse_string($xml);
		    $self->{result} = $simple->XMLin($xml);
		    # (OLD) $self->{result} = XMLin($xml,ForceArray => 0);
		    #include Data::Dumper above if you want to use this line:
		    $self->dprint( Dumper($self->{result}) );
		} else {
		    $self->{result} = {};
		}

		$self->dprint("Google API success!");
		$retval = 1;

	}
	else {
	    # OK. Funky issue. When trying to get a user that doesn't exist,
	    # Google throws a 400 error instead of returning a error document.

	    # Google has fun. If there is a problem with the request,
	    # google triggers a 400 error witch then fails on ->is_success.
	    # So, we need to check the content anyway to see if there is a
	    # reason for the failure.
	    $self->dprint("Google API failure!");
	    my $xml = decode('UTF-8', $response->content);
	    $self->dprint( $xml );
	    if ($xml) {
		my $simple = XML::Simple->new(ForceArray => 1);
		$self->{result} = $simple->XMLin($xml);
		$self->dprint( 'Error result: '.Dumper($self->{result}) );
	    }
	    if (defined ($self->{result}{error}[0]{reason})) {
		$@ = "Google API failure: "
		    .$self->{result}{error}[0]{errorCode}.' - '
		    .$self->{result}{error}[0]{reason};
		$self->dprint("$@\n");
		$self->{result}->{reason} = $@;
	    } else {
		$@ = "Google API failure: reason not found!";
		$self->dprint( "Error in post: " . $response->status_line . "\n");
		$self->{result}->{reason} = "Error in http post: " . $response->status_line;
	    }
	}
	#show full response for now
	#$self->dprint( "Headers:\n" . $response->headers->as_string);
	#foreach my $line (split/\n/, $response->content) {
	#	$self->dprint( "RECV'd:   $line\n");
	#}
	
	return $retval;
}

=pod

=head2 User Methods

These are the acutual API calls. These calls match up with the client
library methods described for the .Net and Java libraries.

=cut

### HOSTED ACCOUNT routines ###

=pod

CreateUser($userName, $givenName, $familyName, $password, $quota, $forceChange, $hashName)

=over

Creates a user in your Google Apps domain. The first four arguments are
required. The C<$quota> argument is optional and may not do anything unless
your agreement with Google allows you to change quotas.

If C<$forceChange> is true, the user will be required to change their
password after log in.

C<$hashName>, if set, must be I<sha-1> or I<md5>.

CreateUser() returns a C<VUser::Google::ProvisioningAPI::V2_0::UserEntry> object if
the request was successful and C<undef> otherwise.

=back

=cut

sub CreateUser {
    my $self = shift;

    if (@_ < 4 and @_ > 7) {
	$self->dprint("CreateUser method requires 4 to 7 arguments\n");
	$self->{result}->{reason} = "CreateUser method requires 4 to 7 arguments";
	return undef;
    }

    my ($username, $given_name, $family_name, $password, $quotaMB, $forceChange, $hash_name) = @_;
    $forceChange = $forceChange? 1 : 0;
    if(defined $hash_name) {
      if(lc($hash_name) eq "sha-1") {
        $hash_name = "SHA-1";
      } elsif (lc($hash_name) eq 'md5') {
        $hash_name = "MD5";
      }
      else {
	  # Unset $hash_name if it's not a valid hash type
	  $hash_name = undef;
      }
    }

    my $body = $self->XMLPrefix;
    #LP:changePasswordAtNextLogin (todo)
    $body .= '<atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/apps/2006#user"/>';
    $body .= "<apps:login userName=\"$username\" password=\"$password\" suspended=\"false\"";
    if(defined $hash_name) {
      $body .= " hashFunctionName=\"$hash_name\"";
    }
    if ($forceChange) {
	$body .= ' changePasswordAtNextLogin="true"';
    }
    $body .= "/>";
    $body .= "<apps:quota limit=\"$quotaMB\"/>" if defined $quotaMB; 
    $body .= "<apps:name familyName=\"$family_name\" givenName=\"$given_name\"/>";
    $body .= $self->XMLPostfix;

    if ($self->Request('POST',
		       GOOGLEBASEURL.$self->{domain}."/user/$APIVersion",
		       $body)) {
	my $entry = $self->buildUserEntry();
	return $entry;
    } else {
	return undef;
    }

    # Return UserEntry
}

=pod

RetrieveUser($userName)

=over

Get the passed user from Google. Returns a
C<VUser::Google::ProvisioningAPI::V2_0::UserEntry> object.

=back

=cut

sub RetrieveUser {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("RetrieveUser method requires 1 argument\n");
	$self->{result}->{reason} = "RetrieveUser method requires 1 argument";
	return undef;
    }

    my $username = shift;
    my $url = GOOGLEBASEURL.$self->{domain}."/user/$APIVersion/$username";

    if ($self->Request('GET',$url)) {
	return $self->buildUserEntry();
    } else {
	return undef;
    }

    # Return UserEntry
}

=pod

RetrieveAllUsers()

=over

Returns a list of all users in your domain. The entries are
C<VUser::Google::ProvisioningAPI::V2_0::UserEntry> objects.

=back

=cut

sub RetrieveAllUsers {
    my $self = shift;

    # Need to deal with google's pagination thing.
    my $last_page = 0;
    my $url = GOOGLEBASEURL.$self->{domain}."/user/$APIVersion";
    my @entries = ();
    while (not $last_page) {
	# It might be better to adjust this to use RetrievePageOfUsers()
	if ($self->Request('GET', $url)) {			   
	    foreach my $entry (@{ $self->{result}{'entry'} }) {
		push @entries, $self->buildUserEntry($entry);
	    }
	} else {
	    # There was some sort of error which caused the lookup to fail.
	    # This also means that if pages beyond the first fail, the entire
	    # dataset is discarded.
	    return undef;
	}
	$last_page = 1; # gets reset to 0 if there are more pages
	# Look through the links to see if there's another page.
	# A link with rel=next means that we have another page to look at.
	#
	# TODO: May be more efficient with a last; in the else but
	# I had problems with infinite loops while trying to get it
	# sorted out.
	foreach my $link (@{ $self->{result}{'link'} }) {
	    if ($link->{'rel'} eq 'next') {
		$url = $link->{'href'};
		$last_page = 0;
#	    } else {
#		$last_page = 1;
	    }
	}
    }
    return @entries;

    # Return list of UserEntries
}

=pod

RetrievePageOfUsers($startUser)

=over

Google Provisioning API 2.0 supports returning lists of users 100 at a time.
C<$startUser> is optional. When used, it will be the list will start at
that user. Otherwise, it will return the first 100 users.

RetrievePageOfUsers() returns a list of
C<VUser::Google::ProvisioningAPI::V2_0::UserEntry> objects.

=back

=cut

sub RetrievePageOfUsers {
    my $self = shift;

    if (@_ > 1) {
	$self->dprint("RetrievePageOfUser method requires 0 or 1 argument\n");
	$self->{result}->{reason} = "RetrievePageOfUser method requires 0 or 1 argument";
	return undef;
    }

    my $start_username = shift;

    my $url = GOOGLEBASEURL.$self->{domain}."/user/$APIVersion";
    $url .= "?startUsername=$start_username" if defined $start_username;

    my @entries = ();
    if ($self->Request('GET', $url)) {			   
	foreach my $entry (@{ $self->{result}{'entry'} }) {
	    push @entries, $self->buildUserEntry($entry);
	}
    } else {
	# There was some sort of error which caused the lookup to fail.
	# This also means that if pages beyond the first fail, the entire
	# dataset is discarded.
	return undef;
    }

    # Return list of UserEntries
    return @entries;
}

=pod

UpdateUser($userName, $newUserEntry)

=over

C<$userName> is the mandatory name of the user account. C<$newUserEntry> is a
C<VUser::Google::ProvisioningAPI::V2_0::UserEntry> object with the changes to the
account. You only need to set the elements of C<$newUserEntry> that are being
changed. B<Note:> According to the Google API docs, you should not set the
password unless you are actually changing the password.

=back

=cut

sub UpdateUser {
    my $self = shift;

    if (@_ != 2) {
	$self->dprint("UpdateUser method requires 2 arguments\n");
	$self->{result}->{reason} = "UpdateUser method requires 2 arguments";
	return undef;
    }

    my $username = shift;
    my $new_entry = shift; # G::P::V2_0::UserEntry

    my $body = $self->XMLPrefix;
    $body .= '<atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/apps/2006#user"/>';
    if (defined ($new_entry->User)
	or defined ($new_entry->Password)
	or defined ($new_entry->isSuspended)
	or defined ($new_entry->changePasswordAtNextLogin)
	) {
	$body .= '<apps:login';
	if(defined $new_entry->{hashFunctionName}) {
	    $body .= ' hashFunctionName="'.$new_entry->{hashFunctionName}.'"';
	}
	$body .= ' userName="'.$new_entry->User.'"' if defined $new_entry->User;

	if (defined $new_entry->Password) {
	    my $passwd = $new_entry->Password;
	    # escape quotes
	    # See section 2.4 of http://www.w3.org/TR/xml/
	    #$passwd =~ s/\"/\\"/;
	    $passwd =~ s/\"/&quot;/;
	    $body .= ' password="'.$passwd.'"';
	}

	$body .= ' suspended="'.($new_entry->isSuspended? 'true' : 'false').'"';
	#LP:changePasswordAtNextLogin
	#print "too(".$new_entry->changePasswordAtNextLogin.")";
	$body .= ' changePasswordAtNextLogin="'.($new_entry->changePasswordAtNextLogin? 'true' : 'false').'"';
	$body .= '/>';
    }

    if (defined ($new_entry->FamilyName)
	or defined ($new_entry->GivenName)) {
	$body .= '<apps:name';
	$body .= ' familyName="'.$new_entry->FamilyName.'"' if defined $new_entry->FamilyName;
	$body .= ' givenName="'.$new_entry->GivenName.'"' if defined $new_entry->GivenName;
	$body .= '/>';
    }

    if (defined ($new_entry->Quota)) {
	$body .= '<apps:quota limit="'.$new_entry->Quota.'"/>';
    }

    $body .= $self->XMLPostfix;

    # The body has been contructed. We are 'Go' to make the request.
    if ($self->Request('PUT',
		       GOOGLEBASEURL.$self->{domain}."/user/$APIVersion/$username",
		       $body)) {
	my $entry = $self->buildUserEntry();
	return $entry;
    } else {
	return undef;
    }

    # Return UserEntry
}

=pod

SuspendUser($userName)

=over

C<$userName> is the name of the user that you want to suspend.

Returns a C<VUser::Google::ProvisioningAPI::V2_0::UserEntry> object if successful.

=back

=cut

sub SuspendUser {
    my $self = shift;
    my $username = shift;

    my $entry = VUser::Google::ProvisioningAPI::V2_0::UserEntry->new();
    $entry->isSuspended(1);

    return $self->UpdateUser($username, $entry);
    
    # Return UserEntry
}

=pod

RestoreUser($userName)

=over

Unsuspend the user's account. C<$userName> is required.

Returns a C<VUser::Google::ProvisioningAPI::V2_0::UserEntry> object if successful.

=back

=cut

sub RestoreUser {
    my $self = shift;
    my $username = shift;

    my $entry = VUser::Google::ProvisioningAPI::V2_0::UserEntry->new();
    $entry->isSuspended(0);

    return $self->UpdateUser($username, $entry);

    # Return UserEntry
}

=pod

DeleteUser($userName)

=over

C<$userName> is the required user name to delete.

Returns '1' on success.

=back

=cut

sub DeleteUser {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("DeleteUser method requires 1 argument\n");
	$self->{result}->{reason} = "DeleteUser method requires 1 argument";
	return undef;
    }

    my $username = shift;

    if ($self->Request('DELETE',
		       GOOGLEBASEURL.$self->{domain}."/user/$APIVersion/$username")) {
	return 1;
    } else {
	return undef;
    }

    # Return undef
}

### NICKNAME routines ###

=pod

=head3 Nickname methods

CreateNickname($userName, $nickName)

=over

Creates a nickname (or alias) for a user. C<$userName> is the existing user
and C<$nickName> is the user's new nickname.

Returns a C<VUser::Google::ProvisioningAPI::V2_0::NicknameEntry> object on success.

=back

=cut

sub CreateNickname {
    my $self = shift;

    if (@_ != 2) {
	$self->dprint("CreateNickname method requires 2 arguments\n");
	$self->{result}->{reason} = "CreateNickname method requires 2 arguments";
	return undef;
    }

    my $username = shift;
    my $nickname = shift;

    my $body = $self->XMLPrefix;
    $body .= '<atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/apps/2006#nickname"/>';
    $body .= "<apps:nickname name=\"$nickname\"/>";
    $body .= "<apps:login userName=\"$username\"/>";
    $body .= $self->XMLPostfix;

    if ($self->Request('POST',
		       GOOGLEBASEURL.$self->{domain}."/nickname/$APIVersion",
		       $body)) {
	return $self->buildNicknameEntry();
    } else {
	return undef;
    }

    # Return NicknameEntry
}

=pod

RetrieveNickname($nickName)

=over

Returns a C<VUser::Google::ProvisioningAPI::V2_0::NicknameEntry> if the C<$nickName>
exists.

=back

=cut

sub RetrieveNickname {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("RetrieveNickname method requires 1 argument\n");
	$self->{result}->{reason} = "RetrieveNickname method requires 1 argument";
	return undef;
    }

    my $nickname = shift;

    if ($self->Request('GET',
		       GOOGLEBASEURL.$self->{domain}."/nickname/$APIVersion/$nickname")) {
	return $self->buildNicknameEntry();
    } else {
	return undef;
    }
	
    # Return NicknameEntry
}

=pod

RetrieveNicknames($userName)

=over

Get all nicknames for C<$userName>.

Returns a list of C<VUser::Google::ProvisioningAPI::V2_0::NicknameEntry> objects.

=back

=cut

sub RetrieveNicknames {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("RetrieveNicknames method requires 1 argument\n");
	$self->{result}->{reason} = "RetrieveNicknames method requires 1 argument";
	return undef;
    }

    my $username = shift;

    my $url = GOOGLEBASEURL.$self->{domain}."/nickname/$APIVersion?username=$username";
    my $last_page = 0;
    my @entries = ();
    # And we get to deal with funky pagination here, too.
    while (not $last_page) {
	if ($self->Request('GET', $url)) {
	    foreach my $entry (@{ $self->{result}{'entry'} }) {
		push @entries, $self->buildNicknameEntry($entry);
	    }
	} else {
	    return undef;
	}

	# Look through the links to see if there's another page.
	# A link with rel=next means that we have another page to look at.
	foreach my $link (@{ $self->{result}{'link'} }) {
	    if ($link->{'rel'} eq 'next') {
		$url = $link->{'href'};
		$last_page = 0;
	    } else {
		$last_page = 1;
	    }
	}
    }

    return @entries;

    # Return list of NicknameEntries
}

=pod

RetrieveAllNicknames()

=over

Get all of the nick names for your domain.

Returns a list of C<VUser::Google::ProvisioningAPI::V2_0::NicknameEntry> objects.

=back

=cut

sub RetrieveAllNicknames {
    my $self = shift;


    my $url = GOOGLEBASEURL.$self->{domain}."/nickname/$APIVersion";
    my $last_page = 0;
    my @entries = ();
    # And we get to deal with funky pagination here, too.
    while (not $last_page) {
	if ($self->Request('GET', $url)) {
	    foreach my $entry (@{ $self->{result}{'entry'} }) {
		push @entries, $self->buildNicknameEntry($entry);
	    }
	} else {
	    return undef;
	}

	# Look through the links to see if there's another page.
	# A link with rel=next means that we have another page to look at.
	foreach my $link (@{ $self->{result}{'link'} }) {
	    if ($link->{'rel'} eq 'next') {
		$url = $link->{'href'};
		$last_page = 0;
	    } else {
		$last_page = 1;
	    }
	}
    }

    return @entries;

    # Return list of NicknameEntries
}

=pod

RetrievePageOfNicknames($startNick)

=over

Get 100 of the nick names for your domain. If C<$startNick> is defined,
the list will start with that nick name, otherwise, the first 100 nicks
will be returned.

Returns a list of C<VUser::Google::ProvisioningAPI::V2_0::NicknameEntry> objects.

=back

=cut

sub RetrievePageOfNicknames {
    my $self = shift;
    my $start_nick = shift;

    my $url = GOOGLEBASEURL.$self->{domain}."/nickname/$APIVersion";
    $url .= "?startNickname=$start_nick" if defined $start_nick;
    my @entries = ();
    if ($self->Request('GET', $url)) {
	foreach my $entry (@{ $self->{result}{'entry'} }) {
	    push @entries, $self->buildNicknameEntry($entry);
	}
    } else {
	return undef;
    }

    return @entries;
    # Return list of NicknameEntries
}

=pod

DeleteNickname($nickName)

=over

Delete C<$nickName> from your domain. Returns 1 if the request succeeds.

=back

=cut

sub DeleteNickname {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("DeleteNickname method requires 1 argument\n");
	$self->{result}->{reason} = "DeleteNickname method requires 1 argument";
	return undef;
    }

    my $nickname = shift;

    if ($self->Request('DELETE',
		       GOOGLEBASEURL.$self->{domain}."/nickname/$APIVersion/$nickname")) {
	return 1;
    } else {
	return undef;
    }

    # Return undef
}

### EMAIL LIST routines ###

=pod

=head3 Email list methods

CreateEmailList($listName)

=over

Create an email list named C<$listName>.

Returns a C<VUser::Google::ProvisioningAPI::V2_0::EmailListEntry> on success.

=back

=cut

sub CreateEmailList {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("CreateEmailList method requires 1 argument\n");
	$self->{result}->{reason} = "CreateEmailList method requires 1 argument";
	return undef;
    }

    my $emaillist = shift;

    my $body = $self->XMLPrefix;
    $body .= '<atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/apps/2006#emailList"/>';
    $body .= "<apps:emailList name=\"$emaillist\"/>";
    $body .= $self->XMLPostfix;

    if ($self->Request('POST',
		       GOOGLEBASEURL.$self->{domain}."/emailList/$APIVersion",
		       $body)) {
	my $entry = $self->buildEmailListEntry();
	return $entry;
    } else {
	return undef;
    }

    # Return EmailListEntry
}

=pod

RetrieveEmailLists($recipient)

=over

Get a list of all local email lists that C<$recipient> is subscribed to.
C<$recipient> is limited to users at your domain.

Returns a list of C<VUser::Google::ProvisioningAPI::V2_0::EmailListEntry> objects.

=back

=cut

sub RetrieveEmailLists {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("RetrieveEmailLists method requires 1 argument\n");
	$self->{result}->{reason} = "RetrieveEmailLists method required 1 argument\n";
    }

    my $recipient = shift;

    my $url = GOOGLEBASEURL.$self->{domain}."/emailList/$APIVersion?recipient=$recipient";
    my $last_page = 0;
    my @entries = ();
    # Work with Google's pagination
    while (not $last_page) {
	if ($self->Request('GET', $url)) {
	    foreach my $entry (@{ $self->{result}{'entry'} }) {
		push @entries, $self->buildEmailListEntry($entry);
	    }
	} else {
	    return undef;
	}

	# Look for next page link
	foreach my $link (@{ $self->{result}{'link'} }) {
	    if ($link->{'rel'} eq 'next') {
		$url = $link->{'href'};
		$last_page = 0;
	    } else {
		$last_page = 1;
	    }
	}
    }

    # Return list of EmailListEntries
    return @entries;
}

=pod

RetrieveAllEmailLists()

=over

Get a list of all email lists for your domain.

Returns a list of C<VUser::Google::ProvisioningAPI::V2_0::EmailListEntry> objects.

=back

=cut

sub RetrieveAllEmailLists {
    my $self = shift;

    my $url = GOOGLEBASEURL.$self->{domain}."/emailList/$APIVersion";
    my $last_page = 0;
    my @entries = ();
    # Work with Google's pagination
    while (not $last_page) {
	if ($self->Request('GET', $url)) {
	    foreach my $entry (@{ $self->{result}{'entry'} }) {
		push @entries, $self->buildEmailListEntry($entry);
	    }
	} else {
	    return undef;
	}

	# Look for next page link
	foreach my $link (@{ $self->{result}{'link'} }) {
	    if ($link->{'rel'} eq 'next') {
		$url = $link->{'href'};
		$last_page = 0;
	    } else {
		$last_page = 1;
	    }
	}
    }

    # Return list of EmailListEntries
    return @entries;
}

=pod

RetrievePageOfEmailLists($startList)

=over

Get a single page (100 lists) of email lists.

=back

=cut

sub RetrievePageOfEmailLists {
    my $self = shift;

    my $start_emaillist = shift;

    my $url = GOOGLEBASEURL.$self->{domain}."/emailList/$APIVersion";
    if ($start_emaillist) {
	$url .= "?startEmailListName=$start_emaillist";
    }
    my @entries = ();

    if ($self->Request('GET', $url)) {
	foreach my $entry (@{ $self->{result}{'entry'} }) {
	    push @entries, $self->buildEmailListEntry($entry);
	}
    } else {
	return undef;
    }

    # Return list of EmailListEntries
    return @entries;
}

=pod

DeleteEmailList($emailList)

=over

Delete C<$emailList> from your domain.

Returns 1 on success.

=back

=cut

sub DeleteEmailList {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("DeleteUser method requires 1 argument\n");
	$self->{result}->{reason} = "DeleteUser method requires 1 argument";
	return undef;
    }

    my $emaillist = shift;

    if ($self->Request('DELETE',
		       GOOGLEBASEURL.$self->{domain}."/emailList/$APIVersion/$emaillist")) {
	return 1;
    } else {
	return undef;
    }

    # Return undef
}

=pod

AddRecipientToEmailList($recipient, $emailList)

=over

Adds a recipient to a mail list. C<$recipient> is the address you want to
add and C<$emailList> is the list to add to.

Returns a C<VUser::Google::ProvisioningAPI::V2_0::EmailListRecipientEntry> object on
success.

=back

=cut

sub AddRecipientToEmailList {
    my $self = shift;

    if (@_ != 2) {
	$self->dprint("AddRecipientToEmailList method requires 2 argument\n");
	$self->{result}->{reason} = "AddRecipientToEmailList method requires 2 argument";
	return undef;
    }

    my $recipient = shift;
    my $emaillist = shift;

    my $body = $self->XMLPrefix;
    $body =~ s!>$! xmlns:gd="http://schemas.google.com/g/2005">!;
    $body .= '<atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/apps/2006#emailList.recipient"/>';
    $body .= "<gd:who xmlns=\"http://schemas.google.com/g/2005\" email=\"$recipient\"/>";
    $body .= $self->XMLPostfix;

    if ($self->Request('POST',
		       GOOGLEBASEURL.$self->{domain}
		       ."/emailList/$APIVersion/$emaillist/recipient",
		       $body)) {
	my $entry = $self->buildEmailListRecipientEntry();
	return $entry;
    } else {
	return undef;
    }

    # Return EmailListRecipientEntry
}

=pod

RetrieveAllRecipients($emailList)

=over

Get a list of the recipients of the specified email list.

Returns a list of C<VUser::Google::ProvisioningAPI::V2_0::EmailListRecipientEntry> objects.

=back

=cut

sub RetrieveAllRecipients {
    my $self = shift;

    if (@_ != 1) {
	$self->dprint("RetrieceAllRecipients method requires 1 argument\n");
	$self->{result}->{reason} = "RetrieveAllRecipients method requires 1 argument";
	return undef;
    }

    my $emaillist = shift;

    my $url = GOOGLEBASEURL.$self->{domain}."/emailList/$APIVersion/$emaillist/recipient";
    my $last_page = 0;
    my @entries = ();
    # Google Pagination again
    while (not $last_page) {
	if ($self->Request('GET', $url)) {
	    foreach my $entry (@{ $self->{result}{'entry'} }) {
		my $entry = $self->buildEmailListRecipientEntry($entry);
		push @entries, $entry if $entry;
	    }
	} else {
	    return undef;
	}

	foreach my $link (@{ $self->{result}{'link'} }) {
	    if ($link->{'rel'} eq 'next') {
		$url = $link->{'href'};
		$last_page = 0;
	    } else {
		$last_page = 1;
	    }
	}
    }

    # Return list of EmailListRecipientEntries
    return @entries;
}

=pod

RetrievePageOfRecipients($emailList, $startRecpt)

=over

Get a page of recipients for that given list (C<$emailList)> starting with
C<$startRecpt> or the beginning if C<$startRecpt> is not defined.

Returns a list of C<VUser::Google::ProvisioningAPI::V2_0::EmailListRecipientEntry> objects.

=back

=cut

sub RetrievePageOfRecipients {
    my $self = shift;

    if (@_ != 2) {
	$self->dprint("RetrievePageOfRecipients method requires 2 arguments\n");
	$self->{result}->{reason} = "RetrievePageOfRecipients method requires 2 arguments";
	return undef;
    }

    my $emaillist = shift;
    my $start_rcpt = shift;

    my $url = GOOGLEBASEURL.$self->{domain}."/emailList/$APIVersion/$emaillist/recipient";
    if ($start_rcpt) {
	$url .= "?startRecipient=$start_rcpt";
    }
    my @entries = ();
    
    if ($self->Request('GET', $url)) {
	foreach my $entry (@{ $self->{result}{'entry'} }) {
	    push @entries, $self->buildEmailListRecipientEntry();
	}
    } else {
	return undef;
    }

    # Return list of EmailListRecipientEntries
    return @entries;
}

=pod

RemoveRecipientFromEmailList($recipient, $emailList)

=over

Remove C<$recipient> from the given email list (C<$emailList>).

Returns 1 in success.

=back

=cut

sub RemoveRecipientFromEmailList {
    my $self = shift;

    if (@_ != 2) {
	$self->dprint("RemoveRecipientFromEmailList method requires 2 arguments\n");
	$self->{result}->{reason} = "RemoveRecipientFromEmailList method requires 2 arguments";
	return undef;
    }

    my $recipient = shift;
    my $emaillist = shift;

    if ($self->Request('DELETE',
		       GOOGLEBASEURL.$self->{domain}
		       ."/emailList/$APIVersion/$emaillist/recipient/$recipient")) {
	return 1;
    } else {
	return undef;
    }

    # Return undef
}

### Private methods

sub XMLPrefix {
    my $pre = '<?xml version="1.0" encoding="UTF-8"?>';
    $pre .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom"';
    $pre .= ' xmlns:apps="'.GOOGLEAPPSSCHEMA.'">';

    return $pre;
}

sub XMLPostfix {
    return '</atom:entry>';
}

sub buildUserEntry {
    my $self = shift;
    my $xml = shift || $self->{result};

    my $entry = VUser::Google::ProvisioningAPI::V2_0::UserEntry->new();

    $entry->User($xml->{'apps:login'}[0]{'userName'});

    if ($xml->{'apps:login'}[0]{'suspended'}) {
	if ($xml->{'apps:login'}[0]{'suspended'} eq 'true') {
	    $entry->isSuspended(1);
	} else {
	    $entry->isSuspended(0);
	}
    }

    #LP: changePasswordAtNextLogin
    if ($xml->{'apps:login'}[0]{'changePasswordAtNextLogin'}) {
	if ($xml->{'apps:login'}[0]{'changePasswordAtNextLogin'} eq 'true') {
	    $entry->changePasswordAtNextLogin(1);
	} else {
	    $entry->changePasswordAtNextLogin(0);
	}
    }    

    $entry->FamilyName($xml->{'apps:name'}[0]{'familyName'});
    $entry->GivenName($xml->{'apps:name'}[0]{'givenName'});
    $entry->Quota($xml->{'apps:quota'}[0]{'limit'});

    return $entry;
}

sub buildNicknameEntry {
    my $self = shift;
    my $xml = shift || $self->{result};

    my $entry = VUser::Google::ProvisioningAPI::V2_0::NicknameEntry->new();

    $entry->User($xml->{'apps:login'}[0]{'userName'});
 
    # Odd parser problem:
    #  <apps:nickname name='test1'/>
    # yeilds:
    #  'apps:nickname' => { 'test1' => {} },
    #$entry->Nickname($xml->{'apps:nickname'}[0]{'name'});
    # This is an exceptionally ugly hack to work around the parser issue
    # above.
    $entry->Nickname((keys %{$xml->{'apps:nickname'}})[0]);

    return $entry;
}

sub buildEmailListEntry {
    my $self = shift;
    my $xml = shift || $self->{'result'};

    my $entry = VUser::Google::ProvisioningAPI::V2_0::EmailListEntry->new();

    # This seems to have the same problem as nicknames.
    #$entry->EmailList($xml->{'apps:emailList'}[0]{'name'});
    $entry->EmailList((keys %{$xml->{'apps:emailList'}})[0]);

    return $entry;
}

sub buildEmailListRecipientEntry {
    my $self = shift;
    my $xml = shift || $self->{'result'};

    my $entry = VUser::Google::ProvisioningAPI::V2_0::EmailListRecipientEntry->new();

    $entry->Who($xml->{'gd:who'}[0]{'email'});

    return $entry;
}

=pod

=head1 ACCESSING RESULTING DATA

Most API calls return an object so that you don't have to screw around with the
XML data. The parsed XML (by XML::Simple) is available in C<$google->{result}>.

=head1 EXPORT

None by default.


=head1 SEE ALSO

The perldocs for VUser::Google::ProvisioningAPI::V2_0::UserEntry;
VUser::Google::ProvisioningAPI::V2_0::NicknameEntry;
VUser::Google::ProvisioningAPI::V2_0::EmailListEntry;
and VUser::Google::ProvisioningAPI::V2_0::EmailListRecipientEntry.

The official Google documentation can be found at
http://code.google.com/apis/apps-for-your-domain/google_apps_provisioning_api_v2.0_reference.html

http://code.google.com/apis/apps/gdata_provisioning_api_v2.0_reference.html

For support, see the Google Group at
http://groups.google.com/group/apps-for-your-domain-apis

For additional support specific to this modules, email me at johan at reinalda dot net.

=head1 AUTHOR

Johan Reinalda, johan at reinalda dot net
Randy Smith, perlstalker at vuser dot org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Johan Reinalda, johan at reinalda dot net
Copyright (C) 2007 by Randy Smith, perlstalker at vuser dot org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

If you make useful modification, kindly consider emailing then to me for inclusion in a future version of this module.

=cut

1;

