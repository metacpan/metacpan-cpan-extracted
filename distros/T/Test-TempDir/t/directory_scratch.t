use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    use File::Spec;
    plan skip_all => "No writable temp dir" unless grep { -d && -w } File::Spec->tmpdir;
}

use Test::Requires 'Directory::Scratch';

use ok 'Test::TempDir' => qw(temp_root scratch);

my $root = temp_root;

isa_ok( my $s = scratch(), "Directory::Scratch" );

ok( $root->contains($s->base), "root contains scratch dir" );

done_testing;
