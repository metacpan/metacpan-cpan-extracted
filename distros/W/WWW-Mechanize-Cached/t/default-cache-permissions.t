use strict;
use warnings;

use Path::Tiny ();
use Test::More;
use Test::Needs            qw( Cache::FileCache );
use WWW::Mechanize::Cached ();

my $tmp;

BEGIN {
    if ( $^O =~ /MSWin/ ) {
        plan skip_all => 'POSIX mode bits required';
    }
    $tmp = Path::Tiny->tempdir;
    $ENV{XDG_CACHE_HOME} = "$tmp";

    # Pre-create the cache_root with attacker-friendly perms so we can
    # confirm _build_cache forces it back to 0700.
    my $squat = $tmp->child('WWW-Mechanize-Cached');
    $squat->mkdir;
    chmod 0777, "$squat";
}

sub mode_of { ( stat shift )[2] & 07777 }

sub assert_owner_only {
    my $dir  = shift;
    my $mode = mode_of("$dir");
    is(
        $mode & 077,
        0,
        sprintf( '%s is owner-only (mode=%04o)', $dir, $mode ),
    );
}

my $mech = WWW::Mechanize::Cached->new;

like(
    $mech->cache->get_cache_root,
    qr{\A\Q$tmp\E/},
    'cache_root is under XDG_CACHE_HOME',
);

$mech->cache->set( 'k', 'v' );

# Explicit assertions on the two directories we know must exist after a
# successful set(). These fire unconditionally, so a no-op visit() below
# cannot silently mask a regression.
my $cache_root    = $tmp->child('WWW-Mechanize-Cached');
my $namespace_dir = $cache_root->child('www-mechanize-cached');
assert_owner_only($cache_root);
assert_owner_only($namespace_dir);

# Defense-in-depth: every nested subdirectory under the namespace dir
# must also be owner-only.
my $deep_dirs = 0;
$namespace_dir->visit(
    sub {
        my $path = shift;
        return unless $path->is_dir;
        return if "$path" eq "$namespace_dir";
        $deep_dirs++;
        assert_owner_only($path);
    },
    { recurse => 1 },
);

cmp_ok(
    $deep_dirs, '>=', 1,
    'walked at least one nested cache directory under namespace'
);

done_testing;
