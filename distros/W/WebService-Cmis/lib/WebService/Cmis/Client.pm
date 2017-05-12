package WebService::Cmis::Client;

=head1 NAME

WebService::Cmis::Client - Transport layer

=head1 DESCRIPTION

A CMIS client is used to communicate with the document manangement server
by connecting to an exposed web service. It provides the initial access function
to the L<repositories|WebService::Cmis::Repository>.

A client may use one of the user agents to authenticate against the CMIS backend,
as specified by the =useragent= parameter during object construction. By default
a user agent will be used performing HTTP basic auth as a fallback implemented
by most CMIS servers.

Available user agents are:

=over 4

=item * L<WebService::Cmis::Agent::BasicAuth> (default)

=item * L<WebService::Cmis::Agent::TockenAuth> 

=item * L<WebService::Cmis::Agent::CookieAuth>

=back

  use Cache::FileCache ();

  my $client = WebService::Cmis::getClient(
      url => "http://cmis.alfresco.com/service/cmis",
      cache => new Cache::FileCache({
        cache_root => "/tmp/cmis_client"
      },
      useragent => new WebSercice::Cmis::Agent::BasicAuth(
        user => "...",
        password => "..."
      )
    )
  )
  
  my $repo = $client->getRepository;

Parent class: L<REST::Client>

=cut

use strict;
use warnings;

use WebService::Cmis qw(:namespaces :utils);
use WebService::Cmis::Repository ();
use WebService::Cmis::ClientException ();
use WebService::Cmis::ServerException ();
use XML::LibXML ();
use REST::Client ();
use Data::Dumper ();
use Storable ();
use Digest::MD5  ();
use Error qw(:try);
use URI ();

our @ISA = qw(REST::Client);

our $CMIS_XPATH_REPOSITORIES = new XML::LibXML::XPathExpression('./*[local-name()="service" and namespace-uri()="'.APP_NS.'"]/*[local-name()="workspace" and namespace-uri()="'.APP_NS.'"]');

=head1 METHODS

=over 4

=item new(%params)

Create a new WebService::Cmis::Client. This requires
a url of the webservice api, as well as a valid useragent handler.

See L<REST::Client> for more options.

Parameters:

=over 4

=item * useragent - handler to be used for authentication

  "WebService::Cmis::Agent::BasicAuth" (default)

=item * url - repository url; example:

  "http://localhost:8080/alfresco/service/cmis"

=item * cache - a Cache::Cache object to be used for caching

=item * overrideCacheContrib - boolean flag to ignore any http cache control for more aggressive caching

=back

=cut 

sub new {
  my ($class, %params) = @_;

  my $userAgent = delete $params{useragent};
  my $repositoryUrl = delete $params{url} || '';
  my $cache = delete $params{cache};
  my $overrideCacheControl = delete $params{overrideCacheControl};

  if (!defined $userAgent) {
    # default
    
    require WebService::Cmis::Agent::BasicAuth;
    $userAgent = new WebService::Cmis::Agent::BasicAuth();

  } elsif (!ref $userAgent) {
    # a scalar describing the user agent implementation

    my $agentClass = $userAgent;
    eval "use $agentClass";
    if ($@) {
      throw Error::Simple($@);
    }

    $userAgent = $agentClass->new();

  } elsif (!UNIVERSAL::can($userAgent, 'isa')) {
    # unblessed reference

    my %params = %$userAgent;
    my $agentClass = delete $params{impl} || "WebService::Cmis::Agent::BasicAuth";
    #print STDERR "agentClass=$agentClass\n";
    eval "use $agentClass";
    if ($@) {
      throw Error::Simple($@);
    }

    $userAgent = $agentClass->new(%params);

  } else {
    # some class to be used as a user agent as is
  }

  $params{useragent} = $userAgent;
  _writeCmisDebug("userAgent=$userAgent");

  my $this = $class->SUPER::new(%params);

  $this->{cache} = $cache;
  $this->{overrideCacheControl} = $overrideCacheControl;
  $this->{repositoryUrl} = $repositoryUrl;
  $this->{_cacheHits} = 0;

  $this->setFollow(1);
  $this->setUseragent($userAgent); 
  $this->getUseragent()->env_proxy();

  return $this;
}

sub DESTROY {
  my $this = shift;

  my $ua = $this->getUseragent;
  $ua->{client} = undef if defined $ua; # break cyclic links
  _writeCmisDebug($this->{_cacheHits}." cache hits found") if $this->{cache};
  $this->_init;
}


sub _init {
  my $this = shift;

  $this->{_res} = undef;
  $this->{_cacheEntry} = undef;
  $this->{_cacheHits} = undef;
  $this->{repositories} = undef;
  $this->{defaultRepository} = undef;
}

=item setUseragent($userAgent)

setter to assert the user agent to be used in the REST::Client

=cut

sub setUseragent {
  my ($this, $userAgent) = @_;

  $this->SUPER::setUseragent($userAgent);
  $userAgent->{client} = $this if defined $userAgent;
}

=item toString

return a string representation of this client

=cut

sub toString {
  my $this = shift;
  return "CMIS client connection to $this->{repositoryUrl}";
}

# parse a resonse coming from alfresco
sub _parseResponse {
  my $this = shift;

  #_writeCmisDebug("called _parseResponse");

  #print STDERR "response=".Data::Dumper->Dump([$this->{_res}])."\n";
  my $content = $this->responseContent;
  #_writeCmisDebug("content=$content");

  unless ($this->{xmlParser}) {
    $this->{xmlParser} = XML::LibXML->new;
  }

  return if !defined $content || $content eq '';
  return $this->{xmlParser}->parse_string($content);
}

=item clearCache

nukes all of the cache. calling this method is sometimes required
to work around caching effects.

=cut

sub clearCache {
  my $this = shift;
  my $cache = $this->{cache};
  return unless defined $cache;

  _writeCmisDebug("clearing cache");
  return $cache->clear(@_);
}

=item purgeCache

purges outdated cache entries. call this method in case the
cache backend is able to do a kind of house keeping.

=cut

sub purgeCache {
  my $this = shift;
  my $cache = $this->{cache};
  return unless defined $cache;

  return $cache->purge(@_);
}

=item removeFromCache($path, %params)

removes an item from the cache associated with the given path
and url parameters

=cut

sub removeFromCache {
  my $this = shift;
  my $path = shift;

  my $uri = _getUri($path, @_);
  _writeCmisDebug("removing from cache $uri");
  return $this->_cacheRemove($uri);
}

# internal cache layer
sub _cacheGet {
  my $this = shift;
  my $cache = $this->{cache};
  return unless defined $cache;

  my $key = $this->_cacheKey(shift);
  my $val = $cache->get($key, @_);
  return unless $val;
  return ${Storable::thaw($val)};
}

sub _cacheSet {
  my $this = shift;
  my $cache = $this->{cache};
  return unless defined $cache;

  my $key = $this->_cacheKey(shift);
  my $val = shift;
  $val = Storable::freeze(\$val);
  return $cache->set($key, $val, @_);
}

sub _cacheRemove {
  my $this = shift;
  my $cache = $this->{cache};
  return unless defined $cache;

  my $key = $this->_cacheKey(shift);
  return $cache->remove($key, @_);
}

sub _cacheKey {
  my $this = shift;
  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Sortkeys = 1;

  my $agent = $this->getUseragent;
  my $user = $agent->{user} || 'guest';

  # cache per user as data must not leak between users via the cache
  return _untaint(Digest::MD5::md5_hex(Data::Dumper::Dumper($_[0]).'::'.$user)); 
}

=item get($path, %params) 

does a get against the CMIS service. More than likely, you will not
need to call this method. Instead, let the other objects to it for you.

=cut

sub get {
  my $this = shift;
  my $path = shift;

  my $url;
  if ($path) {
    $path =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus port
    if ($path =~ /^http/) {
      $url = $path;
    } else {
      $path =~ s/^\///g;
      $url = $this->{repositoryUrl};
      $url .= '/'.$path;
    }
  } else {
    $url = $this->{repositoryUrl};
  }

  my $uri = _getUri($url, @_);
  _writeCmisDebug("called get($uri)");

  # do it
  $this->GET($uri);

  #_writeCmisDebug("content=".$this->responseContent);

  my $code = $this->responseCode;

  return $this->_parseResponse if $code >= 200 && $code < 300;
  $this->processErrors;
}

sub _getUri {
  my $url = shift;

  my $uri = new URI($url);
  my %queryParams = ($uri->query_form, @_);
  $uri->query_form(%queryParams);

  return $uri;
}

=item request ( $method, $url, [$body_content, %$headers] )

add a cache layer on top of all network connections of the rest client

=cut

sub request {
  my $this = shift;
  my $method = shift;
  my $url = shift;

  if($this->{_cacheEntry} = $this->_cacheGet($url)) {
    _writeCmisDebug("found in cache: $url");
    $this->{_cacheHits}++;
    return $this;
  }
  #_writeCmisDebug("request url=$url");

  my $result = $this->SUPER::request($method, $url, @_);

  # untaint
  $this->{_res}->content(_untaint($this->{_res}->content));
  $this->{_res}->code(_untaint($this->{_res}->code));
  $this->{_res}->status_line(_untaint($this->{_res}->status_line));

  my $code = $this->responseCode;
  
  my $cacheControl = $this->{_res}->header("Cache-Control") || '';
  #_writeCmisDebug("cacheControl = $cacheControl");
  $cacheControl = '' if $this->{overrideCacheControl};
  if ($cacheControl ne 'no-cache' && $code >= 200 && $code < 300 && $this->{cache}) {
    my $cacheEntry = {
      content => $this->{_res}->content,
      code => $this->{_res}->code,
      status_line => $this->{_res}->status_line,
      base => $this->{_res}->base,
    };
    $this->_cacheSet($url, $cacheEntry);
  }

  return $result;
}

=item responseContent

returns the full content of a response

=cut

sub responseContent {
  my $this = shift;

  return $this->{_cacheEntry}{content} if $this->{_cacheEntry};
  return $this->{_res}->content;
}

=item responseCode

returns the HTTP status code of the repsonse

=cut

sub responseCode {
  my $this = shift;

  return $this->{_cacheEntry}{code} if $this->{_cacheEntry};
  return $this->{_res}->code;
}

=item responseStatusLine

returns the "code message" of the response. (See HTTP::Status)

=cut

sub responseStatusLine {
  my $this = shift;

  return $this->{_cacheEntry}{status_line} if $this->{_cacheEntry};
  return $this->{_res}->status_line;
}

=item responseBase -> $uri

returns the base uri for this response

=cut

sub responseBase {
  my $this = shift;
  return $this->{_cacheEntry}{base} if $this->{_cacheEntry};
  return $this->{_res}->base;
}

sub _untaint {
  my $content = shift;
  if (defined $content && $content =~ /^(.*)$/s) {
    $content = $1;
  }
  return $content;
}

=item post($path, $payload, $contentType, %params) 

does a post against the CMIS service. More than likely, you will not
need to call this method. Instead, let the other objects to it for you.

=cut

sub post {
  my $this = shift;
  my $path = shift;
  my $payload = shift;
  my $contentType = shift;
  my %params = @_;

  $path =~ s/^\///g;

  my $url;
  if ($path) {
    $path =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus port
    if ($path =~ /^$this->{repositoryUrl}/) {
      $url = $path;
    } else {
      $path =~ s/^\///g;
      $url = $this->{repositoryUrl};
      $url .= '/'.$path;
    }
  } else {
    $url = $this->{repositoryUrl};
  }

  _writeCmisDebug("called post($url)");
  $params{"Content-Type"} = $contentType;

#  if ($ENV{CMIS_DEBUG}) {
#    _writeCmisDebug("post params:\n   * ".join("\n   * ", map {"$_=$params{$_}"} keys %params));
#  }

  # do it
  $this->POST($url, $payload, \%params);

  # auto clear the cache
  $this->clearCache;

  my $code = $this->responseCode;
  return $this->_parseResponse if $code >= 200 && $code < 300;
  $this->processErrors;
}

=item put($path, $payload, $contentType, %params) 

does a put against the CMIS service. More than likely, you will not
need to call this method. Instead, let the other objects to it for you.

=cut

sub put {
  my $this = shift;
  my $path = shift;
  my $payload = shift;
  my $contentType = shift;

  $path =~ s/^\///g;

  my $url;
  if ($path) {
    $path =~ s/^(http:\/\/[^\/]+?):80\//$1\//g; # remove bogus port
    if ($path =~ /^$this->{repositoryUrl}/) {
      $url = $path;
    } else {
      $path =~ s/^\///g;
      $url = $this->{repositoryUrl};
      $url .= '/'.$path;
    }
  } else {
    $url = $this->{repositoryUrl};
  }

  my $uri = _getUri($url, @_);
  _writeCmisDebug("called put($uri)");
  _writeCmisDebug("contentType: ".$contentType);
  #_writeCmisDebug("payload: ".$payload);

  # auto clear the cache
  $this->clearCache;

  # do it
  $this->PUT($uri, $payload,  {"Content-Type"=>$contentType});

  my $code = $this->responseCode;
  return $this->_parseResponse if $code >= 200 && $code < 300;
  $this->processErrors;
}

=item delete($url, %params)

does a delete against the CMIS service. More than likely, you will not
need to call this method. Instead, let the other objects to it for you.

=cut

sub delete {
  my $this = shift;
  my $url = shift;

  my $uri = _getUri($url, @_);
  _writeCmisDebug("called delete($uri)");

  $this->DELETE($uri);

  # auto clear the cache
  $this->clearCache;

  my $code = $this->responseCode;
  return $this->_parseResponse if $code >= 200 && $code < 300;
  $this->processErrors;
}

=item processErrors 

throws a client or a server exception based on the http error code
of the last transaction.

=cut

sub processErrors {
  my $this = shift;

  my $code = $this->responseCode;

  if ($ENV{CMIS_DEBUG}) {
    _writeCmisDebug("processError($code)");
    _writeCmisDebug($this->responseContent);
  }

  #print STDERR "header:".$this->{_res}->as_string()."\n";

  if ($code >= 400 && $code < 500) {
    # SMELL: there's no standardized way of reporting the error properly
    my $reason = $this->{_res}->header("Title");
    $reason = $this->responseStatusLine . ' - ' . $reason if defined $reason;
    throw WebService::Cmis::ClientException($this, $reason);
  }

  if ($code >= 500) {
    throw WebService::Cmis::ServerException($this);
  }

  # default
  throw Error::Simple("unknown client error $code: ".$this->responseStatusLine);
}

=item getRepositories() -> %repositories;

returns a hash of L<WebService::Cmis::Repository> objects available at this
service. 

=cut

sub getRepositories {
  my $this = shift;

  _writeCmisDebug("called getRepositories");

  unless (defined $this->{repositories}) {
    $this->{repositories} = ();

    my $doc = $this->get;
    if (defined $doc) {
      foreach my $node ($doc->findnodes($CMIS_XPATH_REPOSITORIES)) {
        my $repo = new WebService::Cmis::Repository($this, $node);
        $this->{repositories}{$repo->getRepositoryId} = $repo;

        #SMELL: not covered by the specs, might need a search which one actually is the default one
        $this->{defaultRepository} = $repo unless defined $this->{defaultRepository};
      }
    }
  }

  return $this->{repositories};
}

=item getRepository($id) -> L<$repository|WebService::Cmis::Repository>

returns a WebService::Cmis::Repository of the given ID. if
ID is undefined the default repository will be returned.

=cut

sub getRepository {
  my ($this, $id) = @_;

  $this->getRepositories;
  return $this->{defaultRepository} unless defined $id;
  return $this->{repositories}{$id};
}

=item getCacheHits() -> $num

returns the number of times a result has been fetched from the cache
instead of accessing the CMIS backend. returns undefined when no cache
is configured

=cut

sub getCacheHits {
  my $this = shift;

  return unless defined $this->{cache};
  return $this->{_cacheHits};
}

=item login(%params) -> $ticket

Logs in to the web service. returns an identifier for the internal state
of the user agent that may be used to login again later on.

  my $ticket = $client->login(
    user=> $user, 
    password => $password
  );

  $client->login(
    user => $user,
    ticket => $ticket
  );

=cut

sub login {
  my $this = shift;
  return $this->getUseragent->login(@_);
}

=item logout() 

Logs out of the web service invalidating a stored state within the auth handler.

=cut

sub logout {
  my $this = shift;

  my $userAgent = $this->getUseragent;
  $userAgent->logout(@_) if $userAgent;
  $this->setUseragent;
  $this->_init;
}


=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
