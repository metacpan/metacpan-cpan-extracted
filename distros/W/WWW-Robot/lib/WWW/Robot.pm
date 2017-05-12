#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

WWW::Robot - configurable web traversal engine (for web robots & agents)

=head1 SYNOPSIS

    use WWW::Robot;
   
    $robot = new WWW::Robot(
        'NAME'     => 'MyRobot',
        'VERSION'  => '1.000',
        'EMAIL'    => 'fred@foobar.com'
    );
   
    # ... configure the robot's operation ...
       
    $robot->run( 'http://www.foobar.com/' );

=head1 DESCRIPTION

This module implements a configurable web traversal engine,
for a I<robot> or other web agent.
Given an initial web page (I<URL>),
the Robot will get the contents of that page,
and extract all links on the page, adding them to a list of URLs to visit.

Features of the Robot module include:

=over

=item *

Follows the I<Robot Exclusion Protocol>.

=item *

Supports the META element proposed extensions to the Protocol.

=item *

Implements many of the I<Guidelines for Robot Writers>.

=item *

Configurable.

=item *

Builds on standard Perl 5 modules for WWW, HTTP, HTML, etc.

=back


A particular application (robot instance) has to configure
the engine using I<hooks>, which are perl functions invoked by the Robot
engine at specific points in the control loop.

The robot engine obeys the Robot Exclusion protocol,
as well as a proposed addition.
See L<SEE ALSO> for references to
documents describing the Robot Exclusion protocol and web robots.

=head1 QUESTIONS

This section contains a number of questions. I'm interested in hearing
what people think, and what you've done faced with similar questions.

=over

=item *

What style of API is preferable for setting attributes? Maybe
something like the following:

    $robot->verbose(1);
    $traversal = $robot->traversal();

I.e. a method for setting and getting each attribute,
depending on whether you passed an argument?

=item *

Should the robot module support a standard logging mechanism?
For example, an LOGFILE attribute, which is set to either a filename,
or a filehandle reference.
This would need a useful file format.

=item *

Should the module also support an ERRLOG attribute, with all warnings
and error messages sent there?

=item *

At the moment the robot will print warnings and error messages to stderr,
as well as returning error status. Should this behaviour be configurable?
I.e. the ability to turn off warnings.

=back

The basic architecture of the Robot is as follows:

    Hook: restore-state
    Get Next URL
        Hook: invoke-on-all-url
        Hook: follow-url-test
        Hook: invoke-on-followed-url
        Get contents of URL
        Hook: invoke-on-contents
        Skip if not HTML
        Foreach link on page:
            Hook: invoke-on-link
            Hook: add-url-test
            Add link to robot's queue
    Continue? Hook: continue-test
    Hook: save-state
    Hook: generate-report

Each of the hook procedures and functions is described below.
A robot must provide a C<follow-url-test> hook,
and at least one of the following:

=over

=item *

C<invoke-on-all-url>

=item *

C<invoke-on-followed-url>

=item *

C<invoke-on-contents>

=item *

C<invoke-on-link>

=back

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------

package WWW::Robot;
require 5.002;
use strict;

use HTTP::Request;
use HTTP::Status;
use HTML::TreeBuilder 3.03;
use URI::URL;
use LWP::RobotUA 1.171;
use IO::File;
use English;
use Encode qw( encode );

#------------------------------------------------------------------------------
#
# Public Global Variables
#
#------------------------------------------------------------------------------

use vars qw( $VERSION );
$VERSION = '0.026';

#------------------------------------------------------------------------------
#
# Private Global Variables
#
#------------------------------------------------------------------------------

my %ATTRIBUTES = (
    'NAME'              => 'Name of the Robot',
    'VERSION'           => 'Version of the Robot, N.NNN',
    'EMAIL'             => 'Contact email address for Robot owner',
    'TRAVERSAL'         => 'traversal order - depth or breadth',
    'VERBOSE'           => 'boolean flag for verbose reporting',
    'IGNORE_TEXT'       => 'should we ignore text content of HTML?',
    'IGNORE_UNKNOWN'    => 'should we ignore unknown HTML elements?',
    'CHECK_MIME_TYPES'  => 'should we check the MIME types of links?',
    'ACCEPT_LANGUAGE'   => 'array ref to list of languages to accept',
    'DELAY'             => 'delay between robot requests (minutes)',
    'ANY_URL'           => 'whether to omit default URL filtering',
    'ANY_LINK'          => 'whether to restrict to default link types',
    'ANY_CONTENT'       => 'whether to offer content of non-HTML documents',
);

my %ATTRIBUTE_DEFAULT = (
    'TRAVERSAL'         => 'depth',
    'VERBOSE'           => 0,
    'IGNORE_TEXT'       => 1,
    'IGNORE_UNKNOWN'    => 1,
    'CHECK_MIME_TYPES'  => 1,
    'ANY_URL'           => 0,
    'ANY_LINK'          => 0,
    'ANY_CONTENT'       => 0,
);

my %SUPPORTED_HOOKS = (
    'restore-state'             => 'opportunity for client to restore state',
    'invoke-on-all-url'         => 'invoked on all URLs (even not visited)',
    'follow-url-test'           => 'return true if robot should visit the URL',
    'invoke-on-followed-url'    => 'invoked on only URLs which are visited',
    'invoke-on-get-error'       => 'invoked when HTTP request results in error',
    'invoke-on-contents'        => 'invoked on contents of each visited URL',
    'invoke-on-link'            => 'invoked on all links seen on a page',
    'add-url-test'              => 'returns true if robot should add URL',
    'continue-test'             => 'return true if should continue iterating',
    'save-state'                => 'opportunity for client to save state',
    'generate-report'           => 'report for the run just finished',
    'modified-since'            => 'returns modified-since time for URL passed',
    'invoke-after-get'          => 'invoked right after every GET request',
);

#------------------------------------------------------------------------------

=head1 CONSTRUCTOR

   $robot = new WWW::Robot( <attribute-value-pairs> );

Create a new robot engine instance.  If the constructor fails for any reason, a
warning message will be printed, and C<undef> will be returned.

Having created a new robot, it should be configured using the methods described
below.  Certain attributes of the Robot can be set during creation; they can be
(re)set after creation, using the C<setAttribute()> method.

The attributes of the Robot are described below, in the I<Robot Attributes>
section.

=cut

#------------------------------------------------------------------------------

sub new
{
    my $class    = shift;
    my %options  = @ARG;

    # The two argument version of bless() enables correct subclassing.
    # See the "perlbot" and "perlmod" documentation in perl distribution.

    my $object = bless {}, $class;

    return $object->initialise( \%options );
}

#==============================================================================

=head1 METHODS

=cut

#==============================================================================

#------------------------------------------------------------------------------

=head2 run

    $robot->run( @url_list );

Invokes the robot, initially traversing the root URLs provided in C<@url_list>,
and any which have been provided with the C<addUrl()> method before invoking
C<run()>.  If you have not correctly configured the robot, the method will
return C<undef>.

The initial set of URLs can either be passed as arguments to the B<run()>
method, or with the B<addUrl()> method before you invoke B<run()>.  Each URL
can be specified either as a string, or as a URI::URL object.

Before invoking this method, you should have provided at least some of the hook
functions.  See the example given in the EXAMPLES section below.

By default the B<run()> method will iterate until there are no more URLs in the
queue.  You can override this behavior by providing a C<continue-test> hook
function, which checks for the termination conditions.  This particular hook
function, and use of hook functions in general, are described below.

=cut

#------------------------------------------------------------------------------

sub run
{
    my $self      = shift;
    my @url_list  = @ARG; # optional list of URLs

    return undef unless $self->required_attributes_set();
    return undef unless $self->required_hooks_set();

    $self->addUrl( @url_list );
    $self->invoke_hook_procedures( 'restore-state' );

    my $url;

    while ( $url = $self->next_url() )
    {
        $self->verbose( $url, "\n" );

        $self->invoke_hook_procedures( 'invoke-on-all-url', $url );
        next unless $self->invoke_hook_functions( 'follow-url-test', $url );
        $self->invoke_hook_procedures( 'invoke-on-followed-url', $url );

        my $response = $self->get_url( $url );

        # This hook function is for people who want to see the result
        # of every GET, so they can deal with odd cases, or whatever

        $self->invoke_hook_procedures( 'invoke-after-get', $url, $response );

        if ( $response->is_error )
        {
            $self->invoke_hook_procedures(
                'invoke-on-get-error',
                $url, 
                $response
            );
            next;
        }

        # If the request got a 304 (not modified), then we
        # can stop at this point.

        next if $response->code == RC_NOT_MODIFIED;

        # The response says we should use something else as the BASE
        # from which to resolve any relative URLs. This might be from
        # a BASE element in the HEAD, or just "foo" which should be "foo/"

        my $base = $response->base;

        if ( $base ne $url )
        {
            $url = new URI::URL( $base );
        }

        if ( $response->content_type ne 'text/html' )
        {
	    if ( $self->{'ANY_CONTENT'} )
	    {
                $self->invoke_hook_procedures(
                    'invoke-on-contents', 
                    $url,
                   $response, 
                   undef  # no $structure
                );
	    }
	}
        else
        {

            my $contents = $response->content;
	    utf8::decode($contents);
            $self->verbose( "Parse $url into HTML::TreeBuilder ..." );
            my $structure = new HTML::TreeBuilder;
            $structure->ignore_text if $self->getAttribute( 'IGNORE_TEXT' );
            $structure->ignore_unknown 
                if $self->getAttribute( 'IGNORE_UNKNOWN' )
            ;
            $structure->parse( $contents );
            $self->verbose( "\n" );

            my @page_urls;

            # Check page for page specific robot exclusion commands

            my ( $noindex, $nofollow ) = 
                $self->check_protocol( $structure, $url )
            ;
            if ( $nofollow == 0 )
            {
                $self->verbose( "Extract links from $url\n" );
                @page_urls = $self->extract_links( $url, $base, $contents );
            }
            if ( $noindex == 0 )
            {
                $self->invoke_hook_procedures(
                    'invoke-on-contents', 
                    $url,
                   $response, 
                   $structure
                );

                # delete required, because of potential circular links

            }
            foreach my $link_url ( @page_urls )
            {
                $self->invoke_hook_procedures(
                    'invoke-on-link', 
                    $url, 
                    $link_url
                );
                $self->addUrl( $link_url );
            }
            $structure->delete() if defined $structure;
        }
    }
    continue
    {
        # If there is no continue-test hook, then we will continue until
        # there are no more URLs.

        last if ( 
            exists $self->{ 'HOOKS' }->{ 'continue-test' } and 
            not $self->invoke_hook_functions( 'continue-test' ) 
        );
    }

    $self->invoke_hook_procedures( 'save-state' );
    $self->invoke_hook_procedures( 'generate-report' );

    return 1;
}

#------------------------------------------------------------------------------

=head2 setAttribute

  $robot->setAttribute( ... attribute-value-pairs ... );

Change the value of one or more robot attributes.  Attributes are identified
using a string, and take scalar values.  For example, to specify the name of
your robot, you set the C<NAME> attribute:

   $robot->setAttribute( 'NAME' => 'WebStud' );

The supported attributes for the Robot module are listed below, in the I<ROBOT
ATTRIBUTES> section.

=cut

#------------------------------------------------------------------------------

sub setAttribute
{
    my $self   = shift;
    my %attrs  = @ARG;

    while ( my ( $attribute, $value ) = each( %attrs ) )
    {
        unless ( exists $ATTRIBUTES{ $attribute } )
	{
	    $self->warn( "unknown attribute $attribute - ignoring it." );
	    next;
	}
        $self->{ $attribute } = $value;
    }
}

#------------------------------------------------------------------------------

=head2 getAttribute

  $value = $robot->getAttribute( 'attribute-name' );

Queries a Robot for the value of an attribute.  For example, to query the
version number of your robot, you would get the C<VERSION> attribute:

   $version = $robot->getAttribute( 'VERSION' );

The supported attributes for the Robot module are listed below, in the I<ROBOT
ATTRIBUTES> section.

=cut

#------------------------------------------------------------------------------

sub getAttribute
{
    my $self       = shift;
    my $attribute  = shift;

    unless ( exists $ATTRIBUTES{ $attribute } )
    {
	$self->warn( "unknown attribute $attribute" );
	return undef;
    }

    return $self->{ $attribute };
}

#------------------------------------------------------------------------------

=head2 getAgent

  $agent = $robot->getAgent();

Returns the agent that is being used by the robot.

=cut

#------------------------------------------------------------------------------

sub getAgent
{
    my $self = shift;

    return $self->{ 'AGENT' };
}

#------------------------------------------------------------------------------

=head2 addUrl

  $robot->addUrl( $url1, ..., $urlN );

Used to add one or more URLs to the queue for the robot.  Each URL can be
passed as a simple string, or as a URI::URL object.

Returns True (non-zero) if all URLs were successfully added, False (zero) if at
least one of the URLs could not be added.

=cut

#------------------------------------------------------------------------------

sub addUrl
{
    my $self       = shift;
    my @list       = @ARG;

    my $status     = 1;

    foreach my $url ( @list )
    {
	next if exists $self->{ 'SEEN_URL' }->{ $url };

	# create a URI::URL object for the url, if needed
	
        my $urlObject;

	if ( ref $url )
	{
	    $urlObject = $url;
	}
        else
	{
	    $urlObject = eval { new URI::URL($url) };
	    if ( $EVAL_ERROR )
	    {
		$self->warn( <<WARNING );
Unable to create URI::URL object for $url: $EVAL_ERROR
WARNING
		$status = 0;
		next;
	    }
	}

	# Mark the URL as having been seen by the robot, then add it
	# to the list of URLs for the robot to visit. Doing it this way
	# means we won't get duplicate URLs on the list.
	
	$self->{ 'SEEN_URL' }->{ $url } = 1;
	# $self->{ 'URL_LIST' } = [] if not exists $self->{ 'URL_LIST' };
	push( @{ $self->{ 'URL_LIST' } }, $urlObject );
    }

    return $status;
}

#------------------------------------------------------------------------------

=head2 unshiftUrl

  $robot->unshiftUrl( $url1, ..., $urlN );

Used to add one or more URLs to the queue for the robot.  Each URL can be
passed as a simple string, or as a URI::URL object.

Returns True (non-zero) if all URLs were successfully added, False (zero) if at
least one of the URLs could not be added.

=cut

#------------------------------------------------------------------------------

sub unshiftUrl
{
    my $self       = shift;
    my @list       = @ARG;

    my $status     = 1;

    foreach my $url ( @list )
    {
	next if exists $self->{ 'SEEN_URL' }->{ $url };

	# create a URI::URL object for the url, if needed
	
        my $urlObject;

	if ( ref $url )
	{
	    $urlObject = $url;
	}
        else
	{
	    $urlObject = eval { new URI::URL($url) };
	    if ( $EVAL_ERROR )
	    {
		$self->warn( <<WARNING );
Unable to create URI::URL object for $url: $EVAL_ERROR
WARNING
		$status = 0;
		next;
	    }
	}

	# Mark the URL as having been seen by the robot, then add it
	# to the list of URLs for the robot to visit. Doing it this way
	# means we won't get duplicate URLs on the list.
	
	$self->{ 'SEEN_URL' }->{ $url } = 1;
	# $self->{ 'URL_LIST' } = [] if not exists $self->{ 'URL_LIST' };
	unshift( @{ $self->{ 'URL_LIST' } }, $urlObject );
    }

    return $status;
}

#------------------------------------------------------------------------------

=head2 listUrls

  $robot->listUrls( );

Returns a list of the URLs currently in the robots list to be traversed.

=cut

#------------------------------------------------------------------------------

sub listUrls
{
    my $self = shift;
    return @{ $self->{ 'URL_LIST' } };
}

#------------------------------------------------------------------------------

=head2 addHook

  $robot->addHook( $hook_name, \&hook_function );
  
  sub hook_function { ... }

Register a I<hook> function which should be invoked by the robot at a specific
point in the control flow. There are a number of I<hook points> in the robot,
which are identified by a string.  For a list of hook points, see the
B<SUPPORTED HOOKS> section below.

If you provide more than one function for a particular hook, then the hook
functions will be invoked in the order they were added.  I.e. the first hook
function called will be the first hook function you added.

=cut

#------------------------------------------------------------------------------

sub addHook
{
    my $self       = shift;
    my $hook_name  = shift;
    my $hook_fn    = shift;

    if ( not exists $SUPPORTED_HOOKS{ $hook_name } )
    {
	$self->warn( <<WARNING );
Unknown hook name $hook_name; Ignoring it!
WARNING
	return undef;
    }

    if ( ref( $hook_fn ) ne 'CODE' )
    {
	$self->warn( <<WARNING );
$hook_fn is not a function reference; Ignoring it
WARNING
	return undef;
    }

    if ( exists $self->{ 'HOOKS' }->{ $hook_name } )
    {
	push( @{ $self->{ 'HOOKS' }->{ $hook_name } }, $hook_fn );
    }
    else
    {
	$self->{ 'HOOKS' }->{ $hook_name } = [ $hook_fn ];
    }

    return 1;
}

#------------------------------------------------------------------------------

=head2 proxy, no_proxy, env_proxy

These are convenience functions are setting proxy information on the
User agent being used to make the requests.

    $robot->proxy( protocol, proxy );

Used to specify a proxy for the given scheme.
The protocol argument can be a reference to a list of protocols.

    $robot->no_proxy(domain1, ... domainN);

Specifies that proxies should not be used for the specified
domains or hosts.

    $robot->env_proxy();

Load proxy settings from I<protocol>B<_proxy> environment variables:
C<ftp_proxy>, C<http_proxy>, C<no_proxy>, etc.

=cut

#------------------------------------------------------------------------------

sub proxy
{
    my $self  = shift;
    my @argv  = @ARG;

    return $self->{ 'AGENT' }->proxy( @argv );
}

sub no_proxy
{
    my $self  = shift;
    my @argv  = @ARG;

    return $self->{ 'AGENT' }->no_proxy( @argv );
}

sub env_proxy
{
    my $self  = shift;

    return $self->{ 'AGENT' }->env_proxy();
}

#==============================================================================
#
# Private Methods
#
#==============================================================================

#------------------------------------------------------------------------------
#
# required_attributes_set - check that the required attributes have been set
#
#------------------------------------------------------------------------------

sub required_attributes_set
{
    my $self = shift;

    $self->verbose( "Check that the required attributes are set ...\n" );
    my $status = 1;

    for ( qw( NAME VERSION EMAIL ) )
    {
        if ( not defined $self->{ $_ } )
        {
            $self->warn( "You haven't set the $_ attribute" );
            $status = 0;
        }
    }

    $self->{ 'AGENT' }->from( $self->{ 'EMAIL' } );
    $self->{ 'AGENT' }->agent( $self->{ 'NAME' } . '/' . $self->{ 'VERSION' } );
    $self->{ 'AGENT' }->delay( $self->{ 'DELAY' } )
        if defined( $self->{ 'DELAY' } )
    ;

    if ( defined( $self->{ 'TRAVERSAL' } ) )
    {
	# check that TRAVERSAL is set to a legal value
	
	unless (
            $self->{ 'TRAVERSAL' } eq 'depth' or
            $self->{ 'TRAVERSAL' } eq 'breadth' 
        )
	{
	    $self->warn( <<WARNING );
Ignoring unknown traversal method $self->{ TRAVERSAL }; using depth
WARNING
	    $self->{ 'TRAVERSAL' } = 'depth';
	}
    }
    else
    {
        $self->{ 'TRAVERSAL' } = 'depth';
    }

    $self->verbose( "Traversal type set to $self->{ 'TRAVERSAL' }\n" );

    return $status;
}

#------------------------------------------------------------------------------
#
# required_hooks_set - check that the required hooks have been set
#
#------------------------------------------------------------------------------

sub required_hooks_set
{
    my $self = shift;

    $self->verbose( "Check that the required hooks are set ...\n" );

    if ( not exists $self->{ 'HOOKS' }->{ 'follow-url-test' } )
    {
        $self->warn( "You must provide a `follow-url-test' hook." );
        return 0;
    }

    my $status = 0;

    for ( 
        qw( 
            invoke-on-all-url 
            invoke-on-followed-url
            invoke-on-contents
            invoke-on-link
        )
    )
    {
        $status = 1 if exists $self->{ 'HOOKS' }->{ $_ };
    }


    $self->warn( "You must provide at least one invoke-on-* hook." )
        unless $status
    ;
    return $status;
}

#------------------------------------------------------------------------------
#
# extract_links - extract links from a URL, using HTML::Element's extract_links()
#       $url            - a URI::URL object for the URL
#       $base           - the base (from the HTTP::Response)
#       $contents       - the contents (from the HTTP::Response)
#
#------------------------------------------------------------------------------

sub extract_links
{
    my $self        = shift;
    my $url         = shift;
    my $base        = shift;
    my $contents    = shift;

    my %url_seen;

    $self->verbose( "Extract links from $url (base = $base) ...\n" );

    utf8::decode($contents);
    my ( $link_extor ) = new HTML::TreeBuilder->new->parse($contents);

    my ( @default_link_types ) = ('a','area','frame');
	# () means 'all types'

    my @abslinks = ();

    my @eltlinks = map { $_->[0] } @{
	$self->{ 'ANY_LINK' } ?
	    $link_extor->extract_links() :
	    $link_extor->extract_links(@default_link_types)
	};
    
    $link_extor->delete() if defined $link_extor;

	foreach my $link (@eltlinks)
	{
            $self->verbose( "Process link: '$link'\n" );

            # ignore page internal links

            next if $link =~ m!^#!;

            # strip hashes (i.e. ignore / don't distinguish page internal links)

            $link =~ s!#.*!!;

            my $link_url = eval { new URI::URL( $link, $url ) };

            if ( $EVAL_ERROR )
            {
                $self->warn("unable to create URL object for link.",
                            "LINK:  $link",
                            "Error: $EVAL_ERROR\n");
                next;
            }

	    $URI::URL::ABS_REMOTE_LEADING_DOTS = 1;

            my $link_url_abs = $link_url->abs();

            unless ( $self->{ 'ANY_URL' } ||
                # only follow html links (.html or .htm or no extension)
		$link =~ /\.s?html?/ || $link =~ m{/$} )
                # lets assume .s?html  or "/" type links really are text/html
            {
                # put in some obvious ones here ...
                next if $link =~ 
                    /(?:ftp|gopher|mailto|news|telnet|javascript):/
                ;
                next if $link =~ /\.(?:gif|jpe?g)/;
                if ( $self->{ 'CHECK_MIME_TYPES' } )
                {
		    # grab anchor / area / frame links
                    $self->verbose( " check mime type ..." );
                    next unless 
                        $self->check_mime_type( $link_url_abs, [ 'text/html' ] )
                    ;
                }
            }

            # only follow links we haven't seen yet ...

            next if $url_seen{ $link };
            $url_seen{ $link }++;

            next if ( 
                exists $self->{ 'HOOKS' }->{ 'add-url-test' } and 
                not $self->invoke_hook_functions( 
                    'add-url-test', 
                    $link_url_abs
                ) 
            );
            push( @abslinks, $link_url_abs );
            $self->verbose( "Adding  link: '$link_url_abs'\n" );

	}

    $self->verbose( "\n" );
    return( @abslinks );
}

#------------------------------------------------------------------------------
#
# check_mime_type( $url, [ $type1, $type2, ...]  - do a head request on the
# link, and check that it is of one of the required type ($type1, $type2,
# etc.). Returns 1 if the head reports a match, 0 otherwise
#
#------------------------------------------------------------------------------

sub check_mime_type
{
    my $self            = shift;
    my $url             = shift;
    my $mime_types      = shift;

    my $request = new HTTP::Request( 'HEAD', $url );
    return 0 unless $request;
    if ( ref( $self->{ 'ACCEPT_LANGUAGE' } ) eq 'ARRAY' )
    {
        $request->push_header(
            'Accept-Language' => join( ',', @{ $self->{ 'ACCEPT_LANGUAGE' } } )
        )
    }
    $self->verbose( " HEAD $url ...\n" );
    my $response = $self->{ 'AGENT' }->request( $request );
    return 0 unless defined $response;
    return 0 unless $response->is_success;
    my $content_type = $response->content_type();
    return 0 unless defined $content_type;
    for ( @$mime_types )
    {
        return 1 if $_ eq $content_type;
    }
    return 0;
}

#------------------------------------------------------------------------------
#
# check_protocol() - check the page for per-page robot exclusion commands
#       $structure - an HTML::Element object for the page to check
#
# This function looks for page specific robot exclusion commands.
# At the moment the only one we look for is the META element with
# a NAME attribute of ROBOTS:
#
#       <META NAME="ROBOTS" CONTENT="NOINDEX">
#       This means that the Robot should not look at the contents
#       of this page. Ok to follow links though.
#
#       <META NAME="ROBOTS" CONTENT="NOFOLLOW">
#       This means that the Robot should ignore any links on this
#       page. Ok to look at the contents though.
#
#       CONTENT="NONE" is NOINDEX and NOFOLLOW together. You can also
#       specify this with CONTENT="nofollow,noindex"
#
#------------------------------------------------------------------------------

sub check_protocol
{
    my $self       = shift;
    my $structure  = shift;
    my $url        = shift;

    my $noindex    = 0;
    my $nofollow   = 0;

    $self->verbose( "Check META NAME=ROBOTS ...\n" );

    # recursively traverse the page elements, looking for META with
    # NAME=ROBOTS, then look for directives in the CONTENTS.
    
    $structure->traverse(
        sub {
            my $node        = shift;
            my $start_flag  = shift;
            my $depth       = shift;

            return 1 unless $start_flag;
            return 1 if $node->tag() ne 'meta';
            my $name = $node->attr( 'name' );
            return 1 unless defined $name;
            return 1 unless lc( $name ) eq 'robots';
            my $content = lc( $node->attr( 'content' ) );
            foreach my $directive ( split( /,/, $content ) )
            {
                if ( $directive eq 'nofollow' or $directive eq 'none' )
                {
                    $nofollow = 1;
                }
                if ( $directive eq 'noindex' or $directive eq 'none' )
                {
                    $noindex  = 1;
                }
            }
            return 0;
        },
        1
    );

    $self->verbose( "ROBOT EXCLUSION -- IGNORING LINKS\n") if $nofollow;
    $self->verbose( "ROBOT EXCLUSION -- IGNORING CONTENT\n") if $noindex;

    return ( $noindex, $nofollow );
}

#------------------------------------------------------------------------------
#
# get_url() - retrieve the document referenced by a url
#       $url    - the URL to retrieve (a URI::URL object, or text URL)
#       RETURNS the HTTP::Response
#
#------------------------------------------------------------------------------

sub get_url
{
    my $self       = shift;
    my $url        = shift;

    my $request = new HTTP::Request( 'GET', $url );
    if ( ref( $self->{ 'ACCEPT_LANGUAGE' } ) eq 'ARRAY' )
    {
        my @lang = @{ $self->{ 'ACCEPT_LANGUAGE' } };
        $request->push_header( 'Accept-Language' => join( ',', @lang ) );
    }

    # Is there a modified-since hook?

    if ( exists $self->{ 'HOOKS' }->{ 'modified-since' } )
    {
        my $time = $self->invoke_hook_functions( 'modified-since', $url );
        if ( defined $time && $time > 0 )
        {
            $request->if_modified_since( int( $time ) );
        }
    }

    # make the request

    $self->verbose( "$self->{ AGENT } GET $url ..." );
    my $response = $self->{ 'AGENT' }->request( $request );
    $self->verbose( "\n" );

    return $response;
}

#------------------------------------------------------------------------------
#
# initialise() - initialise global variables, contents, tables, etc
#       $self   - the robot object being initialised
#       @options - a LIST of (attribute, value) pairs, used to specify
#               initial values for robot attributes.
#       RETURNS    undef if we failed for some reason, non-zero for success.
#
# Initialise the robot, setting various attributes, and creating the
# User Agent which is used to make requests.
#
#------------------------------------------------------------------------------

sub initialise
{
    my $self     = shift;
    my $options  = shift;

    my $attribute;

    $self->create_agent( $options ) || return undef;

    # set attributes which are passed as arguments
    
    foreach $attribute ( keys %$options )
    {
        $self->setAttribute( $attribute, $options->{ $attribute } );
    }

    # set those attributes which have a default value,
    # and which weren't set on creation.

    foreach $attribute ( keys %ATTRIBUTE_DEFAULT )
    {
        if ( not exists $self->{ $attribute } )
        {
            $self->{ $attribute } = $ATTRIBUTE_DEFAULT{ $attribute };
        }
    }

    return $self;
}

#------------------------------------------------------------------------------
#
# create_agent() - create the User-Agent which will perform requests
#
# $self->{ 'AGENT' } holds the UserAgent object we use to perform
# HTTP requests. The RobotUA class gives us a UserAgent which follows
# the robot exclusion protocol.
#
#------------------------------------------------------------------------------

sub create_agent
{
    my $self    = shift;
    my $options = shift;

    my $ua = delete $options->{ 'USERAGENT' };
    if ( defined $ua )
    {
        $self->{ 'AGENT' } = $ua;
    }
    else
    {
        eval { $self->{ 'AGENT' } = new LWP::RobotUA( 'NAME', 'FROM@DUMMY' ) };
        if ( not $self->{ 'AGENT' } )
        {
            $self->warn( "failed to create User Agent object: $EVAL_ERROR\n" );
            return undef;
        }
    }

    return 1;
}

#------------------------------------------------------------------------------
#
# next_url() - get the next URL which should be traversed
#	RETURNS the next URL to visit, or undef if there are no
#	        URLs on the list.
#
# This function is used to get the next URL which the robot should visit.
# Depending on the traversal order, we get the next URL from the front
# or back of the list of unvisited URLs.
#
#------------------------------------------------------------------------------

sub next_url
{
    my $self    = shift;

    # We return 'undef' to signify no URLs on the list
    
    if ( not exists $self->{ 'URL_LIST' } or @{ $self->{ 'URL_LIST' } } == 0 )
    {
	return undef;
    }

    if ( $self->{ 'TRAVERSAL' } eq 'depth' )
    {
	return pop @{ $self->{ 'URL_LIST' } };
    }

    return shift @{ $self->{ 'URL_LIST' } };
}

#------------------------------------------------------------------------------
#
# invoke_hook_procedures() - invoke a specific set of hook procedures
#	$self      - the object for the robot we're invoking hooks on
#	$hook_name - a string identifying the hook functions to invoke
#	@argv      - zero or more arguments which are passed to hook function
#
# This is used to invoke hooks which do not return any value.
#
#------------------------------------------------------------------------------

sub invoke_hook_procedures
{
    my $self       = shift;
    my $hook_name  = shift;
    my @argv       = @ARG;

    return unless exists $self->{ 'HOOKS' }->{ $hook_name };
    foreach my $hookfn ( @{ $self->{ 'HOOKS' }->{ $hook_name } } )
    {
	&$hookfn( $self, $hook_name, @argv );
    }
    return;
}

#------------------------------------------------------------------------------
#
# invoke_hook_functions() - invoke a specific set of hook functions
#	$self     - the object for the robot we're invoking hooks on
#	$hook_name - a string identifying the hook functions to invoke
#	@argv      - zero or more arguments which are passed to hook function
#
# This is used to invoke hooks which return a success/failure value.
# If there is more than one function for the hook, we OR the results
# together, so that if one passes, the hook is deemed to have passed.
#
#------------------------------------------------------------------------------

sub invoke_hook_functions
{
    my $self       = shift;
    my $hook_name  = shift;
    my @argv       = @ARG;

    my $result     = 0;

    return $result unless exists $self->{ 'HOOKS' }->{ $hook_name };

    foreach my $hookfn ( @{ $self->{ 'HOOKS' }->{ $hook_name } } )
    {
	$result ||= &$hookfn( $self, $hook_name, @argv );
    }
    return $result;
}

#------------------------------------------------------------------------------
#
# verbose() - display a reporting message if we're in verbose mode
#	$self  - the robot object
#	@lines - a LIST of one or more strings, which are print'ed to
#		 standard error output (STDERR) if VERBOSE attribute has
#		 been set on the robot.
#
#------------------------------------------------------------------------------

sub verbose
{
    my $self   = shift;

    print STDERR @ARG if $self->{ 'VERBOSE' };
}

#------------------------------------------------------------------------------
#
# warn() - our own warning routine, generate standard format warnings
#
#------------------------------------------------------------------------------

sub warn
{
    my $self  = shift;
    my @lines = shift;

    my $me = ref $self;

    print STDERR "$me: ", shift @lines, "\n";
    foreach my $line ( @lines )
    {
        print STDERR ' ' x ( length( $me ) + 2 ), $line, "\n";
    }
}

#==============================================================================
#
#		END OF CODE - POD DOCUMENTATION FOLLOWS
#
#==============================================================================

=head1 ROBOT ATTRIBUTES

This section lists the attributes used to configure a Robot object.
Attributes are set using the C<setAttribute()> method,
and queried using the C<getAttribute()> method.

Some of the attributes B<must> be set before you start the Robot
(with the C<run()> method).
These are marked as B<mandatory> in the list below.

=over

=item NAME

The name of the Robot.
This should be a sequence of alphanumeric characters,
and is used to identify your Robot.
This is used to set the C<User-Agent> field of HTTP requests,
and so will appear in server logs.

B<mandatory>

=item VERSION

The version number of your Robot.
This should be a floating point number,
in the format B<N.NNN>.

B<mandatory>

=item EMAIL

A valid email address which can be used to contact the Robot's owner,
for example by someone who wishes to complain about the behavior of
your robot.

B<mandatory>

=item VERBOSE

A boolean flag which specifies whether the Robot should display verbose
status information as it runs.

Default: 0 (false)

=item TRAVERSAL

Specifies what traversal style should be adopted by the Robot.
Valid values are I<depth> and I<breadth>.

Default: depth

=item IGNORE_TEXT

Specifies whether the HTML structure passed to the I<invoke-on-contents>
hook function should include the textual content of the page,
or just the HTML elements.

Default: 1 (true)

=item IGNORE_UNKNOWN

Specifies whether the HTML structure passed to the I<invoke-on-contents>
hook function should ignore unkonwn HTML elements.

Default: 1 (true)

=item CHECK_MIME_TYPES

This tells the robot that if it can't easily determine the MIME type of a link
from its URL, to issue a HEAD request to check the MIME type directly, before
adding the link.

Default: 1 (true)

=item USERAGENT

Allows the caller to specify its own user agent to make the HTTP requests.

Default: LWP::RobotUA object created by the robot

=item ACCEPT_LANGUAGE

Optionally allows the caller to specify the list of languages that the robot
accepts. This is added as an "Accept-Language" header field in the HTTP
request. Takes an array reference.

=item DELAY

Optionally set the delay between requests for the user agent, in minutes. The
default for this is 1 (see LWP::RobotUA).

=back

=head1 SUPPORTED HOOKS

This section lists the hooks which are supported by the WWW::Robot module.
The first two arguments passed to a hook function are always the Robot
object followed by the name of the hook being invoked. I.e. the start of
a hook function should look something like:

    sub my_hook_function
    {
        my $robot = shift;
        my $hook  = shift;
        # ... other, hook-specific, arguments

Wherever a hook function is passed a C<$url> argument,
this will be a URI::URL object, with the URL fully specified.
I.e. even if the URL was seen in a relative link,
it will be passed as an absolute URL.


=head2 restore-state

   sub hook { my($robot, $hook_name) = @_; }

This hook is invoked just before entering the main iterative loop
of the robot.
The intention is that the hook will be used to restore state,
if such an operation is required.

This can be helpful if the robot is running in an incremental mode,
where state is saved between each run of the robot.



=head2 invoke-on-all-url

   sub hook { my($robot, $hook_name, $url) = @_; }

This hook is invoked on all URLs seen by the robot,
regardless of whether the URL is actually traversed.
In addition to the standard C<$robot> and C<$hook> arguments,
the third argument is C<$url>, which is the URL being travered by
the robot.

For a given URL, the hook function will be invoked at most once,
regardless of how many times the URL is seen by the Robot.
If you are interested in seeing the URL every time,
you can use the B<invoke-on-link> hook.



=head2 follow-url-test

   sub hook { my($robot, $hook_name, $url) = @_; return $boolean; }

This hook is invoked to determine whether the robot should traverse
the given URL.
If the hook function returns 0 (zero),
then the robot will do nothing further with the URL.
If the hook function returns non-zero,
then the robot will get the contents of the URL,
invoke further hooks,
and extract links if the contents are HTML.



=head2 invoke-on-followed-url

   sub hook { my($robot, $hook_name, $url) = @_; }

This hook is invoked on URLs which are about to be traversed by the robot;
i.e. URLs which have passed the follow-url-test hook.



=head2 invoke-on-get-error

   sub hook { my($robot, $hook_name, $url, $response) = @_; }

This hook is invoked if the Robot ever fails to get the contents
of a URL.
The C<$response> argument is an object of type HTTP::Response.



=head2 invoke-on-contents

   sub hook { my($robot, $hook, $url, $response, $structure) = @_; }

This hook function is invoked for all URLs for which the contents
are successfully retrieved.

The C<$url> argument is a URI::URL object for the URL currently being
processed by the Robot engine.

The C<$response> argument is an HTTP::Response object,
the result of the GET request on the URL.

The C<$structure> argument is an
HTML::Element object which is the root of a tree structure constructed
from the contents of the URL.
You can set the C<IGNORE_TEXT> attribute to specify whether the structure
passed includes the textual content of the page,
or just the HTML elements.
You can set the C<IGNORE_UNKNOWN> attribute to specify whether the structure
passed includes unkown HTML elements.


=head2 invoke-on-link

   sub hook { my($robot, $hook_name, $from_url, $to_url) = @_; }

This hook function is invoked for all links seen as the robot traverses.
When the robot is parsing a page (B<$from_url>) for links,
for every link seen the I<invoke-on-link> hook is invoked with the URL
of the source page, and the destination URL.
The destination URL is in canonical form.

=head2 add-url-test

   sub hook { my($robot, $hook_name, $url) = @_; }

This hook function is invoked for all links seen as the robot traverses.
If the hook function returns non-zero, then the robot will add the URL given by
$url to its list of URLs to be traversed.

=head2 continue-test

   sub hook { my($robot) = @_; }

This hook is invoked at the end of the robot's main iterative loop.
If the hook function returns non-zero, then the robot will continue
execution with the next URL.
If the hook function returns zero,
then the Robot will terminate the main loop, and close down
after invoking the following two hooks.

If no C<continue-test> hook function is provided,
then the robot will always loop.

=head2 save-state

   sub hook { my($robot) = @_; }

This hook is used to save any state information required by the robot
application.

=head2 generate-report

   sub hook { my($robot) = @_; }

This hook is used to generate a report for the run of the robot,
if such is desired.


=head2 modified-since

If you provide this hook function, it will be invoked for each URL
before the robot actually requests it.
The function can return a time to use with the If-Modified-Since
HTTP header.
This can be used by a robot to only process those pages which have
changed since the last visit.

Your hook function should be declared as follows:

    sub modifed_since_hook
    {
        my $robot = shift;        # instance of Robot module
        my $hook  = shift;        # name of hook invoked
        my $url   = shift;        # URI::URL for the url in question
    
        # ... calculate time ...
        return $time;
    }

If your function returns anything other than C<undef>,
then a B<If-Modified-Since:> field will be added to the request header.


=head2 invoke-after-get

This hook function is invoked immediately after the robot makes
each GET request.
This means your hook function will see every type of response,
not just successful GETs.
The hook function is passed two arguments: the C<$url> we tried to GET,
and the C<$response> which resulted.

If you provided a modified-since hook, then provide an invoke-after-get
function, and look for error code 304 (or RC_NOT_MODIFIED if you are
using HTTP::Status, which you should be :-):

    sub after_get_hook
    {
        my($robot, $hook, $url, $response) = @_;
        
        if ($response->code == RC_NOT_MODIFIED)
        {
        }
    }


=head1 EXAMPLES

This section illustrates use of the Robot module,
with code snippets from several sample Robot applications.
The code here is not intended to show the right way to code a web robot,
but just illustrates the API for using the Robot.

=head2 Validating Robot

This is a simple robot which you could use to validate your web site.
The robot uses B<weblint> to check the contents of URLs of type
B<text/html>

   #!/usr/bin/perl
   require 5.002;
   use WWW::Robot;
   
   $rootDocument = $ARGV[0];
   
   $robot = new WWW::Robot('NAME'     =>  'Validator',
			   'VERSION'  =>  1.000,
			   'EMAIL'    =>  'fred@foobar.com');
   
   $robot->addHook('follow-url-test', \&follow_test);
   $robot->addHook('invoke-on-contents', \&validate_contents);
   
   $robot->run($rootDocument);
   
   #-------------------------------------------------------
   sub follow_test {
      my($robot, $hook, $url) = @_;
   
      return 0 unless $url->scheme eq 'http';
      return 0 if $url =~ /\.(gif|jpg|png|xbm|au|wav|mpg)$/;
  
      #---- we're only interested in pages on our site ----
      return $url =~ /^$rootDocument/;
   }
   
   #-------------------------------------------------------
   sub validate_contents {
      my($robot, $hook, $url, $response, $structure) = @_;
   
      return unless $response->content_type eq 'text/html';

      # some validation on $structure ...
   
   }

If you are behind a firewall, then you will have to add something
like the following, just before calling the C<run()> method:

   $robot->proxy(['ftp', 'http', 'wais', 'gopher'],
		 'http://firewall:8080/');

=head1 MODULE DEPENDENCIES

The Robot.pm module builds on a lot of existing Net, WWW and other
Perl modules.
Some of the modules are part of the core Perl distribution,
and the latest versions of all modules are available from
the Comprehensive Perl Archive Network (CPAN).
The modules used are:

=over

=item HTTP::Request

This module is used to construct HTTP requests, when retrieving the contents
of a URL, or using the HEAD request to see if a URL exists.

=item HTML::LinkExtor

This is used to extract the URLs from the links on a page.

=item HTML::TreeBuilder

This module builds a tree data structure from the contents of an HTML page.
This is also used to check for page-specific Robot exclusion commands,
using the META element.

=item URI::URL

This module implements a class for URL objects,
providing resolution of relative URLs, and access to the different
components of a URL.

=item LWP::RobotUA

This is a wrapper around the LWP::UserAgent class.
A I<UserAgent> is used to connect to servers over the network,
and make requests.
The RobotUA module provides transparent compliance with the
I<Robot Exclusion Protocol>.

=item HTTP::Status

This has definitions for HTTP response codes,
so you can say RC_NOT_MODIFIED instead of 304.

=back

All of these modules are available as part of the libwww-perl5
distribution, which is also available from CPAN.

=head1 SEE ALSO

=over 4

=item The SAS Group Home Page

http://www.cre.canon.co.uk/sas.html

This is the home page of the Group at Canon Research Centre Europe
who are responsible for Robot.pm.

=item Robot Exclusion Protocol

http://info.webcrawler.com/mak/projects/robots/norobots.html

This is a I<de facto> standard which defines how a `well behaved'
Robot client should interact with web servers and web pages.

=item Guidelines for Robot Writers

http://info.webcrawler.com/mak/projects/robots/guidelines.html

Guidelines and suggestions for those who are (considering)
developing a web robot.

=item Weblint Home Page

http://www.cre.canon.co.uk/~neilb/weblint/

Weblint is a perl script which is used to check HTML for syntax
errors and stylistic problems,
in the same way B<lint> is used to check C.

=item Comprehensive Perl Archive Network (CPAN)

http://www.perl.com/perl/CPAN/

This is a well-organized collection of Perl resources,
such as modules, documents, and scripts.
CPAN is mirrored at FTP sites around the world.

=back

=head1 VERSION

This documentation describes version 0.021 of the Robot module.
The module requires at least version 5.002 of Perl.

=head1 AUTHOR

    Neil Bowers <neilb@cre.canon.co.uk>
    Ave Wrigley <wrigley@cre.canon.co.uk>

    Web Department, Canon Research Centre Europe

=head1 COPYRIGHT

 Copyright (C) 1997, Canon Research Centre Europe.
 Copyright (C) 2006,2007 Konstantin Matyukhin.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
