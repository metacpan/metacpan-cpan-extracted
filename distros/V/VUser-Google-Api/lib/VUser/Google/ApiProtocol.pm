package VUser::Google::ApiProtocol;
use warnings;
use strict;

use Moose;

our $VERSION = '1.0.1';

## Members
# The Google hosted domain we are accessing
has 'domain' => (is => 'rw');

# The admin account
has 'admin' => (is => 'rw');

# Admin password
has 'password' => (is => 'rw');

# Turn on deugging
has 'debug' => (is => 'rw', default => 0);

# If set, will force re-authentication
has 'refresh_token' => (is => 'rw',
			isa => 'Bool',
			default => 0,
			#init_arg => undef
			);

# The authentication token returned from Google
has 'authtoken' => (is => 'rw',
		    writer => '_set_authtoken',
		    #init_arg => undef
		    );

# Time when auth happened; only valid for 24 hours
# Unix timestamp
has 'authtime' => (is => 'rw',
		   default => 0,
		   writer => '_set_authtime',
		   #init_arg => undef
		   );

# the last http content posted from Google
has 'request_content' => (is => 'rw',
			  writer => '_set_request_content',
			  #init_arg => undef
			  );

# The http headers of the last reply
has 'reply_headers' => (is => 'rw',
			writer => '_set_reply_headers',
			#init_arg => undef
			);

# The http content of the last reply
has 'reply_content' => (is => 'rw',
			writer => '_set_reply_content',
			#init_arg => undef
			);

# The resulting hash from the last reply data as parsed
# by XML::Simple
has 'result' => (is => 'rw',
		 isa => 'HashRef',
		 writer => '_set_result',
		 #init_arg => undef
		 );

# Some API statistics
has 'stats' => (is => 'rw',
		isa => 'HashRef',
		default => sub { {ctime => time(), # object creation time
				  rtime => 0,      # time of last request
				  requests => 0,   # number of API requests made
				  success => 0,    # number of successes
				  logins => 0      # number of authentications
				  };
			     },
		writer => '_set_stats',
		#init_arg => undef
		);

has 'useragent' => (is => 'ro',
		    lazy => 1,
		    builder => '_build_useragent'
		    );

has 'version' => (is => 'ro',
		  builder => '_build_version'
		  );

## Methods
sub _build_useragent {
    my $self = shift;
    return ref($self).'/'.$self->version();
}

sub _build_version {
    my $self = shift;
    my $class = ref($self);
    my $ver;
    no strict 'refs';
    # There has got to be cleaner way to do this.
    $ver = eval { ${ $class."::VERSION" } };
    $ver = $VERSION if $@;
    return $ver;
}

sub Login {}

sub IsAuthenticated {}

#generic request routine that handles most functionality
#requires 3 arguments: Method, URL, Body
#Method is the HTTP method to use. ('GET', 'POST', etc)
#URL is the API URL to talk to.
#Body is the xml specific to the action.
# This is not used on 'GET' or 'DELETE' requests.
sub Request {}

#print out debugging to STDERR if debug is set
sub dprint
{
    my $self = shift;
    my $text = shift;
    my @args = @_;
    if( $self->debug and defined ($text) ) {
	if (@_) {
	    print STDERR sprintf ("$text\n", @args);
	}
	else {
	    print STDERR "$text\n";
	}
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

VUser::Google::ApiProtocol - Base class for implementation of the Google APIs

=head1 SYNOPSIS

This class is not meant to be used directly. Instead use
L<VUser::Google::ApiProtocol::V2_0>.

=head1 DESCRIPTION

=head1 MEMBERS

These are the members of the ApiProtocol class. You get and set the values
by using the method of the same name. For example:

 # Get the domain from the ApiProtocol object
 my $domain = $google->domain;
 
 # Set the domain
 $google->domain('myappsdomain.com');

Most of the member can be set when the object is created with C<new()>.

 my $google = VUser::ApiProtocol->new(
     domain => 'myappsdomain.com'
 );

B<Note:> VUser::Google::ApiProtocol is not meant to be used directly.
Please see the version specific subclasses, such as
L<VUser::Google::ApiProtocol::V2_0>, to create a usable object.

=head2 Read-write Members

=over

=item admin

The administrative user. This user must have be set as an admin in the
Google Apps control panel. Also, be sure to log into the Google Apps control
panel once with this user to accept all of the legal garbage or you will
see intermittent auth errors.

=item debug

Turn on debugging output.

=item domain

The Google Apps domain to work on.

=item password

The plain text password of the admin user.

=item refresh_token

If set to a true value, C<Login()> will refresh the authentication token
even if it's not necessary.
=back

=head2 Read-only members

=over

=item authtime

The unix timestamp of the last authentication.

=item authtoken

The authentication token retrieved from Google on a successful login.
The token is only valid for 24 hours.

=item reply_headers

The HTTP headers of the last reply

=item reply_content

The HTTP content of the last reply

=item result

The resulting hash from the last reply data as parsed by XML::Simple

=item useragent

The user agent VUser::Google::ApiProtocol uses when talking to Google. It
is set to the I<classname/version>. For example,
I<VUser::Google::ApiProtocol::V2_0/0.25>.

=back

=head1 METHODS

=head2 new (%defaults)

Create a new ApiProtocol object. Any read-write member may be set in the
call to C<new()>.

=head2 Login

Login to the Google API. C<Login()> takes no parameters. Instead, you
must set the C<domain>, C<admin>, and C<password> members, then call
C<Login()>.

C<Login()> will use the existing authentication token if it exists and
hasn't yet timed out. You may force it to do a full re-authentication by
setting C<refresh_token> to a true value before calling C<Login()>.

=head2 IsAuthenticated

Returns true if the B<object> thinks that it has already authenticated and
the token hasn't timed out and a false value otherwise.

B<Note:> C<IsAuthenticated()> only knows if there's an authtoken and if
it's still fresh. It may be possible for Google to decide that a token
is not valid which C<IsAuthenticated()> cannot check.

=head2 Request ($method, $url[, $body])

Sends an API request to Google.

C<$method> is the HTTP method to use, e.g. I<GET>, I<POST>, etc. B<Note:>
Many of the API calls use different methods. Double check the API docs to
make sure you are using the correct method.

C<$url> is the url to use to make the API call. The URLs are defined in 
the API docs.

C<$body> is the XML specific action. Again, see the API docs for the
specific format for each API call. C<$body> is not needed when the method
is I<GET> or I<DELETE>.

=head2 dprint ($message)

Prints C<$message> to STDERR if C<debug> is set to a true value.

=head1 SEE ALSO

L<XML::Simple>

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE


