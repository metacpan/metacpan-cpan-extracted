
package Apache::Request::Dispatcher;

use strict;
use DBI;
use Template;
use AppConfig;
#use Exception qw(:all);

use Apache::Const qw(:common :methods :http);
use POSIX qw(strftime);
use Carp qw(cluck);
use Apache::Session::Postgres;

use Data::Dumper;

# TODO: Need to change these to Apache::Request (libapreq)
use CGI;
use CGI::Cookie;

our @ISA;

=pod
=head1 NAME

Apache::Request::Dispatcher - dispatches requests to a sub-class of Apache::Request::Controller

=head1 SYNOPSIS

    <Location /myApplication>
      SetHandler perl-script
      Perlhander Apache::Request::Dispatcher
      SetEnv DispatcherConf /path/to/file.cfg
      setEnv APP_NAME myApplication
    </Location>

=head1 DESCRIPTION

Apache::Request::Dispatcher is a mod_perl handler which handles
Apache HTTP requests under mod_perl, and dispatches them to a
sub-class of Apache::Request::Controller (after some initial
request setup has been performed).

If required, it will establish a connection to a database
using the DBI, retrieve (or create) session data for this
request (using Apache::Session), initialise a template
processor (using the Template-Toolkit).

The Dispatcher parses  the URI of the request to determine
which subclass of Apache::Request::Controller to then pass
control to.

Parsing of the URI occurs as follows:

APP_NAME (environment set in Apache Config) is removed
from the begining of the URI, so that:

    '/myApplication/SubClass/action'

becomes: 'SubClass/action'

or

    '/myApplication/Sub/Class/action'

becomes: 'Sub/Class/action'

This is then converted to a module name, and a method name,
such as:

    Apache::Request::Controller::SubClass or
    Apache::Request::Controller::Sub::Class

with action() being the method name.

It should be noted that if the SubClass or Action name
contain any thing other than [A-Za-z0-9_] then the request
is declined.

The dispatcher then dynamically inherits from the module name,
and then calls $self->action().

The action() method of the controller is then called in an object-oriented
fashion, with a dispatcher object passed in as its first parameter.

This object contains the following hash elements:

    request  => $r,        # The Apache Request Object
    dbh      => $dbh,      # The Database Connection Object
    cfg      => $cfg,      # The AppConfig object
    template => $template, # The Template Processor
    apr      => $q,        # The CGI/libapreq object
    session  => \%session  # Any session data for this user

Depending on the configuration file, 'dbh' or 'session' may be
undefined if they've been turned off.

an example controller method might be written as follows:

    package Apache::Request::Controller::SubClass;
    our @ISA = qw(Apache::Request::Controller);
    use strict;
    use Apache::Const qw(:common :methods :http);

    sub action
    {
        my $self = shift;

        my $thing = getThingByID($self->{'dbh'}, $self->{'apr'}->param('thingId'));

        $self->{'request'}->status(HTTP_OK);
        $self->{'request'}->content_type('text/html');

        $self->{'template'}->process('myTemplate', {thing => $thing});
        return OK;
    }
    1;

=head2 Special Actions

=over 4

=item __cache()

Generally, the controllers that are dispatched to will generate dynamic
content, and as such the dispatcher automatically sets the browsers
caching policy to not cache any content. However, if your Controller
sub-class has a method called __cache() then will be used to define
the caching policy. The action name is given as a parameter to the
__cache() method, and based on this, the __cache() method should
return 1 to allow caching, or zero to prevent it.

For exmaple, if your Controller sub-class provides 2 actions, staticContent()
and dynamicContent(), then your __cache() method can control the caching
policy as follows:

    sub __cache
    {
        my $action = shift;

        my $policy = { staticContent  => 1,
                       dynamicContent => 0};
        return $policy->{$action} || 0; # Default to no caching.
    }

If your Controller sub-class wants to turn off caching globally,
then you can just return zero regardless of what the action name is.

=item __index()

If the dispatcher cannot work out which action the request is for
(this happens on a URI such as '/myApplication/SubClass') then the
dispatcher checkes to see if the Controller SubClass has a 'default'
action by calling __index(). If this method does not exist, then
the request is declined. The __index() method should return the name
of the default action, such as:

    sub __index
    {
        return 'listAllItems';
    }

=back

=head2 Template Defaults

The template processor has the following defaults defined, and may
be used by all templates:

=over 4

=item DisplayNumber()

This template variable is a reference to a subroutine which will add
comma's in the right place in numbers, for exmaple:

    [% DisplayNumber(1000) %] becomes 1,000

=item DisplayDate()

This template variable is a reference to a subroutine which will take
a time value (in the form of seconds since the epoch) and display
the actual date. You may optionally specify an strftime() format:

    [% DisplayDate( CURRENT_TIME, '%a %d %B %Y' ) %]

=item DisplayTime()

This template variable is a reference to a subroutine which will
take a time value (in the form of seconds since the epoch) and
displays the time-of-day. You may optionally specify an strftime() format:

    [% DisplayTime( CURRENT_TIME, '%a %d %B %Y' ) %]

=item DisplayDateTime()

This template variable is a reference to a subroutine which will
take a time value (in the form of seconds since the epoch) and
displays the date and time of day

    [% DisplayDateTime( CURRENT_TIME ) %]

=item DisplayDuration()

This template variable is a reference to a subroutine which
will take a number of seconds as input, and output a string
of the form 'H hours, M minutes and S seconds', eg:

    Last Modified: [% DisplayDuration( CURRENT_TIME - LAST_MODIFIED %]

=item APP_NAME

This template variable is a string which represents the application
name, as defined by the environment variable APP_NAME.

=item REQUEST

This template variable is an Apache2::RequestRec object, so that the
template can have access to the current URI etc. Its not really meant
to be used to set any outgoing headers or any thing tho, as setting
up the response should really be done in the Controller.

=back

=head2 The Configuration File

The dispatcher can be used to dispatch to multiple controllers
that dont even need to belong to the same application, and each
can application can have its own database connection and set of
templates. This is achieved by having Apache specify which
configuration file to use based on the Location of the request
URI. For example:

    <Location /myApplication>
      SetHandler perl-script
      Perlhander Apache::Request::Dispatcher
      SetEnv DispatcherConf /path/to/file.cfg
      setEnv APP_NAME myApplication
    </Location>

will specify that all requests with a root-URI of /myApplication
will use the configuration file as specified in the DispatcherConf
environment variable, which is /path/to/file.cfg in the above
example.

The contents of this configuration file are as follows:

    db_dsn="DBI:Pg:database=myApplication;host=127.0.0.1"
    db_username=apache
    db_password=apache

    templatePath="/data/myApplication/templates"

    defaultController=WelcomePage

    # If you wish to use sessions, uncomment this and make sure you have
    # created the sessions table within the database db_dsn.
    useSessions="Apache::Session::Postgres"
    sessionTable="sessions"

where db_dsn, db_username, and db_password specifies the database connection
options, templatePath specifies where the templates are all stored,
and defaultController specifies which controller is the default, so
that if a request for '/myApplication' is recieved, it will be converted
to '/myApplication/WelcomePage', which will in turn get converted to
Apache::Request::Controller::WelcomePage.

At a minimum, you have to have templatePath defined. If you dont specify a
default Controller, then the top-level URI will not work.

=head1 AUTHOR

Bradley Kite <bradley-cpan@kitefamily.co.uk>

If you wish to email me, then please remove the '-cpan' part
of my email address as anything addressed to 'bradley-cpan'
is assumed to be spam and is not read.

=head1 SEE ALSO

L<Apache::Request::Controller>, L<DB::Table>, L<DB::Table::Row>, L<DBI>, L<perl>

=cut

# /* handler */ {{{
sub handler
{
    my $r = shift;

    # Validate the URI
    my $uri     = $r->uri;

    # The app-name is allowed to contain funny characters, so we strip it off
    # before we check its validity.
    my $relativePath = substr($uri, length($r->location) + 1); # +1 for the training slash
    if (($relativePath ne '') && ($relativePath !~ /^[A-Za-z0-9_\/]+$/))
    {
        return DECLINED;
    }

    my $self = init($r);

    # Auth Levels: none (default), mixed (anon users allowed), login (must login)
    if ($self->{'cfg'}->authLevel eq 'login')
    {
        # Force the user to login
        unless ($self->{'session'}->{'auth'}->{'username'})
        {
            my $authController = join('/', $self->{'request'}->location, $self->{'cfg'}->authController);
            $self->{'request'}->headers_out->set(Location => $authController);
            return HTTP_MOVED_TEMPORARILY;
        }
    }

    # Start parsing the URI
    my @bits = split(/\/+/, $relativePath);

    my $webPrefix = 'Apache::Request::Controller';
    my $method    = pop @bits;
    my $pkgName   = join('::', $webPrefix, @bits);

    # Prevent access to the session table.
    if ($self->{'cfg'}->useSessions && $pkgName eq "Apache::Request::Controller::" . ucfirst($self->{'cfg'}->sessionTable))
    {
        return DECLINED;
    }

    # Show the "Index" page of the given component.
    if ($pkgName eq $webPrefix)
    {
        $pkgName .= '::' . $method;
        $method   = '';
    }

    if ($pkgName eq 'Apache::Request::Controller::' || $pkgName eq 'Apache::Request::Controller')
    {
        if ($self->{'cfg'}->defaultController)
        {
            unless ($uri =~ /\/$/)
            {
                $uri .= '/';
            }
            $uri .= $self->{'cfg'}->defaultController;
            #$r->uri($uri);
            $r->headers_out->set(Location => $uri);
            return HTTP_MOVED_TEMPORARILY;
        }
    }

    if ($method =~ /^\_/)
    {
        warn("Cannot dispatch to $pkgName\-\>$method (actions cannot start with a leading underscore)");
        return DECLINED;
    }

#    my $ret = try {
        unshift @ISA, ($pkgName);
        my $return;
        eval {
            if ($method eq '')
            {
                unless ($uri =~ /\/$/)
                {
                    $uri .= '/';
                }
                if ($self->can('__index'))
                {
                    $uri .= $self->__index();
                    $r->uri($uri);
                    $r->headers_out->set(Location => $uri);
                    $return  = HTTP_MOVED_TEMPORARILY;
                }
                else
                {
                    warn("Cannot figure out the default method of $pkgName. Please write an __index() method which returns it");
                    $return = DECLINED;
                }
            }
            elsif ($self->can($method))
            {
                if ($self->can('__cache'))
                {
                    eval "\$r->no_cache((${pkgName}::__cache}(\$method) ? 0 : 1));";
                    confess($@) if ($@);
                }
                else
                {
                    $r->no_cache(1);
                }
                $return = $self->$method();
            }
            else
            {
                warn("Cannot find $pkgName->$method, declining request");
                $return = DECLINED;
            }
        };
        if ($@)
        {
            my $err = sprintf('Cannot dispatch to %s->%s (%s)',
                               $pkgName, $method, $@);
            warn($err);
            # Exception->new('other')->raise($err);
            $self->{'dbh'}->rollback;
            return HTTP_INTERNAL_SERVER_ERROR;
        }
        if (($return == OK || $return == HTTP_MOVED_TEMPORARILY) && $self->{'request'}->is_initial_req())
        {
            # We only commit if we're the "main" (initial) request  (and if every thing is OK, of course)
            $self->{'session'}->{'_mtime'} = time();
            $self->{'dbh'}->commit();
        }
        elsif ($return != OK && $return != HTTP_MOVED_TEMPORARILY)
        {
            # We roll-back any time. This is so that if the main request works but then
            # makes a sub-request which fails, then the subrequest will roll-back the main
            # requests actions too. This is because the sub-request will present some sort
            # of error to the user, leading them to think that what they just did failed.
            $self->{'dbh'}->rollback;
        }
        return $return;
#    }
#    when 'template',
#    except
#    {
#        # If a template error occurs, then the http header etc. would
#        # have already have been sent.
#        my $err = shift;
#        $err->confess;
#        $self->{'template'}->process('error.tt2'. {ERROR => $err->stringify})
#          or do { print $err->stringify };
#        return OK;
#    }
#    when 'not_found',
#    except
#    {
#        my $err = shift;
#        $err->confess;
#        return DECLINED;
#    }
#    when 'other',
#    except
#    {
#        my $err = shift;
#        $err->confess;
#        return HTTP_INTERNAL_SERVER_ERROR;
#    }
#    finally
#    {
#        my $err = shift; 
#        my $retCode = shift;

#        if ($err)
#        {
#            $self->{'dbh'}->rollback;
#        }
#        else
#        {
#            $self->{'dbh'}->commit;
#        }
#        return $retCode;
#    };
#
#    return $ret;
}
# /* handler */ }}}

# /* init */ {{{
sub init
{
    my $r = shift;

    # Do some initial setup config.

    @ISA = ();

    my $q = new CGI;

    # TODO: Perhaps cache the config files using the key ($ENV{'DispatcherConf'}) into a
    #       global hash
    my ($cfg, $dbh, $template);
    unless ($cfg)
    {
        $cfg = AppConfig->new(qw(db_dsn=s db_username=s db_password=s
                                 templatePath=s defaultController=s
                                 useSessions=s sessionTable=s
                                 session_dsn=s session_username=s session_password=s
                                 authLevel=s authController=s));
        $cfg->file($ENV{'DispatcherConf'}) || die "Could not open config: $ENV{DispatcherConf}: $!";
    }

    if ($cfg->db_dsn)
    {
        $dbh = DBI->connect($cfg->db_dsn, $cfg->db_username, $cfg->db_password,
                            {AutoCommit => 0,
                             RaiseError => 0});
        unless ($dbh)
        {
            confess(sprintf("Could not connect to database %s: %s",
                            $cfg->db_dsn,
                            $DBI::errstr));
        }
    }

    my %session;
    if ($cfg->useSessions)
    {
        my $cookies = CGI::Cookie->fetch($r) || {};
        my $cookie  = $cookies->{'session_id'};

        $cfg->sessionTable('sessions') unless ($cfg->sessionTable);
        my $opts = {Handle => $dbh, Commit => 1, TableName => $cfg->sessionTable};

        if ($cookie)
        {
            my $cookieValue = $cookie->value;
            tie %session, $cfg->useSessions, $cookieValue, $opts;
        }
        else
        {
            tie %session, $cfg->useSessions, undef, $opts;
        }
        # TODO: Add some extra stuff to the config file to determine cookie
        #       options, such as expire time.
        $cookie = $q->cookie('-name'    => 'session_id',
                             '-value'   => $session{'_session_id'},
                             #'-expires' => '+1d', Per-Session is all thats needed.
                             '-path'    => $r->location . '/',
                             '-domain'  => $r->hostname,
                             '-secure'  => 0);
        $r->headers_out->set('Set-Cookie' => $cookie->as_string);
    }

    my $templatePath = $cfg->templatePath || '/data/templates';
    $template ||= new Template(INCLUDE_PATH => $templatePath,
                               RECURSION    => 1,
                               PRE_DEFINE   => { DisplayNumber   => \&T_DisplayNumber,
                                                 DisplayDate     => \&T_DisplayDate,
                                                 DisplayTime     => \&T_DisplayTime,
                                                 DisplayDateTime => \&T_DisplayDateTime,
                                                 DisplayDuration => \&T_DisplayDuration,
                                                 REQUEST         => $r,
                                                 SESSION         => \%session,
                                                 CFG             => $cfg});
    my $self = {request  => $r,
                dbh      => $dbh,
                cfg      => $cfg,
                template => $template,
                apr      => $q,
                session  => \%session};
    bless ($self, __PACKAGE__);

    return $self;
}
# /* init */ }}}

# /* Template Display Functions */ {{{
sub T_DisplayNumber
{
    my $number = reverse(shift);
    $number =~ s/(\d\d\d)(?!$)/$1\,/g;
    return scalar(reverse($number));
}

sub T_DisplayDateTime
{
    my $time = shift;

    return strftime('%a %d %B %T %Y', gmtime($time));
}

sub T_DisplayTime
{
    my $time   = shift;
    my $format = shift || '%a %d %B %Y';

    return strftime($format, gmtime($time));
}

sub T_DisplayDate
{
    my $time   = shift;
    my $format = shift || '%a %d %B %Y';

    return strftime($format, gmtime($time));
}

sub T_DisplayDuration
{
    my $duration = shift; # number of seconds

    my @bits = ({ NAME => 'Seconds',
                  NEXT => 60},
                { NAME => 'Minutes',
                  NEXT => 60 },
                { NAME => 'Hours',
                  NEXT => '24' },
                { NAME => 'Days',
                  NEXT => 7 },
                { NAME => 'Weeks' });
    my @results;
    do
    {
        my $remainder = ($duration % $bits[0]->{'NEXT'});
        unshift @results, sprintf("%d %s", $remainder,
                                        $bits[0]->{'NAME'}) if ($remainder > 0);
        $duration -= $remainder;
        $duration /= $bits[0]->{'NEXT'};
        shift @bits;
    }
    while (defined ($bits[0]) && defined ($bits[0]->{'NEXT'}));

    return join(' ', @results);
}
# /* Template Display Functions */ }}}

1;

