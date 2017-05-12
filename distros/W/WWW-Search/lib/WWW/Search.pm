# Search.pm
# by John Heidemann
# Copyright (C) 1996 by USC/ISI
# $Id: Search.pm,v 2.565 2008-11-29 05:52:08 Martin Exp $
#
# A complete copyright notice appears at the end of this file.

=head1 NAME

WWW::Search - Virtual base class for WWW searches

=head1 SYNOPSIS

  use WWW::Search;
  my $sEngine = 'AltaVista';
  my $oSearch = new WWW::Search($sEngine);

=head1 DESCRIPTION

This class is the parent for all access methods supported by the
C<WWW::Search> library.  This library implements a Perl API
to web-based search engines.

See README for a list of search engines currently supported, and for a
lot of interesting high-level information about this distribution.

Search results can be limited, and there is a pause between each
request to avoid overloading either the client or the server.

=head2 Sample program

Here is a sample program:

  my $sQuery = 'Columbus Ohio sushi restaurant';
  my $oSearch = new WWW::Search('AltaVista');
  $oSearch->native_query(WWW::Search::escape_query($sQuery));
  $oSearch->login($sUser, $sPassword);
  while (my $oResult = $oSearch->next_result())
    {
    print $oResult->url, "\n";
    } # while
  $oSearch->logout;

Results are objects of type C<WWW::SearchResult>
(see L<WWW::SearchResult> for details).
Note that different backends support different result fields.
All backends are required to support title and url.

=head1 SEE ALSO

For specific search engines, see L<WWW::Search::TheEngineName>
(replacing TheEngineName with a particular search engine).

For details about the results of a search,
see L<WWW::SearchResult>.

=head1 METHODS AND FUNCTIONS FOR SEARCHERS

=over

=cut

#####################################################################

package WWW::Search;

use strict qw( vars );
use warnings;

use Carp ();
use CGI;
# use Data::Dumper;  # for debugging only
use Exporter;
use File::Find;
use File::Spec::Functions;
use HTML::TreeBuilder;
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;
use LWP::MemberMixin;
use LWP::RobotUA;
use LWP::UserAgent;
# use Net::Domain qw( hostfqdn );
use URI;
use URI::Escape;
# use User;

# Internal states:
use constant SEARCH_BEFORE => 1;
use constant SEARCH_UNDERWAY => 2;
use constant SEARCH_DONE => 3;
use constant SEARCH_RETRIEVING => 4;

use vars qw( @ISA @EXPORT @EXPORT_OK );
@EXPORT = qw();
@EXPORT_OK = qw( escape_query unescape_query generic_option strip_tags );
@ISA = qw(Exporter LWP::MemberMixin);
our
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';
our
$VERSION = do { my @r = (q$Revision: 2.565 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=item new

To create a new WWW::Search, call

    $oSearch = new WWW::Search('SearchEngineName');

where SearchEngineName is replaced with a particular search engine.
For example:

    $oSearch = new WWW::Search('Yahoo');

If no search engine is specified, a default (currently 'Null::Empty')
will be chosen for you.

=cut

sub new
  {
  my $class = shift;
  my $engine = shift;
  # Remaining arguments will become hash args

  # The default backend (not currently more configurable :-< )
  my $default_engine = 'Null::Empty';
  my $default_agent_name = "$class/$VERSION";
  my $default_agent_email = '';
  $engine = $default_engine if (!defined($engine));
  # Load the engine, if necessary.
  my $subclass = "${class}::$engine";
  my $sEval = "use $subclass;";
  eval $sEval;
  Carp::croak("can not load backend $engine ($@)") if ($@);
  my $self = bless {
                    engine => $engine,
                    maximum_to_retrieve => 500,  # both pages and hits
                    interrequest_delay => 0.25,  # in seconds
                    agent_name => $default_agent_name,
                    agent_email => $default_agent_email,
                    env_proxy => 0,
                    http_method => 'GET',
                    http_proxy => undef,
                    http_proxy_user => undef,
                    http_proxy_pwd => undef,
                    timeout => 60,
                    _debug => 0,
                    _parse_debug => 0,
                    search_from_file => undef,
                    search_to_file => undef,
                    search_to_file_index => 0,
                    @_,
                    # variable initialization goes here
                   }, $subclass;
  $self->reset_search();
  return $self;
  } # new

=item version

Returns the value of the $VERSION variable of the backend engine, or
$WWW::Search::VERSION if the backend does not contain $VERSION.

=cut

sub version
  {
  my $self = shift;
  my $iVersion = eval '$'.ref($self).'::VERSION';
  # print STDERR " + iVersion = >>>$iVersion<<<\n";
  $iVersion ||= $VERSION;
  return $iVersion;
  } # version

=item maintainer

Returns the value of the $MAINTAINER variable of the backend engine,
or $WWW::Search::MAINTAINER if the backend does not contain
$MAINTAINER.

=cut

sub maintainer
  {
  my $self = shift;
  my $sMaintainer = eval '$'.ref($self).'::MAINTAINER';
  # print STDERR " + sMaintainer = >>>$sMaintainer<<<\n";
  $sMaintainer ||= $MAINTAINER;
  return $sMaintainer;
  } # maintainer


=item installed_engines

Returns a list of the names of all installed backends.
We can not tell if they are up-to-date or working, though.

  use WWW::Search;
  my @asEngines = sort &WWW::Search::installed_engines();
  local $" = ', ';
  print (" + These WWW::Search backends are installed: @asEngines\n");
  # Choose a backend at random (yes, this is rather silly):
  my $oSearch = WWW::Search->new($asEngines[rand(scalar(@asEngines))]);

=cut

use constant DEBUG_ARC     => 0;
use constant DEBUG_COOKIES => 0;
use constant DEBUG_FIND    => 0;
use constant DEBUG_FUNC    => 0;
use constant DEBUG_RETR    => 0;

sub _wanted
  {
  # Code adapted from the following netnews post (Thank you, Tom!):
  # From: Tom Christiansen (tchrist@mox.perl.com)
  # Subject: SRC: pminst - find modules whose names match this pattern
  # Newsgroups: comp.lang.perl.misc
  # Date: 1999/02/15
  my $startdir = shift;
  my $sFullPath = $File::Find::name;
  print STDERR " +   _wanted($startdir, $sFullPath)\n" if DEBUG_FIND;
  if (-d && /^[a-z]/)
    {
    # This is so we don't go down site_perl etc too early (whatever
    # that means):
    $File::Find::prune = 1;
    DEBUG_FIND && print STDERR " +     prune\n";
    return;
    } # if
  unless ($sFullPath =~ s!\.pm\Z!!)
    {
    DEBUG_FIND && print STDERR " +     not .pm\n";
    return;
    } # unless
  # Delete absolute path off front of file path:
  $sFullPath =~ s{^\Q$startdir\E[\\/]}{};
  unless (1 || ($sFullPath =~ s!\AWWW/Search!!))
    {
    print STDERR " +     not WWW/Search\n" if DEBUG_FIND;
    return;
    } # unless
  print STDERR " +     found $sFullPath\n" if DEBUG_FIND;
  $sFullPath =~ s{/}{::}g;
  $sFullPath =~ s!\A::!!;
  return $sFullPath;
  } # _wanted

sub installed_engines
  {
  # Does NOT need a WWW::Search object to operate
  my %hsi;
  local $" = '|';
  DEBUG_FIND && print STDERR " + installed_engines() start, INC is @INC...\n";
 INC_DIR:
  foreach my $sDir (map catdir($_, 'WWW', 'Search'), @INC)
    {
    DEBUG_FIND && print STDERR " +   foreach ==$sDir==\n";
    next INC_DIR unless -d $sDir;
    File::Find::find(sub {
                       $hsi{&_wanted($sDir) || 'JUNKJUNK'}++;
                       }, $sDir);
    } # foreach INC_DIR
  delete $hsi{'JUNKJUNK'};
  delete $hsi{'Test'};
  delete $hsi{'Result'};
  return keys %hsi;
  } # installed_engines


=item native_query

Specify a query (and optional options) to the current search object.
Previous query (if any) and its cached results (if any) will be thrown away.
The option values and the query must be escaped;
call L<WWW::Search::escape_query()> to escape a string.
The search process is not actually begun until C<results()> or
C<next_result()> is called (lazy!), so native_query does not return anything.

Example:

  $oSearch->native_query('search-engine-specific+escaped+query+string',
                        { option1 => 'able', option2 => 'baker' } );

The hash of options following the query string is optional.
The query string is backend-specific.
There are two kinds of options:
options specific to the backend,
and generic options applicable to multiple backends.

Generic options all begin with 'search_'.
Currently a few are supported:

=over 4

=item search_url

Specifies the base URL for the search engine.

=item search_debug

Enables backend debugging.  The default is 0 (no debugging).

=item search_parse_debug

Enables backend parser debugging.  The default is 0 (no debugging).

=item search_to_file FILE

Causes the search results to be saved in a set of files 
prefixed by FILE.
(Used internally by the test-suite, not intended for general use.)

=item search_from_file FILE

Reads a search from a set of files prefixed by FILE.
(Used internally by the test-suite, not intended for general use.)

=back

Some backends may not implement these generic options,
but any which do implement them must provide these semantics.

Backend-specific options are described
in the documentation for each backend.
In most cases the options and their values are packed together to create the query portion of
the final URL.

Details about how the search string and option hash are interpreted
might be found in the search-engine-specific manual pages
(WWW::Search::SearchEngineName).

=cut

sub native_query
  {
  my $self = shift;
  print STDERR " FFF native_query($_[0])\n" if (DEBUG_FUNC || $self->{_debug});
  $self->reset_search();
  $self->{'native_query'} = $_[0];
  $self->{'native_options'} = $_[1];
  # promote generic options
  my $opts_ref = $_[1];
  foreach my $sKey (keys %$opts_ref)
    {
    if (generic_option($sKey))
      {
      print STDERR " +   promoting $sKey to $self\n" if $self->{_debug};
      $self->{$sKey} = $opts_ref->{$sKey};
      # delete $opts_ref->{$sKey};
      } # if
    } # foreach
  $self->setup_search() if ($self->{state} == SEARCH_BEFORE);
  } # native_query


=item gui_query

Specify a query to the current search object;
the query will be performed with the engine's default options,
as if it were typed by a user in a browser window.

Same arguments as C<native_query()> above.

Currently, this feature is supported by only a few backends;
consult the documentation for each backend to see if it is implemented.

=cut

sub gui_query
  {
  # This function is a stub to prevent runtime errors.  This function
  # should be defined in each backend as appropriate.  See Yahoo.pm in
  # the WWW-Search-Yahoo distribution for an example of how to
  # implement it.
  my $self = shift;
  return $self->native_query(@_);
  } # gui_query


=item cookie_jar

Call this method (anytime before asking for results) if you want to
communicate cookie data with the search engine.  Takes one argument,
either a filename or an HTTP::Cookies object.  If you give a filename,
WWW::Search will attempt to read/store cookies there (by passing the
filename to HTTP::Cookies::new).

  $oSearch->cookie_jar('/tmp/my_cookies');

If you give an HTTP::Cookies object, it is up to you to save the
cookies if/when you wish.

  use HTTP::Cookies;
  my $oJar = HTTP::Cookies->new(...);
  $oSearch->cookie_jar($oJar);

If you pass in no arguments, the cookie jar (if any) is returned.

  my $oJar = $oSearch->cookie_jar;
  unless (ref $oJar) { print "No jar" };

=cut

sub cookie_jar
  {
  my $self = shift;
  if (! @_)
    {
    return $self->{'_cookie_jar'};
    } # if no arguments
  my $arg = shift;
  my $sRef = ref($arg);
  if ($sRef =~ m!\AHTTP::Cookies!)
    {
    print STDERR " + WWW::Search using caller's $sRef object\n" if DEBUG_COOKIES;
    $self->{'_cookie_jar'} = $arg;
    $self->{'_cookie_jar_we_save'} = 0;
    } # if
  elsif (! ref($arg))
    {
    # Assume that $arg is a file name:
    print STDERR " + WWW::Search using Cookies from file $arg\n" if DEBUG_COOKIES;
    $self->{'_cookie_jar'} = HTTP::Cookies->new(
                                               'file' => $arg,
                                               'autosave' => 1,
                                               'ignore_discard' => 1,
                                               );
    $self->{'_cookie_jar'}->load;
    $self->{'_cookie_jar_we_save'} = 1;
    # print STDERR " + WWW::Search just loaded cookies from $arg\n";
    }
  else
    {
    Carp::carp "argument to WWW::Search::cookie_jar() must be a scalar or a flavor of HTTP::Cookies";
    }
  } # cookie_jar


=item date_from

Set/get the start date for limiting the query by a date range.  See
the documentation for each backend to find out if date ranges are
supported.

=item date_to

Set/get the end date for limiting the query by a date range.  See the
documentation for each backend to find out if date ranges are
supported.

=cut

sub date_from
  {
  return shift->_elem('date_from', @_) || '';
  } # date_from

sub date_to
  {
  return shift->_elem('date_to', @_) || '';
  } # date_to


=item env_proxy

Enable loading proxy settings from environment variables.
The proxy URL will be read from $ENV{http_proxy}.
The username for authentication will be read from $ENV{http_proxy_user}.
The password for authentication will be read from $ENV{http_proxy_pwd}.

If you don't want to put passwords in the environment, one solution
would be to subclass LWP::UserAgent and use $ENV{WWW_SEARCH_USERAGENT}
instead (see user_agent below).

env_proxy() must be called before the first retrieval is attempted.

Example:

  $ENV{http_proxy     } = 'http://my.proxy.com:80';
  $ENV{http_proxy_user} = 'bugsbun';
  $ENV{http_proxy_pwd } = 'c4rr0t5';
  $oSearch->env_proxy('yes');  # Turn on with any true value
  ...
  $oSearch->env_proxy(0);  # Turn off with zero
  ...
  if ($oSearch->env_proxy)  # Test

=cut

# contributed by Klaus Johannes Rusch
sub env_proxy
  {
  return shift->_elem('env_proxy', @_);
  } # env_proxy


=item http_proxy

Set up an HTTP proxy (for connections from behind a firewall).

Takes the same arguments as LWP::UserAgent::proxy().

This routine should be called before calling any of the result
functions (any method with "result" in its name).

Example:

  # Turn on and set address:
  $oSearch->http_proxy(['http','ftp'] => 'http://proxy:8080');
  # Turn off:
  $oSearch->http_proxy('');

=cut

sub http_proxy
  {
  my $self = shift;
  # Make a copy of our arguments:
  if (@_)
    {
    my @a = @_;
    return $self->_elem('http_proxy', \@a);
    }
  else
    {
    return $self->_elem('http_proxy');
    }
  } # http_proxy


=item http_proxy_user, http_proxy_pwd

Set/get HTTP proxy authentication data.

These routines set/get username and password used in proxy
authentication.
Authentication is attempted only if all three items (proxy URL, username
and password) have been set.

Example:

    $oSearch->http_proxy_user("myuser");
    $oSearch->http_proxy_pwd("mypassword");
    $oSearch->http_proxy_user(undef);   # Example for no authentication

    $username = $oSearch->http_proxy_user();

=cut

sub http_proxy_user
  {
  return shift->_elem('http_proxy_user', @_);
  }

sub http_proxy_pwd
  {
  return shift->_elem('http_proxy_pwd', @_);
  }


=item maximum_to_retrieve

Set the maximum number of hits to return.
Queries resulting in more than this many hits will return
the first hits, up to this limit.
Although this specifies a maximum limit,
search engines might return less than this number.

Defaults to 500.

Example:
    $max = $oSearch->maximum_to_retrieve(100);

You can also spell this method "maximum_to_return".

=cut

sub maximum_to_retrieve
  {
  return shift->_elem('maximum_to_retrieve', @_);
  }


=item maximum_to_return

Synonym for maximum_to_retrieve

=cut

sub maximum_to_return
  {
  return shift->_elem('maximum_to_retrieve', @_);
  }


=item timeout

The maximum length of time any portion of the query should take,
in seconds.

Defaults to 60.

Example:
    $oSearch->timeout(120);

=cut

sub timeout
  {
  return shift->_elem('timeout', @_);
  }


=item login

Backends which need to login to the search engine should implement
this function.  Takes two arguments, user and password.  Return
nonzero if login was successful.  Return undef or 0 if login failed.

=cut

sub login
  {
  my $self = shift;
  # Here is just a stub.
  return 1;
  # These are the arguments:
  my ($sUser, $sPassword) = @_;
  } # login

=item logout

Backends which need to logout from the search engine should implement
this function.

=cut

sub logout
  {
  my $self = shift; # no other args
  # Here is just a stub.
  } # logout


=item approximate_result_count

Some backends indicate how many results they have found.
Typically this is an approximate value.

=cut

sub approximate_result_count
  {
  my $self = shift;
  # Optional arg1 = new value for this option.
  my $iArg = shift;
  $iArg = undef if (defined($iArg) && ($iArg eq ''));
  DEBUG_FUNC && print STDERR " FFF a_r_c(state=$self->{state},iArg=$iArg)\n";
  DEBUG_ARC && print STDERR " + a_r_c(state=$self->{state},iArg=$iArg)\n";
  if (defined($iArg) && (0 <= $iArg))
    {
    # Caller is trying to SET the value:
    DEBUG_ARC && print STDERR " + a_r_cSET(state=$self->{state},iArg=$iArg)\n";
    $self->{'approx_count'} =  $iArg;
    return $iArg;
    } # if
  if (
      # This prevents infinite recursion, for when retrieve_some()
      # calls this function in order to SET the value:
      ($self->{state} ne SEARCH_RETRIEVING)
      &&
      # This prevents useless repeat calls to retrieve_some() after
      # the search has been completed:
      ($self->{state} ne SEARCH_DONE))
    {
    DEBUG_ARC && print STDERR " DDD a_r_c prime the pump\n";
    # Prime the pump, if necessary:
    $self->retrieve_some();
    } # if
  $iArg = $self->{'approx_count'} || 0;
  # print STDERR " + a_r_cGET(state=$self->{state},answer=$iArg)\n";
  return $iArg;
  } # approximate_result_count

=item approximate_hit_count

This is an alias for approximate_result_count().

=cut

sub approximate_hit_count
  {
  shift->approximate_result_count(@_);
  } # approximate_hit_count


=item results

Return all the results of a query as an array of WWW::SearchResult
objects.

Note: This might take a while, because a web backend will keep asking
the search engine for "next page of results" over and over until there
are no more next pages, and THEN return from this function.

If an error occurs at any time during query processing, it will be
indicated in the response().

Example:

    @results = $oSearch->results();
    # Go have a cup of coffee while the previous line executes...
    foreach $oResult (@results)
      {
      print $oResult->url(), "\n";
      } # foreach

=cut

sub results
  {
  my $self = shift;
  print STDERR " FFF results(",$self->{'native_query'},")\n" if (DEBUG_FUNC || $self->{_debug});
  # Put all the search results into the cache:
  1 while ($self->retrieve_some());
  $self->{cache} ||= [];
  my $iMax = scalar(@{$self->{cache}});
  # print STDERR " +   mtr is ", $self->{maximum_to_retrieve}, "\n" if $self->{_debug};
  # print STDERR " +   cache contains $iMax results\n" if $self->{_debug};
  $iMax = $self->{maximum_to_retrieve} if ($self->{maximum_to_retrieve} < $iMax);
  # print STDERR " +   returning $iMax results\n" if $self->{_debug};
  return @{$self->{cache}}[0..$iMax-1];
  } # results

=item next_result

Call this method repeatedly to return each result of a query as a
WWW::SearchResult object.  Example:

    while ($oResult = $oSearch->next_result())
      {
      print $oResult->url(), "\n";
      } # while

When there are no more results, or if an error occurs, next_result()
will return undef.

If an error occurs at any time during query processing, it will be
indicated in the response().

=cut

sub next_result
  {
  my $self = shift;
  # Carp::croak "search not yet specified" if (!defined($self->{'native_query'}));
  return undef if ($self->{next_to_return} >= $self->{maximum_to_retrieve});
  while (1)
    {
    if ($self->{next_to_return} <= $#{$self->{cache}})
      {
      # The cache already contains the desired element; return it:
      my $i = ($self->{next_to_return})++;
      return $self->{cache}->[$i];
      } # if
    # If we get here, then the desired element is beyond the end of
    # the cache.
    if ($self->{state} == SEARCH_DONE)
      {
      # There are no more results to be gotten; fail & bail:
      return undef;
      } # if
    # Get some more results into the cache:
    $self->retrieve_some();
    # Go back and try again:
    } # while infinite
  } # next_result


=item seek_result($offset)

Set which result should be returned next time
C<next_result()> is called.  Results are zero-indexed.

The only guaranteed valid offset is 0,
which will replay the results from the beginning.
In particular, seeking past the end of the current cached
results probably will not do what you might think it should.

Results are cached, so this does not re-issue the query
or cause IO (unless you go off the end of the results).
To re-do the query, create a new search object.

Example:

    $oSearch->seek_result(0);

=cut

sub seek_result
  {
  my ($self, $desired) = @_;
  my $old = $self->{next_to_return};
  $self->{next_to_return} = $desired if (defined($desired) and (0 <= $desired));
  return $old;
  } # seek_result


=item response

Returns an L<HTTP::Response> object which resulted from the
most-recently-sent query.  Errors can be detected like this:

    if (! $oSearch->response->is_success)
      {
      print STDERR "Error:  " . $oSearch->response->as_string() . "\n";
      } # if

Note to backend authors: even if the backend does not involve the web,
it should return an L<HTTP::Response> object.

=cut

sub response
  {
  my $self = shift;
  $self->{response} ||= new HTTP::Response(RC_OK);
  return $self->{response};
  } # response


=item submit

This method can be used to submit URLs to the search engines for indexing.
Consult the documentation for each backend to find out if it is implemented there,
and if so what the arguments are.

Returns an HTTP::Response object describing the result of the submission request.
Consult the documentation for each backend to find out the meaning of the response.

=cut

sub submit
  {
  return new HTTP::Response(788, 'Sorry, this backend does not support the submit() method.');
  } # submit


=item opaque

This function provides an application a place to store
one opaque data element (or many, via a Perl reference).
This facility is useful to (for example),
maintain client-specific information in each active query
when you have multiple concurrent queries.

=cut

sub opaque { return shift->_elem('opaque', @_); }


=item escape_query

Escape a query.
Before queries are sent to the internet, special characters must be escaped
so that a proper URL can be formed.
This is like escaping a URL,
but all non-alphanumeric characters are escaped and
and spaces are converted to "+"s.

Example:

    $escaped = WWW::Search::escape_query('+hi +mom');
    # $escaped is now '%2Bhi+%2Bmom'

See also C<unescape_query()>.
NOTE that this is not a method, it is a plain function.

=cut

sub escape_query
  {
  my $text = join(' ', @_);
  $text ||= '';
  # print STDERR " +   escape_query($text)\n";
  $text =~ s/([^ A-Za-z0-9])/$URI::Escape::escapes{$1}/g; #"
  # print STDERR " +   escape_query($text)\n";
  $text =~ s/ /+/g;
  # print STDERR " +   escape_query($text)\n";
  return $text;
  } # escape_query

=item unescape_query

Unescape a query.
See C<escape_query()> for details.

Example:

    $unescaped = WWW::Search::unescape_query('%22hi+mom%22');
    # $unescaped eq q{"hi mom"}

NOTE that this is not a method, it is a plain function.

=cut

sub unescape_query
  {
  # code stolen from URI::Escape.pm.
  my @copy = @_;
  for (@copy)
    {
    s!\+! !g;
    s!\%([\dA-Fa-f]{2})!chr(hex($1))!eg;
    } # for
  return wantarray ? @copy : $copy[0];
  } # unescape_query

=item strip_tags

Given a string, returns a copy of that string with HTML tags removed.
This should be used by each backend as they insert the title and
description values into the search results objects.

NOTE that this is not a method, it is a plain function.

=cut

sub strip_tags
  {
  # Prevent undef warnings if we get passed any undefined values:
  my @args = @_;
  @args = map { $_ ||= '' } @args;
  my $s = join('', @args);
  # Special case: change BR to space:
  $s =~ s!<BR>! !gi;
  # We assume for now that we will not be encountering tags with
  # embedded '>' characters!
  $s =~ s/\074.+?\076//g;
  $s =~ s/&nbsp;/ /g;
  $s =~ s/&quot;/\042/g;
  $s =~ s/&amp;/\046/g;
  $s =~ s/&lt;/\074/g;
  $s =~ s/&gt;/\076/g;
  # Coalesce multiple spaces:
  $s =~ tr!\040\t\r\n! !s;
  # Delete leading & trailing spaces:
  $s =~ s!\A\s+!!;
  $s =~ s!\s+\Z!!;
  return $s;
  } # strip_tags

=item is_http_proxy

Returns true if proxy information is available.

=cut

sub is_http_proxy
  {
  my $self = shift;
  my $ra = $self->http_proxy;
  my $ret = (
             ('ARRAY' eq ref($ra))
             &&
             defined($ra->[0])
             &&
             ($ra->[0] ne '')
            );
  # print STDERR " DDD is_http_proxy() return =$ret=\n";
  return $ret;
  } # is_http_proxy

=back

=head1 METHODS AND FUNCTIONS FOR BACKEND PROGRAMMERS

=over

=item reset_search

Resets internal data structures to start over with a new search (on
the same engine).

=cut

sub reset_search
  {
  my $self = shift;
  print STDERR " FFF reset_search(",$self->{'native_query'},")\n" if (DEBUG_FUNC || $self->{_debug});
  $self->{'cache'} = [];
  $self->{'native_query'} = '';
  $self->{'next_to_retrieve'} = 1;
  $self->{'next_to_return'} = 0;
  $self->{'number_retrieved'} = 0;
  $self->{'requests_made'} = 0;
  $self->{'state'} = SEARCH_BEFORE;
  $self->{'_next_url'} = '';
  $self->{'approx_count'} = 0;
  # This method is called by native_query().  native_query() is called
  # either by gui_query() or by the user.  In the case that
  # gui_query() was called, we do NOT want to clear out the _options
  # hash.  For now, I implement a pretty ugly hack to make this work:
  if (caller(2))
    {
    my @as = caller(2);
    if (1 < scalar(@as))
      {
      # print STDERR " in reset_search(), as is (", join(',', @as), ")\n";
      return if $as[3] =~ m/gui_query/;
      } # if
    } # if
  $self->{_options} = ();
  } # reset_search


=item is_http_proxy_auth_data

Returns true if all authentication data
(proxy URL, username, and password) are available.

=cut

sub is_http_proxy_auth_data
  {
  my $self = shift;
  # print STDERR (" DDD http_proxy is ", Dumper(\$self));
  my $ret = (
             $self->is_http_proxy
             &&
             defined($self->http_proxy_user)
             &&
             ($self->http_proxy_user ne '')
             &&
             defined($self->http_proxy_pwd)
             &&
             ($self->http_proxy_pwd ne '')
            );
  # print STDERR " DDD is_http_proxy_auth_data() return =$ret=\n";
  return $ret;
  } # is_http_proxy_auth_data


=item agent_name($sName)

If your search engine rejects certain browser,
you can trick it into thinking you're any browser type you want.
See below under user_agent().

=cut

sub agent_name
  {
  return shift->_elem('agent_name', @_);
  }

=item agent_email($sName)

=cut

sub agent_email
  {
  return shift->_elem('agent_email', @_);
  }

=item user_agent($NON_ROBOT)

This internal routine creates a user-agent for derived classes that
query the web.  If any non-false argument is given, a normal
LWP::UserAgent (rather than a LWP::RobotUA) is used.

Returns the user-agent object.

If a backend needs the low-level LWP::UserAgent or LWP::RobotUA to
have a particular name, $oSearch->agent_name() and possibly
$oSearch->agent_email() should be called to set the desired values
*before* calling $oSearch->user_agent().

If the environment variable WWW_SEARCH_USERAGENT has a value, it will
be used as the class for a new user agent object.  This class should
be a subclass of LWP::UserAgent.  For example,

  $ENV{WWW_SEARCH_USERAGENT} = 'My::Own::UserAgent';
  # If this env.var. has no value,
  # LWP::UserAgent or LWP::RobotUA will be used.
  $oSearch = new WWW::Search('MyBackend');
  $oSearch->agent_name('MySpider');
  if ($iBackendWebsiteRequiresNonRobot)
    {
    $oSearch->user_agent('non-robot');
    }
  else
    {
    $oSearch->agent_email('me@here.com');
    $oSearch->user_agent();
    }

Backends should use robot-style user-agents whenever possible.

=cut

sub _load_env_useragent
  {
  my $self = shift;
  my $sUA = $ENV{'WWW_SEARCH_USERAGENT'} || '';
  my $ua;
  if ($sUA ne '')
    {
    eval "use $sUA";
    # print STDERR " DDD this is after eval use $sUA\n";
    if (! $@)
      {
      # Successfully loaded module.
      eval { $ua = $sUA->new };
      # print STDERR " DDD this is after eval new $sUA\n";
      if (ref($ua) && ! $@)
        {
        # Successfully created object.
        return $ua;
        }
      else
        {
        warn " --- WWW::Search::user_agent can not create $sUA object: $@\n";
        # Fall through and try the other methods:
        }
      }
    else
      {
      warn " --- WWW::Search::user_agent can not load $sUA: $@\n";
      # Fall through and try the other methods:
      }
    } # if found WWW_SEARCH_USERAGENT in environment
  } # _load_env_useragent

sub user_agent
  {
  my $self = shift;
  unless (@_)
    {
    # If NO ARGS, return the previously-created agent (if any):
    return $self->{'user_agent'} if ref($self->{'user_agent'});
    } # unless
  my $non_robot = shift || 0;
  my $ua = _load_env_useragent();
  # If we loaded a UserAgent, don't do any of this stuff:
  if (! ref $ua)
    {
    if ($non_robot)
      {
      eval
        {
        $ua = new LWP::UserAgent;
        $ua->agent($self->agent_name);
        $ua->from($self->agent_email);
        }; # end of eval block
      }
    else
      {
      $ua = LWP::RobotUA->new($self->agent_name, $self->agent_email);
      $ua->delay($self->{'interrequest_delay'});
      }
    $ua->timeout($self->{'timeout'});
    eval { $ua->proxy(@{$self->{'http_proxy'}}) } if $self->is_http_proxy;
    if ($self->env_proxy)
      {
      $ua->env_proxy($self->env_proxy);
      # Read password from ENV:
      $self->http_proxy_user($ENV{http_proxy_user});
      $self->http_proxy_pwd ($ENV{http_proxy_pwd});
      } # if
    } # if ! ref $ua
  $self->{'user_agent'} = $ua;
  return $ua;
  } # user_agent


=item http_referer

Get / set the value of the HTTP_REFERER variable for this search object.
Some search engines might only accept requests that originated at some specific previous page.
This method lets backend authors "fake" the previous page.
Call this method before calling http_request.

  $oSearch->http_referer('http://prev.engine.com/wherever/setup.html');
  $oResponse = $oSearch->http_request('GET', $url);

=cut

sub http_referer
  {
  return shift->_elem('_http_referer', @_);
  }


=item http_method

Get / set the method to be used for the HTTP request.
Must be either 'GET' or 'POST'.
Call this method before calling http_request.
(Normally you would set this during _native_setup_search().)
The default is 'GET'.

  $oSearch->http_method('POST');

=cut

sub http_method
  {
  shift->_elem('http_method', @_);
  }


=item http_request($method, $url)

Submit the HTTP request to the world, and return the response.
Similar to LWP::UserAgent::request.
Handles cookies, follows redirects, etc.
Requires that http_referer already be set up, if needed.

=cut

sub http_request
  {
  my $self = shift;
  my ($method, $url) = @_;
  my $response;
  if (50 <= $self->{_debug})
    {
    eval q{ use LWP::Debug qw(+) }; # } # emacs bug
    } # if
  if ($self->{search_from_file})
    {
    $response = $self->_http_request_from_file($url);
    }
  else
    {
    # fetch it
    my $request;
    if ($method eq 'POST')
      {
      my $uri_url = URI->new($url);
      my $equery = $uri_url->query;
      $uri_url->query(undef);   # we will handle the query ourselves
      $request = new HTTP::Request($method, $uri_url);
      $request->header('Content-Type', 'application/x-www-form-urlencoded');
      $request->header('Content-Length', length $equery);
      $request->content($equery);
      }
    else
      {
      $request = new HTTP::Request($method, $url);
      }
    $request->header('Accept-Charset' => 'iso-8859-1,*,utf-8');
    if ($self->is_http_proxy_auth_data)
      {
      $request->proxy_authorization_basic($self->http_proxy_user,
                                          $self->http_proxy_pwd);
      } # if
    $self->{'_cookie_jar'}->add_cookie_header($request) if ref($self->{'_cookie_jar'});

    if ($self->{'_http_referer'} && ($self->{'_http_referer'} ne ''))
      {
      my $s = uri_escape($self->{'_http_referer'});
      # print STDERR " +    referer($s), ref(s) = ", ref($s), "\n";
      $s = $s->as_string if ref($s) =~ m!URI!;
      $request->referer($s);
      } # if referer
    print STDERR " DDD   raw HTTP::Request is:\n", $request->as_string if (3 <= $self->{_debug});
    my $ua = $self->user_agent();

  TRY_GET:
    while (1)
      {
      $response = $ua->request($request);
      printf(STDERR " +   got HTTP::Response (code=%d):\n%s",
             $response->code,
             $response->headers->as_string) if (3 <= $self->{_debug});
      if (ref($self->{'_cookie_jar'}))
        {
        $self->{'_cookie_jar'}->extract_cookies($response);
        $self->{'_cookie_jar'}->save if $self->{'_cookie_jar_we_save'};
        print STDERR " + WWW::Search just extracted cookies\n" if DEBUG_COOKIES;
        print STDERR $self->{'_cookie_jar'}->as_string if DEBUG_COOKIES;
        # print STDERR Dumper($self->{'_cookie_jar'}) if DEBUG_COOKIES;
        } # if
      if ($self->{'search_to_file'} && $response->is_success)
        {
        $self->_http_request_to_file($url, $response);
        } # if
      last TRY_GET if ($response->is_success);
      last TRY_GET if ($response->is_error);
      last TRY_GET if ($response->headers->header('Client-Warning') =~ m!redirect loop detected!i);
      if ($response->is_redirect
          ||
          # Some engines spoof us with a false 302 code, so look at
          # the message rather than the code:
          ($response->message =~ m!Object moved!i)
         )
        {
        my $sURL = $response->request->uri->as_string;
        my $sURLredir = $response->headers->header('Location');
        # Low-level loop detection:
        last TRY_GET if ($sURLredir eq $sURL);
        print STDERR " +   'Object moved' from $sURL to $sURLredir\n" if (2 <= $self->{_debug});
        # Follow the redirect:
        $request = new HTTP::Request('GET',
                                     URI->new_abs($sURLredir, $sURL),
                                    );
        $request->referer($sURL);
        $self->{'_cookie_jar'}->add_cookie_header($request) if ref($self->{'_cookie_jar'});
        print STDERR " +   'Object moved', new HTTP::Request is:\n", $request->as_string if (3 <= $self->{_debug});
        # Go back and try again
        } # if
      } # while infinite
    } # if not from_file
  return $response;
  } # http_request

sub _http_request_get_filename {
    my $self = shift;
    my $fn;
    # filename?
    if (!defined($self->{search_filename})) {
	$fn = $self->{search_from_file};
	$fn = $self->{search_to_file} if (!defined($fn));
	$self->{search_filename} = WWW::Search::unescape_query($fn);
    }
    $fn = $self->{search_filename};
    die "$0: bogus filename.\n" if (!defined($fn));
    return $fn;
} # _http_request_get_filename

sub _http_request_from_file {
    my $self = shift;
    my ($url) = @_;

    my $fn = $self->_http_request_get_filename();

    # read index?
    if (!defined($self->{search_from_file_hash})) {
	open(TABLE, "<$fn") || die "$0: open $fn failed.\n";
	my $i = 0;
	while (<TABLE>) {
	    chomp;
	    $self->{search_from_file_hash}{$_} = $i;
	    # print STDERR "$0: file index: $i <$_>\n";
	    $i++;
	};
	close TABLE;
    };
    # read file
    my $i = $self->{search_from_file_hash}{$url};
    if (defined($i)) {
	# print STDERR "$0: saved request <$url> found in $fn.$i\n";
	# read the data
	open(FILE, "<$fn.$i") || die "$0: open $fn.$i\n";
	my $d = '';
	while (<FILE>) {
	    $d .= $_;
	};
	close FILE;
	# make up the response
	my $r = new HTTP::Response(RC_OK);
	$r->content($d);
	return $r;
    } else {
	print STDERR "$0: saved request <$url> not found.\n";
	my $r = new HTTP::Response(RC_NOT_FOUND);
	return $r;
    };
} # _http_request_from_file

sub _http_request_to_file {
    my $self = shift;
    # The LAST arg is a LWP::Response object:
    my $response = pop;
    # The only other arg we care about is the FIRST arg, a url:
    my ($url, ) = @_;

    my $fn = $self->_http_request_get_filename();

    unlink($fn)
        if ($self->{search_to_file_index} == 0);
    open(TABLE, ">>$fn") || die "$0: open $fn\n";
    print TABLE "$url\n";
    close TABLE;
    my $i = ($self->{search_to_file_index})++;
    open (FILE, ">$fn.$i") || die "$0: open $fn.$i\n";
    print FILE $response->content();
    close FILE;
} # _http_request_to_file


=item next_url

Get or set the URL for the next backend request.  This can be used to
save the WWW::Search state between sessions (e.g. if you are showing
pages of results to the user in a web browser).  Before closing down a
session, save the value of next_url:

  ...
  $oSearch->maximum_to_return(10);
  while ($oSearch->next_result) { ... }
  my $urlSave = $oSearch->next_url;

Then, when you start up the next session (e.g. after the user clicks
your "next" button), restore this value before calling for the results:

  $oSearch->native_query(...);
  $oSearch->next_url($urlSave);
  $oSearch->maximum_to_return(20);
  while ($oSearch->next_result) { ... }

WARNING: It is entirely up to you to keep your interface in sync with
the number of hits per page being returned from the backend.  And, we
make no guarantees whether this method will work for any given
backend.  (Their caching scheme might not enable you to jump into the
middle of a list of search results, for example.)

=cut

sub next_url
  {
  return shift->_elem('_next_url', @_);
  }


=item split_lines

This internal routine splits data (typically the result of the web
page retrieval) into lines in a way that is OS independent.  If the
first argument is a reference to an array, that array is taken to be a
list of possible delimiters for this split.  For example, Yahoo.pm
uses <p> and <dd><li> as "line" delimiters for convenience.

=cut

sub split_lines
  {
  # This probably fails on an EBCDIC box where input is in text mode.
  # Too bad Macs do not just use binmode like Windows boxen.
  my $self = shift;
  my $s = shift;
  my $patt = '\015?\012';
  if (ref($s))
    {
    $patt = '('. $patt;
    foreach (@$s)
      {
      $patt .= "|$_";
      } # foreach
    $patt .= ')';
    # print STDERR " +     patt is >>>$patt<<<\n";
    $s = shift;
    } # if
  return split(/$patt/i, $s);
  # If we require perl 5.005, this can be done by:
  # use Socket qw(:crlf :DEFAULT);
  # split(/$CR?$LF/,$_[0])
  } # split_lines


=item generic_option

This internal routine checks if an option
is generic or backend specific.
Currently all generic options begin with 'search_'.
This routine is not a method.

=cut

sub generic_option
  {
  my $option = shift || '';
  return ($option =~ /^search_/);
  } # generic_option


=item _native_setup_search

Do some backend-specific initialization.
It will be called with the same arguments as native_query().

=cut

sub _native_setup_search
  {
  my $self = shift;
  print STDERR " FFF _n_s_s\n" if (DEBUG_FUNC || $self->{_debug});
  # Backward-compatibility for backends that define the old
  # native_setup_search(), but not the new _native_setup_search()
  if ($self->can('native_setup_search'))
    {
    return $self->native_setup_search(@_);
    } # if
  } # _native_setup_search


=item setup_search

This internal routine does generic Search setup.
It calls C<_native_setup_search()> to do backend-specific setup.

=cut

sub setup_search
  {
  my ($self) = @_;
  print STDERR " FFF setup_search(",$self->{'native_query'},")\n" if (DEBUG_FUNC || $self->{_debug});
  $self->{cache} = [];
  $self->{next_to_retrieve} = 1;
  $self->{number_retrieved} = 0;
  $self->{state} = SEARCH_UNDERWAY;
  # $self->{_options} = ();
  $self->_native_setup_search($self->{'native_query'}, $self->{'native_options'});
  } # setup_search


=item need_to_delay

A backend should override this method in order to dictate whether
user_agent_delay() needs to be called before the next HTTP request is
sent.  Return any perlish true or zero value.

=cut

sub need_to_delay
  {
  my $self = shift;
  # This is a NOP stub.  Unless the subclass overrides this method,
  # there is no reason to delay.
  return 0;
  } # need_to_delay


=item user_agent_delay

According to what need_to_delay() returns,
user_agent_delay() will be called between requests to remote
servers to avoid overloading them with many back-to-back requests.

=cut

sub user_agent_delay
  {
  my $self = shift;
  # Sleep for some number of seconds:
  select(undef, undef, undef, $self->{interrequest_delay});
  } # user_agent_delay


=item absurl

An internal routine to convert a relative URL into a absolute URL.  It
takes two arguments, the 'base' url (usually the search engine CGI
URL) and the URL to be converted.  Returns a URI object.

=cut

sub absurl
  {
  my ($self, $base, $url) = @_;
  $base ||= '';
  $url ||= '';
  # print STDERR " +   this is WWW::Search::absurl($base,$url)\n" if 1 < $self->{_debug};
  $base = $self->{_prev_url} if ($base eq '');
  return '' unless (($url ne '') && ($base ne ''));
  my $link = URI->new_abs($url, $base);
  return $link;
  } # absurl


=item retrieve_some

An internal routine to interface with C<_native_retrieve_some()>.
Checks for overflow.

=cut

sub retrieve_some
  {
  my $self = shift;
  print STDERR " FFF retrieve_some(", $self->{'native_query'}, ")\n" if (DEBUG_FUNC || $self->{_debug});
  return undef if ($self->{state} == SEARCH_DONE);
  $self->setup_search() if ($self->{state} == SEARCH_BEFORE);
  $self->{state} = SEARCH_RETRIEVING;
  if (! $self->{'_allow_empty_query'})
    {
    if (! defined($self->{'native_query'}))
      {
      $self->{response} = new HTTP::Response(500, "query string is not defined");
      $self->{state} = SEARCH_DONE;
      return;
      } # if
    if ($self->{'native_query'} eq '')
      {
      $self->{response} = new HTTP::Response(500, "query string is empty");
      $self->{state} = SEARCH_DONE;
      return;
      } # if
    } # if
  # Got enough already?
  if ($self->{number_retrieved} >= $self->{'maximum_to_retrieve'})
    {
    print STDERR " DDD retrieve_some() got enough already\n" if (DEBUG_RETR || $self->{_debug});
    $self->{state} = SEARCH_DONE;
    return;
    } # if
  # Spinning our wheels?
  if ($self->{requests_made} > $self->{'maximum_to_retrieve'})
    {
    print STDERR " DDD retrieve_some() too many requests\n" if (DEBUG_RETR || $self->{_debug});
    $self->{state} = SEARCH_DONE;
    return;
    } # if
  # Need more results:
  my $res = $self->_native_retrieve_some() || 0;
  print STDERR " +   _native_retrieve_some() returned $res\n" if (DEBUG_RETR || $self->{_debug});
  $self->{requests_made}++;
  $self->{number_retrieved} += $res;
  $self->{state} = SEARCH_DONE if ($res == 0);
  return $res;
  } # retrieve_some


sub HTML::TreeBuilder::www_search_reset
  {
  # If a reset() method becomes available in HTML::TreeBuilder, we
  # won't need this any more.
  my $self = shift;
  $self->delete;
  # These 4 lines copied from HTML::TreeBuilder::new
  $self->{'_head'} = $self->insert_element('head',1);
  $self->{'_pos'} = undef; # pull it back up
  $self->{'_body'} = $self->insert_element('body',1);
  $self->{'_pos'} = undef; # pull it back up again
  } # HTML::TreeBuilder::www_search_reset


=item _native_retrieve_some

Fetch the next page of results from the web engine, parse the results,
and prepare for the next page of results.

If a backend defines this method, it is in total control of the WWW
fetch, parsing, and preparing for the next page of results.  See the
WWW::Search::AltaVista module for example usage of the
_native_retrieve_some method.

An easier way to achieve this in a backend is to inherit
_native_retrieve_some from WWW::Search, and do only the HTML parsing.
Simply define a method _parse_tree which takes one argument, an
HTML::TreeBuilder object, and returns an integer, the number of
results found on this page.  See the WWW::Search::Yahoo module for
example usage of the _parse_tree method.

A backend should, in general, define either _parse_tree() or
_native_retrieve_some(), but not both.

Additional features of the default _native_retrieve_some method:

Sets $self->{_prev_url} to the URL of the page just retrieved.

Calls $self->preprocess_results_page() on the raw HTML of the page.

Then, parses the page with an HTML::TreeBuilder object and passes that
populated object to $self->_parse_tree().

Additional notes on using the _parse_tree method:

The built-in HTML::TreeBuilder object used to parse the page has
store_comments turned ON.  If a backend needs to use a subclassed or
modified HTML::TreeBuilder object, the backend should set
$self->{'_treebuilder'} to that object before any results are
retrieved.  The best place to do this is at the end of
_native_setup_search.

  my $oTree = new myTreeBuilder;
  $oTree->store_pis(1);  # for example
  $self->{'_treebuilder'} = $oTree;

When _parse_tree() is called, the $self->next_url is cleared.
During parsing, the backend should set $self->next_url to the appropriate URL for the next page of results.
(If _parse_tree() does not set the value, the search will end after parsing this page of results.)

When _parse_tree() is called, the URL for the page being parsed can be
found in $self->{_prev_url}.

=cut

sub _parse_tree
  {
  my $self = shift;
  # This is a NOP stub.  Backend MUST define their own parse function!
  print STDERR " FFF stub _parse_tree\n" if (DEBUG_FUNC || $self->{_debug});
  # This is for backward-compatibility, for backends that define the
  # old parse_tree(), but not the new _parse_tree():
  return $self->parse_tree(@_) if $self->can('parse_tree');
  return 0;
  } # _parse_tree


sub _native_retrieve_some
  {
  my $self = shift;
  if ($self->can('native_retrieve_some'))
    {
    # This is for backward-compatibility, for backends that define the
    # old native_retrieve_some(), but not the new
    # _native_retrieve_some():
    return $self->native_retrieve_some(@_);
    } # if
  print STDERR " FFF _n_r_s\n" if (DEBUG_FUNC || $self->{_debug});
  # Fast exit if already done:
  return if (!defined($self->{_next_url}));
  return if ($self->{_next_url} eq q{});
  # If this is not the first page of results, sleep so as to not
  # overload the server:
  $self->{_next_to_retrieve} ||= 1;
  $self->user_agent_delay if (
                              (1 < $self->{_next_to_retrieve})
                              ||
                              $self->need_to_delay
                             );
  # Get one page of results:
  print STDERR " +   submitting URL (", $self->{'_next_url'}, ")\n" if $self->{_debug};
  my $response = $self->http_request($self->http_method, $self->{'_next_url'});
  print STDERR " +     got response\n", $response->headers->as_string, "\n" if 2 <= $self->{_debug};
  $self->{_prev_url} = $self->{_next_url};
  # Assume there are no more results, unless we find out otherwise
  # when we parse the html:
  $self->{_next_url} = undef;
  $self->{response} = $response;
  # print STDERR " --- HTTP response is:\n", $response->as_string if 4 < $self->{_debug};
  if (! $response->is_success)
    {
    if ($self->{_debug})
      {
      print STDERR " --- HTTP request failed, response is:\n", $response->as_string;
      } # if
    return;
    } # if
  # Pre-process the output:
  my $sPage = $self->preprocess_results_page($response->content);
  # Parse the output:
  my $tree;
  if (ref $self->{'_treebuilder'})
    {
    # print STDERR " +   using existing _treebuilder\n" if 1 < $self->{_debug};
    # Assume that the backend has installed their own TreeBuilder
    $tree = $self->{'_treebuilder'};
    }
  else
    {
    # print STDERR " +   creating new _treebuilder\n" if 1 < $self->{_debug};
    $tree = HTML::TreeBuilder->new(
                                   # use all default options
                                  );
    $tree->store_comments('yes');
    $self->{'_treebuilder'} = $tree;
    }
  # If a reset() method becomes available in HTML::TreeBuilder, we can
  # change this:
  $tree->www_search_reset;
  # print STDERR " +   parsing content, tree is ", Dumper(\$tree) if 1 < $self->{_debug};
  # use Encode;
  # my $sPageOctets = Encode::encode_utf8($sPage);
  $tree->utf8_mode('true');
  $tree->parse($sPage);
  # print STDERR " +   done parsing content.\n" if 1 < $self->{_debug};
  $tree->eof();
  print STDERR " +   calling _parse_tree...\n" if (1 < $self->{_debug});
  return $self->_parse_tree($tree);
  } # _native_retrieve_some


=item result_as_HTML

Given a WWW::SearchResult object, formats it human-readable with HTML.

=cut

sub result_as_HTML
  {
  # print STDERR " DDD r_as_H(@_)\n";
  my $self = shift;
  my $oSR = shift or return '';
  return '' unless (ref($oSR) =~ m'WWW::Search(::)?Result');
  my $o = new CGI;
  return join('',
              $o->a(
                      { href => $oSR->url, },
                    $oSR->title,
                   ),
              $o->br,
              $oSR->description,
             );
  } # result_as_HTML


=item preprocess_results_page

A filter on the raw HTML of the results page.
This allows the backend to alter the HTML before it is parsed,
such as to correct for known problems, HTML that can not be parsed correctly, etc.

Takes one argument, a string (the HTML webpage);
returns one string (the same HTML, modified).

This method is called from within _native_retrieve_some (above)
before the HTML of the page is parsed.

See the WWW::Search::Ebay distribution 2.07 or higher for example
usage.

=cut

sub preprocess_results_page
  {
  # Here is just a stub.  Return our argument without modification.
  my $self = shift;
  return shift;
  } # preprocess_results_page


=item test_cases (DEPRECATED)

Deprecated.

Returns the value of the $TEST_CASES variable of the backend engine.

=cut

sub test_cases
  {
  my $self = shift;
  return eval '$'.ref($self).'::TEST_CASES';
  } # test_cases

=item hash_to_cgi_string (DEPRECATED)

Given a reference to a hash of string => string, constructs a CGI
parameter string that looks like 'key1=value1&key2=value2'.

If the value is undef, the key will not be added to the string.

At one time, for testing purposes, we asked backends to use this
function rather than piecing the URL together by hand, to ensure that
URLs are identical across platforms and software versions.  But this
is no longer necessary.

Example:

    $self->{_options} = {
                         'opt3' => 'val3',
                         'search_url' => 'http://www.deja.com/dnquery.xp',
                         'opt1' => 'val1',
                         'QRY' => $native_query,
                         'opt2' => 'val2',
                        };
    $self->{_next_url} = $self->{_options}{'search_url'} .'?'.
                         $self->hash_to_cgi_string($self->{_options});

=cut

sub hash_to_cgi_string
  {
  my $self = shift;
  # Because of the design of our test suite, we need our generated
  # URLs to be identical on all systems, all versions of perl.  Ergo
  # we must explicitly control the order in which our CGI parameter
  # strings are cobbled together.  For now, I assume sorting the hash
  # keys will suffice.
  my $rh = shift;
  my $ret = '';
  foreach my $key (sort keys %$rh)
    {
    # printf STDERR "option: $key is " . $rh->{$key} . "\n";
    next if generic_option($key);
    # Throw out keys with undef values.
    next unless defined($rh->{$key});
    # If we want to let the user delete options, uncomment the next
    # line. (They can still blank them out, which may or may not have
    # the same effect):
    # next unless $rh->{$key} ne '';
    $ret .= $key .'='. $rh->{$key} .'&';
    } # foreach $key
  # Remove the trailing '&':
  chop $ret;
  return $ret;
  } # hash_to_cgi_string


=back

=head1 IMPLEMENTING NEW BACKENDS

C<WWW::Search> supports backends to separate search engines.  Each
backend is implemented as a subclass of C<WWW::Search>.
L<WWW::Search::Yahoo> provides a good sample backend.

A backend must have the routine C<_native_setup_search()>.  A backend
must have the routine C<_native_retrieve_some()> or C<_parse_tree()>.

C<_native_setup_search()> is invoked before the search.  It is passed
a single argument: the escaped, native version of the query.

C<_native_retrieve_some()> is the core of a backend.  It will be called
periodically to fetch URLs.  It should retrieve several hits from the
search service and add them to the cache.  It should return the number
of hits found, or undef when there are no more hits.

Internally, C<_native_retrieve_some()> typically sends an HTTP request to
the search service, parses the HTML, extracts the links and
descriptions, then saves the URL for the next page of results.  See
the code for the C<WWW::Search::AltaVista> module for an example.

Alternatively, a backend can define the method C<_parse_tree()> instead
of C<_native_retrieve_some()>.  See the C<WWW::Search::Ebay> module for a
good example.

If you implement a new backend, please let the authors know.


=head1 BUGS AND DESIRED FEATURES

The bugs are there for you to find (some people call them Easter Eggs).

Desired features:

=over 4

=item A portable query language.

A portable language would easily allow you to move queries easily
between different search engines.  A query abstraction is non-trivial
and unfortunately will not be done any time soon by the current
maintainer.  If you want to take a shot at it, please let me know.

=back

=head1 AUTHOR

John Heidemann <johnh@isi.edu>
Maintained by Martin Thurn, C<mthurn@cpan.org>, L<http://www.sandcrawler.com/SWB/cpan-modules.html>.

=head1 COPYRIGHT

Copyright (c) 1996 University of Southern California.
All rights reserved.

Redistribution and use in source and binary forms are permitted
provided that the above copyright notice and this paragraph are
duplicated in all such forms and that any documentation, advertising
materials, and other materials related to such distribution and use
acknowledge that the software was developed by the University of
Southern California, Information Sciences Institute.  The name of the
University may not be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut


1;

__END__

