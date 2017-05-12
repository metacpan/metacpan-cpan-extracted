package Tree::Numbered::Tools;

use 5.006000;
use strict;
use warnings;

use Tree::Numbered;
use Text::ParseWords;
use Carp; # generate better errors with more context

require Exporter;

our @ISA = qw(Tree::Numbered);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tree::Numbered::Tools ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.04';


# - Generate a tree object from different sources: database table, text file, SQL statement, Perl array.
# - Dump a tree object to one of these sources.
# - Convert between source formats.

# Parse a tree from a text file and convert it to a Tree::Numbered object
# Each line in the text file should indent using at least one space for each level
# The term 'top level' is used to describe a root child.

=head1 NAME

Tree::Numbered::Tools - Perl module to create tree objects using different sources.

=head1 SYNOPSIS

Example 1: Using a text file as a source:


  Value          LastName  FirstName
# -----          --------  ---------
  Grandfather    Smith     Abraham
    Son1         Smith     Bert
    Son2         Smith     'Clumsy Carl'
      Grandson1  Jones     Dennis
      Grandson2  Jones     Eric
    Son3         Smith     'Fatty Fred'
      Grandson3  Smith     Greg
      Grandson4  Smith     Huey
  Grandmother    Smith     Anna
    Daughter1    Smith     Berta
    Daughter2    Smith     Celine

  use Tree::Numbered::Tools;

  # Reads a text file, returns a tree object
  my $tree = Tree::Numbered::Tools->readFile(
	      filename         => $filename,
	      use_column_names => 1,
  );

Example 2: Using an array as a source:

  use Tree::Numbered::Tools;

  my $arrayref = [
	  	  [qw(serial parent name url)],
		  [1, 0, 'ROOT', 'ROOT'],
		  [2, 1, 'File', 'file.pl'],
		  [3, 2, 'New', 'file-new.pl'],
		  [4, 3, 'Window', 'file-new-window.pl'],
                 ];
  my $tree = Tree::Numbered::Tools->readArray(
	      arrayref         => $arrayref,
	      use_column_names => 1,
  );

Example 3: Using a database table as a source, use the SQL 'AS' statement for easy column mapping:

  use Tree::Numbered::Tools;

  my $sql = 'SELECT serial, parent AS "Parent", name AS "Name", url AS "URL" FROM mytable ORDER BY serial';
  my $tree = Tree::Numbered::Tools->readSQL(
              dbh              => $dbh,
              sql              => $sql,
  );

Example 4: Display a tree object in the same format as the text file in example 1:

  my $output = Tree::Numbered::Tools->outputFile();

Example 5: Display a tree object as an array reference, to be used for cut 'n paste in a Perl program.

  my $output = Tree::Numbered::Tools->outputArray();

Example 6: Convert a text file to a database table.

  my $sql = Tree::Numbered::Tools->convertFile2DB(
	      filename         => $filename,
	      use_column_names => 1,
              dbh              => $dbh,
              table            => $table,
  );

Example 7: Convert a text file to SQL 'INSERT INTO' statements.

  my $sql = Tree::Numbered::Tools->convertFile2SQL(
	      filename         => $filename,
	      use_column_names => 1,
  );


=head1 DESCRIPTION

Tree::Numbered::Tools is a child class of Tree::Numbered.
Its purpouse is to easily create a tree object from different sources.

The most useful source is probably a text file (see SYNOPSIS, example 1).
The text file visualizes the tree structure as well as node names in the first column.
Any other columns represent each node's properties.
The format is easy to read and understand, even for a non-programmer.
Besides, editing a text file is normally far more easy than editing records in a database table.
Anyhow, at run time, reading from/writing to a database outperformances a text file.
This module is intented to be used as a tool to create database tables using text files, not to replace tables with text files (even if the module permits you to use the text file as a source without dealing with a database).
The format of the first column in the text file only requires that each tree level should be indented using one or more spaces (or tabs). It is recommended to be consistent and use the same number of spaces to indent all tree levels, even if the readFile() method tries to determine each node's level even if the indenting isn't consistent. To get each node's properties, the readFile() method parses each line in the text file using the Text::ParseWords module, so any property value containg a space must be quoted. If the last column or columns in the text file for a node are omitted, the corresponding property value is assigned the empty string.

Programmers who prefer not using an external source when creating a tree may use an array reference.
Being a programmer, it is probably easier to edit an array than database records.
See SYNOPSIS, example 2.

The purpouse of the SQL statement as a source for the tree object is the more straightforward way to map column names using Tree::Numbered::Tools->readSQL() than the Tree::Numbered::DB->read() method.
See SYNOPSIS, example 3.

=head1 NOTES ABOUT THE ROOT NODE

Using a text file as a source, the text file does not contain the root node itself. This is on purpouse. In daily life, describing a tree, frequently there is not one single root node, but two or many 'top level nodes' as the 'Grandfather' and 'Grandmother' nodes in SYNOPSIS, example 1.
To manage all the nodes as a single tree, a single root node named 'ROOT' will always be created.
In tree terminology, a 'top level node' is the same as a root child.
Anyway, using any other source, the 'ROOT' node should be included.
See SYNOPSIS, example 2, how to create the 'ROOT' node with an array. 

=head1 NOTES ABOUT FIELDS AND COLUMNS

A Tree::Numbered object uses the term 'fields' for each node's properties.
A Tree::Numbered::Tools object uses the term 'columns'.
Shortly, 'columns' are 'fields' in a specified order.
The Tree::Numbered->getFieldNames() method uses a hash internally to get field names.
This means there is no way to guarantee a specific order in obtaining the field names. The field order doesn't matter for an abstract tree object, but it does when printing a tree structure, for example.
The Tree::Numbered::Tools->getColumnNames method uses an array internally to guarantee the specified order.

The column order is only an issue when working with a tree object created by a source not specifying columns, for example creating a new tree using the Tree::Numbered->new() method.
When creating a tree using the readSQL() method, the column names will be obtained from the DBI::$sth->{NAME} method, i.e. the SQL statement, and thus listed in a known order.
When creating a tree using the readFile()/readArray() method, the column names can be obtained using the getColumnNames() method, if the source file/array was specified with column names on its first line/row, and use_column_names is set to true.

There is no way to 'map' column names from a file/SQL/array to field names in the tree object using distinct names, as it is in Tree::Numbered::DB, for example.
Instead of mapping, modify the column names in your text file or array row, or use the SQL 'AS' statement, depending on which method you use to create the tree.

=head1 METHODS SUMMARY

Methods to create a tree object reading from a source:
  readFile()  - read from a text file
  readArray() - read from an array
  readSQL()   - read from an SQL statement
  readDB()    - read from a database table

Methods to output the contents of a tree object:
  outputFile()  - output in text file format
  outputArray() - output in array format (Perl code)
  outputSQL()   - output as SQL statements
  outputDB()    - output to (creates) a database table

Methods to convert from one source format to another:
  convertFile2Array()
  convertFile2SQL()
  convertFile2DB()
  convertArray2File()
  convertArray2SQL()
  convertArray2DB()
  convertSQL2File()
  convertSQL2Array()
  convertSQL2DB()
  convertDB2File()
  convertDB2Array()
  convertDB2SQL()

Using convertX2Y() is practically the same as calling readX() followed by outputY().

Other Methods:
  getColumnNames - see NOTES ABOUT FIELDS AND COLUMNS
  getSourceType  - File, Array, SQL, DB
  getSourceName  - file name, database table name

=head1 METHODS

=head2 readFile()

  readFile(
           filename         => $filename,
           use_column_names => $use_column_names,
          );

Reads $filename, returns a tree object.
$use_column_names is a boolean, if set (default), assumes that the first (non-comment, non-blank) line contains column names.

=cut


sub readFile {
  my $self = shift;
  # Get args
  my %args = ( 
	      filename         => '',
	      use_column_names => 1, # Require column names by default, as we create them by default in outputFile
	      @_,         # argument pair list goes here
	     );
  # Die on missing filename
  my $filename = $args{filename} or croak "Missing filename";
  my $use_column_names = $args{use_column_names};

  # Get the file contents into an array
  open FH, "<$filename" or croak "Cannot open $filename: $!";
  chomp(my @lines = <FH>);
  close FH;

  # Weed out comments and blank lines
  @lines = grep(!/^\s*\#/, @lines);
  @lines = grep(!/^\s*$/, @lines);

  # Default root value:
  my $root_value = 'ROOT';

  # Optionally, get column names from first line, pass column names to Tree::Numbered->new method
  # Column names cannot have spaces.
  my %args_hash = ();
  my @column_names;

  my $first_line = $self->_trim($lines[0]);
  # Initiate the column names array if asked for
  if ($use_column_names) {
    # Shift off first line (column names) from contents
    shift(@lines);
    # Get column names from first line
    my $column_names_ref = $self->_getColumnNamesFile($first_line);
    @column_names = @$column_names_ref;
  }
  # When not using column names, we have to scan all lines in the text file to get the one with most columns, as some lines, including the first, may have omitted the last column(s).
  # The line with most columns will decide the number of columns used.
  else {
    # Get max columns
    my $max_cols = $self->_getMaxColumnsFile(\@lines);
    # Use default column names ('serial', 'parent', 'Value', 'Value2', 'Value3', etc) if no column names were given
    @column_names[0..2] = ('serial', 'parent', 'Value');
    for (my $i = 3; $i < $max_cols; $i++) {
      $column_names[$i] = 'Value'.($i-1);
    }
  }
  # The argument hash for the root node
  foreach my $column_name (@column_names) {
    $args_hash{$column_name} = $root_value;
  }

  # Create a root node to tie all top level nodes
  $self = $self->new(%args_hash);

  # Assume that first line is a top level node
  # Use a hash, where the key is the indentation and the value is the level
  my %level_indent = ();
  # Use first top level node as start values
  my $current_indent = $self->_indented($lines[0]);
  my $previous_indent = $self->_indented($lines[0]);
  my $current_level = 0;
  $level_indent{$current_indent} = 0;

  my $node = $self;

  # Loop through lines
  for (my $i = 0; $i < @lines; $i++) {
    my $line = $self->_trim($lines[$i]);
    # Split possible line fields, keep quotes, Text::ParseWords for details
    my @line_fields = &parse_line('\s+', 1, $line);
    @line_fields = $self->_strip_quotes(@line_fields);
    my $value = $line_fields[0];

    $current_indent = $self->_indented($lines[$i]);
    $previous_indent = ($i > 0) ? $self->_indented($lines[$i-1]) : $self->_indented($lines[0]);

    # Down one level ?
    if ($current_indent > $previous_indent) {
      # We never go down more than one level at a time
      $self = $node;
      $current_level++;
    }

    # Up one or more levels ?
    elsif ($current_indent < $previous_indent) {
      # We may go up one or more levels at a time

      # BUGFIX - BEGIN
      # Bug in Tree-Numbered-Tools-1.01:
      # Warning message "Use of uninitialized value in subtraction (-)" when nodes at the first line or lines use a higher indent level than following lines.
      # The warning message is caused by $current_indent having a undefined value.
      # The solution is to set $current_indent to 0 and show a customized warning message.
      # (NOT reported in bug ticket http://rt.cpan.org/Public/Bug/Display.html?id=48068)
      # Bugfix added in 1.02 (2009-07-25).
      if (!defined $level_indent{$current_indent})
        {
          $level_indent{$current_indent} = 0;
          my $warn_lines = $i ? "'$lines[$i-1]'\n'$lines[$i]'\n'$lines[$i+1]'\n" : "'$lines[0]'\n'$lines[1]'\n'$lines[2]'\n";
          warn "WARNING: One or more of the following line seems to be incorrectly indented:\n$warn_lines";
        }
      # BUGFIX - END
      my $up_levels = $level_indent{$previous_indent} - $level_indent{$current_indent};
      $current_level = $current_level - $up_levels;
      foreach (1..$up_levels) {
	$self = $self->getParentRef;
      }
    }

    # Determine fields used
    if ($use_column_names) {
      my $j = 0;
      foreach my $column_name (@column_names) {
	$args_hash{$column_name} = $line_fields[$j++];
      }

    }
    else {
      # Default field 'Value' if no column names
      $args_hash{Value} = $value;
    }
    # Append node
    $node = $self->append(%args_hash);

    # Save current level state
    $level_indent{$current_indent} = $current_level;
  }

  # Up to top level, to get the entire tree object
  while ($self->getNumber != 1) {
    $self = $self->getParentRef;
  }

  # Set object properties
  # Initiate the column names variable so the outside world can use getColumnNames
  # (will return undef if use_column_names was set to false)
  $self->{COLUMN_NAMES_REF} = \@column_names;
  $self->{SOURCE_TYPE} = 'File';
  $self->{SOURCE_NAME} = $filename;

  # Return the tree object
  return $self;
}

=cut

=head2 readArray()

  readArray(
            arrayref         => $arrayref,
            use_column_names => $use_column_names,
           );

Reads $arrayref, returns a Tree::Numbered object.
$use_column_names is a boolean, if set (default), assumes that the first array row contains column names.

=cut

sub readArray {
  my $self = shift;
  # Get args
  my %args = ( 
	      arrayref         => '',
	      use_column_names => 1, # Assume column names by default
	      @_,         # argument pair list goes here
	     );
  my $arrayref = $args{arrayref} or croak "Missing array";
  my $use_column_names = $args{use_column_names};

  # Get the array
  my @array = @$arrayref;

  # Get first element
  my @first_element = @{$array[0]};
  croak "The array must have at least three columns: 'serial', 'parent', and 'Value'" if (@first_element < 3);

  my @column_names = ();

  # Shift off first element (column names) from array if we are using column names.
  if ($use_column_names) {
    @column_names = @first_element;
    shift @array;
  }
  # use default column names ('serial', 'parent', 'Value', 'Value2', 'Value3', etc) if no column names were given
  else {
    @column_names[0..2] = ('serial', 'parent', 'Value');
    for (my $i = 3; $i < @first_element; $i++) {
      $column_names[$i] = 'Value'.($i-1);
    }
  }

  # BUGFIX BEGIN
  # First column's name must be 'serial' (lower case).
  croak "The first column's name must be 'serial' (lower case)" if ($column_names[0] ne 'serial');
  # BUGFIX END

  # BUGFIX - BEGIN
  # Bug in Tree-Numbered-Tools-1.01:
  # http://rt.cpan.org/Public/Bug/Display.html?id=48068
  # Bugfix added in 1.02 (2009-07-24), suggested by Daniel Higgins:
  # Check column 'serial' and 'parent', both must be numeric integer values.
  # Then sort array numerically by 'parent' column to avoid append() error later, bug occurs with unsorted arrays.
  # Check for valid integers.
  for (my $i = 0; $i < @array; $i++) 
    {
      # Get element and it fields
      my @element_fields = @{$array[$i]};
      # Get current node and parent node numbers
      my $serial = $element_fields[0];
      my $parent = $element_fields[1];
      croak "The 'serial' element '$serial' in row $i isn't an integer'" if (!_isInteger($serial));
      croak "The 'parent' element '$parent' in row $i isn't an integer'" if (!_isInteger($parent));
    }
  # Sort array.
  @array = sort {
    ($a->[1] <=> $b->[1]) } @array;
  # BUGFIX - END

  # Get root node
  my @root_node = @{$array[0]};

  # Create argument hash using column names as keys and root node as values
  my %args_hash = ();
  for (my $i = 0; $i < @column_names; $i++) {
    $args_hash{$column_names[$i]} = $root_node[$i];
  }

  # Shift off the root node from the array
  shift @array;

  # Create a root node to tie all top level nodes
  $self = $self->new(
		     %args_hash
		    );

  # Loop through elements
  for (my $i = 0; $i < @array; $i++) {
    # Get element and it fields
    my @element_fields = @{$array[$i]};

    # Get current node and parent node numbers
    my $serial = $element_fields[0];
    my $parent = $element_fields[1];

    # Determine fields used
    my $j = 0;
    foreach my $column_name (@column_names) {
      $args_hash{$column_name} = $element_fields[$j++];
    }

    # BUGFIX - BEGIN
    # Bug in Tree-Numbered-Tools-1.01:
    # http://rt.cpan.org/Public/Bug/Display.html?id=48068
    # Bugfix added in 1.02 (2009-07-24), suggested by Daniel Higgins:
    our $parentnode=undef;
    $self->allProcess( sub {
                         my ($self,$parent) = @_;
                         our $parentnode;
                         $_ = $self->getserial ;
                         $parentnode = $self if $_ == $parent ;
                       },
                       $parent );

    # Add current node to its parent
    my $node = $parentnode ;
    $node = $node->append(%args_hash);
    # BUGFIX - END
  }

  # Set object properties
  # Initiate the column names variable so the outside world can use getColumnNames
  # (will return undef if use_column_names was set to false)
  # Column names serial and parent should not be included in column names list, shift them off
  shift @column_names if @column_names;
  shift @column_names if @column_names;
  $self->{COLUMN_NAMES_REF} = \@column_names;
  $self->{SOURCE_TYPE} = 'Array';
  $self->{SOURCE_NAME} = undef;

  # Return the tree object
  return $self;
}


=head2 readSQL()

  readSQL(
          dbh => $dbh,
          sql => $sql,
         );

Fetches an array using the database handle $dbh and the SQL statement $sql, returns a tree object.
Uses readArray() internally to create the tree object.
To map column names in the database table to tree column names, use the SQL 'AS' statement.
Always get used to double quote the alias name, to make the SQL statement database type independent.
Without alias quotes, reserved SQL words such as 'AS' will work as an alias on MySQL but not on PgSQL (PgSQL returns lower case aliases unless double quoted).
Remember that aliases cannot contain spaces, as they reflect the column names, which in turn are used for methods getting a column's value. For example, to obtain a value for a column created from an alias called 'MyColumn', the method getMyColumn() will be used. An alias called 'My Column' will try to call the method getMy Column(), which of course will cause a run-time syntax error.

  Example 1:
  # GOOD, works on both MySQL and PgSQL
  my $sql = 'SELECT serial AS "Serial", parent AS "Parent", name AS "Name", url AS "URL" FROM mytable ORDER BY Serial';

  Example 2:
  # BAD, works on MySQL but not on PgSQL
  my $sql = 'SELECT serial AS Serial, parent AS Parent, name AS Name, url AS URL FROM mytable ORDER BY Serial';

  Example 3:
  # BAD, single quotes will not do on PgSQL
  my $sql = "SELECT serial AS 'Serial', parent AS 'Parent', name AS 'Name', url AS 'URL' FROM mytable ORDER BY Serial";

Well, if you forgot to quote the aliases, readSQL() adds the quotes for you.
You should just be aware of that unquoted aliases doesn't always work as expected in your daily SQL life. :-)

=cut

sub readSQL {
  my $self = shift;
  # Get args
  my %args = ( 
	      dbh => '',
	      sql => '',
	      @_,         # argument pair list goes here
	     );
  my $dbh = $args{dbh} or croak "Missing DB handle";
  my $sql = $args{sql} or croak "Missing SQL statement" ;

  # Quote any SQL aliases
  $sql = $self->_sql_alias_quoted($sql);

  # Get array reference
  # Column names are always used, named after the SQL columns
  my $sth = $dbh->prepare($sql) or croak $dbh->errstr;
  $sth->execute or croak $dbh->errstr;
  # Get column names
  my $colnamesref = $sth->{'NAME'};
  my $arrayref = $sth->fetchall_arrayref or croak $dbh->errstr;

  # Insert column names as first element into the retreived array
  unshift @$arrayref, $colnamesref;

  # Use readArray to create the tree
  my $use_column_names = 1;
  $self = $self->readArray(
			   arrayref         => $arrayref,
			   use_column_names => 1,
			  );

  # Set object properties
  # Initiate the column names variable so the outside world can use getColumnNames
  # $self->{COLUMN_NAMES_REF} = $colnamesref; # Already set from readArray
  $self->{SOURCE_TYPE} = 'SQL';
  $self->{SOURCE_NAME} = undef;

  # Return the tree object
  return $self;
}

=head2 readDB()

  readDB(
         dbh   => $dbh,
         table => $table,
         );

Fetches an array using the database handle $dbh from the table $table, returns a Tree::Numbered object.
This is a wrapper for the readSQL() mehod using the SQL statement 'SELECT * from $table'.
It is recommended to use the more flexible readSQL() instead, as you can map names using the 'AS' statement.

=cut

sub readDB {
  my $self = shift;
  # Get args
  my %args = ( 
	      dbh   => '',
	      table => '',
	      @_,         # argument pair list goes here
	     );
  my $dbh = $args{dbh} or croak "Missing DB handle";
  my $table = $args{table} or croak "Missing database table name" ;
  my $sql = "SELECT * FROM $table";

  # Use readSQL to create the tree
  $self = $self->readSQL(
			 dbh => $dbh,
			 sql => $sql,
			);

  # Set object properties
  # Initiate the column names variable so the outside world can use getColumnNames
  # $self->{COLUMN_NAMES_REF} = $colnamesref; # Already set from readSQL
  $self->{SOURCE_TYPE} = 'DB';
  $self->{SOURCE_NAME} = $table;

  # Return the tree object
  return $self;
}


=head2 outputFile()

  outputFile(
             first_indent     => $first_indent,
             level_indent     => $level_indent,
             column_indent    => $column_indent,
            );

The ouputFile() method returns the tree structure as used in the file format.
The purpouse of this method is to display/create an overview of a tree object, both the tree hierarchy and each node's properties, which easily can be modified with a text editor to create a new tree object using the readFile() method.

All arguments are optional.
Formatting arguments:
$first_indent decides the position of the first column.
$level_indent decides the indenting for each node level.
$column_indent decides the number of spaces to separate columns.

=cut

sub outputFile {
  my $self = shift;
  my %args = (
	      first_indent     => 2,
	      level_indent     => 2,
	      column_indent    => 2,
	      @_,         # argument pair list goes here
	     );

  # Get list of column names
  my $column_names_ref = $self->getColumnNames();
  # If column names are defined, compare number of columns with number of fields in tree
  my @column_names = @$column_names_ref;
  my @field_names = $self->getFieldNames;

  # If column names aren't defined ($column_names_ref returns undef), use tree field names (arbitrary order).
  @column_names = @field_names if (!$column_names_ref);

  # Create the indented tree structure and optional additional columns
  my $first_indent = $args{first_indent};
  my $level_indent = $args{level_indent};
  my $column_indent = $args{column_indent};
  my $first_indent_string = ' ' x $first_indent;
  my $indent_string = ' ' x $level_indent;;
  my $tree_structure = '';
  # Use a copy of the array, as it will be modified.
  my @extra_column_names = @column_names;
  my $first_column_name = shift(@extra_column_names);

  # Calculate each node value's string length, needed for pretty printing.
  # The longest string in each column will decide each column's position.
  # The first column's value will be indented according to its tree level.
  # Thus, the indenting has to be included when calculate the string length for the first column.

  # Array to store each column's position, needed for pretty printing
  # Initiate the @column_pos array with the length of each column_name, in case that the column name is longer than any of its values.
  my @column_pos = ();
  foreach (@column_names) {
    push @column_pos, length($_);
  }

  # Calculate first column's position, including indenting
  foreach my $node_number ($self->listChildNumbers) {
    my @values = $self->follow($node_number, $first_column_name);
    # Calculate spaces before this node's string
    my $node_indent_length = $first_indent + (scalar(@values) - 1) * $level_indent;
    # Add this node's string length
    my $first_value = pop(@values);
    my $first_value_string_length = length($first_value);
    # Add 2 to string length if quoting is needed
    $first_value_string_length = $first_value_string_length + 2 if ($first_value =~ m/\s+/);
    # Caclulate entire length for first column
    my $first_column_string_length = $node_indent_length + $first_value_string_length + 1;
    $column_pos[0] = $first_column_string_length if ($first_column_string_length > $column_pos[0]);
    # Calculate extra columns' positions
    for (my $i = 1; $i < @column_names; $i++) {
      # Last value in array contains this node's value 
      my @values = $self->follow($node_number, $column_names[$i]);
      my $value = pop(@values);
      # If no $value (last column may be blank, which returns undef), ignore.
      if ($value) {
	my $column_string_length = ($value) ? length($value) : 0;
	# Add 2 to length if quoting is needed
	$column_string_length = $column_string_length + 2 if ($value =~ m/\s+/);
	$column_pos[$i] = $column_string_length if ($column_string_length > $column_pos[$i]);
      }
    }
  }

  # Create contents string
  foreach my $node_number ($self->listChildNumbers) {
    my $line = $first_indent_string;
    # The array contains a list of all the node's parent values as well as its own value
    my @values = $self->follow($node_number, $first_column_name);
    # The scalar contains only the node's own value
    my $value = pop(@values);
    $line .= $indent_string x scalar(@values);
    $line .= $value;
    # Add any necessary spaces after the value
    $line .= " " x ($column_pos[0] - length($line) + $column_indent - 1);
    # Loop through all other columns but the first
    for (my $i = 1; $i < @column_names; $i++) {
      my @values = $self->follow($node_number, $column_names[$i]);
      my $column_value = pop(@values);
      # If no $value (last column may be blank, which returns undef), ignore.
      if ($column_value) {
	# Quote if necessary
	$column_value = "'".$column_value."'" if ($column_value =~ m/\s+/);
	# Pretty printing
	$line .= $column_value;
	$line .= " " x ($column_pos[$i] - length($column_value) + $column_indent);
      }
    }
    $tree_structure .= "$line\n";
  }

  # Insert columns at top of tree contents
  my $header = $first_indent_string;
  for (my $i = 0; $i < @column_names; $i++) {
    $header .= $column_names[$i];
    # Dirty hack
    if ($i == 0) {
      $header .= " " x ($column_pos[$i] - length($column_names[$i]) - $first_indent + $column_indent - 1);
    }
    else {
      $header .= " " x ($column_pos[$i] - length($column_names[$i]) + $column_indent);
    }
  }
  $header .= "\n";
  # Add underscore to columns, replace all non-space characters with '-'
  (my $underscore = $header) =~ s/\S/-/g;
  # Replace first character with a comment sign
  $underscore =~ s/^./\#/g;

  # Insert comments at top
  my $package = __PACKAGE__ || '';
  my $method = (caller(0))[3] || '';
  # Replace last :: with ->
  $method =~ s/$package\:\:/->/;
  $method .= '()' if $method;
  my $comments = <<COMMENT;
# Tree contents generated by $package$method.
# Redirect this output to a file called for example 'tree.txt'.
# To create a tree object, use the $package->readFile() method with 'tree.txt' as the filename argument.
# For details, check the $package documentation.
#
COMMENT

  # Return the entire output
  my $output = $comments.$header.$underscore.$tree_structure;
  return $output;
}

=cut

=head2 outputArray()

  outputArray();

The outputArray() method returns a Perl code snippet for creating a new tree object based on the current tree object, using an array reference and the readArray() method.
The purpouse of this method is to easily create Perl code from whatever tree source, possibly modify/add/delete elements (nodes) in the array reference, and then use the readArray() method to create a new tree object.

=cut

sub outputArray {

  my $self = shift;
#   my %args = (
# 	      @_,         # argument pair list goes here
# 	     );

  # Get list of column names
  my $column_names_ref = $self->getColumnNames();
  my @column_names = @$column_names_ref;

  # If column names aren't defined ($column_names_ref returns undef), use tree field names (arbitrary order).
  my @field_names = $self->getFieldNames;
  if (!$column_names_ref)  {
    @column_names = @field_names 
  }
  # Insert required columns:
  my @required_column_names = ('serial', 'parent');

  my $arrayref_code = 
'my $arrayref = [
  		[qw('.join(' ', @required_column_names, @column_names).')],
 		[1, 0, ' . "'ROOT', " x @column_names . '],
';

   foreach my $node_number ($self->listChildNumbers) {
     my $node = $self->getSubTree($node_number);
     my $parent_node = $node->getParentRef;
     my $parent_number = $parent_node->getNumber;
     my $value_code = '';
     foreach my $column_name (@column_names) {
       # Last value in array contains this node's value 
       my @values = $self->follow($node_number, $column_name);
       my $value = pop(@values);
       # Set value to empty string if undefined
       $value = '' if !$value;
       # Escape possible quote characters in values
       $value =~ s/\'/\\\'/g;
       # Add quotes and comma
       $value_code .= "'$value', ";
     }
     $arrayref_code .= " 		[$node_number, $parent_number, $value_code],\n"; 
   }
  $arrayref_code .=
' 	       ];
';

  my $extra_code = '# Create a new tree object using the array above
my $use_column_names = 1;
my $tree = Tree::Numbered::Tools->readArray(
					    arrayref         => $arrayref,
					    use_column_names => $use_column_names,
					   );
# Display the Perl code for the created object
print $tree->outputArray();
';

  # Insert comments at top
  my $package = __PACKAGE__ || '';
  my $method = (caller(0))[3] || '';
  # Replace last :: with ->
  $method =~ s/$package\:\:/->/;
  $method .= '()' if $method;
  my $comments = <<COMMENT;
#
# Perl code generated by $package$method.
# Redirect this output to a file called for example 'tree.pl'.
# The run from the command line:
# perl -w tree.pl
# For details, check the $package documentation.
#
COMMENT

  # Insert program header
  ###  my $perl_binary = $^X; # BUGFIX: Normally shows just 'perl' instead of '/usr/bin/perl'
  my $perl_binary = `which perl`;
  chomp $perl_binary;
  my $header = '#!' . $perl_binary  . " -w\n";
  $header .= "use strict;\n";
  $header .= "use $package;\n";

  # Return the entire output (complete program snippet)
  my $output = $header.$comments.$arrayref_code.$extra_code;
  return $output;
}

=cut

=head2 outputSQL()

  outputSQL(
            table => $table,
            dbs   => $dbs,
            drop  => $drop,
           );

The outputSQL() method returns SQL statements for creating records in the database table $table.
The purpouse of this method is to create SQL statements for later use.
If you want to create the records instead of the SQL stataments, use the outputDB() method instead.

The $dbs argument is optional, sets the database server type, defaults to 'mysql'.
Currently supported database server types are MySQL and PostgreSQL.
Due to inconsistent naming convention for PostgreSQL ($dbh->{Driver}->{Name} returns 'Pg' while $dbh->get_info( SQL_DBMS_NAME ) returns 'PostgreSQL'), valid 'dbs' values when using PostgreSQL are: 'postgres', 'PostgreSQL', 'PgSQL', and 'Pg'.
The 'dbs' argument is case-insensitive.
The generated SQL code has been tested with MySQL 5.0.77 and PostgreSQL 8.2.13 on FreeBSD 7.2, but may need modification for use with other database servers/versions/platforms.

The $drop argument is optional, if true (false by default), inserts a DROP TABLE statement before the CREATE TABLE statement.
If false, the DROP TABLE statement will be left outcommented.

=cut

sub outputSQL {

  my $self = shift;
  my %args = (
	      table     => '',
	      dbs       => 'mysql',
	      drop      => '',
	      @_,         # argument pair list goes here
	     );

  # Die on missing table name
  my $table = $args{table} or croak "Missing table name";
  my $dbs = $args{dbs};
  my $drop = $args{drop};

  # Get all SQL statements into array refs
  my $sql_statements_ref = $self->_sql_statements(%args);
  my @sql_statements = @$sql_statements_ref;
  my ($sql_header_ref, $drop_table_ref, $create_table_ref, $insert_into_ref, $create_index_ref, $comments_ref) = @sql_statements;

  # Format SQL statements and comments for string output
  my $comments_header = $comments_ref->[0];
  my $comments1 = $comments_ref->[1];
  $comments1 .= "\n" if $comments1;
  my $comments2 = $comments_ref->[2];
  $comments2 .= "\n" if $comments2;
  my $sql_header = join("\n", @$sql_header_ref);
  $sql_header .= "\n" if $sql_header;
  my $drop_table = join("\n", @$drop_table_ref);
  $drop_table .= "\n" if $drop_table;
  my $create_table = join("\n", @$create_table_ref);
  $create_table .= "\n" if $create_table;
  my $insert_into = join("\n", @$insert_into_ref);
  $insert_into .= "\n" if $insert_into;
  my $create_index = join("\n", @$create_index_ref);
  $create_index .= "\n" if $create_index;

  # Return the entire output (SQL statements and comments)
  my $output = $comments_header.$sql_header.$comments1.$drop_table.$create_table.$insert_into.$comments2.$create_index;
  return $output;

}

=cut

=head2 outputDB()

  outputDB(
           dbh   => $dbh,
           table => $table,
           drop  => $drop,
          );

The outputDB() method creates a database table $table using the database handle $dbh, and insert tree nodes as table records.
The purpouse of this method is to store a tree in a table. The tree object can be recreated by using one of the readSQL() or readDB methods.
This method uses outputSQL() internally to get the SQL statements, and executes them.
If you want to tie a tree object to a database table in "real time", first use this method with an existing tree object to create the database table. Then create a tree object using the Tree::Numbered::DB module by Yosef Meller, which will reflect changes in the database table as you modify the tree nodes.

The $dbh is a database handle.
The $table and $drop arguments are the same as for outputSQL().
There is no $dbs argument, as the database server type is determined by the $dbh argument ($dbh->{Driver}->{Name} more exactly).

=cut

sub outputDB {

  my $self = shift;
  my %args = (
	      dbh       => '',
	      table     => '',
	      drop      => '',
	      @_,         # argument pair list goes here
	     );

  # Die on missing DB handle and/or table name
  my $dbh = $args{dbh} or croak "Missing DB handle";
  my $table = $args{table} or croak "Missing table name";
  $args{dbs} = $dbh->{Driver}->{Name};
  my $dbs = $args{dbs};
  my $drop = $args{drop};

  # Get all SQL statements into array refs
  my $sql_statements_ref = $self->_sql_statements(%args);
  my @sql_statements = @$sql_statements_ref;
  my ($sql_header_ref, $drop_table_ref, $create_table_ref, $insert_into_ref, $create_index_ref, $comments_ref) = @sql_statements;

  my $sql = '';

  # We will not execute comments nor empty strings in array elements.
  # Execute SQL headers, if any
  foreach (@$sql_header_ref) {
    $sql = $_;
    if ($sql) {
      $dbh->do($sql) or croak $dbh->errstr;
    }
  }
  # Execute DROP TABLE, if $drop
  if ($drop) {
###    $sql = $drop_table_ref->[0];
    $sql = $drop_table_ref->[1];
    if ($sql) {
      $dbh->do($sql) or croak $dbh->errstr;
    }
  }
  # Execute CREATE TABLE
  $sql = $create_table_ref->[0];
  if ($sql) {
    $dbh->do($sql) or croak $dbh->errstr;
  }
  # Execute INSERT INTO statements
  foreach (@$insert_into_ref) {
    $sql = $_;
    if ($sql) {
      $dbh->do($sql) or croak $dbh->errstr;
    }
  }
  # Execute CREATE INDEX statements, if any
  foreach (@$create_index_ref) {
    $sql = $_;
    if ($sql) {
      $dbh->do($sql) or croak $dbh->errstr;
    }
  }

  return 1;

}

=cut

=head2 convertFile2Array()

  convertFile2Array(
                    filename         => $filename,
                    use_column_names => $use_column_names,
                   );

Calls readFile() followed by outputArray().

=cut

sub convertFile2Array {
  my $self = shift;
###  my $tree = $self->readFile(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readFile(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputArray();
}

=cut

=head2 convertFile2SQL()

  convertFile2SQL(
                  filename         => $filename,
                  use_column_names => $use_column_names,
                  table            => $table,
                  dbs              => $dbs,
                  drop             => $drop,
                 );

Calls readFile() followed by outputSQL().

=cut

sub convertFile2SQL {
  my $self = shift;
###  my $tree = $self->readFile(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readFile(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputSQL(@_);
}

=cut

=head2 convertFile2DB()

  convertFile2DB(
                 filename         => $filename,
                 use_column_names => $use_column_names,
                 dbh              => $dbh,
                 table            => $table,
                 drop             => $drop,
                 );

Calls readFile() followed by outputDB().

=cut

sub convertFile2DB {
  my $self = shift;
###  my $tree = $self->readFile(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readFile(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputDB(@_);
}

=cut

=head2 convertArray2File()

  convertArray2File(
                    arrayref         => $arrayref,
                    use_column_names => $use_column_names,
                    first_indent     => $first_indent,
                    level_indent     => $level_indent,
                    column_indent    => $column_indent,
                   );

Calls readArray() followed by outputFile().

=cut

sub convertArray2File {
  my $self = shift;
###  my $tree = $self->readArray(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readArray(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputFile(@_);
}

=cut

=head2 convertArray2SQL()

  convertArray2SQL(
                   arrayref         => $arrayref,
                   use_column_names => $use_column_names,
                   table            => $table,
                   dbs              => $dbs,
                   drop             => $drop,
                  );

Calls readArray() followed by outputSQL().

=cut

sub convertArray2SQL {
  my $self = shift;
###  my $tree = $self->readArray(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readArray(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputSQL(@_);
}

=cut

=head2 convertArray2DB()

  convertArray2DB(
                  arrayref         => $arrayref,
                  use_column_names => $use_column_names,
	          dbh              => $dbh,
	          table            => $table,
	          drop             => $drop,
                 );

Calls readArray() followed by outputDB().

=cut

sub convertArray2DB {
  my $self = shift;
###  my $tree = $self->readArray(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readArray(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputDB(@_);
}

=cut

=head2 convertSQL2File()

  convertSQL2File(
   	          dbh           => $dbh,
	          sql           => $sql,
	          first_indent  => $first_indent,
	          level_indent  => $level_indent,
	          column_indent => $column_indent,
                 );

Calls readSQL() followed by outputFile().

=cut

sub convertSQL2File {
  my $self = shift;
###  my $tree = $self->readSQL(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readSQL(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputFile(@_);
}

=cut

=head2 convertSQL2Array()

  convertSQL2Array(
   	          dbh           => $dbh,
	          sql           => $sql,
                 );

Calls readSQL() followed by outputArray().

=cut

sub convertSQL2Array {
  my $self = shift;
###  my $tree = $self->readSQL(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readSQL(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputArray(@_);
}

=cut

=head2 convertSQL2DB()

  convertSQL2DB(
   	        dbh           => $dbh,
	        sql           => $sql,
	        dbh_dest      => $dbh_dest,
	        table         => $table,
	        drop          => $drop,
               );

Calls readSQL() followed by outputDB().

NOTE: There are two database handles, $dbh and $dbh_dest, in case you use one database as a source and another as destination.  The argument $dbh_dest is optional, defaults to $dbh, assumes using the same database handle for both source and destination.
Using different database handles, this method can be useful to migrate a tree table from MySQL to PostgreSQL, for example.

=cut

sub convertSQL2DB {
  my $self = shift;
  my %args_sql = (
		  dbh      => '',
		  sql      => '',
		  @_,         # argument pair list goes here
		 );
  my %args_db = (
		 dbh_dest => $args_sql{dbh},
		 table    => '',
		 drop     => '',
		 @_,         # argument pair list goes here
		);
  $args_db{dbh} = $args_db{dbh_dest};
###  my $tree = $self->readSQL(%args_sql);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readSQL(%args_sql); # SOLUTION: Always use a new tree object.
  return $tree->outputDB(%args_db);
}

=cut

=head2 convertDB2File()

  convertDB2File(
  	         dbh           => $dbh,
		 table         => $table,
	         first_indent  => $first_indent,
	         level_indent  => $level_indent,
	         column_indent => $column_indent,
                );

Calls readDB() followed by outputFile().

=cut

sub convertDB2File {
  my $self = shift;
###  my $tree = $self->readDB(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readDB(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputFile(@_);
}

=cut

=head2 convertDB2Array()

  convertDB2Array(
  	          dbh           => $dbh,
		  table         => $table,
                 );

Calls readDB() followed by outputArray().

=cut

sub convertDB2Array {
  my $self = shift;
###  my $tree = $self->readDB(@_);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readDB(@_); # SOLUTION: Always use a new tree object.
  return $tree->outputArray(@_);
}

=cut

=head2 convertDB2SQL()

  convertDB2SQL(
   	        dbh           => $dbh,
	        sql           => $sql,
	        table         => $table,
	        table_dest    => $table_dest,
	        dbs           => $dbs,
	        drop          => $drop,
               );

Calls readDB() followed by outputSQL().
NOTE: $table is the source table, $table_dest is the table name used in the generated SQL statements.

=cut

sub convertDB2SQL {
  my $self = shift;
  my %args_db = (
		 dbh           => '',
		 sql           => '',
		 table         => '',
		 @_,         # argument pair list goes here
		);
  my %args_sql = (
		  table_dest    => '',
		  dbs           => 'mysql',
		  drop          => '',
		  @_,         # argument pair list goes here
		 );
  $args_sql{table} = $args_db{table_dest};
###  my $tree = $self->readDB(%args_db);              # BUG: Using an existing tree object, the tree nodes are not replaced.
  my $tree = Tree::Numbered::Tools->readDB(%args_db); # SOLUTION: Always use a new tree object.
  return $tree->outputSQL(%args_sql);
}

=cut

=head2 getColumnNames()

  Returns a list (in array context) or a ref to a list (in scalar context) of the column names.
  The list corresponds to:
    Using a file           - the words on the first non-comment or blank line.
    Using an array         - the first array row.
    Using an SQL statement - the SQL field names
    Using a database table - the table column names

  Using this method on a tree created using with use_column_names set to 0 returns the default column names: 'Value', 'Value2', 'Value3', etc.

=cut

sub getColumnNames {
  my $self = shift;
  my $ary_ref = $self->{COLUMN_NAMES_REF};
  my @ary = @$ary_ref;
  return (wantarray) ? @ary : $ary_ref;
}

=head2 getSourceType()

  Returns one of the strings 'File', 'Array', 'SQL', 'DB' depending on which source was used to create the tree object.

=cut

sub getSourceType {
  my $self = shift;
  return $self->{SOURCE_TYPE};
}

=head2 getSourceName()

  Returns the file name if the source type is 'File', or the database table name if the source type is 'DB'.
  Returns undef if source type is 'Array' or 'SQL'.

=cut

sub getSourceName {
  my $self = shift;
  return $self->{SOURCE_NAME};
}

# version
sub version{
  my $self = shift;
  return $VERSION;
}

#----------- Internal subs -------------

# Get column names from file (internal use only)
# Use getColumnNames from the outside world
sub _getColumnNamesFile {
  my $self = shift;
  my $first_line = shift;
  my @column_names = &parse_line('\s+', 0, $first_line);
  return \@column_names;
}

# Get the max number of columns in a file contents, passed as an array of lines.
sub _getMaxColumnsFile {
  my $self = shift;
  my $lines_ref = shift;
  my @lines = @$lines_ref;
  my $max_cols = 0;
  foreach my $line (@lines) {
    my @columns = &parse_line('\s+', 0, $line);
    $max_cols = scalar(@columns) if (scalar(@columns) > $max_cols);
  }
  return $max_cols;
}

sub _trim {
  my $self = shift;
  my @s = @_;
  for (@s) {
    s/^\s+//;
    s/\s+$//;
  }
  return wantarray ? @s : $s[0];
}

sub _strip_quotes {
  my $self = shift;
  my @s = @_;
  for (@s) {
    s/^\'(.*)\'$/$1/;
    s/^\"(.*)\"$/$1/;
#    s/^[\'|\"]//;
#    s/[\'|\"]$//;
  }
  return wantarray ? @s : $s[0];
}

sub _indented {
  my $self = shift;
  my $s = shift;
  $s =~ s/^(\s*).*/$1/;
  return length($s);
}

sub _isInteger {
  my $string = shift;
  return ($string =~ /^[+-]?\d+$/) ? 1 : 0;
}

# Quotes SQL aliases (the word that follows 'AS' in an SQL statement).
# Used by readSQL() to ensure all aliases are quoted.
# Unquoted aliases works on MySQL but not on PgSQL.
sub _sql_alias_quoted {
  my $self = shift;
  my $sql = shift;
  # Split the SQL statement into an array of words.

  # When found the word 'AS' (without quotes, case insensitive), the following word is an alias.
  # If the following word (the alias) isn't double quoted, double quote it.
  # It is possible to use a double quote character as part of the alias, escaping it with an extra double quote:
  # SELECT serial as """SERIAL""" FROM treetest
  # will create the alias "SERIAL", including the double quotes.
  # This means, if the alias was quoted with 1, 3, 5, or any odd number of double quotes, there is no need to quote the alias, as it will work any way.
  # If the alias was quoted with 2, 4, 6, or any even number of double quotes, there is no need to quote the alias, as the SQL statement was invalid anyway. ;-)
  # Summary: never double quote an already double quoted alias.

  # It is possible to use a reserved SQL word as an alias, as long as it is quoted:
  # SELECT serial AS "AS" from treetest
  # On PgSQL, it even works without quotes:
  # SELECT serial AS AS FROM treetest
  # This could cause a parsing error, as the second AS could try to quote the following word ('FROM' in the example above).
  # To avoid this, test exactly on the word 'AS' (without quotes).
  # When found, the following word in the array will be double quoted.
  # When testing the next element ('"AS"' in the example above) for the word 'AS', it will not match.

  # Quoted aliases may have spaces:
  # SELECT serial AS "My Serial" FROM treetest
  # This means that we can't just split on \s+
  # Solution: Text::ParseWords takes care of not splitting quoted words. Nevertheless, quotes have to be added, as Text::ParseWords removes them.
  # The concern about aliases with spaces is to make this sub generic.
  # Aliases with spaces will never occur generating a tree, as the aliases corresponds to the field names, which can contain spaces, so aliases with spaces will not work with trees.

  # Bugfix in 1.03:
  # Warning message when SQL string contains trailing newline(s)
  ### chomp $sql; BAD SOLUTION: works ONLY for ones single trailing newline, not for two newlines.
  # Better solution: trim leading and trailing whitespace characters [ \t\n\r\f];
  $sql =~ s/^\s+//;
  $sql =~ s/\s+$//;

  my @words = &parse_line('\s+', 0, $sql);
  for (my $i = 0; $i < @words; $i++) {
    # If reserved word AS, quote the following word
    if (uc($words[$i]) eq 'AS') {
      # Check for existing array element
      if ($words[$i+1]) {
	# The alias may include the following comma, which must follow the quote.
	if ($words[$i+1] =~ m/\,$/) {
	  $words[$i+1] =~ s/\,$/\"\,/;
	}
	else {
	  $words[$i+1] .= '"';
	}
	$words[$i+1] = '"'.$words[$i+1];
      }
    }
    #print $words[$i], "\n";
  }
  $sql = join(' ', @words);
  return $sql;
}

# Returns the SQL statements as an reference to a list of arrays references, where each element is one statement.
# The statements are separated by type: the CREATE TABLE statement goes in one array, all INSERT INTO statements in another array, etc.
sub _sql_statements {
  my $self = shift;

  my %args = (
	      table     => '',
	      dbs       => 'mysql',
	      drop      => '',
	      @_,         # argument pair list goes here
	     );

  # Die on missing table name
  my $table = $args{table} or croak "Missing table name";
  my $dbs = $args{dbs};
  my $drop = $args{drop};

  my @sql_header = ();
  my @drop_index_and_table = ();
  my @create_table = ();
  my @insert_into = ();
  my @create_index = ();
  my @comments = ();

  # Get list of column names
  my $column_names_ref = $self->getColumnNames();
  my @column_names = @$column_names_ref;

  # If column names aren't defined ($column_names_ref returns undef), use tree field names (arbitrary order).
  my @field_names = $self->getFieldNames;
  if (!$column_names_ref)  {
    @column_names = @field_names;
  }

  # Insert required columns:
  my @required_column_names = ('serial', 'parent');

  # Variables for the SQL statements 
  my $sql_header             = '';
  my $example_output_file    = 'insert-into.sql';
  my $drop_index             = '';
  my $drop_table             = '';
  my $create_table           = '';
  my $create_table_last_line = '';
  my $insert_into            = '';
  my $create_index           = '';
  my $field_type             = '';
  my $qc                     = '';
  my $sql_comment            = '';
  my $command_line           = '';
  my $comments               = '';
  # Use only lower case letters for columns names in SQL statements, even if column names may be mixed or upper case letters.
  my @column_names_sql = @column_names;
  @column_names_sql = grep(s/^(.+$)/lc($1)/e, @column_names_sql);

  # Database dependent SQL syntax
 SWITCH: for ($dbs) {
    # MySQL
    /^mysql$/i        && do {
      # No SQL header for MySQL
      # $sql_header   = '';
      # DROP TABLE statement for MySQL (outcommented if $drop is not set)
      $drop_table = "DROP TABLE IF EXISTS $table;";
      $sql_comment = "#";
      # CREATE TABLE statement for MySQL ('serial' and 'parent' columns only)
      $create_table = 
'CREATE TABLE '. $table . ' (
  `serial` int(11) NOT NULL auto_increment,
  `parent` int(11) NOT NULL default \'0\',
';
      # CREATE TABLE statement (last line) for MySQL
      $create_table_last_line = 
'  PRIMARY KEY  (serial)
) TYPE=MyISAM;';
      # No separate 'CREATE INDEX' for MySQL
      # $create_index = '';
      # Field type for MySQL
      $field_type = 'varchar(255) default NULL';
      # Quote character for MySQL
      $qc = '`';
      # Command line for MySQL
      $example_output_file = 'insert-into-mysql.sql';
      $command_line = "mysql -u root -pmysqlpassword test < $example_output_file";
      # Push dummy empty string comments
      push @comments, '', '';
      last SWITCH;
    };
    # PgSQL
    /^postgres$|^PostgreSQL$|^pgsql$|^pg$/i         && do {
      # SQL header for PostgresSQL
      $sql_header   = 
'SET SESSION AUTHORIZATION \'pgsql\';';
      push @sql_header, $sql_header;
      $sql_header   = 
'SET search_path = "public", pg_catalog;';
      push @sql_header, $sql_header;
      $comments   = 
'-- Definition';
      push @comments, $comments;

      # DROP INDEX statement for PostgresSQL (outcommented if $drop is not set)
      $drop_index = 'DROP INDEX IF EXISTS "'. $table .'_serial_index"'.";";
      # DROP TABLE statement for PostgresSQL (outcommented if $drop is not set)
      $drop_table = 'DROP TABLE IF EXISTS "'. $table .'"'.";";
      $sql_comment = "--";
      # CREATE TABLE statement for PostgresSQL ('serial' and 'parent' columns only)
      $create_table = 
'CREATE TABLE "'. $table .'" (
  "serial" integer,
  "parent" integer,
';
      # CREATE TABLE statement (last line) for PostgresSQL
      $create_table_last_line = 
') WITH OIDS;';
      # 'CREATE INDEX' for PostgresSQL
      $comments = 
'-- Indexes';
      push @comments, $comments;
      $create_index = 
'CREATE UNIQUE INDEX '.$table.'_serial_index ON '.$table.' USING btree (serial);';
      push @create_index, $create_index;
      # Field type for PostgresSQL
      $field_type = 'text';
      # Quote character for PostgresSQL
      $qc = '"';
      # Command line for PostgresSQL
      $example_output_file = 'insert-into-pgsql.sql';
      $command_line = "psql -q -U pgsql -d test -f $example_output_file";
      last SWITCH;
    };
    # DEFAULT
    croak "Database server type '$dbs' is not supported.";
  }

  # DROP TABLE statement (outcommented if $drop is not set)
  $drop_index = $sql_comment.' '.$drop_index if !$drop;
  push @drop_index_and_table, $drop_index;
  $drop_table = $sql_comment.' '.$drop_table if !$drop;
  push @drop_index_and_table, $drop_table;

  # CREATE TABLE statement

# MySQL
# DROP TABLE IF EXISTS junk;
# CREATE TABLE junk (
#   serial int(11) NOT NULL auto_increment,
#   parent int(11) NOT NULL default '0',
#   name varchar(255) default NULL,
#   url varchar(255) default NULL,
#   color varchar(255) default NULL,
#   permission varchar(255) default NULL,
#   visible varchar(255) default NULL,
#   PRIMARY KEY  (serial)
# ) TYPE=MyISAM;


# PostgreSQL
# SET SESSION AUTHORIZATION 'postgres';
# SET search_path = "public", pg_catalog;
# -- Definition
# DROP TABLE "public"."menu";
# CREATE TABLE "menu" (
#     "serial" integer,
#     "parent" integer,
#     "name" text,
#     "url" text,
#     "color" text,
#     "permission" text,
#     "visible" text
# ) WITH OIDS;
# -- Indexes
# CREATE UNIQUE INDEX serial ON menu USING btree (serial);

  for (my $i = 0; $i < @column_names_sql; $i++) {
    # Add quotes
    $create_table .= "  ".$qc.$column_names_sql[$i].$qc." $field_type";
    # Add comma for all but last value or if MySQL
    $create_table .= "," if (($i < @column_names_sql - 1) || lc($dbs) eq 'mysql') ;
    # Add newline
    $create_table .= "\n";
  }
  $create_table .= $create_table_last_line;

  push @create_table, $create_table;

  # INSERT INTO statements

# INSERT INTO `junk2` ( `serial` , `parent` , `name` , `url` , `color` , `permission` , `visible` ) 
# VALUES (
#   '1', '0', 'ROOT', 'ROOT', 'ROOT', 'ROOT', 'ROOT'
# );

  $insert_into =
"INSERT INTO $qc". $table ."$qc ( $qc".join("$qc, $qc", @required_column_names, @column_names_sql)."$qc )\n".
"VALUES (\n".
"  1, 0, " . "'ROOT', " x (@column_names_sql - 1). "'ROOT'\n".
');';
  push @insert_into, $insert_into;

  foreach my $node_number ($self->listChildNumbers) {
    my $node = $self->getSubTree($node_number);
    my $parent_node = $node->getParentRef;
    my $parent_number = $parent_node->getNumber;
    my $value_code = '';
    for (my $i = 0; $i < @column_names; $i++) {
      my $column_name = $column_names[$i];
      # Last value in array contains this node's value 
      my @values = $self->follow($node_number, $column_name);
      my $value = pop(@values);
      # Set value to empty string if undefined
      $value = '' if !$value;
      # Escape possible quote characters in values
      ### $value =~ s/\'/\\\'/g; # BUGFIX: double quote instead of escape quotes to avoid warning message on PgSQL 8.2.
      $value =~ s/\'/\'\'/g; # BUGFIX: double quote instead of escape quotes to avoid warning message on PgSQL 8.2.
      # Add quotes
      $value_code .= "'$value'";
      # Add comma for all but last value
      $value_code .= ", " if ($i < @column_names - 1);
    }
    $insert_into =
"INSERT INTO $qc". $table ."$qc ( $qc".join("$qc, $qc", @required_column_names, @column_names_sql)."$qc )\n".
"VALUES (\n".
"  $node_number, $parent_number, $value_code\n".
');';
    push @insert_into, $insert_into;
  }

  # Insert comments at top
  my $package = __PACKAGE__ || '';
  my $method = (caller(1))[3] || '';
  # Replace last :: with ->
  $method =~ s/$package\:\:/->/;
  $method .= '()' if $method;
  # Supress the following comment if $drop.
  my $uncomment_drop = ($drop) ? "Comment out the 'DROP TABLE ...' statement if you don't want to delete an existing table." : "Uncomment the 'DROP TABLE ...' statement if you want to delete an existing table.";
  $comments = <<COMMENT;
$sql_comment SQL statements for $dbs generated by $package$method.
$sql_comment For details, check the $package documentation.
$sql_comment $uncomment_drop
$sql_comment Usage of this output:
$sql_comment Redirect this output to a file called, for example, '$example_output_file':
$sql_comment $0 @ARGV > $example_output_file
$sql_comment Then run from the command line (assumes that the database 'test' already exists):
$sql_comment $command_line
$sql_comment
COMMENT
    unshift @comments, $comments;

  # Return a reference to all array references.
  my @list = (\@sql_header, \@drop_index_and_table, \@create_table, \@insert_into, \@create_index, \@comments);
  return \@list;
}


=cut

=head1 BUGS AND OTHER ISSUES

 There may be bugs in the code.
 The code was written more to be useful as a tool, rather than to be compact, fast and clean.
 Please report through CPAN:
 http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Numbered-Tools
 or send mail to bug-Tree-Numbered-Tools@rt.cpan.org

 Incorrectly using $use_column_names=1 together with a source where column names are *not* specified will cause unpredictable results, probably a run-time error.
 The same is true for incorrect usage of $use_column_names=0 together with a source where column names *are* specified.
 This module doesn't try to determine incorrect usage as described above.
 The possible incorrect usage applies to files and arrays, which may or may not use column names.
 SQL expressions and DB tables always use column names by nature.
 Always use $use_column_names=1 (set by default using any method) and always specify column names in the source text file or array.

 For suggestions, questions and such, email me directly.

=head1 EXAMPLES

To see working examples, see the 'examples' directory in the distribution.

=head1 SEE ALSO

Tree::Numbered, Tree::Numbered::DB by Yosef Meller

=head1 AUTHOR

Johan Kuuse, E<lt>johan@kuu.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2009 by Johan Kuuse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
1;
