
require 5;
package XML::RSS::TimingBot;         # Time-stamp: "2004-05-19 12:50:53 ADT"
use      LWP::UserAgent::Determined ();
@ISA = ('LWP::UserAgent::Determined');

use strict;
use vars qw($VERSION);
$VERSION = '2.03';

use LWP::Debug ();
use XML::RSS::Timing ();

BEGIN { *DEBUG = sub () {0} unless defined &DEBUG }

die "Where's _elem?!!?" unless __PACKAGE__->can('_elem');
#--------------------------------------------------------------------------
# Some incidental accessors:
sub minAge { shift->_elem( 'minAge' , @_) }
sub maxAge { shift->_elem( 'maxAge' , @_) }
sub min_age { shift->minAge(@_) } #alias
sub max_age { shift->maxAge(@_) } #alias

sub rss_semaphore_file { shift->_elem( 'rss_semaphore_file' , @_) }

#==========================================================================

sub feed_get_last_modified {
  # This is not an epochtime, it's a string that we probably got
  #  from the remote server.
  # As says RFC2616 section 14.25 : <<
  #	Note: When handling an If-Modified-Since header field, some
  #	servers will use an exact date comparison function, rather than a
  #	less-than function, for deciding whether to send a 304 (Not
  #	Modified) response. To get best results when sending an If-
  #	Modified-Since header field for cache validation, clients are
  #	advised to use the exact date string received in a previous Last-
  #	Modified header field whenever possible.
  #   >> (among many other wise things)
  # Example value: "Sun, 04 Apr 2004 11:58:04 GMT"

  my($self, $url) = @_;
  DEBUG and print "Getting lastmod value for $url ...\n";
  return $self->get_datum($url, 'lastmodified');
}

sub feed_get_next_update {  # this is an epochtime
  my($self, $url) = @_;
  DEBUG and print "Getting next-update value for $url ...\n";
  return $self->get_datum($url, 'nextupdate');
}

sub feed_get_etag {  # this is a string
  # See RFC 2616, "3.11 Entity Tags"
  my($self, $url) = @_;
  DEBUG and print "Getting etag value for $url ...\n";
  return $self->get_datum($url, 'etag');
}

sub feed_set_last_modified { 
  my($self, $url, $last_modified_time) = @_;
  DEBUG and print "Setting lastmod for $url to $last_modified_time\n";
  $self->set_datum($url, 'lastmodified', $last_modified_time);
}

sub feed_set_next_update {
  my($self, $url, $next_update_time) = @_;
  DEBUG and print "Setting next-update for $url to $next_update_time\n";
  $self->set_datum($url, 'nextupdate', $next_update_time);
}

sub feed_set_etag {
  my($self, $url, $etag) = @_;
  DEBUG and print "Setting etag for $url to $etag\n";
  $self->set_datum($url, 'etag', $etag);
}

#--------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->_rssagent_init();
  return $self;
}

sub _rssagent_init {
  my $self = shift;
  $self->agent("XmlRssTimingBot/$VERSION (" . $self->agent . ")" );
  
  $self->rss_semaphore_file(1) unless $^O =~ m/(?:Mac|MSWin)/;

  # Whatever needs doing here
  return;
}

#==========================================================================

sub commit {  # save all our new data for these various feeds we've been seeing
  my $self = shift;
  return $self->_stupid_commit;
}

sub datum_from_db {
  my($self, $url, $varname) = @_;
  return $self->_stupid_datum_from_db($url, $varname);
}

#==========================================================================

sub rssagent_just_before_real_request {   # Override if you like
  #my($self, $args_ref) = @_;
}
sub rssagent_just_after_real_request {    # Override if you like
  #my($self, $response, $args_ref) = @_;
}

#==========================================================================

sub simple_request {
  my($self, @args) = @_;
  LWP::Debug::trace('simple_request()');

  LWP::Debug::debug("Trying simple_request with args: ["
    . join(',', map $_||"''", @args) . "]");

  DEBUG and print(  "Trying simple_request with args: ["
    . join(',', map $_||"''", @args) . "]");

  my $resp;
  my $maybe_response = $self->_rssagent_maybe_null_response($args[0]);
  if( $maybe_response ) {
    LWP::Debug::debug("Returning cached response");
    return $maybe_response;
  }

  $self->           _rssagent_add_header_conditions(@args);
    $self->       rssagent_just_before_real_request(\@args);
       $resp = $self->SUPER::simple_request(@args);
    $self->       rssagent_just_after_real_request($resp, \@args);
  $self->           _rssagent_response_consider($resp);

  LWP::Debug::debug("Returning uncached response");
  return $resp;
}

#==========================================================================

sub _rssagent_maybe_null_response {
  # Return a (virtual) response object if you want to block this request.
  # Otherwise, to allow this request to actually happen, return a false value.

  my($self, $req) = @_;
  LWP::Debug::trace('_rssagent_maybe_null_response()');
  my $url = $req->uri;

  my $not_until = $self->feed_get_next_update($url);
  unless(defined $not_until) {
    LWP::Debug::debug(  "No restrictions on when to get $url");
    DEBUG > 1 and print "No restrictions on when to get $url\n";
    return undef;
  }

  my $now = $self->now;
  if($not_until >= $now) {
    LWP::Debug::debug(  "It's now $now, but I shouldn't look at $url until $not_until.");
    DEBUG > 1 and print "It's now $now, but I shouldn't look at $url until $not_until.\n";
    return $self->_rss_agent_null_response($req, $not_until);
  }

  # Else give the all-clear
  return undef;
}

#==========================================================================

sub _rssagent_response_consider {
  my($self, $response) = @_;
  # Possibly extract the RSS-timing content from this response.

  LWP::Debug::trace('_maybe_null_response()');
  my $code = $response->code;
  unless($code eq '200') {  #  or $code eq '304' ?
    LWP::Debug::debug('Not trying to find RSS content in this $code response');
    return;
  }

  my $url = $self->_url_from_response( $response );

  return unless $self->_looks_like_rss( $url, $response );

  my $now = $self->now();

  my $time_string_from_resp = $self->_time_string_from_resp($response, $now);
  $self->feed_set_last_modified($url, $time_string_from_resp)
   if defined $time_string_from_resp;
  
  my $etag = $self->_etag_from_resp($response);
  $self->feed_set_etag($url, $etag) if defined $etag;
  
  $self->_ponder_next_update($url, $now, $response) unless $code eq '304';
  return;
}

#==========================================================================

sub _looks_like_rss {
  my($self, $url, $response) = @_;
  LWP::Debug::trace('_ponder_next_update');
  my $content;

  # Look for rss/rdf in the first 2000 bytes
  #  TODO: support Atom here?  Does anyone ever use sy:* stuff in Atom?

  my $c = $response->content_ref;
  unless( $c and $$c ) {
    LWP::Debug::debug("Content from $url is apparently null.");
    print "NULL!\n";
     # so it's sure not RSS!
    return 0;
  }

  if ( $$c =~ m{^[^\x00]{0,2000}?(?:<rss|<rdf)}s ) {
    LWP::Debug::debug("Content from $url looks like RSS/RDF.");
    return 1;
  }
    
  LWP::Debug::debug("Content from $url doesn't look like RSS/RDF.");
  return 0;
}

#==========================================================================

sub _ponder_next_update {
  my($self, $url, $now, $response) = @_;
  LWP::Debug::trace('_ponder_next_update');
  my $content = $response->content;
  $content =~ s/<!--.*?-->//sg; # kill XML comments

  unless( $content =~ m{^[^\x00]{0,2000}?<rss|<rdf}s ) {
    # Make super-sure that the our apparent start-tag wasn't just in a comment!
    LWP::Debug::debug("Content from $url doesn't look like RSS/RDF.");
    return;
  }
  
  my $timing = $self->{"_rss_timing_obj"} || XML::RSS::Timing->new;
  $timing->use_exceptions(0);
  $timing->minAge( $self->minAge ) if defined $self->minAge;
  $timing->maxAge( $self->maxAge ) if defined $self->maxAge;

  # Note that we use our server-time, not the other server's time
  $timing->last_polled($now);
  
  $self->_scan_xml_timing(\$content, $timing);

  if( $timing->complaints ) {
    LWP::Debug::debug("Errors in this feed's timing fields:\n"
      . map("* $_\n", $timing->complaints)
      . "]... so ignoring it all.\n"
    );
    return;
  }

  # Now actually learn...
  my $next_update = $timing->nextUpdate();
  LWP::Debug::debug("Remembering not to poll $url until $next_update");
  $self->feed_set_next_update( $url, $next_update );
   # Now, we /could/ also slip this into the response as a faked-out
   # "Expires" header value, except that 1) who the hell ever looks at
   # those, and 2) "Expires" is the expiration time expressed against
   # the REMOTE server's clock, whereas nextUpdate is expressed
   # against OUR clock.  So mixing these up would screw up all kinds of
   # things in the unhappy event of clock skew combined with someone
   # actually looking at a fake-o Expires value.

  return;
}

#==========================================================================

sub _scan_xml_timing {
  my($self, $contentref, $timingobj) = @_;
  return unless $contentref and $$contentref;
  DEBUG > 1 and print "# _scan_xml_timing << self <$self>; contentref <$contentref>; timingobj <$timingobj>\n";
  $self->_scan_for_ttl(             $contentref, $timingobj );
  $self->_scan_for_skipDays(        $contentref, $timingobj );
  $self->_scan_for_skipHours(       $contentref, $timingobj );
  $self->_scan_for_updatePeriod(    $contentref, $timingobj );
  $self->_scan_for_updateFrequency( $contentref, $timingobj );
  $self->_scan_for_updateBase(      $contentref, $timingobj );
  return;
}

sub _scan_for_updateFrequency {my($s,$c,$t)=@_;$s->_scan_xml('updateFrequency', $c, $t) }
sub _scan_for_updatePeriod    {my($s,$c,$t)=@_;$s->_scan_xml('updatePeriod',    $c, $t) }
sub _scan_for_updateBase      {my($s,$c,$t)=@_;$s->_scan_xml('updateBase',      $c, $t) }
sub _scan_for_ttl             {my($s,$c,$t)=@_;$s->_scan_xml('ttl',             $c, $t) }
sub _scan_for_skipDays        {my($s,$c,$t)=@_;$s->_scan_xml('skipDays' , $c, $t, 'day' ) }
sub _scan_for_skipHours       {my($s,$c,$t)=@_;$s->_scan_xml('skipHours', $c, $t, 'hour') }

#==========================================================================

sub _etag_from_resp {
  my($self, $response) = @_;
  my $etag = $response->header('ETag');
  return undef unless defined $etag
    and length($etag)
    and length($etag) < 251 # A good sanity limit, I think
    and $etag !~ m/[\n\r]/  # Enforce this minimal sanity on content
  ;
  DEBUG and print "Using etag $etag for resp-obj $response\'s etag\n";
  return $etag;
}

sub _time_string_from_resp {
  my($self, $response, $now) = @_;
  require HTTP::Date;
  foreach my $time_string ( 
    $response->header('Last-Modified'),
    $response->header('Date'),
    HTTP::Date::time2str( $now ),
  ) {
    next unless   # enforce minimal sanity on the value...
      defined $time_string
      and $time_string =~ m/^[- \,\.\:a-zA-Z0-9]{4,40}$/s
      and $time_string =~ m/[0-9A-Za-z]/;
    DEBUG and print "Using time-string \"$time_string\" for resp-obj $response\'s lastmod\n";
    return $time_string;
  }
  return undef;
}

#==========================================================================

sub _url_from_response {
  my($self, $response) = @_;

  my $this_res = $response;
  for(1 .. 30) { # get the original request's URL
    $this_res = ($this_res->previous || last);
  }
  return $this_res->request->uri;
}

#==========================================================================

sub _rssagent_add_header_conditions {
  my $self = shift;
  $self->_rssagent_add_ifmod_header(@_);
  $self->_rssagent_add_ifnonematch_header(@_);
  return;
}

sub _rssagent_add_ifmod_header {
  my($self, $req) = @_;  
  LWP::Debug::trace('_rssagent_add_ifmod_header()');
  my $url = $req->uri;

  my $lastmod = $self->feed_get_last_modified( $url );

  if(defined $lastmod and length $lastmod) {
    LWP::Debug::debug("Setting If-Modified-Since on get-$url to $lastmod");
    DEBUG and print   "Setting If-Modified-Since on get-$url to $lastmod\n";
    $req->header('If-Modified-Since' => $lastmod);
  } else {
    LWP::Debug::debug("I see no last-polled time for $url");
    DEBUG and print   "I see no last-polled time for $url\n";
  }
  return;
}

sub _rssagent_add_ifnonematch_header {
  my($self, $req) = @_;  
  LWP::Debug::trace('_rssagent_add_ifnonematch_header()');
  my $url = $req->uri;

  my $etag = $self->feed_get_etag( $url );

  if(defined $etag and length $etag) {
    LWP::Debug::debug("Setting If-None-Match on get-$url to $etag");
    DEBUG and print   "Setting If-None-Match on get-$url to $etag\n";
    $req->header('If-None-Match' => $etag);
  } else {
    LWP::Debug::debug("I see no etag for $url");
    DEBUG and print   "I see no etag for $url\n";
  }
  return;
}

#==========================================================================

sub _rss_agent_null_response {
  my($self, $request, $not_until) = @_;
  require HTTP::Response;
  require HTTP::Date;
  require HTTP::Status;

  my $now_str       = HTTP::Date::time2str( $self->now );
  my $not_until_str = HTTP::Date::time2str( $not_until - 1);
   # The -1 is because "Expires" means the last moment when it's still
   #  good, and not_until is the first moment when we can check.  Q.E.D.
  
  my $response = HTTP::Response->new(
    HTTP::Status::RC_NOT_MODIFIED() => "Not Modified (" . __PACKAGE__
     . " says it won't change until after $not_until_str)"
  );
  my $h = $response->headers;
  $h->header( "Client-Date" => $now_str);
  $h->header(        "Date" => $now_str);
  $h->header(     "Expires" => $not_until_str);
  $response->request($request);

  return $response;
}

#==========================================================================

sub now {
  # This is here just so we can change what we mean by 'now', when we're
  #  running tests.  Trust me, it's handy.
  return $_[0]->{'_now_hack'} if ref $_[0] and defined $_[0]->{'_now_hack'};
  return time();
}

###########################################################################
#
# get_datum and set_datum implement the caching that both speeds things up
#  and allows a layer of indirection so that changes don't happen until
#  we commit

sub get_datum {
  my($self, $url, $varname) = @_;
  $url =~ s{\s+}{}g;
  return unless length $url;

  # First look in our dirty cache
  my $for_db = ($self->{'rsstimingbot_for_db'} ||= {});
  if( $for_db->{$url} and exists $for_db->{$url}{$varname} ) {
    DEBUG > 6 and print "  Found  $varname for $url in dirty cache\n";
    return $for_db->{$url}{$varname};
  }

  # then look in our has-been-read-from-disk cache
  my $from_db = ($self->{'rsstimingbot_from_db'} ||= {});
  if( $from_db->{$url} and exists $from_db->{$url}{$varname} ) {
    DEBUG > 6 and print "  Found  $varname for $url in clean cache\n";
    return $from_db->{$url}{$varname};
  }

  # and finally, as a last resort, actually fetch from the real DB
  return(
   $from_db->{$url}{$varname} = $self->datum_from_db($url, $varname)
  );
}

sub set_datum {
  my($self, $url, $varname, $value) = @_;
  $url =~ s{\s+}{}g;
  return unless length $url;
  $self->{'rsstimingbot_from_db'  }{$url}{$varname}
   = $self->{'rsstimingbot_for_db'}{$url}{$varname}
   = $value;
   # And upon commit, we'll save all of 'rsstimingbot_for_db' to database
}

###########################################################################
#
# Our lame default storage methods, in case you didn't override
#  commit and datum_from_db

sub _stupid_datum_from_db {
  my($self, $url, $varname) = @_;
  my $dbfile = $self->_stupid___url2dbfile($url);
  DEBUG > 1 and print " DB: Getting datum $varname for $url ...\n";

  return undef unless -e $dbfile;

  my $unlocker = $self->_stupid_lock();

  open( STUPID_DB, $dbfile)
   or die "Can't read-open $dbfile for $url : $!\nAborting";
  my @f;
  local $/ = "\n";
  my $from_db = ($self->{'rsstimingbot_from_db'} ||= {});
  DEBUG > 8 and print "   Reading DB file $dbfile...\n";
  while(<STUPID_DB>) {
    chomp;
    @f = split ' ', $_, 3; 
     # Yup, just three space-separated fields:  "url varname value"
    if( @f >= 2 ) {
      DEBUG > 9 and print "      Datum read {$f[0]} {$f[1]} {$f[2]}\n";
      $from_db->{ $f[0] }->{ $f[1] } =
        defined($f[2]) ? $f[2] : "";  # because of split's behavior
    }
  }
  close(STUPID_DB);
  $unlocker and $unlocker->();
  DEBUG > 8 and print "   Done reading DB file $dbfile\n";
  
  return $from_db->{$url}{$varname}
   if $from_db->{$url} and exists $from_db->{$url}{$varname};
  return undef;
}

# See XML::RSS::TimingBotDBI for a better example of a commit method

sub _stupid_commit {  # write all our dirty cache to DB files
  my $self = shift;
  my $for_db = $self->{'rsstimingbot_for_db'} || return;
  DEBUG > 1 and print " I see ", scalar(keys %$for_db), " url-data in $self to save\n";
  return unless %$for_db;
  
  my %path2mods;
  foreach my $url (sort keys %$for_db) {
    my $dbfile = $self->_stupid___url2dbfile($url);
    foreach my $varname (sort keys %{ $for_db->{$url} }) {
      my $value = $for_db->{$url}{$varname};
      $path2mods{$dbfile}{ "$url $varname" } = defined($value) ? $value : '';
    }
  }
  DEBUG > 7 and print "  Committing to ", scalar(keys %path2mods),
   " database files...\n";

  my $unlocker = $self->_stupid_lock();

  foreach my $dbfile (keys %path2mods) {
    $self->_stupid___mod_db( $dbfile, $path2mods{$dbfile} );
    $path2mods{$dbfile} = undef;  # potentially free up some memory
  }
  DEBUG > 7 and print "  Done committing all database files\n";

  $unlocker and $unlocker->();
  %$for_db = ();
  return;
}

#
#  And now some very internal stuff:
#

sub _stupid_lock {
  my $self = shift;
  my $file = $self->rss_semaphore_file;
  return unless $file;

  $file = $self->_stupid___url2dbfile("http://lock.nowhere.int/lock")
   if $file eq '1';

  DEBUG > 2 and
   print "About to request (maybe wait for!) an exclusive lock on $file\n";

  return $self->_getsem($file);
}


sub _stupid___my_db_path  {
  my $self = shift;
  return $self->{'_dbpath'}
   || $ENV{'TIMINGBOTPATH'}
   || $ENV{'APPDATA'}
   || $ENV{'HOME'}
   || do { require File::Spec; File::Spec->curdir; }
}

sub _stupid___url2dbfile {
  my($self, $url) = @_;
  require File::Spec;
  DEBUG > 2 and print "  Pondering filespec for url $url\n";
  my $url_stem = lc $url;
  $url_stem =~ s{^http://(?:www\.)?}{}s;
  $url_stem =~ s{\.(?:xml|rss|rdf)$}{}s;
  $url_stem =~ s/\W+//sg; # includes killing all whitespace
  $url_stem = 'misc' unless length $url_stem;
  $url_stem = substr($url_stem,0,30) if length($url) > 30; # truncate
  
  my $rssdir  = File::Spec->catfile( $self->_stupid___my_db_path, 'rssdata');
  if( -e $rssdir ) {
    DEBUG > 12 and print "  RSSdir $rssdir exists already.\n";
  } else {
    if( mkdir($rssdir, 0777) ) {
      DEBUG > 1 and print "  Successfully created RSSdir $rssdir\n";
    } else {
      die "Can't mkdir $rssdir: $!\nAborting";
    }
  }
  my $path = File::Spec->catfile( $rssdir, $url_stem );
  DEBUG > 6 and print "#   Path to stupid DB: $path\n";
  return $path;
}

#  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .

sub _stupid___mod_db {
  my($self, $dbfile, $to_write) = @_;

  if( -e $dbfile and -s _ ) {
    DEBUG > 9 and print "Reading db $dbfile ...\n";
    open( STUPID_DB, $dbfile)
     or die "Can't read-open $dbfile : $!\nAborting";
    my @f;
    local $/ = "\n";
    while(<STUPID_DB>) {
      chomp;
      @f = split ' ', $_, 3;  # yup, just three space-separated fields
      $to_write->{ "$f[0] $f[1]" } = defined($f[2]) ? $f[2] : ""
        if @f >= 2 and ! exists $to_write->{ "$f[0] $f[1]" };
    }
    close(STUPID_DB);
  } else {
    DEBUG > 9 and print "No db $dbfile to read, so just writing new.\n";
  }

  DEBUG > 8 and print "   Saving DB file $dbfile (", scalar(keys %$to_write), " entries)\n";

  open( STUPID_DB, ">$dbfile" ) or die "Can't write-open $dbfile: $!\nAborting";
  my $value;
  foreach my $key (sort keys %$to_write) {
    next unless defined( $value = $to_write->{$key} );
    $value =~ tr/\n\r//d;  # Enforce sanity
    print STUPID_DB "$key $value\n";
  }
  close(STUPID_DB);
  DEBUG > 8 and print "   Done saving DB file $dbfile\n";
  return;
}

############################################################################

sub _getsem {
  my($self, $file, $be_nonblocking) = @_;
  # Lock this semaphore file.  Returns the unlocker sub!!
  #
  # To have the lock be non-blocking, specify a true second parameter.
  # In that case, returns false if can't get the lock.  Unlocker
  # sub otherwise.
  
  unless(defined $file and length $file) {
    require Carp;  
    Carp::confess("Filename argument to _getsem must be contentful!")
  }
   
  open(my $fh, ">$file") or Carp::croak("Can't write-open $file\: $!");
  #chmod 0666, $file; # yes, make it world-writeable.  or at least try.
  
  if($be_nonblocking) { # non-blocking!
    eval { flock($fh, 2 | 4) } # Exclusive + NONblocking
      or return; # couldn't get a lock.
  } else { # normal case: Exclusive, Blocking
    eval { flock($fh, 2) } # Exclusive
     or do { require Carp; Carp::confess("Can't exclusive-block lock $file: $!") };
     # should never just fail -- should queue up forever
  }
  
  unless( print $fh "I am a lowly " , __PACKAGE__ , " semaphore file\cm\cj" ) {
    require Carp;
    Carp::confess("Can't write to $file\: $!");
  }
  
  return(
    sub {
      if($fh) { # So we can call multiple times
        DEBUG > 1 and print "Releasing lock on $file\n";
        close($fh); # Presumably will never fail!
          # Will release the lock.
        undef $fh;
        return 1;
      } else {
        return '';
      }
    }
  );
  # Now, I /could/ just have this work by returning the globref --
  # then when all the references to the glob go to 0, the FH
  # closes, and the lock is released.  However, this /relies/ on
  # the timing of garbage collection.
}


###########################################################################
#
# XML HELL BEGINS HERE
#

sub _scan_xml {
  my($self, $tag, $c, $timing, $subtag) = @_;
  die "Crazy tag \"$tag\"!!"
   unless $tag =~ m/^[a-zA-Z_][a-zA-Z_0-9]*$/s; # sanity
  die "Contentref has to be a scalar ref"  unless $c and ref($c) eq 'SCALAR';
  die "Timing object has to be an object!" unless $timing and ref($timing)
   and ref($timing) ne 'SCALAR';

  my $method = $tag;

  DEBUG > 5 and print "# _scan_xml << self <$self>; timingobj <$timing>\n#   tag <$tag>; subtag ",
    defined($subtag) ? "<$subtag>" : "(nil)",  "\n",
    "# Content {\n$$c\n# }\n",
  ;

  unless(defined $subtag) { # common case:  just <tag>someval</tag>
    if( $$c =~
      m{
        <
          (?: [a-zA-Z_][-_\.a-zA-Z0-9]* \: )? # optional namespace
          $tag\b
          .*?  # optional attributes and whitespace and junk
        >
          \s*
        ([^<>\s"]+)
          \s*
        </
          (?: [a-zA-Z_][-_\.a-zA-Z0-9]* \: )? # optional namespace
          $tag
        \s*  # just the optional (and rare) whitespace
        >
      }sx
    ) {
      my $it = $1;
      LWP::Debug::debug("Content has $method value: \"$it\"");
      DEBUG > 2 and print(" Content has $method value: \"$it\"!!\n");
      $timing->$method( $it );
    } else {
      LWP::Debug::debug("Content has no $method value");
      DEBUG > 2 and print("  Content has no $method value\n");
    }
    return;
  }

  # Else it's a tag and subtaggy thing
  die "Crazy subtag \"$tag\"!!"
   unless $subtag =~ m/^[a-zA-Z_][a-zA-Z_0-9]*$/s; # sanity

  if( $$c =~
      m{
        <
          (?:   [a-zA-Z_][-_\.a-zA-Z0-9]* \: )? # optional namespace
          $tag
        \b.*?>
        \s*
      (
        (?:
          <
            (?: [a-zA-Z_][-_\.a-zA-Z0-9]* \: )? # optional namespace
            $subtag
          \b.*?>
            \s*
         [^<>\s"]+
            \s*
          </
            (?: [a-zA-Z_][-_\.a-zA-Z0-9]* \: )? # optional namespace
            $subtag
          \s*>
          \s*
        )+
      )
        </
          (?:   [a-zA-Z_][-_\.a-zA-Z0-9]* \: )? # optional namespace
          $tag
        \s*>
      }sx
  ) {
    my $there = $1;
    DEBUG > 3 and print "  $method+subtag valuecluster \"$there\"\n";
    my(@them) = ( $there =~
       # Our previous RE made sure that this is a very simply-structured
       # area, so we can get away with just this simple regexp:
       m{
         >
         \s*
         ([^<>\s"]+)
         \s*
         </
       }xsg
    );
    LWP::Debug::debug("Content $method+$subtag values: @them");
    DEBUG > 2 and print(" Content $method+$subtag values:  (",
      join(q<,>, map("\"$_\" ", @them)), ")  !!\n");
    $timing->$method( @them );  #  yes, we call the method, not a submethod
  } else {
    LWP::Debug::debug("Content has no $method+$subtag values");
    DEBUG > 2 and print("  Content has no $method+$subtag values\n");
  }

  # Qvia sicvt exaltantvr Caeli a Terra,
  # sic exaltatae svnt viae Meae a viis vestris,
  # et cogitationes Meae a cogitationibvs vestris!
  # VGABVGA!

  return;
}

# EndHell.
###########################################################################
  
1;
__END__
  
<skipHours><hour>0</hour><hour>2</hour><hour>4</hour><hour>6</hour>
<hour>8</hour><hour>10</hour><hour>12</hour><hour>14</hour>
<hour>16</hour><hour>18</hour><hour>20</hour><hour>22</hour></skipHours>
<sy:updateFrequency>12</sy:updateFrequency>
<sy:updatePeriod>daily</sy:updatePeriod>
<sy:updateBase>1970-01-01T01:30+00:00</sy:updateBase>
<ttl>120</ttl>

http://interglacial.com/rss/find_of_the_week.rss

