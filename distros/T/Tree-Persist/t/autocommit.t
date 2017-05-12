use strict;
use warnings;

use Test::More;

# ---------------------------------------------

eval "use XML::Parser";
plan skip_all => "XML::Parser required for testing File plugin" if $@;

# The EXLOCK option is for BSD-based systems.

my $in_dir  = catfile( qw( t datafiles ) );
my $out_dir = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);

plan skip_all => "Temp dir is un-writable" if (! -w $out_dir);

plan tests => 20;

my $CLASS = 'Tree::Persist';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

use File::Slurp; # For read_file() and write_file().
use File::Spec::Functions qw( catfile );
use File::Temp;

use Scalar::Util qw( refaddr );

use Test::File;
use Test::File::Contents;

{
    my $filename = catfile( $out_dir, 'save1.xml' );

    write_file($filename, read_file(catfile($in_dir, 'tree1.xml') ) );

    file_exists_ok( $filename, 'Tree1 file exists' );

    file_contents_is( $filename, <<__END_FILE__, '... and the contents are good' );
<node class="Tree" value="root">
</node>
__END_FILE__

    my $persist = $CLASS->connect({
        filename => $filename,
        autocommit => 0,
    });

    ok( !$persist->autocommit, "Autocommit takes the value passed in." );

    ok( !$persist->autocommit( 1 ), "Setting autocommit returns the old value" );
    ok( $persist->autocommit, "After setting it to true, it's now true" );

    ok( $persist->autocommit( 0 ), "Setting autocommit returns the old value" );
    ok( !$persist->autocommit, "After setting it to false, it's now false" );

    $persist->autocommit( 0 );

    my $tree = $persist->tree;

    $tree->set_value( 'foo' );

    file_contents_is( $filename, <<__END_FILE__, "Shoudn't change anything with autocommit off" );
<node class="Tree" value="root">
</node>
__END_FILE__

    $persist->commit;

    file_contents_is( $filename, <<__END_FILE__, "... but committing should." );
<node class="Tree" value="foo">
</node>
__END_FILE__

    $tree->set_value( 'bar' );

    file_contents_is( $filename, <<__END_FILE__, "No change ..." );
<node class="Tree" value="foo">
</node>
__END_FILE__

    $persist->rollback;

    file_contents_is( $filename, <<__END_FILE__, "Still no change ..." );
<node class="Tree" value="foo">
</node>
__END_FILE__

    my $tree2 = $persist->tree;

    isnt( refaddr($tree), refaddr($tree2), "After rollback, the actual tree object changes" );

    is( $tree->value, 'bar', "The reference to the old tree still has the old value" );
    is( $tree2->value, 'foo', "... and rollback restores the original value in the new tree" );
}

{
    my $filename = catfile( $out_dir, 'save2.xml' );

    write_file($filename, read_file(catfile($in_dir, 'tree1.xml') ) );

    file_exists_ok( $filename, 'Tree1 file exists' );

    file_contents_is( $filename, <<__END_FILE__, '... and the contents are good' );
<node class="Tree" value="root">
</node>
__END_FILE__

    my $persist = $CLASS->connect({
        filename => $filename,
    });

    ok( $persist->autocommit, "Autocommit defaults to true." );

    my $modtime = -M $filename;

    sleep 1;

    $persist->commit;

    my $new_modtime = -M $filename;

    # Need to track changes made to the tree
    cmp_ok( $modtime, '==', $new_modtime, "commit() with autocommit() on is a no-op" );

    sleep 1;

    $persist->rollback;

    $new_modtime = -M $filename;

    # Need to track changes made to the tree
    cmp_ok( $modtime, '==', $new_modtime, "rollback() with autocommit() on is a no-op" );
}
