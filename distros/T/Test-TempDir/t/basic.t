use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    use File::Spec;
    plan skip_all => "No writable temp dir" unless grep { -d && -w } File::Spec->tmpdir;
}

use ok 'Test::TempDir' => qw(temp_root tempfile);

isa_ok( my $root = temp_root, "Path::Class::Dir" );

ok( -d $root, "root exists" );

ok( my ( $fh, $file ) = tempfile(), "tempfile" );

ok( $fh, "file handle returned" );
ok( $file, "file name returned" );

ok( ref($fh), "filehandle is a ref" );
ok( eval { fileno($fh) }, "file opened" );
ok( (print $fh "bar"), "writable" );;

ok( !ref($file), "file name is not a ref" );
ok( -f $file, "file exists" );

ok( $root->contains($file), "root contains file" );


done_testing;
