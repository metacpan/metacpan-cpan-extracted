# Test script for Tree::Numbered::Tools
# Tested with Perl 5.8.9 on FreeBSD 7.2.

# Before `make install' is performed this script should be runnable with `make test'. 
# After `make install' it should work as `perl Tree-Numbered-Tools.t'

use strict;
use warnings;
use IO::Scalar;
###use Test::More 'no_plan';
use Test::More tests => 86;

# Check if we can load the module to be tested correctly.
BEGIN {use_ok('Tree::Numbered::Tools'); }

my $first_indent     = 2;
my $level_indent     = 2;
my $column_indent    = 2;
my $table = 'treetest';

my $filename = 't/tree.txt';
my $filename_incorrectly_indented = 't/tree-incorrectly-indented.txt';

my $arrayref = [
		[qw(serial parent name url)],
		[1, 0, 'ROOT', 'ROOT'],
		[2, 1, 'File', 'file.pl'],
		[3, 2, 'New', 'file-new.pl'],
		[4, 3, 'Window', 'file-new-window.pl'],
		[5, 3, 'Template', 'file-new-template.pl'],
		[6, 2, 'Open', 'file-open.pl'],
		[7, 2, 'Save', 'file-save.pl'],
		[8, 2, 'Close', 'file-close.pl'],
		[9, 2, 'Exit', 'file-exit.pl'],
		[10, 1, 'Edit', 'edit.pl'],
		[11, 10, 'Undo', 'edit-undo.pl'],
		[12, 10, 'Cut', 'edit-cut.pl'],
		[13, 10, 'Copy', 'edit-copy.pl'],
		[14, 10, 'Paste', 'edit-paste.pl'],
		[15, 10, 'Find', 'edit-find.pl'],
		[16, 1, 'View', 'view.pl'],
		[17, 16, 'Toolbars', 'view-toolbars.pl'],
		[18, 17, 'Navigation', 'view-toolbars-navigation.pl'],
		[19, 17, 'Location', 'view-toolbars-location.pl'],
		[20, 17, 'Personal', 'view-toolbars-personal.pl'],
		[21, 16, 'Reload', 'view-reload.pl'],
		[22, 16, 'Source', 'view-source.pl'],
	       ];

# Array ordered by parent will WORK boh with 1.01 and 1.02.
my $arrayref_sorted = [
                       [qw(serial parent name url)],
                       [1, 0, 'ROOT', 'ROOT'],
                       [3, 1, 'Edit', 'edit.pl'],
                       [2, 3, 'Search', 'search.pl'],            # notice this one has a parent to the previous line
                      ];

# Array not ordered by parent will FAIL with 1.01 but will WORK with 1.02.
my $arrayref_unsorted = [
                         [qw(serial parent name url)],
                         [1, 0, 'ROOT', 'ROOT'],
                         [2, 3, 'Search', 'search.pl'],            # notice this one has a parent to the next  line
                         [3, 1, 'Edit', 'edit.pl'],
                        ];


# ----------------------------------------
# TREE OBJECTS
# ----------------------------------------

my $warning_unexpected = '';
my $warning_expected = '';


# Trees from files, capture warning messages from STDERR into variables.
tie *STDERR, 'IO::Scalar', \$warning_unexpected;
my $tree_file = Tree::Numbered::Tools->readFile(
					   filename         => $filename,
					   use_column_names => 1,
					  );
untie *STDERR;

tie *STDERR, 'IO::Scalar', \$warning_expected;
my $tree_file_incorrectly_indented = Tree::Numbered::Tools->readFile(
                                                                     filename         => $filename_incorrectly_indented,
                                                                     use_column_names => 1,
                                                                    );
untie *STDERR;

# Tree from arrays.
my $tree_array = Tree::Numbered::Tools->readArray(
					     arrayref         => $arrayref,
					     use_column_names => 1,
					    );
my $tree_array_sorted = Tree::Numbered::Tools->readArray(
                                                         arrayref         => $arrayref_sorted,
                                                         use_column_names => 1,
                                                        );
my $tree_array_unsorted = Tree::Numbered::Tools->readArray(
                                                           arrayref         => $arrayref_unsorted,
                                                           use_column_names => 1,
                                                          );

# ----------------------------------------
# TEST FOR EXISTING OBJECTS.
# ----------------------------------------

# Test trees from files.
ok(defined $tree_file, "readFile() returned an object (using 'tree.txt' as a source)")
  or diag("readFile() did not return an object");
ok($tree_file->isa('Tree::Numbered::Tools'),   "    it's a Tree::Numbered::Tools object")
  or diag("No, it's not an object.");
ok($tree_file->isa('Tree::Numbered'),   "    it's also a Tree::Numbered object")
  or diag("No, it's not an object.");
ok(!$warning_unexpected, "    no warnings returned")
  or diag("Warning message:\n$warning_unexpected");

ok(defined $tree_file_incorrectly_indented, "readFile() returned an object  (using 'tree-incorrectly-intended.txt' as a source)")
  or diag("readFile() did not return an object");
ok($tree_file_incorrectly_indented->isa('Tree::Numbered::Tools'), "    it's a Tree::Numbered::Tools object")
  or diag("No, it's not an object.");
ok($tree_file_incorrectly_indented->isa('Tree::Numbered'),   "    it's also a Tree::Numbered object")
  or diag("No, it's not an object.");
ok($warning_expected, "    warnings returned as expected, due to the incorrectly indented file")
  or diag("No warning message, even if it should have caused one.");

# Test trees from arrays.
ok( defined $tree_array, "readArray() returned an object" );
ok( $tree_array->isa('Tree::Numbered::Tools'), "    it's a Tree::Numbered::Tools object" );
ok( $tree_array->isa('Tree::Numbered'), "    it's also a Tree::Numbered object" );
ok( defined $tree_array_sorted, "readArray() returned an object (sorted array)");
ok( $tree_array_sorted->isa('Tree::Numbered::Tools'), "    it's a Tree::Numbered::Tools object" );
ok( $tree_array_sorted->isa('Tree::Numbered'), "    it's also a Tree::Numbered object" );
ok( defined $tree_array_unsorted, "readArray() returned an object (unsorted array)");
ok( $tree_array_unsorted->isa('Tree::Numbered::Tools'), "    it's a Tree::Numbered::Tools object" );
ok( $tree_array_unsorted->isa('Tree::Numbered'), "    it's also a Tree::Numbered object" );

# Skip SQL and DB object tests.
SKIP: {
  skip 'the readSQL() test because we have no access to a database handle', 1;
};
SKIP: {
  skip 'the readDB() test because we have no access to a database handle', 1;
};


# ----------------------------------------
# TEST OUTPUT FORMATS.
# ----------------------------------------

my $output = '';

# Test file format output using all tree objects.
$output = $tree_file->outputFile(
                                 first_indent     => $first_indent,
                                 level_indent     => $level_indent,
                                 column_indent    => $column_indent,
                                );
ok( $output,   'outputFile() returned some output (source: file)' );
$output = $tree_file_incorrectly_indented->outputFile(
                                                      first_indent     => $first_indent,
                                                      level_indent     => $level_indent,
                                                      column_indent    => $column_indent,
                                                     );
ok( $output,   'outputFile() returned some output (source: incorrectly indented file)' );
$output = $tree_array->outputFile(
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                                 );
ok( $output,   'outputFile() returned some output (source: array)' );
$output = $tree_array_sorted->outputFile(
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                                 );
ok( $output,   'outputFile() returned some output (source: sorted array)' );
$output = $tree_array->outputFile(
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                                 );
ok( $output,   'outputFile() returned some output (source: unsorted array)' );

# Test array format output using all tree objects.
$output = $tree_file->outputArray();
ok( $output,   'outputArray() returned some output (source: file)' );
$output = $tree_file_incorrectly_indented->outputArray();
ok( $output,   'outputArray() returned some output (source: incorrectly indented file)' );
$output = $tree_array->outputArray();
ok( $output,   'outputArray() returned some output (source: array)' );
$output = $tree_array_sorted->outputArray();
ok( $output,   'outputArray() returned some output (source: sorted array)' );
$output = $tree_array_unsorted->outputArray();
ok( $output,   'outputArray() returned some output (source: unsorted array)' );

# Test MySQL SQL format output using all tree objects.
# (The SQL format defaults to 'mysql' if the 'dbs' argument is omitted.)
$output = $tree_file->outputSQL(
                                table => $table,
                                drop  => 1,
                               );
ok( $output,   "outputSQL() returned some output (source: file \t\t\t\toutput format: MySQL)");
$output = $tree_file_incorrectly_indented->outputSQL(
                                                          table => $table,
                                                          drop  => 1,
                                                         );
ok( $output,   "outputSQL() returned some output (source: incorrectly indented file \toutput format: MySQL)" );
$output = $tree_array->outputSQL(
                                 table => $table,
                                 drop  => 1,
                                );
ok( $output,   "outputSQL() returned some output (source: array \t\t\toutput format: MySQL)");
$output = $tree_array_sorted->outputSQL(
                                        table => $table,
                                        drop  => 1,
                                       );
ok( $output,   "outputSQL() returned some output (source: sorted array \t\t\toutput format: MySQL)" );
$output = $tree_array_unsorted->outputSQL(
                                          table => $table,
                                          drop  => 1,
                                         );
ok( $output,   "outputSQL() returned some output (source: unsorted array \t\toutput format: MySQL)" );

# Test PostgreSQL SQL format output using all tree objects.
$output = $tree_file->outputSQL(
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
ok( $output,   "outputSQL() returned some output (source: file \t\t\t\toutput format: PostgreSQL)");
$output = $tree_file_incorrectly_indented->outputSQL(
                                                          table => $table,
                                                          dbs   => 'PgSQL',
                                                          drop  => 1,
                                                         );
ok( $output,   "outputSQL() returned some output (source: incorrectly indented file \toutput format: PostgreSQL)" );
$output = $tree_array->outputSQL(
                                 table => $table,
                                 dbs   => 'PgSQL',
                                 drop  => 1,
                                );
ok( $output,   "outputSQL() returned some output (source: array \t\t\toutput format: PostgreSQL)" );
$output = $tree_array_sorted->outputSQL(
                                        table => $table,
                                        dbs   => 'PgSQL',
                                        drop  => 1,
                                       );
ok( $output,   "outputSQL() returned some output (source: sorted array \t\t\toutput format: PostgreSQL)");
$output = $tree_array_unsorted->outputSQL(
                                          table => $table,
                                          dbs   => 'PgSQL',
                                          drop  => 1,
                                         );
ok( $output,   "outputSQL() returned some output (source: unsorted array \t\toutput format: PostgreSQL)" );


# Skip DB output tests.
SKIP: {
  skip 'the outputDB() test because we have no access to a database handle', 1;
};


# ----------------------------------------
# TEST CONVERSIONS.
# ----------------------------------------
my ($output1, $output2, $output3, $output4, $output5);
# For the following tests, the object's state doesn't matter, it just have to be an object.
# Thus, use the object copies ($t1, $t2 etc.) usingi less descriptive but more handy names.
my ($t1, $t2, $t3, $t4, $t5) = ($tree_file, $tree_file_incorrectly_indented, $tree_array, $tree_array_sorted, $tree_array_unsorted);

# Test file-to-array conversions using all tree objects. (All objects should return the same output.)

# Test using 'tree.txt' as a source.
# Prepare for unexpected warnings.
$warning_expected='';
tie *STDERR, 'IO::Scalar', \$warning_unexpected;
$output1 = $t1->convertFile2Array(
                                  filename         => $filename,
                                  use_column_names => 1,
                                 );
$output2 = $t2->convertFile2Array(
                                  filename         => $filename,
                                  use_column_names => 1,
                                 );
$output3 = $t3->convertFile2Array(
                                  filename         => $filename,
                                  use_column_names => 1,
                                 );
$output4 = $t4->convertFile2Array(
                                  filename         => $filename,
                                  use_column_names => 1,
                                 );
$output5 = $t5->convertFile2Array(
                                  filename         => $filename,
                                  use_column_names => 1,
                                 );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertFile2Array() returned some output from each and every test tree object. All objects generated identical output. (source: 'tree.txt')" );
untie *STDERR;
ok(!$warning_unexpected, "    no warnings returned")
  or diag("Warning message:\n$warning_unexpected");

# Test using 'tree-incorrectly-intended.txt' as a source.
# Prepare for expected warnings.
$warning_expected='';
tie *STDERR, 'IO::Scalar', \$warning_expected;
$output1 = $t1->convertFile2Array(
                                  filename         => $filename_incorrectly_indented,
                                  use_column_names => 1,
                                 );
$output2 = $t2->convertFile2Array(
                                  filename         => $filename_incorrectly_indented,
                                  use_column_names => 1,
                                 );
$output3 = $t3->convertFile2Array(
                                  filename         => $filename_incorrectly_indented,
                                  use_column_names => 1,
                                 );
$output4 = $t4->convertFile2Array(
                                  filename         => $filename_incorrectly_indented,
                                  use_column_names => 1,
                                 );
$output5 = $t5->convertFile2Array(
                                  filename         => $filename_incorrectly_indented,
                                  use_column_names => 1,
                                 );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertFile2Array() returned some output from each and every test tree object. All objects generated identical output. (source: 'tree-incorrectly-intended.txt')" );
untie *STDERR;
ok($warning_expected, "    warnings returned as expected, due to the incorrectly indented file")
  or diag("No warning message, even if it should have caused one.");


# Test file-to-SQL conversions using all tree objects. (All objects should return the same output.)

# Test using 'tree.txt' as a source, MySQL output format.
# Prepare for unexpected warnings.
$warning_expected='';
tie *STDERR, 'IO::Scalar', \$warning_unexpected;
$output1 = $t1->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
$output2 = $t2->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
$output3 = $t3->convertFile2SQL(
                               filename         => $filename,
                               use_column_names => 1,
                               table => $table,
                               drop  => 1,
                              );
$output4 = $t4->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
$output5 = $t5->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertFile2SQL() returned some output from each and every test tree object. All objects generated identical output. (source: 'tree.txt', output format: MySQL)" );
untie *STDERR;
ok(!$warning_unexpected, "    no warnings returned")
  or diag("Warning message:\n$warning_unexpected");

# Test using 'tree-incorrectly-intended.txt' as a source, MySQL output format.
# Prepare for expected warnings.
$warning_expected='';
tie *STDERR, 'IO::Scalar', \$warning_expected;
$output1 = $t1->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
$output2 = $t2->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
$output3 = $t3->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
$output4 = $t4->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
$output5 = $t5->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                drop  => 1,
                               );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertFile2SQL() returned some output from each and every test tree object. All objects generated identical output. (source: 'tree-incorrectly-indented.txt', output format: MySQL)" );
untie *STDERR;
ok($warning_expected, "    warnings returned as expected, due to the incorrectly indented file")
  or diag("No warning message, even if it should have caused one.");

# Test using 'tree.txt' as a source, PostgreSQL output format.
# Prepare for unexpected warnings.
$warning_expected='';
tie *STDERR, 'IO::Scalar', \$warning_unexpected;
$output1 = $t1->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
$output2 = $t2->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
$output3 = $t3->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
$output4 = $t4->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1, 
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
$output5 = $t5->convertFile2SQL(
                                filename         => $filename,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertFile2SQL() returned some output from each and every test tree object. All objects generated identical output. (source: 'tree.txt', output format: PostgresSQL)" );
untie *STDERR;
ok(!$warning_unexpected, "    no warnings returned")
  or diag("Warning message:\n$warning_unexpected");


# Test using 'tree-incorrectly-intended.txt' as a source, PostgreSQL output format.
# Prepare for expected warnings.
$warning_expected='';
tie *STDERR, 'IO::Scalar', \$warning_expected;
$output1 = $t1->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
$output2 = $t2->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
$output3 = $t3->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
$output4 = $t4->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
$output5 = $t5->convertFile2SQL(
                                filename         => $filename_incorrectly_indented,
                                use_column_names => 1,
                                table => $table,
                                dbs   => 'PgSQL',
                                drop  => 1,
                               );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertFile2SQL() returned some output from each and every test tree object. All objects generated identical output. (source: 'tree-incorrectly-indented.txt', output format: PostgreSQL)" );
untie *STDERR;
ok($warning_expected, "    warnings returned as expected, due to the incorrectly indented file")
  or diag("No warning message, even if it should have caused one.");


# Skip file-to-DB conversion tests.
SKIP: {
  skip 'the convertFile2DB() test because we have no access to a database handle', 1;
};


# Test array-to-file conversions using all tree objects. (All objects should return the same output.)

# Test using array as a source.
$output1 = $t1->convertArray2File(
                                  arrayref         => $arrayref,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                                 );
$output2 = $t2->convertArray2File(
                                  arrayref         => $arrayref,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output3 = $t3->convertArray2File(
                                  arrayref         => $arrayref,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output4 = $t4->convertArray2File(
                                  arrayref         => $arrayref,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output5 = $t5->convertArray2File(
                                  arrayref         => $arrayref,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2File() returned some output from each and every test tree object. All objects generated identical output. (source: array)" );

# Test using sorted array as a source.
$output1 = $t1->convertArray2File(
                                  arrayref         => $arrayref_sorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                                 );
$output2 = $t2->convertArray2File(
                                  arrayref         => $arrayref_sorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output3 = $t3->convertArray2File(
                                  arrayref         => $arrayref_sorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output4 = $t4->convertArray2File(
                                  arrayref         => $arrayref_sorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output5 = $t5->convertArray2File(
                                  arrayref         => $arrayref_sorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2File() returned some output from each and every test tree object. All objects generated identical output. (source: sorted array)" );

# Test using unsorted array as a source.
$output1 = $t1->convertArray2File(
                                  arrayref         => $arrayref_unsorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                                 );
$output2 = $t2->convertArray2File(
                                  arrayref         => $arrayref_unsorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output3 = $t3->convertArray2File(
                                  arrayref         => $arrayref_unsorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output4 = $t4->convertArray2File(
                                  arrayref         => $arrayref_unsorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
$output5 = $t5->convertArray2File(
                                  arrayref         => $arrayref_unsorted,
                                  use_column_names => 1,
                                  first_indent     => $first_indent,
                                  level_indent     => $level_indent,
                                  column_indent    => $column_indent,
                               );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2File() returned some output from each and every test tree object. All objects generated identical output. (source: unsorted array)" );

# Test array-to-SQL conversions using all tree objects. (All objects should return the same output.)

# Test using array as a source, MySQL output format.
$output1 = $t1->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output2 = $t2->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output3 = $t3->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output4 = $t4->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output5 = $t5->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2SQL() returned some output from each and every test tree object. All objects generated identical output. \t(source: array \t\t output format: MySQL)" );

# Test using sorted array as a source, MySQL output format.
$output1 = $t1->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output2 = $t2->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output3 = $t3->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output4 = $t4->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output5 = $t5->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2SQL() returned some output from each and every test tree object. All objects generated identical output. \t(source: sorted array \t output format: MySQL)" );

# Test using unsorted array as a source, MySQL output format.
$output1 = $t1->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output2 = $t2->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output3 = $t3->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output4 = $t4->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
$output5 = $t5->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 drop             => 1,
                                );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2SQL() returned some output from each and every test tree object. All objects generated identical output. \t(source: unsorted array  output format: MySQL)" );


# Test array-to-SQL conversions using all tree objects. (All objects should return the same output.)

# Test using array as a source, PostgreSQL output format.
$output1 = $t1->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output2 = $t2->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output3 = $t3->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output4 = $t4->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output5 = $t5->convertArray2SQL(
                                 arrayref         => $arrayref,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2SQL() returned some output from each and every test tree object. All objects generated identical output. \t(source: array \t\t output format: PostgreSQL)" );

# Test using sorted array as a source, PostgreSQL output format.
$output1 = $t1->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output2 = $t2->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output3 = $t3->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output4 = $t4->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output5 = $t5->convertArray2SQL(
                                 arrayref         => $arrayref_sorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2SQL() returned some output from each and every test tree object. All objects generated identical output. \t(source: sorted array \t output format: PostgreSQL)" );

# Test using unsorted array as a source, PostgreSQL output format.
$output1 = $t1->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output2 = $t2->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output3 = $t3->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output4 = $t4->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                                );
$output5 = $t5->convertArray2SQL(
                                 arrayref         => $arrayref_unsorted,
                                 use_column_names => 1,
                                 table            => $table,
                                 dbs   => 'PgSQL',
                                 drop             => 1,
                               );
ok( $output1 && ($output1 eq $output2) && ($output1 eq $output3) && ($output1 eq $output4) && ($output1 eq $output5), "convertArray2SQL() returned some output from each and every test tree object. All objects generated identical output. \t(source: unsorted array  output format: PostgreSQL)" );

# Skip array-to-DB conversion tests.
SKIP: {
  skip 'the convertArray2DB() test because we have no access to a database handle', 1;
};

# Skip sql-to-file conversion tests.
SKIP: {
  skip 'the convertSQL2File() test because we have no access to a database handle', 1;
};

# Skip sql-to-array conversion tests.
SKIP: {
  skip 'the convertSQL2Array() test because we have no access to a database handle', 1;
};

# Skip sql-to-db conversion tests.
SKIP: {
  skip 'the convertSQL2DB() test because we have no access to a database handle', 1;
};

# Skip db-to-file conversion tests.
SKIP: {
  skip 'the convertDB2File() test because we have no access to a database handle', 1;
};

# Skip db-to-array conversion tests.
SKIP: {
  skip 'the convertDB2Array() test because we have no access to a database handle', 1;
};

# Skip db-to-sql conversion tests.
SKIP: {
  skip 'the convertDB2SQL() test because we have no access to a database handle', 1;
};


# ----------------------------------------
# TEST ADDITIONAL FUNCTIONS.
# ----------------------------------------

# getColumnNames()
# Returns a list (in array context) or a ref to a list (in scalar context) of the column names.
my @column_names = ();
@column_names = $tree_file->getColumnNames();
ok( scalar(@column_names),   'getColumnNames() returned some column names for a tree created from a file' );
@column_names = ();
@column_names = $tree_file_incorrectly_indented->getColumnNames();
ok( scalar(@column_names),   'getColumnNames() returned some column names for a tree created from another file' );
@column_names = ();
@column_names = $tree_array->getColumnNames();
ok( scalar(@column_names),   'getColumnNames() returned some column names for a tree created from an array' );
@column_names = ();
@column_names = $tree_array_sorted->getColumnNames();
ok( scalar(@column_names),   'getColumnNames() returned some column names for a tree created from a second array' );
@column_names = ();
@column_names = $tree_array_unsorted->getColumnNames();
ok( scalar(@column_names),   'getColumnNames() returned some column names for a tree created from a third array' );
# Test a tree without column names, should return the default.
my $arrayref_no_column_names = [
                                [1, 0, 'ROOT', 'ROOT', 'R3', 'R4', 'R5'],
                                [2, 3, 'Search', 'search.pl', 's3', 's4', 's4'],
                                [3, 1, 'Edit', 'edit.pl', 'e3', 'e4', 'e5'],
                               ];
my $tree_no_column_names = Tree::Numbered::Tools->readArray(
                                                            arrayref         => $arrayref_no_column_names,
                                                            use_column_names => 0,
                                                           );
my @default_column_names = ('Value', 'Value2', 'Value3', 'Value4', 'Value5');
my @no_column_names_specified = $tree_no_column_names->getColumnNames();
ok( @default_column_names = @no_column_names_specified ,   'getColumnNames() returned the default column names for a tree created from an array without specifying column names' );

# getSourceType()
#  Returns one of the strings 'File', 'Array', 'SQL', 'DB' depending on which source was used to create the tree object.
my $source_type;
$source_type = $tree_file->getSourceType();
ok( ($source_type eq 'File'),   'getSourceType() returned "File" for a tree created from a file' );
$source_type = $tree_file_incorrectly_indented->getSourceType();
ok( ($source_type eq 'File'),   'getSourceType() returned "File" for a tree created from another file' );
$source_type = $tree_array->getSourceType();
ok( ($source_type eq 'Array'),   'getSourceType() returned "Array" for a tree created from an array' );
$source_type = $tree_array_sorted->getSourceType();
ok( ($source_type eq 'Array'),   'getSourceType() returned "Array" for a tree created from a second array' );
$source_type = $tree_array_unsorted->getSourceType();
ok( ($source_type eq 'Array'),   'getSourceType() returned "Array" for a tree created from a third array' );

# getSourceName()
# Returns the file name if the source type is 'File', or the database table name if the source type is 'DB'.
# Returns undef if source type is 'Array' or 'SQL'.
my $source_name;
$source_name = $tree_file->getSourceName();
ok( ($source_name eq $filename),   'getSourceName() returned "'.$source_name.'" as the source name for a tree created from a file' );
$source_name = $tree_file_incorrectly_indented->getSourceName();
ok( ($source_name eq $filename_incorrectly_indented),   'getSourceName() returned "'.$source_name.'" as the source name for a tree created from another file' );
$source_name = $tree_array->getSourceName();
ok( (!defined($source_name)),   'getSourceName() returned "undef" (as expected) for a tree created from an array' );
$source_name = $tree_array_sorted->getSourceName();
ok( (!defined($source_name)),   'getSourceName() returned "undef" (as expected) for a tree created from a second array' );
$source_name = $tree_array_unsorted->getSourceName();
ok( (!defined($source_name)),   'getSourceName() returned "undef" (as expected) for a tree created from a third array' );

