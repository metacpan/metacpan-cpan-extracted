package WWW::Mechanize::Plugin::Cache;

our $VERSION = '0.06';
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(caching_initialized cache_args cache cached));

use warnings;
use strict;
use Carp;
use Data::Dump::Streamer;
use Cache::FileCache;
use WWW::Mechanize;

my $prehook_closure  = sub { prehook(@_) };
my $posthook_closure = sub { posthook(@_) };

sub import { }  # This plugin does not have any import options

sub init {
  my ($class, $pluggable, %args) = @_;

  # Set up the one-time pre-hook.
  $pluggable->pre_hook('get',  $prehook_closure);
  $pluggable->post_hook('get', $posthook_closure);

  {
    no strict 'refs';
    # Used to capture the cache arguments on the current statement.
    *{caller(). '::cache_args'} = \&cache_args;

    # Whether or not a given request came from the cache.
    *{caller(). '::cached'} = \&cached;

    # The cache object itself.
    *{caller(). '::cache'} = \&cache;

    # Whether or not the Mech object is sufficiently set up to 
    # allow caching to work.
    *{caller(). '::caching_initialized'} = \&caching_initialized;
  }

  # Grab the arguments now, and process them later.
  $pluggable->cache_args($args{'cache'}); 

  # Note that the Mech object is not yet initialized enough to
  # support caching.
  $pluggable->caching_initialized(0);

  # And we've processed this.
  return qw(cache);
}

sub _make_cache_key {
  # We'll just use the URL as the key, since that's what we have.
  my ($pluggable, $mech, @args) = @_;
  return $args[0];
}

sub _create_cache {
  my($pluggable, $args) = @_;

  if ($args) {
    # We have a cache argument.
    if (ref $args) {
      # It points to something that might be a cache.
      if ( $args->isa('Cache::FileCache')) {
        # Yes, it is. Set up the cache.
        $pluggable->cache($args);
      }
      else {
        # Not a good cache object.
        die "The supplied object is not a valid cache\n";
      }
    }
    elsif ($args) {
      # A true value, which means "start caching, dude."
      # Buld a new cache.
      my $cache = Cache::FileCache->new(
                                        {default_expires_in => "1d",
                                         namespace => 'www-mechanize-cached'},
                                       );
      # Save it in the Mech::Pluggable object.
      $pluggable->cache($cache);
    }
  }
}

sub prehook {
  my ($pluggable, $mech, @args) = @_;

  # Are we supposed to have a cache?
  if (my $args = $pluggable->cache_args) {
    $pluggable->cache(_create_cache($pluggable, $args));

    # Don't create the cache again.
    $pluggable->cache_args(0);
  }

  # Is there a cache available?
  if (my $cache = $pluggable->cache) {
    my $cache_key = _make_cache_key(@_);
    my $cached = $cache->get($cache_key);
  
    # Did we find the current request in the cache?
    if ($cached) {
      if (!$pluggable->caching_initialized) {
        $pluggable->caching_initialized(1);
        # Commit enough surgery on the Mech object to
        # get all of it methods to work even without a
        # real get.
        #
        # Currently we're not doing anything...
      }
      # Yes. Return it and don't call the method.
      $mech->get('file://.');
      $mech->update_html($cached);
      $pluggable->cached(1);
      return -1;
    }
    else {
      # No. Go ahead and call the method.
      $pluggable->cached(0);
      return 0;
    }
  }
  # If there was no cache, just return as usual.
  else {
    return 0;
  }
}

sub posthook {
  my($pluggable, $mech, @args) = @_;
  # If we got to this point, we've actually
  # done either a get or a submit_form. We 
  # should save the current page, unless it's
  # already in the cache.
  unless ($pluggable->cached) {
    # It's not in the cache. Save it --
    # if there actually *IS* a cache.
    my $cache = $pluggable->cache;
    if ($cache) {
      $cache->set($args[0],$mech->content);
      # Don't mark it, because we haven't 
      # tried to fetch it from the cache.
      # We've only stored it.
    }
  }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

WWW::Mechanize::Plugin::Cache - Automatic request caching for WWW::Mechanize::Pluggable

=head1 VERSION

This document describes WWW::Mechanize::Plugin::Cache version 0.0.1

=head1 SYNOPSIS

    # With this plugin installed:
    use WWW::Mechanize::Pluggable;
    my $cached_mech = new WWW::Mechanize::Pluggable new_cache=>1;
    $mech->get("http://yahoo.com");   # Fetched from Web
    $mech->get("http://yahoo.com");   # Fetched from cache

    # To use an old cache:
    my $cache = Cache::FileCache->new(cache_root=>'/old/cache/root');
    my $cached_mech = new WWW::Mechanize::Pluggable cache=>$cache;
    $mech->get("http://yahoo.com");   # Fetched from the old cache

=head1 DESCRIPTION

This plugin adds caching functionality to C<WWW::Mechanize::Pluggable>.
It duplicates the functionality of C<WWW::Mechanize::Cached>; you can
have C<WWW::Mechanize::Pluggable> set up the cache for you, or reuse a
previously-filled cache.

=head1 INTERFACE 

=head2 new

The C<new> method (with this plugin installed) supports two new
options:

=over 4 

=item * new_cache

If supplied, this argument tells C<WWW::Mechanize::Pluggable> to 
create and initialize a new cache.

=item * cache => $cache

If supplied, reuses an old cache. C<$cache> must be an initialized
object conforming to the C<Cache::FileCache> interface.

=back

=head2 init

Handles interfacing to C<WWW::Mechanize::Pluggable>; installs
the necessry methods and puts the cache in place. You do not
want to call this method directly; C<WWW::Mechanize::Pluggable>
handles it for you.

=head2 prehook

This is a C<WWW::Mechanize::Pluggable> prehook; don't call it
yourself.

The prehook checks the C<cache> argument, if any, from the 
C<new> statement; if it finds that we want a cache (or we
have a cache we're reusing), it sets it up as instructed, 
then turns cache creation off so it won't do it again.

If there is a cache, we look up the current request via the
URL; if we find it, we use C<update_html> to install the
HTML we got from the cache, note that it came from the
cache, and skip the call to Mech that would have actually
accessed the page. If there's no cache, or if we didn't
find the supplied URL in the cache, we just exit and let 
C<Mech::Pluggable> go head and call the proper method.

=head2 posthook

This is a C<WWW::Mechanize::Pluggable> prehook; don't call it
yourself.

The posthook checks to see if the current content of the 
internal C<Mech> object came from the cache; if so, it just
exits. If not, it adds it to the cache.

=head2 cached

Tells you whether or not the last response came from the cache.

=head1 DIAGNOSTICS

=over

=item C<< The supplied object is not a valid cache >>

You supplied the C<cache> argument, but the value supplied as
the cache reference doesn't conform to the C<Cache::FileCache>
interface.

=back


=head1 CONFIGURATION AND ENVIRONMENT

WWW::Mechanize::Plugin::Cache requires no configuration files or environment variables.


=head1 DEPENDENCIES

WWW::Mechanize::Pluggable, Cache::FileCache.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

The oages are currently stored as pages under URLs; this may need to be
extended if we do extensive submit-based checking.

Please report any bugs or feature requests to
C<bug-www-mechanize-plugin-cache@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@yahoo-inc.com > >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Yahoo!. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
