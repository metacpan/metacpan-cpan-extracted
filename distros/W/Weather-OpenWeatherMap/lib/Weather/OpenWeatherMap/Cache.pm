package Weather::OpenWeatherMap::Cache;
$Weather::OpenWeatherMap::Cache::VERSION = '0.005004';
use Carp;
use strictures 2;

use Scalar::Util 'blessed';

use Storable ();
use Time::HiRes ();

use Digest::SHA 'sha1_hex';

use List::Objects::WithUtils;

use Path::Tiny;
use Try::Tiny;

use Types::Standard       -all;
use List::Objects::Types  -all;
use Types::Path::Tiny     -all;


use Moo; 


has dir => (
  lazy      => 1,
  is        => 'ro',
  isa       => AbsDir,
  coerce    => 1,
  builder   => sub { Path::Tiny->tempdir(CLEANUP => 1) },
);

has expiry => (
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { 1200 },
);

## FIXME max_entries ? or a size limit ?

sub serialize {
  my ($self, $obj) = @_;
  Storable::freeze(
    [ Time::HiRes::time, $obj ]
  )
}

sub deserialize {
  my ($self, $data) = @_;
  Storable::thaw($data)
}

sub make_path {
  my ($self, $obj) = @_;

  $obj = $obj->request
    if blessed($obj)
    and $obj->isa('Weather::OpenWeatherMap::Result');

  confess "Expected a Weather::OpenWeatherMap::Request but got $obj"
    unless blessed($obj) and $obj->isa('Weather::OpenWeatherMap::Request');

  my $fname = 'W';
  # also see cache_paths; new cache prefixes need added there also
  TYPE: {
    if ($obj->isa('Weather::OpenWeatherMap::Request::Current')) {
      $fname .= 'C';
      last TYPE
    }
    if ($obj->isa('Weather::OpenWeatherMap::Request::Forecast')) {
      $fname .= $obj->hourly ? 'H' : 'F';
      last TYPE
    }
    if ($obj->isa('Weather::OpenWeatherMap::Request::Find')) {
      $fname .= 'S';
      last TYPE
    }
    confess "Fell through; no clue what to do with $obj"
  }

  my $location = lc $obj->location;
  my $digest = $^O eq 'Win32' ? 
      substr sha1_hex($location), 0, 25 
    : sha1_hex($location);
  # If you happen to alter the extension, check ->cache_paths() too:
  $fname .= $digest . '.wx';
  path( join '/', $self->dir->absolute, $fname )
}

sub cache {
  my ($self, @results) = @_;
  my $count = 0;
  for my $result (@results) {
    confess "Expected a Weather::OpenWeatherMap::Result but got $result"
      unless blessed($result) 
      and $result->isa('Weather::OpenWeatherMap::Result');

    my $request = $result->request;
    my $path   = $self->make_path($request);
    my $frozen = $self->serialize($result);
    $path->spew_raw($frozen);
    ++$count;
  }
  $count
}

sub is_cached {
  my ($self, $obj) = @_;
  my $path = $self->make_path($obj);
  return unless $path->exists;
  return if $self->expire($obj);
  $path
}

sub retrieve {
  my ($self, $request) = @_;
  # make_path (via is_cached) will handle Result objs transparently also, but
  # we need a Request so we can reattach it to returned Result later:
  $request = $request->request
    if $request->isa('Weather::OpenWeatherMap::Result');
  my $path = $self->is_cached($request);
  return unless $path;

  my $data = $path->slurp_raw;
  my $ref =
    try { $self->deserialize($data) }
    catch {
      warn "deserialize died on retrieve: $_\n";
      warn "Attempting to remove possibly corrupt cachefile: $path";
      $path->remove;
      undef
    };
  return unless $ref;

  my ($ts, $result) = @$ref;
  unless (defined $ts && defined $result) {
    warn "cachefile incomplete, removing: $path";
    $path->remove;
    return
  }

  # cached Request obj attached to Result may be stale
  # (e.g. tag may be different for new Request/Result pair)
  # FIXME tests for this are lacking
  $result->set_request($request);

  hash(
    cached_at => $ts,
    object    => $result
  )->inflate
}

sub expire {
  my ($self, $obj) = @_;
  return $self->expire_all unless defined $obj;
  my $path = is_Path($obj) ? $obj : $self->make_path($obj);
  return unless $path->exists;

  my $data = $path->slurp_raw;
  my $ref = 
    try { $self->deserialize($data) }
    catch {
      warn "deserialize died on expiry check: $_\n";
      warn "Attempting to remove possibly corrupt cachefile: $path";
      $path->remove;
      undef
    };
  return unless $ref;

  my ($ts) = @$ref;
  unless ($ts) {
    warn "expiring possibly corrupt cachefile: $path";
    return $path->remove
  }
  return $path->remove if Time::HiRes::time - $ts > $self->expiry;
  ()
}

sub cache_paths {
  my ($self) = @_;
  $self->dir->children( qr/^W(?:[CHFS]).+\.wx/ )
}

sub expire_all {
  my ($self) = @_;
  my @expired;
  POSSIBLE: for my $maybe ($self->cache_paths) {
    push @expired, "$maybe" if $self->expire($maybe)
  }
  @expired
}

sub clear {
  my ($self) = @_;
  my @removed;
  POSSIBLE: for my $maybe ($self->cache_paths) {
    try {
      my $data = $maybe->slurp_raw;
      my $ref  = $self->deserialize($data);
      my ($ts, $result) = @$ref;
      die 
        unless is_StrictNum($ts)
        and $result->isa('Weather::OpenWeatherMap::Result')
    } or next POSSIBLE;
    push @removed, "$maybe";
    # Looks like ours; remove() rather than unlink()
    # (we don't care if it exists or not, at this point)
    $maybe->remove
  }
  @removed
}


1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Cache - Cache manager for OpenWeatherMap results

=head1 SYNOPSIS

  # Usually used via Weather::OpenWeatherMap

=head1 DESCRIPTION

A simple cache manager for L<Weather::OpenWeatherMap> results.

=head2 ATTRIBUTES

=head3 dir

The directory cache files are saved in.

Defaults to using a temporary directory that is cleaned up during object
destruction (via L<Path::Tiny> / L<File::Temp>).

If you specify a directory, no automated cleanup is done other than normal
object expiry checks during calls to L</retrieve>.

=head3 expiry

The duration (in seconds) cache files are considered valid; defaults to
C<1200>.

=head2 METHODS

=head3 High-level methods

=head4 cache

Takes a list of L<Weather::OpenWeatherMap::Result> objects and caches to
L</dir>.

Returns the number of items cached.

=head4 retrieve

Takes a L<Weather::OpenWeatherMap::Request> and attempts to retrieve a
(non-expired) cached L<Weather::OpenWeatherMap::Result>.

Returns false if no item was found.

If successful, the return value is a simple struct-like object with two
attributes, B<cached_at> (the C<time()> that the cached item was saved) and
B<object> (the relevant L<Weather::OpenWeatherMap::Result> object):

  my $result;
  if (my $cached = $cache->retrieve($request)) {
    $result = $cached->object
  }

=head3 Low-level methods

Subclasses can override the following methods to alter cache behavior.

=head4 cache_paths

Returns a list of L<Path::Tiny> objects representing (what appear to be)
L<Weather::OpenWeatherMap> cache files.

=head4 clear

Walk our L</dir>, removing any items that appear to belong to the cache.

Returns the list of removed paths (as strings).

=head4 deserialize

Takes a scalar containing serialized cache data and returns a Perl object or
data structure.

Uses L<Storable> by default.

=head4 expire

Given a L<Weather::OpenWeatherMap::Request> or
L<Weather::OpenWeatherMap::Result>, removes relevant stale cache data.

If passed no arguments, calls L</expire_all>.

Called by L</retrieve> before object retrieval.

Returns true if a cached object was expired.

=head4 expire_all

Expires any stale cache files found in L</dir>.

=head4 is_cached

Takes a L<Weather::OpenWeatherMap::Request> or
L<Weather::OpenWeatherMap::Result> and returns boolean true if the object is
cached.

=head4 make_path

Takes a L<Weather::OpenWeatherMap::Request> or
L<Weather::OpenWeatherMap::Result> and returns an appropriate L<Path::Tiny>
object representing the path that would be used to cache or retrieve the
object.

=head4 serialize

Takes a Perl object or data structure and returns serialized cache data
suitable for writing to disk.

Uses L<Storable> by default.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
