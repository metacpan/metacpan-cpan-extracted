# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Copyright (c) 2002-2003 Vivendi Universal Net USA
#
#   May be copied under the same terms as perl itself.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Database-like operations on tab-delimited files.
#
# Given two files:
# band_data.tab with fields band_id, band_name, and band_status
# song_data.tab with fields song_id, band_id, song_title
#
# The following sequence is more or less equivalent to
#
#    SELECT song_id, band_data.band_id AS band_id, 
#           song_title, band_name, 
#           int(band_id/1000) AS band_dir
#     FROM song_data INNER JOIN band_data ON song_data.band_id=band_data.band_id
#     WHERE band_status = 'APPROVED' 
#  ORDER BY band_name
# INTO TABLE songband
#
#
#  $band_data = Text::TabTable->import_headered("band_data.tab") ;
#  $song_data = Text::TabTable->import_headered("song_data.tab") ;
#  $joined = $song_data->join($band_data, "band_id", "band_id", "INNER") ;
#  $selected = $joined->select(
#               [
#                 'song_id',
#                 ['band_data.band_id', 'band_id'],
#                 'song_title',
#                 'band_name',
#                 [ sub { int($_[0] / 1000) }, "band_dir", ["band_id"]],
#               ],
# 
#               sub { $_[0]->band_status eq 'APPROVED' },
#             ) ;
# $out = $selected->order("band_name") ;
# $out->export_headered("songband.tab") ;
#
##############################################################################
#
# You can speed up LEFT and INNER joins on primary keys if you create an index 
# for the primary key column on the *right-side* table using
# 
# $righttable->build_primary_index("band_id") ;
# $newtable = $lefttable->join($righttable, "band_id", "band_id", "LEFT") ;
#
# If both tables are already sorted by the primary key because order() was
# previously used, this will be slower.
#
# The index will not be used for RIGHT joins.

package Text::TabTable ;

use strict ;
use Carp ;
use Data::Dumper ;
use Fcntl qw(O_WRONLY O_EXCL O_CREAT) ;

use vars qw($SORT $JOIN $VERBOSE $TMPDIR $VERSION) ;

$VERSION = "1.02" ;

$TMPDIR = "." ;
$SORT = "/bin/sort" ;
$JOIN = "/usr/bin/join" ;

$VERBOSE=$ENV{TABTABLE_VERBOSE} ;

####
# Constructor.  Takes a tab delimited file with a field name
# header line and returns a TabTable object.  Parses the header line
# and creates a temporary file without the header line.
####
sub import_headered
{
  my ($package,$fname) = @_ ;
  my $newf = _make_tempfile() ;

  carp "importing $fname" if $VERBOSE ;
  open(F, $fname) || return undef ;
  open(NEWF, ">$newf") || return undef ;
  my $header = <F> ;
  my $buf ;

  # copy the unheadered version of the file to a new file.
  while( read(F, $buf, 2048) ) {
    print NEWF $buf ;
  }
  close F ;
  close NEWF ;

  chomp $header ;
  my @fieldnames = split(/\t/, $header) ;
  my @fields = map { Text::TabTable::Field->new($_) } @fieldnames ;

  my $name = $fname ;
  $name =~ s/\..*$// ;   # remove extensions
  $name =~ s@.*\/@@ ;   # remove path

  my $self = {
               filename => $newf,
	       fieldlist => Text::TabTable::FieldList->new(@fields),
	       name => $name,
	     } ;
  bless $self, $package ;
}

####
# Alternate constructor.  Takes a tab delimited file *without* a field name
# header line, plus the field names,  and returns a TabTable object.  This
# saves time because it doesn't require making a tempfile without the header.
####
sub import_unheadered
{
  my ($package,$fname, @fieldnames) = @_ ;
  my $newf = _make_tempfile() ;

  carp "importing $fname (unheadered)" if $VERBOSE ;
  return undef if !-f $fname || !-r $fname ;

  my @fields = map { Text::TabTable::Field->new($_) } @fieldnames ;

  my $name = $fname ;
  $name =~ s/\..*$// ;   # remove extensions
  $name =~ s@.*\/@@ ;   # remove path

  my $self = {
               filename => $fname,
	       dontdelete => 1,     # so we know it's not a tempfile.
	       fieldlist => Text::TabTable::FieldList->new(@fields),
	       name => $name,
	     } ;
  bless $self, $package ;
}


####
# Undoes the escaping done by MediaExtractor.
####
sub unescape
{
  my ($str) = @_ ;

  my $x = $str ;
  $str =~ s/\\\\/\xff/g ;
  $str =~ s/\\n/\n/g ;
  $str =~ s/\\t/\t/g ;
  $str =~ s/\xff/\\/g ;

  return $str ;
}

####
# This is the same escaping done by MediaExtractor.
####
sub escape
{
  my ($str) = @_ ;

  $str =~ s/\\/\\\\/g;
  $str =~ s/\t/\\t/g;
  $str =~ s/\n/\\n/g;


  return $str ;
}

####
# Writes out a table as a file with a header.
####
sub export_headered
{
  my ($self, $filename) = @_ ;
  carp "exporting $self->{name} to $filename" if $VERBOSE ;

  open(F, ">$filename") || croak "$filename: $!\n" ;
  print F $self->{fieldlist}->as_string(), "\n" ;
  close F ;
  system "cat $self->{filename} >> $filename" ;
}

####
# Writes out a table as a file without a header.
####
sub export_unheadered
{
  my ($self, $filename) = @_ ;
  carp "exporting $self->{name} to $filename" if $VERBOSE ;
  system "cp $self->{filename}  $filename" ;
  if ($?) {
    unlink $filename ;
    croak "can't export to $filename: $!" ;
  }
}

####
# Returns a new table that has only one of each value in the specified
# column.
####
sub uniq
{
  my ($table, $colname) = @_ ;

  my $colnum = $table->{fieldlist}->find_colnum($colname) ;
  croak "no field $colname in table" if !$colname ;

  if (!$table->{sorted_column} || $table->{sorted_column} != $colnum) {
    my $name = $table->name() ;
    $table = $table->order($colname) ;
    $table->name($name) ;
  }

  carp "uniquing $table->{name} by $colname" if $VERBOSE ;

  my $newf = _make_tempfile() ;

  open(OLDF, "<$table->{filename}") || die ;
  open(NEWF, ">$newf") || croak "$newf: $!\n" ;

  my $oldval = undef ;
  while (<OLDF>) {
    chomp ;
    my @f = split(/\t/, $_, -1) ;
    if ($oldval ne $f[$colnum-1] || !defined $oldval) {
      print NEWF $_, "\n" ;
      $oldval = $f[$colnum-1] ;
    }
  }

  close(OLDF) ;
  close(NEWF) ;

  my $newtable = {
               filename => $newf,
	       fieldlist => $table->{fieldlist}->deepcopy(),
	       sorted_colnum => $colnum,
	       name => $table->name(),
	     } ;

  if (!defined wantarray ) {
    carp "Warning: Useless uniq in void context." ;
  }

  bless $newtable, ref $table ;
}

####
# Export to a cdb file.
# There will be a special key "*FIELDNAMES*" whose value is a tab
# separated list of the names of the fields.
# The rest of the cdb file will be of the form key => tab-delimited-values.
#
# The key must be unique; however as a special case multiple blank keys
# are allowed to be present; only the first one is used.  This is a hack,
# but is too good an optimization to pass up.
####
sub export_cdb
{
  my ($self, $filename, $colname) = @_ ;
  require CDB_File ;
  carp "exporting $self->{name} to cdb $filename" if $VERBOSE ;

  my $t = CDB_File->new($filename, "$filename.new$$") or croak "$filename: $!" ;

  $t->insert("*FIELDNAMES*", $self->{fieldlist}->as_string()) ;

  open(F, "< $self->{filename}") || die "$self->{filename}: $!" ;
  my $colnum = $self->{fieldlist}->find_colnum($colname) ;
  $colnum-- ;

  # Create a regex to skip over the columns before the key column and 
  # collect the key column in $1.
  my $regex = '^' . ('[^\t]*\t' x $colnum) . '([^\t]*)' ;
  $regex = qr($regex) ;
  my $didblankkey = 0 ;
  while (<F>) {
    chomp ;
    /$regex/ || die ;
    my $key = $1 ;

    next if $key eq '' && $didblankkey++ ;

    $t->insert($key, $_) ;
  }

  $t->finish() ;
  close(F) ;
}

####
# Returns the named column of the table as an array.
####
sub export_column
{
  my ($table, $colname) = @_ ;
  carp "exporting $table->{name} column $colname" if $VERBOSE ;

  my $colnum = $table->{fieldlist}->find_colnum($colname) ;

  if (!defined $colnum) {
    croak "no column $colname" ;
  }

  my @arr ;
  open(CUT, "cut -f$colnum $table->{filename}|") || die ;
  while(defined ($_=<CUT>)) {
    chomp ;
    push @arr, $_ ;
  }
  close CUT ;

  return @arr ;
}

####
# Returns a new TabTable that is sorted by the requested column.  Dies
# if no such column.  You can specify -descending=>1 or -numeric =>1
# after the fieldname.
# 
# The sort is stable, so you can sort on multiple fields by doing
# multiple sorts, with the most important one last.
####
sub order
{
  my ($self, $fieldname, %args) = @_ ;
  carp "sorting $self->{name} by $fieldname" if $VERBOSE ;

  my $newf = _make_tempfile() ;

  # This is a flag that gets turned off if the sort is not alphabetic
  # and ascending.  In that case, the sort order is not correct for the
  # join() method, and so join() would have to re-sort.
  my $joinable_sort = 1 ;

  my $colnum = $self->{fieldlist}->find_colnum($fieldname) ;
  if (!$colnum) {
    unlink $newf ;
    croak "No such field $fieldname" ;
  }

  my @sortargs = ("-s",
		  "-T$TMPDIR",
                  "-t\t", 
		  "-k$colnum,$colnum", 
		  "-o$newf", 
		  $self->{filename}
		) ;
  if ($args{-descending}) {
    unshift @sortargs, "-r" ;
    $joinable_sort = 0 ;
  }
  if ($args{-numeric}) {
    unshift @sortargs, "-n" ;
    $joinable_sort = 0 ;
  }

  system $SORT, @sortargs ;

  if ($?) {
    unlink $newf ;
    croak "sort error" ;
  }

  my $newtable = {
               filename => $newf,
	       fieldlist => $self->{fieldlist}->deepcopy(),
	       sorted_colnum => $joinable_sort ? $colnum : undef,
	       name => $self->name(),
	     } ;

  if (!defined wantarray ) {
    carp "Warning: Useless order in void context." ;
  }

  bless $newtable, ref $self ;
}

####
# Returns a new table with two columns.  The first column will contain the
# unique values of the specified field, the second column will contain the
# number of occurrences of that value.
####
sub groupby_and_count
{
  my ($table, $fieldname, $newfieldname, %args) = @_ ;
  my $colnum = $table->{fieldlist}->find_colnum($fieldname) ;
  if (!$colnum) {
    croak "No such field $fieldname" ;
  }
  # Create a temporary table that is sorted by the specified column.
  my $sortedtable = $table->order($fieldname, %args);

  # Taken from uniq(), One pass through the file counting the number
  # of times the specified column appears and creating a new file
  # with the specified column and count.
  my $newf = _make_tempfile() ;
  open(OLDF, "<$sortedtable->{filename}") || die ;
  open(NEWF, ">$newf") || croak "$newf: $!\n" ;

  my $count = 0 ;
  my $oldval = undef ;
  while (<OLDF>) {
    chomp ;
    my @f = split(/\t/, $_, -1) ;
    if (!defined $oldval) {
      $oldval = $f[$colnum-1] ;
      $count = 1 ;
    } elsif ($oldval ne $f[$colnum-1]) {
      print NEWF $oldval, "\t", $count, "\n" ;
      $oldval = $f[$colnum-1] ;
      $count = 1 ;
    } else {
      $count++ ;
    }
  }
  if (defined $oldval) {
    print NEWF $oldval, "\t", $count, "\n" ;
  }

  close(OLDF) ;
  close(NEWF) ;

  my @newfieldnames = ($fieldname, $newfieldname) ;
  my @newfields = map { Text::TabTable::Field->new($_) } @newfieldnames ;
  my $newtable = {
    filename => $newf,
    fieldlist => Text::TabTable::FieldList->new(@newfields),
    sorted_colnum => 1,
    name => $table->name(),
  } ;

  bless $newtable, ref $table ;
}

####
# Takes a list of pairs of oldname=>newname and changes the names of fields
# of the table.  This wipes out the old field names entirely.
sub rename_fields
{
  my ($table, @renames) = @_ ;

  my $oldname ;
  my $newname ;
  my @fields = $table->{fieldlist}->fields() ;
  while ( ($oldname = shift(@renames)) && ($newname = shift(@renames)) ) {
    my $colnum = $table->{fieldlist}->find_colnum($oldname) ;
    $fields[$colnum-1]->set_name($newname) ;
  }
}

####
# Gets or sets the name of the table.
####
sub name
{
  my ($self, $name) = @_ ;
  if (defined $name) {
    $self->{name} = $name ;
  }
  return $self->{name} ;
}

####
# takes a table and exports it as a cdb file, creating a primary key
# index.  This can make joins go faster if this table is on the right side
# of the join, since neither table has to be sorted, and building a cdb
# is generally faster than sorting (~O(n) instead of O(nLogn).
####
sub build_primary_index
{
  my ($self, $colname) = @_ ;
  my $newf = _make_tempfile() ;

  $self->export_cdb($newf, $colname) ;
  my $colnum = $self->{fieldlist}->find_colnum($colname) ;

  $self->{cdb}{$colnum} = $newf ;
}

####
# Returns a new table created by joining the two tables on a specified
# column.  the $side parameter can be specified as LEFT or RIGHT to
# create LEFT/RIGHT joins, or can be INNER, OUTER, or undef.
# $leftfield/$rightfield are the field names to be used in the two tables
# for joining.
#
# If the right table has a primary index on the join column (created
# by build_primary_index()), and it's either a left or inner join, 
# a simpler join algorithm will be used that does not require sorting.
#
# Both tables must have names.  Tables get names either by setting them
# with the name() method, or from the filename in the import_headered
# method.
####
sub join
{
  my ($lefttable, $righttable, $leftfield, $rightfield, $side) = @_ ;

  if (!$lefttable->name() || !$righttable->name()) {
    croak "both tables must have name()s" ;
  }

  my $leftcol = $lefttable->{fieldlist}->find_colnum($leftfield) ;
  croak "no field $leftfield in left table" if !$leftfield ;
  my $rightcol = $righttable->{fieldlist}->find_colnum($rightfield) ;
  croak "no field $rightfield in right table" if !$rightfield ;

  if ($righttable->{cdb}{$rightcol} && $side ne 'RIGHT' && $side ne 'OUTER') {
    if ($VERBOSE) {
      carp "index joining $lefttable->{name} with $righttable->{name}" ;
    }
    return $lefttable->_join_using_index($righttable, 
                                         $leftcol, $rightcol, $side) ;
  }

  # tables must be sorted by field.
  if (!$lefttable->{sorted_colnum} || $lefttable->{sorted_colnum} ne $leftcol) {
    $lefttable = $lefttable->order($leftfield) ;
  }
  if (!$righttable->{sorted_colnum} || $righttable->{sorted_colnum} ne $rightcol) {
    $righttable = $righttable->order($rightfield) ;
  }

  carp "joining $lefttable->{name} with $righttable->{name}" if $VERBOSE ;


  # create a format string for join(1).
  # Looks like
  # 1.1,1.2,1.3,1.4, ... ,2.1,2.2,2.3, ...

  my $format = 
       join(",", map { "1.$_" } 1..$lefttable->{fieldlist}->fieldcount())
       . "," .
       join(",", map { "2.$_" } 1..$righttable->{fieldlist}->fieldcount()) ;

  
  
  my $command = "$JOIN -1 $leftcol -2 $rightcol -o $format -t '\t' " ;

  if ($side eq 'LEFT') {
    $command .= "-a 1 "
  } elsif ($side eq 'RIGHT') {
    $command .= "-a 2 " ;
  } elsif ($side eq 'OUTER') {
    $command .= "-a 1 -a 2 " ;
  } elsif (defined $side && $side ne 'INNER') {
    croak "invalid side argument" ;
  }

  $command .= $lefttable->{filename} . " " ;
  $command .= $righttable->{filename} . " " ;

  my $newf = _make_tempfile() ;
  $command .= "> $newf" ;

  system $command ;

  croak "join failed" if $? ;


  # We've now joined the files, so we just have to create a fieldlist
  # for the new table.

  my $leftlistcopy = $lefttable->{fieldlist}->deepcopy ;
  foreach my $field ($leftlistcopy->fields) {
    $field->add_name( $lefttable->name . "." . $field->name() ) ;
  }
  my $rightlistcopy = $righttable->{fieldlist}->deepcopy ;
  foreach my $field ($rightlistcopy->fields) {
    $field->add_name( $righttable->name . "." . $field->name() ) ;
  }

  # we've now got copies of the two fieldlists, with new aliases for
  # the field names of the form tablename.fieldname.  Construct
  # a final field list from these two lists.

  my @fields = ($leftlistcopy->fields, $rightlistcopy->fields) ;

  my $newtable = {
	       name => $lefttable->{name},
               filename => $newf,
	       fieldlist => Text::TabTable::FieldList->new(@fields),
	       sorted_colnum => $leftcol,
	     } ;
  
  if (!defined wantarray ) {
    carp "Warning: Useless join in void context." ;
  }
  bless $newtable, ref $lefttable ;
}

####
# called by ->join() to perform a join when there is an appropriate cdb index
# present on the right side table and it's not a right join.
# 
# The column numbers passed in are 1-based.
####
sub _join_using_index
{
  my ($lefttable, $righttable, $leftcol, $rightcol, $side) = @_ ;

  my $isleftjoin = $side eq 'LEFT' ;
  my $emptyright ;
  if ($isleftjoin) {
    $emptyright = "\t" x ($righttable->{fieldlist}->fieldcount() - 1) ;
  }

  open(LEFTF, $lefttable->{filename}) || croak ;
  require CDB_File ;

  my $newf = _make_tempfile() ;
  open(NEWF, ">$newf") || croak "$newf: $!" ;

  my %right ;

  tie (%right, 'CDB_File', $righttable->{cdb}{$rightcol}) || die ;

  # create a regex that will extract the join field from a tab delimited
  # line.
  my $regex = '^' . ('[^\t]*\t' x ($leftcol-1)) . '([^\t]*)' ;
  $regex = qr($regex) ;

  my $leftfieldcount = $lefttable->{fieldlist}->fieldcount() ;
  my $rightfieldcount = $righttable->{fieldlist}->fieldcount() ;

  while (<LEFTF>) {
    chomp ;
    _add_missing_tabs(\$_, $leftfieldcount) ;
    /$regex/ || die "malformed temp file in line $_" ;
    my $key = $1 ;


    if (exists $right{$key}) {
      # found a match.  Print a complete line.
      my $val = $right{$key} ;
      _add_missing_tabs(\$val, $rightfieldcount) ;
      print NEWF CORE::join("\t", $_, $val), "\n" ;
    } else {
      # didn't match.  print a line if it's a left join, otherwise skip it.
      if ($isleftjoin) {
        print NEWF CORE::join("\t", $_, $emptyright), "\n" ;
      }
    }
  }

  untie %right ;

  close LEFTF ;
  close NEWF ;

  # We've now joined the files, so we just have to create a fieldlist
  # for the new table.

  my $leftlistcopy = $lefttable->{fieldlist}->deepcopy ;
  foreach my $field ($leftlistcopy->fields) {
    $field->add_name( $lefttable->name . "." . $field->name() ) ;
  }
  my $rightlistcopy = $righttable->{fieldlist}->deepcopy ;
  foreach my $field ($rightlistcopy->fields) {
    $field->add_name( $righttable->name . "." . $field->name() ) ;
  }

  # we've now got copies of the two fieldlists, with new aliases for
  # the field names of the form tablename.fieldname.  Construct
  # a final field list from these two lists.

  my @fields = ($leftlistcopy->fields, $rightlistcopy->fields) ;

  my $newtable = {
	       name => $lefttable->{name},
               filename => $newf,
	       fieldlist => Text::TabTable::FieldList->new(@fields),
	     } ;
  
  if (!defined wantarray ) {
    carp "Warning: Useless join in void context." ;
  }
  bless $newtable, ref $lefttable ;

}

# Given a ref to a string that's supposed to have n columns, make sure there are
# n-1 tabs by adding more at the end.
sub _add_missing_tabs
{
  my ($strref, $n) = @_ ;

  my $tabcount = ($$strref =~ tr/\t/\t/) ;

  if ($tabcount < $n-1) {
    $$strref .= "\t" x ( $n-1-$tabcount ) ;
  }
}


####
# processes a table and creates a new one with different stuff.
#
# parameters:
#  table is a Text::TabTable object.
#
#  fieldspecs is a listref containing items of any of the following forms
#   fieldname    ( a simple scalar )
#   [fieldname, newfieldname]       ( for "cd_table.id as cd_id")
#   [sub {...}, newfieldname, [list of fieldnames]]
#            (for calculated fields.  The sub receives values for the
#             listed fields as parameters, and returns the new value)
#   fieldspecs can also be a simple "*", which returns all fields unchanged.
#  
#  wheresub is an optional subref.  It is passed an object with getvalue,
#    setvalue, and autoloaded field-name-named methods to get and set values
#    of fields by name.  It is expected to return a true value if the 
#    row should be included in the output.
####
sub select
{
  my ($table, $fieldspecs, $wheresub) = @_ ;

  carp "selecting from $table->{name}" if $VERBOSE ;

  my $newtable = { name => $table->{name} } ;

  # this gets set to zero if there is a where clause or calculated columns.
  # Otherwise it just runs /bin/cut to pick the right columns.
  my $cut_ok = 1 ;

  # create a field list for the new table based on the selected fields.
  # also create an array saying how to calculate each output field.
  my @fieldrules ;
  if (!ref $fieldspecs && ($fieldspecs eq '*' || !defined $fieldspecs)) {
    # simple case.  Just copy the fieldlist.
    undef $fieldspecs ;
    $newtable->{fieldlist} = $table->{fieldlist}->deepcopy() ;

    # we don't need any rules in this case; input = output
  } else {
    # make a new fieldlist, and rules.

    # @fields is the list of Field objects being built.
    my @fields ;

    foreach my $fieldspec (@$fieldspecs) {
      if (!ref $fieldspec) {
        # a simple scalar, representing a field name.
	my $colnum = $table->{fieldlist}->find_colnum($fieldspec) ;
	if (!$colnum) {
	  croak "no field $fieldspec in table" ;
	}
	# find_colnum returns 1-based column numbers.
	push @fieldrules, $colnum - 1 ;
	push @fields, Text::TabTable::Field->new($fieldspec) ;
      } elsif (@$fieldspec == 2) {
        # a field name to look up and what to call it in the output table.

	my $colnum = $table->{fieldlist}->find_colnum($fieldspec->[0]) ;
	if (!$colnum) {
	  croak "no field $fieldspec->[0] in table" ;
	}
	# find_colnum returns 1-based column numbers.
	push @fieldrules, $colnum - 1 ;
	push @fields, Text::TabTable::Field->new($fieldspec->[1]) ;
      } elsif (@$fieldspec == 3) {
        # A subref, a new column name, and a list of columns to pass to
	# the subref.
	my @paramcols ;

	# since we're doing a calculated column, we have to use perl instead
	# of /bin/cut.
	$cut_ok = 0 ;

	foreach my $fieldname (@{$fieldspec->[2]}) {
	  my $colnum = $table->{fieldlist}->find_colnum($fieldname) ;
	  if (!$colnum) {
	    croak "no field $fieldname in table" ;
	  }
	  push @paramcols, $colnum-1 ;
	}
	# create a rule consiting of the subref followed by a listref of
	# what columns to get parameters from.
	push @fieldrules, [ $fieldspec->[0], \@paramcols ] ;
	
	# fieldname is the new name passed in.
	push @fields,  Text::TabTable::Field->new($fieldspec->[1]) ;
      } else {
        croak "bad fieldspec" ;
      }
    }

    $newtable->{fieldlist} = Text::TabTable::FieldList->new(@fields) ;
  }

  $newtable->{filename} = _make_tempfile() ;

  # build a hash saying which field is in which position in the input.
  my %fieldloc ;
  $table->_build_fieldloc(\%fieldloc) ;

  # cut won't reorder columns, which angers me.  So if the columns aren't
  # sorted, don't use cut.
  my $test_unsort = CORE::join(" ", @fieldrules) ;
  my $test_sort = CORE::join(" ", sort {$a <=> $b } @fieldrules) ;
  if ($test_unsort ne $test_sort) {
    $cut_ok = 0 ;
  }

  # now $newtable->{fieldlist} contains the table names.  We're done with that.
  #     $newtable->{filename}  contains the name of the file to be created.
  #     @fieldrules tells us how to create each output column.
  #     %fieldloc says which column number a field name can be found in.
  # so it's time to start processing.


  if ($cut_ok && !$wheresub && $fieldspecs) {
    # there aren't any calculated columns, and there's no where clause,
    # so we can just use cut to pick the columns they wanted.

    # @fieldrules has zero-based column numbers.  Make one-based.
    my @cutfields = map { $_ + 1 } @fieldrules ;

    carp "...selecting using cut" if $VERBOSE ;
    system "cut -f" . CORE::join(',', @cutfields) . 
                      " $table->{filename} > $newtable->{filename}" ;
    if ($?) {
      unlink $newtable->{filename} ;
      croak "cut error in select" ;
    }
  } else {

    # process the file using perl.

    open(INFILE, $table->{filename}) || croak "can't open table file" ;
    open(OUTFILE, ">$newtable->{filename}") || croak "can't open output table file" ;

    while(<INFILE>) {
      chomp ;
      my @values = split(/\t/, $_, 999999) ;

      # run the where clause subroutine, if any, and skip if it says to.
      if ($wheresub) {
	my $rowdata = bless([\%fieldloc, \@values], 'Text::TabTable::DataRow') ;
	next if !&$wheresub($rowdata) ;
      }

      if (!$fieldspecs) {
	# select *.  Just print them out.
	print OUTFILE CORE::join("\t", @values), "\n" ;
      } else {
	my @outvals ;

	# use the @fieldrules to create @outvals from @values.
	foreach my $rule (@fieldrules) {
	  if (!ref $rule) {
	    push @outvals, $values[$rule] ;
	  } else {
	    # it's an arrayref containing a subref and a bunch of column
	    # numbers.  Call the subroutine with the values pointed to 
	    # by those column numbers and use the return value as the 
	    # output field value.
	    my @params = map { $values[$_] } @{$rule->[1]} ;
	    my $subref = $rule->[0] ;
	    push @outvals, scalar(&$subref(@params)) ;
	  }
	}

	print OUTFILE CORE::join("\t", @outvals), "\n" ;
      }
    }

    close OUTFILE ;
    close INFILE ;
  }

  if (!defined wantarray ) {
    carp "Warning: select used in void context." ;
  }

  return bless $newtable, ref $table ;
}

####
# Fills in a hash with a mapping from field name to column number.
####
sub _build_fieldloc
{
  my ($table, $hr_fieldloc) = @_ ;
  my $pos = 0 ;
  foreach my $field ($table->{fieldlist}->fields()) {
    foreach my $fieldname ($field->names()) {
      $hr_fieldloc->{$fieldname} = $pos if !exists $hr_fieldloc->{$fieldname} ;
    }
    $pos++ ;
  }
}

####
# Runs through the rows of a tab table, calling a subroutine for each
# line.  The subroutine has the same calling convention as the where
# part of a select() call.
#
# This is like a select(undef,sub {}) but does not return a new table.
####
sub iterate
{
  my ($table, $wheresub) = @_ ;
  carp "iterating over $table->{name}" if $VERBOSE ;

  open(INFILE, $table->{filename}) || croak "can't open table file" ;

  die if !$wheresub ;

  # build a hash saying which field is in which position in the input.
  my %fieldloc ;
  $table->_build_fieldloc(\%fieldloc) ;

  while(<INFILE>) {
    chomp ;
    my @values = split(/\t/, $_, 999999) ;

    my $rowdata = bless([\%fieldloc, \@values], 'Text::TabTable::DataRow') ;
    &$wheresub($rowdata) ;
  }

  close INFILE ;
}

####
# Returns an object with a next() method, which gives one row object each
# time next() is called.
#
# If -unescape=>1, the tab/backslash/newline escaping will be removed.
####
sub make_iterator
{
  my ($table, %args) = @_ ;
  carp "iterating over $table->{name}" if $VERBOSE ;

  if ($args{-unescape}) {
    return Text::TabTable::Iterator::Unescaping->new($table) ;
  } else {
    return Text::TabTable::Iterator->new($table) ;
  }
}

sub DESTROY
{
  my $self = shift ;
  if (!$self->{dontdelete}) {
    unlink $self->{filename} ;
  }

  foreach my $cdbfile ( values %{$self->{cdb}} ) {
    unlink $cdbfile ;
  }
}

####
# Creates a temporary file and returns its filename.
####
use vars qw(@TEMPFILES) ;
sub _make_tempfile
{
  my $watchdog = 0 ;
  while ($watchdog++ < 1000) {
    my $fname = "$TMPDIR/$$." . int(rand(9999999)) ;
    my $status = sysopen TEMPF, $fname, O_CREAT | O_WRONLY | O_EXCL, 0666 ;
    close(TEMPF) ;
    if (defined $status) {
      push @TEMPFILES, $fname ;
      return $fname ;
    }
  }
  die "couldn't create a temporary file\n" ;
}

END {
  # delete any tempfiles that didn't get deleted.  This shouldn't happen.
  foreach my $file (@TEMPFILES) {
    unlink $file ;
  }
}


###############################################################################
#               Text::TabTable::Field
###############################################################################
package Text::TabTable::Field ;

sub new
{
  my ($package, $fieldname) = @_ ;
  my $self = { names => [$fieldname] } ;
  bless $self, $package ;
}

sub name
{
  return $_[0]->{names}->[0] ;
}

####
# Return all the names for this field.
sub names
{
  return @{$_[0]->{names}} ;
}

sub has_name
{
  my $self = shift ;
  my $name = shift ;
  if (grep( $_ eq $name, @{$self->{names}})) {
    return 1 ;
  } else {
    return 0 ;
  }
}

####
# Add an alias name to a field.
####
sub add_name
{
  my ($self, @names) = @_ ;
  push @{$self->{names}}, @names ;
}

####
# sets the name of the field, wiping out all previous aliases.
####
sub set_name
{
  my ($self, $name) = @_ ;
  $self->{names} = [$name] ;
}

###############################################################################
#               Text::TabTable::FieldList
#
# Represents the list of Fields on a table.
###############################################################################
package Text::TabTable::FieldList ;

use Data::Dumper ;

sub new
{
  my ($package, @fields) = @_ ;
  
  bless { fields => \@fields }, $package ;
}

sub deepcopy
{
  my ($self) = @_ ;

  no strict ;
  my $newent = eval Dumper($self) ;
}

####
# Returns a 1-based column number for the given field, or undef
# if not present.
####
sub find_colnum
{
  my ($self, $fieldname) = @_ ;
  for (my $i = 0 ; $i < @{$self->{fields}} ; $i++) {
    if ($self->{fields}->[$i]->has_name($fieldname)) {
      return $i+1 ;
    }
  }
  return undef ;
}

####
# Return the number of fields.
####
sub fieldcount
{
  my $self = shift ;
  return scalar(@{$self->{fields}}) ;
}

####
# Return field names as a tab-delimited string.
####
sub as_string
{
  my $self = shift ;
  my @names = map {$_->name} @{$self->{fields}} ;
  return join("\t", @names) ;
}

sub fields
{
  return @{$_[0]->{fields}} ;
}

###############################################################################
#               Text::TabTable::Iterator
#               Text::TabTable::Iterator::Unescaping
#
# A thing that returns one row at a time from a table.
# The ::Unescaping version will run Text::TabTable::Unescape on all the
# data first.
###############################################################################
package Text::TabTable::Iterator ;

@Text::TabTable::Iterator::Unescaping::ISA = ('MP3Com::TabTable::Iterator') ;

use strict ;
use Carp ;

sub new
{
  my ($package, $table) = @_ ;

  require IO::File ;

  my %fieldloc ;
  $table->_build_fieldloc(\%fieldloc) ;

  my $fh = IO::File->new("<$table->{filename}") || croak ;

  my $self = {
  		fieldloc => \%fieldloc,
		fh => $fh
	      } ;
  bless $self, $package ;
}

sub next
{
  my ($self) = @_ ;
  my $line = $self->{fh}->getline() ;

  if (!$line) {
    return undef ;
    delete $self->{fh} ;
  }
  chomp $line ;
  my @values = split(/\t/, $line, -1) ;

  return bless([$self->{fieldloc}, \@values], 'Text::TabTable::DataRow') ;
}

sub Text::TabTable::Iterator::Unescaping::next
{
  my ($self) = @_ ;

  # get a row and unescape the data in it.

  my $row = $self->Text::TabTable::Iterator::next() ;
  return undef if !$row ;

  foreach my $val (@{$row->[1]}) {
    $val = Text::TabTable::unescape($val) ;
  }

  return $row ;
}

###############################################################################
#               Text::TabTable::DataRow
#
# Represents a row of data from a TabTable.
###############################################################################
package Text::TabTable::DataRow ;

use vars qw($AUTOLOAD) ;
use Carp ;

use strict ;

# This constructor is not actually used by select(); it blesses the
# right structure itself for speed purposes.
sub new
{
  my ($package, $name2colhash, $values) = @_ ;
  bless [$name2colhash, $values], $package ;
}

sub getvalue
{
  my $self = shift ;
  my $name = shift ;
  return $self->[1][  $self->[0]{$name}   ] ;
}

sub setvalue
{
  my $self = shift ;
  my $name = shift ;
  my $newval = shift ;
  $self->[1][$self->[0]{$name}] = $newval ;
}

# to save work for autoload.
sub DESTROY {} ;

####
# implements field-named methods for getting values.
####
sub AUTOLOAD
{
  my $self = shift ;

  my $name = $AUTOLOAD ;
  $name =~ s/.*:// ;

  if (!exists $self->[0]{$name}) {
    croak "No $name field in table" ;
  }

  # create a function to calculate it.
  eval <<EOT ;
    sub $name {
      return \$_[0]->[1][  \$_[0]->[0]{'$name'} ] ;
    }
EOT

  return $self->$name() ;
}


1;
