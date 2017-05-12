# ABSTRACT: load YAML from cache or disk, whichever seems better
package YAML::CacheLoader;
use strict;
use warnings;

our $VERSION = '0.019';

use base qw( Exporter );
our @EXPORT_OK = qw( LoadFile DumpFile FlushCache FreshenCache);

use constant CACHE_SECONDS   => 3607;                  # Relatively nice prime number just over 1 hour.
use constant CACHE_NAMESPACE => 'YAML-CACHELOADER';    # Make clear who dirtied up the memory

use Cache::RedisDB 0.07;
use Path::Tiny 0.061;
use YAML::XS 0.59;

=head1 FUNCTIONS

=over

=item LoadFile

my $structure = LoadFile('/path/to/yml'[, $force_reload]);

Loads the structure from '/path/to/yml' into $structure, preferring the cached version if available,
otherwise reading the file and caching the result for 593 seconds (about 10 minutes).

If $force_reload is set to a true value, the file will be loaded from disk without regard
to the current cache status.

=cut

sub LoadFile {
    my ($path, $force_reload) = @_;

    my $file_loc = path($path)->canonpath;    # realpath would be more accurate, but slower.
    my $structure;
    if ($force_reload) {
        $structure = _load_and_cache($file_loc);
    } else {
        $structure = Cache::RedisDB->get(CACHE_NAMESPACE, $file_loc) // _load_and_cache($file_loc);
    }

    return $structure;
}

sub _load_and_cache {
    my $loc = shift;

    my $structure = YAML::XS::LoadFile($loc);    # Let this fail in whatever ways it might.
    Cache::RedisDB->set(CACHE_NAMESPACE, $loc, $structure, CACHE_SECONDS) if ($structure);

    return $structure;
}

=item DumpFile

DumpFile('/path/to/yml', $structure);

Dump the structure from $structure into '/path/to/yml', filling the cache along the way.

=cut

sub DumpFile {
    my ($path, $structure) = @_;

    my $file_loc = path($path)->canonpath;    # realpath would be more accurate, but slower.

    if ($structure) {
        YAML::XS::DumpFile($file_loc, $structure);
        Cache::RedisDB->set(CACHE_NAMESPACE, $file_loc, $structure, CACHE_SECONDS);
    }

    return $structure;
}

=item FlushCache

FlushCache();

Remove all currently cached YAML documents from the cache server.

=cut

sub FlushCache {
    my @cached_files = _cached_files_list();

    return (@cached_files) ? Cache::RedisDB->del(CACHE_NAMESPACE, @cached_files) : 0;
}

=item FreshenCache

FreshenCache();

Freshen currently cached files which may be out of date, either by deleting the cache (for now deleted files) or reloading from the disk (for changed ones)

May optionally provide a list of files to check, otherwise all known cached files are checked.

Returns a stats hash-ref.

=back
=cut

sub FreshenCache {
    my (@file_list) = @_;

    @file_list = _cached_files_list() unless @file_list;    # By default check all currently cached.

    my @to_check = map { path($_) } @file_list;
    # A good rough cut is to see if something _might_ have changed in the meantime
    my $cutoff = time - CACHE_SECONDS;

    my $stats = {
        examined  => scalar @to_check,
        cleared   => 0,
        freshened => 0,
    };

    foreach my $file (@to_check) {
        if (!$file->exists) {
            $stats->{cleared}++ if (Cache::RedisDB->del(CACHE_NAMESPACE, $file->canonpath));    # Let's not cache things which don't exist.
        } elsif ((my $mtime = $file->stat->mtime) > $cutoff
            && (my $reloaded_ago = CACHE_SECONDS - Cache::RedisDB->ttl(CACHE_NAMESPACE, $file->canonpath)))
        {
            $stats->{freshened}++ if (time - $reloaded_ago < $mtime && LoadFile($file, 1));
        }
    }

    return $stats;
}

sub _cached_files_list {

    return @{Cache::RedisDB->keys(CACHE_NAMESPACE)};

}

1;
