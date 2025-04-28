#!/usr/bin/env perl
#
# Name: read.write.tree.pl.
#
# Called by read.write.tree.sh.
#
# Reads a tree created by Tree::DAG_Node.tree2string()
# and somehow written to a disk file.

use 5.40.0;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper; # For Dumper().

use File::Spec;

use Getopt::Long;

use Tree::DAG_Node;

# ------------------------------------------------

my(%options);

$options{dir_name}			= '';
$options{in_file_name}		= '';
$options{help}	 			= 0;
$options{log_level}			= 'info';
my(%opts)					=
(
	'dir_name=s'		=> \$options{dir_name},
	'in_file_name=s'	=> \$options{in_file_name},
	'help'				=> \$options{help},
	'log_level=s'		=> \$options{log_level},
);

GetOptions(%opts) || die("Error in options. Options: " . Dumper(%opts) );

if ($options{help} == 1)
{
	pod2usage(1);
}

my($input_file_name)	= File::Spec -> catfile($options{dir_name}, $options{in_file_name});
my($output_file_name)	= File::Spec -> catfile($options{dir_name}, $options{in_file_name} . '.new');

say "Reading: $input_file_name";

my($node)				= Tree::DAG_Node -> new;
my($root)				= $node -> read_tree($input_file_name);
my($no_attr)			= 0;

say "Writing: $output_file_name";

open(my $fh, '> :encoding(utf-8)', $output_file_name);
print $fh "$_\n" for @{$root -> tree2string({no_attributes => $no_attr})};
close $fh;

say "Wrote:   $output_file_name";
