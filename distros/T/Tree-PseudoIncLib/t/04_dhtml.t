#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Tree::PseudoIncLib;
use Log::Log4perl;
use Cwd;
use Test::Simple tests => 2;

Log::Log4perl::init( 'data/log.config' );

# 01:
	my $dir = getcwd;
	my @pseudo_inc = (	$dir.'/data/testlibs/lib1',
				$dir.'/data/testlibs/lib2',);
	my $dobj = Tree::PseudoIncLib->new(
		max_nodes	=> 100,
		p_INC		=> \@pseudo_inc,
		skip_empty_dir	=> 0, # keep them
	);
	$dobj->from_scratch(lib_name => 'fiction');
	my $src_html = $dobj->export_to_DHTML (
		title			=> 'Test-Debug',
		image_dir		=> 'data/images/',
		icon_shaded		=> 'file_x.gif',
		icon_folder_opened	=> 'folder_opened.gif',
		icon_symlink		=> 'hand.right.gif',
		tree_intend		=> 18,
		row_class		=> 'r0',
		css			=> '', # use 'inline' css
		jslib			=> '', # no jslib
		overlib			=> 'js/overlib.js',
	);
#	print STDERR "\n$src_html\n";
	open FO, "> my_test_01.html";
	print FO "$src_html";
ok($src_html, 'export_to_DHTML works');

ok( !($src_html =~ /display-document/g), 'no November 04, 2004 bug');

