package WWW::Sitebase::Navigator;

use warnings;
use strict;
use WWW::Sitebase -Base;
use Carp;
use WWW::Mechanize;
use File::Spec::Functions;
use Term::ReadKey; # For password prompt

=head1 NAME

WWW::Sitebase::Navigator - Base class for modules that navigate web sites

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

This module is a base class for modules that navigate web sites
like Myspace or Bebo.  It provides basic methods like
get_page and submit_form that are more robsut than their counterparts
in WWW::Mechanize.  It also provides some core methods like "site_login".
If you subclass this module and override the "site_info" method,
you'll have a module that can log into your web site. Ta Da.

Note that this module is a subclass of "Spiffy" using "use Spiffy -Base".
perldoc Spiffy for more info or look it up on CPAN.
Most importantly this means we use Spiffy's "field" method to create
accessor methods, you don't need to include "my $self = shift"
in your methods, and you can use "super" to call the base class's
version of an overridden method.

    use WWW::Sitebase::Navigator -Base;

    field site_info => {
        home_page => 'http://www.myspace.com', # URL of site's homepage
        account_field => 'email', # Fieldname from the login form
        password_field => 'password', # Password fieldname
        cache_dir => '.www-MYSITE',
        login_form_name => 'login', # The name of the login form.  OR
        login_form_no => 1, # The number of the login form (defaults to 1).
                            # 1 is the first form on the page.
        login_verify_re => 'Welcome.*view my profile', # (optional)
            # Non-case-sensitive RE we should see once we're logged in
        not_logged_in_re => '<title>Sign In<\/title>',
            # If we log in and it fails (bad password, account suddenly
            # gets logged out), the page will have this RE on it.
            # Case insensitive.
        home_uri_re => '\?fuseaction=user&',
            # _go_home uses this and the next two items to load
            # the home page.  You can provide these options or
            # just override the method.
            # First, this is matched against the current URL to see if we're
            # already on the home page.
        home_link_re => 'fuseaction=user',
            # If we're not on the home page, this RE is 
            # used to find a link to the "Home" button on the current
            # page.
        home_url => 'http://www.myspace.com?fuseaction=user',
            # If the "Home" button link isn't found, this URL is
            # retreived.
        error_regexs => [
            'An unexpected error has occurred',
            'Site is temporarily down',
            'We hired monkeys to program our site, please wait '.
                'while they throw bananas at each other.'
        ],
            # error_regexs is optional.  If the site you're navigating
            # displays  error pages that do not return proper HTTP Status
            # codes (i.e. returns a 200 but displays an error), you can enter
            # REs here and any page that matches will be retried.
            # This is meant for IIS and ColdFusion-based sites that
            # periodically spew error messages that go away when tried again.
    };

IMPORTANT:  If the site your module navigates uses ANY SSL, you'll
need to add "Crypt::SSLEay" or "IO::Socket::SSL" to your list of prerequisite
modules.  Otherwise your methods will die if they hit an SSL-encrypted page.
WWW::Sitebase::Navigator doesn't require this for you to prevent unnecessary
overhead for sites that don't need it.

=cut

# Where should we store files? (cookies, cache dir). We use, and untaint,
# the user's home dir for the default.
sub _home_dir {
    my $home_dir = "";
    if ( defined $ENV{'HOME'} ) {
        $home_dir = "$ENV{'HOME'}";
        
        if ( $home_dir =~ /^([\-A-Za-z0-9_ \/\.@\+\\:]*)$/ ) {
            $home_dir = $1;
        } else {
            croak "Invalid characters in $ENV{HOME}.";
        }
    }
    
    return $home_dir;
}

=head1 OPTIONS

=head2 default_options

Override this method to allow additional options to be passed to
"new".  You should also provide accessor methods for them.
These are parsed by Params::Validate.  In breif, setting an
option to "0" means it's optional, "1" means it's required.
See Params::Validate for more info.

    sub default_options {
        $self->{default_options}={
            account_name => 0,
            password => 0,
            cache_dir => 0,  # Default set by site_info field method
            cache_file => 0, # Default set by field method below
            auto_login => 0, # Default set by field method below
            human => 0,      # Default set by field method below
            config_file => 0
        };

        return $self->{default_options};
    }

    # So to add a "questions" option that's mandatory:

    sub default_options {
        super;
        $self->{default_options}->{questions}=1;
        return $self->{default_options};
    }

=cut

# Options they can pass via hash or hashref.
sub default_options {
    $self->{default_options}={
        account_name => 0,
        password => 0,
        cache_dir => 0,  # Default set by site_info field method
        cache_file => 0, # Default set by field method below
        auto_login => 0, # Default set by field method below
        human => 0,      # Default set by field method below
        config_file => 0,
        use_defaults => 0
    };
    
    return $self->{default_options};
}

=head2 positional_parameters

You can also allow your users to provide information to the "new"
method via positional parameters.  If the first argument passed
to "new" is not a known valid option, positional parameters
are used instead.

These default to:

 const positional_parameters => [ 'account_name', 'password' ];

You can override this method to provide your own list if you like:

 const positional_parameters => [ 'account_name', 'password', 'shoe_size' ];



=cut

# Options they can pass by position.
# Just "new( 'joe@bebo.com', 'mypass' )".
const positional_parameters => [ 'account_name', 'password' ];

field 'account_name';
field 'password';
field cache_file => 'login_cache';
field auto_login => 0;
field human => 1;
field use_defaults => 0;

stub 'site_info';

=head1 OPTION ACCESSORS

These methods can be used to set/retreive the respective option's value.
They're also up top here to document the option, which can be passed
directly to the "new" method.

=head2 account_name

Sets or returns the account name (email address) under which you're logged in.
Note that the account name is retreived from the user or from your program
depending on how you called the "new" method. You'll probably only use this
accessor method to get account_name.

EXAMPLE

The following would prompt the user for their login information, then print
out the account name:

    use WWW::Bebo;
    my $bebo = new WWW::Bebo;
    
    print $site->account_name;

    $site->account_name( 'other_account@bebo.com' );
    $site->password( 'other_accounts_password' );
    $site->site_login;

WARNING: If you do change account_name, make sure you change password and
call site_login.  Changing account_name doesn't (currently) log you
out, nor does it clear "password".  If you change this and don't log in
under the new account, it'll just have the wrong value, which will probably
be ignored, but who knows.

=cut


=head2 password

Sets or returns the password you used, or will use, to log in. See the
warning under "account_name" above - same applies here.

=cut


=head2 cache_dir

WWW::Sitebase::Navigator stores the last account/password used in a
cache file for convenience if the user's entering it. Other modules
store other cache data as well.

cache_dir sets or returns the directory in which we should store cache
data. Defaults to $self->site_info->{cache_dir}.

If using this from a CGI script, you will need to provide the
account and password in the "new" method call, or call "new" with
"auto_login => 0" so cache_dir will not be used.

=cut

sub cache_dir { return catfile( $self->_home_dir,
                $self->site_info->{'cache_dir'} ) }

=head2 cache_file

Sets or returns the name of the file into which the login
cache data is stored. Defaults to login_cache.

If using this from a CGI script, you will need to provide the
account and password in the "new" method call, so cache_file will
not be used.

=cut


=head2 auto_login

Really only useful as an option passed to the "new" method when
creating a new object.

 # Create a new object and prompt the user to log in.
 my $site = new WWW::MySite( auto_login => 1 );

=cut


=head2 human

When set to a true value (which is the default), adds delays to
make the module act more like a human.  This is both to offset
"faux security" measures, and to conserve bandwidth.  If you're
trying to use multiple accounts to spam users who don't
want to hear what you have to say, you should turn this off
because it'll make your spamming go faster.

=head2 use_defaults

When set to a true value, cached username and password will be used, and
the user will only be prompted for a username and password if one or both
aren't already stored.

=cut


=head1 FUNCTIONS

=head2 new( $account, $password )

=head2 new( )

If called without the optional account and password, the new method
looks in a user-specific preferences file in the user's home
directory for the last-used account and password. It prompts
for the username and password with which to log in, providing
the last-used data (from the preferences file) as defaults.

Once the account and password have been retreived, the new method
automatically invokes the "site_login" method and returns a new
object reference. The new object already contains the
content of the user's "home" page, the user's friend ID, and
a WWW::Mechanize object used internally as the "browser" that is used
by all methods in the class.

If account_name and password are specified, the "new" method will
set auto_login to 1 and call the "site_login" method.  This just means
that if you pass an account_name and password when creating the object,
it'll log you in unless you explicitly state "auto_login => 0".

WWW::Sitebase::Navigator is a subclass of WWW::Sitebase, which
basically just means people can call your "new" method in many ways:

    EXAMPLES
        use WWW::YourSiteModule;
        
        # Just create the object
        my $site = new WWW::YourSiteModule;
        
        # Prompt for username and password
        my $site = new WWW::YourSiteModule( auto_login => 1 );

        # Pass just username and password (logs you in)
        my $site = new WWW::YourSiteModule( 'my@email.com', 'mypass' );
        
        # Pass options as a hashref
        my $site = new WWW::YourSiteModule( {
            account_name => 'my@email.com',
            password => 'mypass',
            cache_file => 'passcache',
        } );
        
        # Pass options as a hash
        my $site = new WWW::YourSiteModule(
            account_name => 'my@email.com',
            password => 'mypass',
            cache_file => 'passcache',
            auto_login => 0,  # Don't log in, just create the object)
        );

=cut

sub new() {
    # Call the Base new method (it's ok to feel special about it).
    my $self = super;

    # Log in if requested
    $self->auto_login(1) if ( $self->account_name && $self->password );
    if ( $self->auto_login ) {
    
        # Prompt for username/password if we don't have them yet.
        # (should this be moved to site_login?)
        $self->_get_acct unless $self->account_name;

        $self->site_login;
    
    } else {

        $self->logout; # Why?  Resets variables and gets Mech object.
    
    }

    return $self;
}

=head2 site_login

Logs into the account identified by the "account_name" and
"password" options.

If you don't call the new method with "login => 1", you'll need to
call this method if you want to log in.

If the login gets a "you must be logged-in" page when you first try to
log in, $site->error will be set to an error message that says to
check the username and password.

Once login is successful for a given username/password combination,
the object "remembers" that the username/password
is valid, and if it encounters a "you must be logged-in" page, it will
try up to 20 times to re-login.

=cut

sub site_login {

    my $verify_re;
    if ( defined $self->site_info->{'login_verify_re'} ) {
        $verify_re = $self->site_info->{'login_verify_re'}
    };

    # Reset everything (oddly, this also happens to create a new browser
    # object).
    $self->logout;

    croak "site_login called but account_name isn't set" unless
        ( $self->account_name );
    croak "site_login called but password isn't set" unless ( $self->password );

    # Now log in
    $self->_try_login;
    return undef if $self->error;

    # Load the home page.
#     $self->_go_home;

    # Verify we're logged in
    if ( ( ! $verify_re ) ||
         ( $self->current_page->decoded_content =~ /$verify_re/si )
       ) {
        $self->logged_in( 1 );
    } else {
        $self->logged_in( 0 );
        unless ( $self->error ) {
            $self->error( "Login Failed. Couldn't verify load of home page." )
        }
        return undef;
    }
    
    return 1;

}

# _try_login
# You call this as $self->_try_login.  Attempts to log in using
# the set account_name and password. It gets and submits the login form,
# then checks for a valid submission and for a "you must be logged-in"
# page.
# If called with a number as an argument, tries that many times to
# submit the form.  It calls itself recursively.
sub _try_login {

    # Set the recursive tries counter.
    my ( $tries_left ) = @_;
    if ( $tries_left ) { $tries_left--;  return if ( $tries_left ) < 1; }
    $tries_left = 20 unless defined $tries_left;

    # Default the login form to form#1 for backward compatibility.
    $self->site_info->{'login_form_no'} = 1
        unless ( $self->site_info->{'login_form_no'} || $self->site_info->{'login_form_name'} );

    # Submit the login form
    my $submitted = $self->_submit_login;

    # Check for success
    if ( $submitted ) {

        # Check for invalid login page, which means we either have
        # an invalid login/password, or bebo is messing up again.
        unless ( $self->_check_login ) {
            # Fail unless we already know this account/password is good, in
            # which case we'll just beat the door down until we can get in
            # or the maximum number of attempts has been reached.
            if ( $self->_account_verified ) {
                $self->_try_login( $tries_left );
            } else {
                $self->error( "Login Failed.  Got 'You Must Be Logged-In' page ".
                    "when logging in.\nCheck username and password." );
                return undef;
            }
        }
    } else {
        return undef;
    }

    return 1;

}

=head2 _submit_login

This method just calls submit_form with the values specified in site_info.
It's been separated out just in case you have a sticky login form and you
want to override this method to do something fancy.  The other option was to
give a lot more options in site_info, but to really give the amount of control
you might need, it just makes more sense to set up site_info for the usual cases,
and override this method if you need to get fancy.

You must return 1 for success, 0 for failure.  All you really need to do is
this:

    # Submit the login form
    my $submitted = $self->submit_form(
                    page => $self->site_info->{'home_page'},
                    form_name => $self->site_info->{'login_form_name'},
                    form_no => $self->site_info->{'login_form_no'},
                    fields_ref => {
                      $self->site_info->{'account_field'} => $self->account_name,
                      $self->site_info->{'password_field'} => $self->password
                    }
                  );

    return $submitted;

And fill in your special values instead.  Again, only do this if your login
doesn't work with the stuff you set up in site_info.

=cut

sub _submit_login {

    return $self->submit_form(
                    page => $self->site_info->{'home_page'},
                    form_name => $self->site_info->{'login_form_name'},
                    form_no => $self->site_info->{'login_form_no'},
                    fields_ref => {
                      $self->site_info->{'account_field'} => $self->account_name,
                      $self->site_info->{'password_field'} => $self->password
                    }
                  );

}

=head2 _check_login

Checks for "You must be logged in to do that".  If found, tries to log
in again and returns 0, otherwise returns 1.

=cut

sub _check_login {
    my ( $res ) = @_;
    my $re = "";

    # Check the current page by default
    unless ( $res ) { $res = $self->current_page }

    # Check for the "proper" error response, or just look for the
    # error message on the page.
    $re = $self->site_info->{'not_logged_in_re'};
    if ( ( $res->is_error == 403 ) || ( $res->decoded_content =~ /$re/is ) ) {
        if ( $res->is_error ) {
            warn "Error: " . $res->is_error . "\n"
        } else {
            warn "Got \"not logged in\" page\n";
        }
        # If we already logged in, try to log us back in.
        if ( $self->logged_in ) { $self->site_login }
        # Return 0 so they'll try again.
        return 0;
    } else {
        return 1;
    }

}

# _account_verified
# Returns true if we've verified that the current account and password
# are valid (by successfully logging in with them)
sub _account_verified {

    ( ( $self->{_account_verified}->{ $self->account_name } ) &&
      ( $self->password = $self->{_account_verified}->{ $self->account_name } )
    )

}

# _init_account
# Initialize basic account/login-specific settings after login
sub _init_account {
    
    # Get our friend ID from our profile page (which happens to
    # be the page we go to after logging in).
    $self->_get_friend_id( $self->current_page );

    # If for some reason we couldn't set this, fail login.
    unless ( $self->my_friend_id ) { $self->logged_in(0) ; return }
    
    # Set the user_name and friend_count fields.
    $self->user_name( $self->current_page );
    $self->friend_count( $self->current_page );
    
    # Cache whether or not we're a band.
    $self->is_band;

    # Note that we've verified this account/password
    $self->{_account_verified}->{ $self->account_name } = $self->password;

}

sub _new_mech {

    # Set up our web browser (WWW::Mechanize object)
    $self->mech( new WWW::Mechanize(
                 onerror => undef,
                 # We'll say we're Safari running on MacOS 10.9.1
                 agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1)'
                    . ' AppleWebKit/537.73.11 (KHTML, like Gecko) Version/7.0.1'
                    . ' Safari/537.73.11',
                 stack_depth => 1,
                 quiet => 1,
               ) );

    # We need to follow redirects for POST too.
    push @{ $self->mech->requests_redirectable }, 'POST';

}

#---------------------------------------------------------------------
# _get_acct()
# Get and store the login and password. We check the user's preference
# file for defaults, then prompt them.

sub _get_acct {

    # Initialize
    my $prefs = {};
    my $ref = "";
    my ( $pref, $value, $res );
    my $cache_filepath = catfile( $self->cache_dir, $self->cache_file);

    # Read what we got last time.   
    if ( open ( PREFS, "< ", $cache_filepath ) ) {
        while (<PREFS>) {
            chomp;
            ( $pref, $value ) = split( ":" );
            $prefs->{"$pref"} = $value;
        }
        
        close PREFS;
    }

    # If we have a username and password, and they asked us to use the
    # cached defaults, then skip the login prompts.  Otherwise, prompt
    # the user for login info.
    unless ( $self->use_defaults && $prefs->{'email'} && $prefs->{'password'} ) {
        $prefs = $self->_prompt_for_login( $prefs );
    }
    
    # Store the account info.
    $self->{account_name}=$prefs->{"email"};
    $self->{password}=$prefs->{"password"};
}

# _prompt_for_login( { email => $email, password => $password } )
#
# Given an optional email and password, prompt the user, displaying the
# existing email and password as defaults (well, passwords are displayed as
# "*****").  Returns the email and password entered, or defaulted to,
# by the user.
#
sub _prompt_for_login {
    my ( $prefs ) = @_;

    # Prompt them for current values
    unless ( defined $prefs->{"email"} ) { $prefs->{"email"} = "" }
    print "Email [" . $prefs->{"email"} . "]: ";
    my $res = ReadLine 0; chomp $res;
    if ( $res ) {
        $prefs->{"email"} = $res;
    }

    unless ( defined $prefs->{"password"} ) { $prefs->{"password"} = "" }
    my $password_indicator = $prefs->{'password'} ? '*****' : '';
    print "Password [". $password_indicator . "]: ";
    ReadMode 'noecho'; # From Term::ReadKey.  Make password not echo.
    $res = ReadLine 0;
    chomp $res;
    ReadMode 'normal';
    print "\n"; # Because ReadLine won't output a new line when they hit return
    if ( $res ) {
        $prefs->{"password"} = $res;
    }

    # Make the cache directory if it doesn't exist.
    $self->make_cache_dir;

    # Store the new values.  We clobber the file, set it r/w by the user,
    # *then* write.
    my $cache_filepath = catfile( $self->cache_dir, $self->cache_file);
    open ( PREFS, ">", $cache_filepath ) or croak $!;
    chmod 0600, $cache_filepath;
    print PREFS "email:" . $prefs->{"email"} . "\n" .
        "password:" . $prefs->{"password"} . "\n";
    close PREFS || croak "Error closing file when writing username/password: $!";

    return $prefs;
}

=head2 logout

Clears the current web browsing object and resets any login-specific
internal values.  Currently this drops and creates a new WWW::Mechanize
object.  This may change in the future to actually clicking "logout"
or something.

=cut

sub logout {

    # If you change this to just log out instead of making a new Mech
    # object, be sure you change site_login too.
    $self->_new_mech;
    
    # Clear anything login-specific
    $self->logged_in(0);
    $self->error(0);

    # Do NOT clear options that are set by the user!
#   $self->{account_name} = undef;
#   $self->{password} = undef;

}

#---------------------------------------------------------------------
# Value return methods
# These methods return internal data that is of use to outsiders

sub ____CHECK_STATUS____ {}

=head1 CHECK STATUS

=head2 logged_in

Returns true if login was successful. When you call the new method
of WWW::Sitebase::Navigator, the class logs in using the username and password
you provided (or that it prompted for).  It then retreives your "home"
page (the one you see when you click the "Home" button that's set up in your
site_info field), and checks it against an RE.  If the page matches the RE,
logged_in is set to a true value. Otherwise it's set to a false value.

 Notes:
 - This method is only set on login. If you're logged out somehow,
   this method won't tell you that (yet - I may add that later).
 - The internal login method calls this method to set the value.
   You can (currently) call logged_in with a value, and it'll set
   it, but that would be stupid, and it might not work later
   anyway, so don't.

 Examples, pretending we have a subclass named WWW::Bebo to navigate a site
 named bebo.com:

 my $bebo = new WWW::Bebo;
 unless ( $site->logged_in ) {
    die "Login failed\n";
 }
 
 # This will log you in, looping forever until it succeeds.
 my $bebo;

 do {
    $bebo = new WWW::Bebo( $username, $password );
 } until ( $site->logged_in );

=cut

field logged_in => 0;

=head2 error

This value is set by some methods to return an error message.
If there's no error, it returns a false value, so you can do this:

 $site->get_profile( 12345 );
 if ( $site->error ) {
     warn $site->error . "\n";
 } else {
     # Do stuff
 }

=cut

field 'error' => 0;

=head2 current_page

Returns a reference to an HTTP::Response object that contains the last page
retreived by the WWW::Sitebase::Navigator object. All methods (i.e. get_page, post_comment,
get_profile, etc) set this value.

EXAMPLE

The following will print the content of the user's profile page:

    use WWW::Bebo;
    my $bebo = new WWW::Bebo;
    
    print $site->current_page->decoded_content;

=cut

sub current_page {

    return $self->{current_page};

}

=head2 mech

The internal WWW::Mechanize object.  Use at your own risk: I don't
promose this method will stay here or work the same in the future.
The internal methods used to access sites are subject to change at
any time, including using something different than WWW::Mechanize.

=cut

field 'mech';

=head2 get_page( $url, [ %options ] )

get_page returns a referece to a HTTP::Response object that contains
the web page specified by $url.

get_page will try up to 20 times until it gets the page, with a 2-second
delay between attempts. It checks for invalid HTTP response codes,
and error pages as defined in site_info->{error_regexps}.

Options can be:

 re => $regular_expression
 follow => 1

"re" Is a regular expression.  If provided, get_page 
will consider the page an error unless the page content matches
the regexp. This is designed to get past network problems and such.

If "follow" is set, a "Referer" header will be added, simulating
clicking on a link on the current page to get to the URL provided.

EXAMPLE

    # The following displays the HTML source of MySpace.com's home
    # page, verifying that there is evidence of a login form on the
    # retreived page.
    my $res=get_page( "http://www.myspace.com/", re => 'E-Mail:.*?Password:' );
    
    print $res->decoded_content;

=cut

sub get_page {

    my ( $url, %options ) = @_;

    # Reset error
    $self->error( 0 );

    # Try to get the page 20 times.
    my $attempts = 20;
    my $res;
    my %headers = ();
    if ( $options{follow} ) {
        %headers = ( 'Referer' => $self->{current_page}->request->uri )
    }

    do {

        # Try to get the page
#        unless ( $res = $self->_read_cache( $url ) )
                $res = $self->mech->get( $url, %headers);
#        }
        $attempts--;

    } until ( ( $self->_page_ok( $res, $options{re} ) ) || ( $attempts <= 0 ) );

    # We both set "current_page" and return the value.
#    $self->_cache_page( $url, $res ) unless $self->error;
    $self->{current_page} = $res;
    sleep ( int( rand( 5 ) ) + 6 ) if $self->human;
    if ( $self->error ) {
        return undef;
    } else {
        return ( $res );
    }

}

=head2 follow_to( $url, $regexp )

Convenience method that calls get_page with follow => 1.
Use this if you're stepping through pages.

=cut

sub follow_to {

    my ( $url, $regexp ) = @_;

    $self->get_page( $url, re => $regexp, follow => 1 );

}

=head2 follow_link

This is the method you "should" use to navigate your sites, as it's
the most "human"-looking.

This is like a robust version of WWW::Mechanize's "follow_link"
method.  It calls "find_link" with your arguments (and as such takes
the same arguments.  It adds the "re" argument, which is passed to
get_page to verify we in fact got the page.  Returns an HTTP::Response
object if it succeeds, sets $self->error and returns undef if it fails.

    $self->_go_home;
    $self->follow_link( text_regex => qr/inbox/i, re => 'Mail Center' )
        or die $self->error;

There are a lot of options, so perldoc WWW::Mechanize and search for
$mech->find_link to see them all.

=cut

sub follow_link {

    my ( %options ) = @_;
    my $res;

    # Take out options that are just for us
    my $re = '';
    if ( $options{re} ) { $re = $options{re}; delete $options{re}; }

    # Find the link
    my $link = $self->mech->find_link( %options );

    # Follow it
    if ( $link ) {
        $res = $self->get_page( $link->url, re => $re, follow => 1 );
        return $res;
    } else {
        $self->error('Link not found on page');
        return undef;
    }

}

=head2 _cache_page( $url, $res )

Stores $res in a cache.

=cut

sub _cache_page {

    my ( $url, $res ) = @_;

    $self->{page_cache}->{$url} = $res;
    
    $self->_clean_cache;

}

=head2 _read_cache( $url )

Check the cache for this page.

=cut

sub _read_cache {

    my ( $url ) = @_;
    
    if ( ( $self->{page_cache}->{$url} ) &&
         ( $self->{page_cache}->{$url}->is_fresh ) ) {
        return $self->{page_cache}->{$url};
    } else {
        return "";
    }

}

=head2 _clean_cache

Cleans any non-"fresh" page from the cache.

=cut

sub _clean_cache {

    foreach my $url ( keys( %{ $self->{'page_cache'} } ) ) {
        unless ( $url->is_fresh ) {
            delete $self->{'page_cache'}->{ $url };
        }
    }

}

#---------------------------------------------------------------------
# _page_ok( $response, $regexp )
# Takes a UserAgent response object and checks to see if the
# page was sucessfully retreived, and checks the content against
# known error messages (listed at the top of this file).
# If passed a regexp, it will return true ONLY if the page content
# matches the regexp (instead of checking the known errors).
# It will delay 2 seconds if it fails so you can retry immediately.
# Called by get_page and submit_form.
# Sets the internal error method to 0 if there's no error, or
# to a printable error message if there is an error.

sub _page_ok {
    my ( $res, $regexp ) = @_;

    # Reset error
    $self->error(0);

    # Check for errors
    my $page_ok = 1;
    my $page;
    my $errors;

    # If we think we're logged in, check for the "You must be logged-in"
    # error page.
    if ( ( $self->logged_in ) && ( ! $self->_check_login( $res ) ) ) {
        $self->error( "Not logged in" );
        $page_ok=0;
    }

    # If the page load is "successful", check for other problems.
    elsif ( $res->is_success ) {

        # Page loaded, but make sure it isn't an error page.
        $page = $res->decoded_content; # Get the content
        $page =~ s/[ \t\n\r]+/ /g; # Strip whitespace

        # If they gave us a RE with which to verify the page, look for it.
        if ( $regexp ) {
            # Page must match the regexp
            unless ( $page =~ /$regexp/ism ) {
                $page_ok = 0;
                $self->error("Page doesn't match verification pattern.");
#                warn "Page doesn't match verification pattern.\n";
            }

        # Otherwise, look for our known temporary errors.
        } else {
            if ( defined $self->site_info->{'error_regexs'} ) {
                $errors = $self->site_info->{'error_regexs'};
                foreach my $error_regex ( @{$errors} ) {
                    if ( $page =~ /$error_regex/ism ) {
                        $page_ok = 0;
                        $self->error( "Got error page." );
#                        warn "Got error page.\n";
                        last;
                    }
                }
            }
        }

    } else {

        $self->error("Error getting page: \n" .
            "  " . $res->status_line);
        $page_ok = 0;

        warn "Error getting page: \n" .
            "  " . $res->status_line . "\n";

    }

    sleep 2 unless ( $page_ok );

    return $page_ok;

}


=head2 submit_form( %options )

 Valid options:
 $site->submit_form(
    page => "http://some.url.org/formpage.html",
    form_no => 1,
    form_name => "myform",  # Use this OR form_no OR form
    form => $form, # HTML::Form object with a ready-to-post form.
                   # (page, form_no, form_name, fields_ref and action will
                   # be ignored).
    button => "mybutton",
    no_click => 0,  # 0 or 1.
    fields_ref => { field => 'value', field2 => 'value' },
    re1 => 'something unique.?about this[ \t\n]+page',
    re2 => 'something unique about the submitted page',
    action => 'http://some.url.org/newpostpage.cgi', # Only needed in weird occasions
 );

This powerful little method reads the web page specified by "page",
finds the form specified by "form_no" or "form_name", fills in the values
specified in "fields_ref", and clicks the button named "button".

You may or may not need this method - it's used internally by
any method that needs to fill in and post a form. I made it
public just in case you need to fill in and post a form that's not
handled by another method (in which case, see CONTRIBUTING below :).

"page" can either be a text string that is a URL or a reference to an
HTTP::Response object that contains the source of the page
that contains the form. If it is an empty string or not specified,
the current page ( $site->current_page ) is used.

"form_no" is used to numerically identify the form on the page. It's a
simple counter starting from 1.  If there are 3 forms on the page and
you want to fill in and submit the second form, set "form_no => 2".
For the first form, use "form_no => 1".

"form_name" is used to indentify the form by name.  In actuality,
submit_form simply uses "form_name" to iterate through the forms
and sets "form_no" for you.

"form" can be used if you have a customized form you want to submit.
Pass an HTML::Form object and set "button", "no_click", and "re2"
as desired, and you can use submit_form's tenacious submission routine
with your own values.

"button" is the name of the button to submit. This will frequently
be "submit", but if they've named the button something clever like
"Submit22" (as MySpace did in their login form), then you may have to
use that.  If no button is specified (either by button => '' or by
not specifying button at all), the first button on the form
is clicked.

If "no_click" is set to 1, the form willl be submitted without
clicking any button.   This is used to simulate the JavaScript
form submits Myspace does on the browse pages.

"fields_ref" is a reference to a hash that contains field names
and values you want to fill in on the form.
For checkboxes with no "value" attribute, specify a value of "on"
to check it, "off" to uncheck it.

"re1" is an optional Regular Expression that will be used to make
sure the proper form page has been loaded. The page content will
be matched to the RE, and will be treated as an error page and retried
until it matches. See get_page for more info.

"re2" is an optional RE that will me used to make sure that the
post was successful. USE THIS CAREFULLY! If your RE breaks, you could
end up repeatedly posting a form.

"action" is the post action for the form, as in:

 <form action="http://www.mysite.com/process.cgi">

This is here because Myspace likes to do weird things like reset
form actions with Javascript then post them without clicking form buttons.

EXAMPLE

This is how WWW::Myspace's post_comment method posted a comment:

    # Submit the comment to $friend_id's page
    $self->submit_form( "${VIEW_COMMENT_FORM}${friend_id}", 1, "submit",
                        { 'f_comments' => "$message" }, '', 'f_comments'
                    );
    
    # Confirm it
    $self->submit_form( "", 1, "submit", {} );

=cut


sub submit_form {

    my ( %options ) = @_;

    # Initialize our variables
    my $mech = $self->mech; # For convenience
    my $res = "";
    my ( $field, $form_no );

    # If they gave us a form, use it.  Otherwise, get it and fill it in.
    my $f = "";
    if ( $options{'form'} ) {
        $f = $options{'form'};
    } else {
        # Get the page
        if ( ref( $options{'page'} ) eq "HTTP::Response" ) {
            # They gave us a page already
            $res = $options{'page'};
        } elsif ( ! $options{'page'} ) {
            $res = $self->current_page;
        } else {
            # Get the page
            $res = $self->get_page( $options{'page'}, re => $options{'re1'} );
            # If we couldn't get the page, return failure.
            return 0 if $self->error;
        }
    
        # Select the form they wanted, or return failure if we can't.
        my @forms = HTML::Form->parse( $res );
        if ( $options{'form_no'} ) {
            $options{'form_no'}--; # To be like WWW::Mechanize;
            unless ( @forms > $options{'form_no'} ) {
                $self->error( "Form not on page in submit_form!" );
                return 0;
            }
        }
        if ( $options{'form_name'} ) {
            $form_no = 0;
            foreach my $form ( @forms ) {
                if ( ( $form->attr( 'name' ) ) && ( $form->attr( 'name' ) eq $options{'form_name'} ) ) {
                    $options{'form_no'} = $form_no;
                    last;
                }
                $form_no++;
            }
        }
    
        $f = $forms[ $options{'form_no'} ];
    }
    
    # Set the action if they gave us one
    if ( $options{'action'} ) { $f->action( $options{'action'} ) }
    
    # Loop through the fields in the form and set them.
    foreach my $field ( keys %{ $options{'fields_ref'} } ) {
        # If the field "exists" on the form, just fill it in,
        # otherwise, add it as a hidden field.
        if ( $f->find_input( $field ) ) {
            if ( $f->find_input( $field )->readonly ) {
                $f->find_input( $field )->readonly(0)
            }
            $f->param( $field, $options{'fields_ref'}->{ $field } );
        } else {
            $f = $self->_add_to_form( $f, $field, $options{'fields_ref'}->{ $field } );
        }
    }

    if ( $options{'die'} ) { print $f->dump; die }

    # Submit the form.  Try up to $attempts times.
    my $attempts = 5;
    my $trying_again = 0;
    do
    {
        # If we're trying again, mention it.
        warn $self->error . "\n" if $trying_again;

        eval {
            if ( $options{'button'} ) {
                $res = $self->mech->request( $f->click( $options{'button'} ) );
            } elsif ( $options{'no_click'} ) {
                # We use make_request because some sites like submitting forms
                # that have buttons by using Javascript. make_request submits
                # the form without clicking anything, whereas "click" clicks
                # the first button, which can break things.
                $res = $self->mech->request( $f->make_request );
            } else {
                # Just click the first button
                $res = $self->mech->request( $f->click );
            }
        };

        # If it died (it will if there's no button), just return failure.
        if ( $@ ) {
            $self->error( $@ );
            return 0;
        }

        $attempts--;
        $trying_again = 1;

    } until ( ( $self->_page_ok( $res, $options{'re2'} ) ) || ( $attempts <= 0 ) );

    # Return the result
    $self->{current_page} = $res;
    return ( ! $self->error );

}

=head2 _add_to_form

Internal method to add a hidden field to a form. HTML::Form thinks we
don't want to change hidden fields, and if a hidden field has no value,
it won't even create an input object for it.  If that's way over your
head don't worry, it just means we're fixing things with this method,
and submit_form will call this method for you if you pass it a field that
doesn't show up on the form.

Returns a form object that is the old form with the new field in it.

 # Add field $fieldname to form $form (a HTML::Form object) and
 # set it's value to $value.
 $self->_add_to_form( $form, $fieldname, $value )

=cut

sub _add_to_form {

    my ( $f, $field, $value ) = @_;

    $f->push_input( 'hidden', { name => $field, value => $value } );
    
    return $f;
}

=head2 _go_home

Internal method to go to the home page.  Checks to see if we're already
there.  If not, tries to click the Home button on the page.  If there
isn't one, loads the page explicitly.

=cut

sub _go_home {

    my $link_re = $self->site_info->{'home_link_re'};
    my $home_uri_re = $self->site_info->{'home_uri_re'};
    
    # If we're not logged in, go to the site's home page
    unless ( $self->logged_in ) {
        $self->get_page( $self->site_info->{'home_page'} );
        return;
    }

    # Are we there?
    if ( $self->mech->uri =~ /$home_uri_re/i ) {
#        warn "I think I'm on the homepage\n";
#        warn $self->mech->uri . "\n";
        return;
    }
    
    # No, try to click home
    my $home_link = "";
    if ( $home_link = $self->mech->find_link( url_regex => qr/$link_re/i ) ) {
#        warn "_go_home going to " . $home_link->url . "\n";
        $self->get_page( $home_link->url );
        return;
    }
    
    # Still here?  Load the page explicitly
    $self->get_page( $self->site_info->{'home_url'} );
#    warn "I think I loaded $HOME_PAGE\n";
    
    return;

}

=head2 make_cache_dir

Creates the cache directory in cache_dir. Only creates the
top-level directory, croaks if it can't create it.

    $myspace->cache_dir("/path/to/dir");
    $myspace->make_cache_dir;

This function mainly exists for the internal login method to use,
and for related sub-modules that store their cache files by
default in WWW:Myspace's cache directory.

=cut

sub make_cache_dir {

    # Make the cache directory if it doesn't exist.
    unless ( -d $self->cache_dir ) {
        mkdir $self->cache_dir or croak "Can't create cache directory ".
            $self->cache_dir;
    }

}

=head2 debug( message );

Use this method to turn on/off debugging output.

=cut

sub debug {
    my ( $message ) = @_;
    
#   warn $message . "\n";

}

=head1 AUTHOR

Grant Grueninger, C<< <grantg at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-bebo at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Bebo>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Bebo

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Bebo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Bebo>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Bebo>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Bebo>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Grant Grueninger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Bebo
