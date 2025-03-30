use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use File::Spec;
use File::Temp;

use File::Slurper 'read_text';

use Test::More;

# ------------------------------------------------

sub process
{
	my($node, $file_name) = @_;

	# The EXLOCK option is for BSD-based systems.

	my($temp_dir)        = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($temp_dir_name)   = $temp_dir -> dirname;
	my($test_file_name)  = File::Spec -> catfile($temp_dir_name, "$file_name.txt");
	my($input_file_name) = File::Spec -> catfile('t', "tree.$file_name.attributes.txt");
	my($root)            = $node -> read_tree($input_file_name);
	my($no_attr)         = $file_name =~ /without/ ? 1 : 0;

	open(my $fh, '> :encoding(utf-8)', $test_file_name);
	print $fh "$_\n" for @{$root -> tree2string({no_attributes => $no_attr})};
	close $fh;

	is(read_text($input_file_name), read_text($test_file_name), "\u$file_name attributes: Output tree matches shipped tree");

} # End of process.

# ------------------------------------------------

BEGIN {use_ok('Tree::DAG_Node'); }

my($node) = Tree::DAG_Node -> new;

isa_ok($node, 'Tree::DAG_Node', 'new() returned correct object type');

for (qw/utf8/)# with without/)
{
	process($node, $_);
}

done_testing;
