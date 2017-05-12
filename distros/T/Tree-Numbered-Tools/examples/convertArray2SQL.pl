#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the convertArray2SQL() method, converts an array into SQL statements (MySQL or PostgreSQL syntax).

# Help message
sub usage
  {
    print "\n";
    print "Usage:\n";
    print "$0 mysql\n";
    print "or\n";
    print "$0 pgsql\n";
    print "\n";
    exit 1;
  }

# Check for command line argument.
if (!$ARGV[0])
  {
    usage();
  }

my $dbs = $ARGV[0];
SWITCH: for ($dbs) {
  # MySQL
  /^mysql$/i        && do {
    last SWITCH;
  };
  # PgSQL
  /^postgres$|^PostgreSQL$|^pgsql$|^pg$/i         && do {
    last SWITCH;
  };
  # DEFAULT
  print STDERR "Database server type '$dbs' is not supported.";
  usage;
}

# The source
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
my $use_column_names = 1;
my $table = 'treetest';
my $drop = 1;

# The output
print Tree::Numbered::Tools->convertArray2SQL(
					      arrayref         => $arrayref,
					      use_column_names => $use_column_names,
					      table            => $table,
					      dbs              => $dbs,
					      drop             => $drop,
					     );
