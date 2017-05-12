package Tk::EMatrix;

use warnings;

require Tk::TableMatrix;
require Exporter;

@ISA = qw(Exporter Tk::Derived Tk::TableMatrix);

$VERSION = '0.01';

Construct Tk::Widget 'EMatrix';

sub Populate{
   my($dw, $args) = @_;
   $dw->SUPER::Populate($args);
   
   $dw->ConfigSpecs(DEFAULT => [$dw]);
   $dw->Delegates(DEFAULT => $dw);
}

# Bind all cells of a particular row
sub bindRow{
   my($dw, %args) = @_;
   
   my $index = $args{-index};
   my $sequence = $args{-sequence};
   my $callback = $args{-command};
   
   if(!defined($index)){ die "\nNo index value specified: $!" }
   if(!defined($sequence)){ die "\nNo sequence value specified: $!" }
   if(!defined($callback)){ die "\nNo callback value specified: $!" }
   
   $dw->bind($sequence, sub{
      my $Ev = $dw->XEvent;
      my $indexTemp = $dw->index('@' . $Ev->x.",".$Ev->y);
      my($row,$col) = $indexTemp =~ /(\d),(\d)/;
      if($row != $index){ return }
      else{ &$callback }
   });   
}

# Bind all cells of a particular column
sub bindCol{
   my($dw, %args) = @_;
   
   my $index = $args{-index};
   my $sequence = $args{-sequence};
   my $callback = $args{-command};
   
   if(!defined($index)){ die "\nNo index value specified: $!" }
   if(!defined($sequence)){ die "\nNo sequence value specified: $!" }
   if(!defined($callback)){ die "\nNo callback value specified: $!" }
   
   $dw->bind($sequence, sub{
      my $Ev = $dw->XEvent;
      my $indexTemp = $dw->index('@' . $Ev->x.",".$Ev->y);
      my($row,$col) = $indexTemp =~ /(\d),(\d)/;
      if($col != $index){ return }
      else{ &$callback }
   });   
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Return the contents of the row specified by '$index' as an array in list
# context, or an array reference in scalar context.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub getRow{
   my($dw, $index, $numCols) = @_;
   
   # Some basic error checking
   if(!defined($index)){ die "\nNo index value specified: $!" }
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If a second index is not specified (or 'end' is specified) then
   # get *all* columns in the row specified.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (!defined($numCols)) || ($numCols =~ /end/i) ){ 
		$numCols = $dw->cget(-cols);
   }

   my @rowArray = $dw->get("$index,0", "$index,$numCols");
   
   if(wantarray){return @rowArray}
   else{ return \@rowArray }
   
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Return the contents of the column specified by '$index' as an array in list
# context, or an array reference in scalar context.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub getCol{
   my($dw, $index, $numRows) = @_;
   
   # Some basic error checking
   if(!defined($index)){ die "\nNo index value specified: $!" }
   
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If a second index is not specified (or 'end' is specified) then
   # get *all* columns in the row specified.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (!defined($numRows)) || ($numRows =~ /end/i) ){ 
		$numRows = $dw->cget(-rows);
   }

   my @colArray = $dw->get("0,$index", "$numRows, $index");
   
   if(wantarray){ return @colArray }
   else{ return \@colArray }
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Return the contents of the row as a hash, with the index as the key and the 
# contents of the cell at that index as the value.
#
# The value returned will be a hash reference in scalar context.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub getRowHash{
   my($dw, $index, $numCols, $tieval) = @_;
   my(%rowHash, @rowArray);

   # Some basic error checking
   if(!defined($index)){ die "\nNo index value specified: $!" }

   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the user omits a range value ('$numCols'), ensure that 'tie'
   # is assigned correctly, if supplied as an argument.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (defined $numCols) && ($numCols =~ /tie/i)){
		$tieval = $numCols;
      undef $numCols;
   }

   # Retain insertion order, if desired
   if(defined $tieval){ 
      require Tie::IxHash;
      tie %rowHash, "Tie::IxHash";
   }

   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Allow the user to tie the hash if used in scalar context.  Double check
   # to make sure that it *is* scalar context that is wanted; otherwise
   # issue a warning - only a reference to a tied hash will work as desired.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (wantarray) && (defined $tieval) ){ 
      warn "\nYou must return a hash in scalar context in order to retain"
      . " insertion order with Tie::IxHash.  Insertion order not maintained.";
   }

   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If a second index is not specified (or 'end' is specified) then
   # get *all* columns in the row specified.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (!defined($numCols)) || ($numCols =~ /end/i) ){ 
      $numCols = $dw->cget(-cols); 
   }
   @rowArray = $dw->get("$index,0", "$index,$numCols");

   my $n = 0;
   while($n < $numCols){
      $rowHash{"$index, $n"} = $rowArray[$n];
      $n++;
   }
  
   if(wantarray){ return %rowHash }
   else{ return \%rowHash }
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Return the contents of the column as a hash, with the index as the key and
# the contents of the cell at that index as the value.
#
# The value returned will be a hash reference in scalar context.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub getColHash{
   my($dw, $index, $numRows, $tieval) = @_;
   my(%colHash, @colArray);
   
   # Some basic error checking
   if(!defined($index)){ die "\nNo index value specified: $!" }

   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If the user omits a range value ('$numRows'), ensure that 'tie'
   # is assigned correctly, if supplied as an argument.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (defined $numRows) && ($numRows =~ /tie/i) ){
		$tieval = $numRows;
      undef $numRows;
   }

   # Retain insertion order, if desired
   if(defined $tieval){ 
      require Tie::IxHash;
      tie %colHash, "Tie::IxHash";
   }
   
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # Allow the user to tie the hash if used in scalar context.  Double check
   # to make sure that it *is* scalar context that is wanted; otherwise
   # issue a warning - only a reference to a tied hash will work as desired.
   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (wantarray) && (defined $tieval) ){ 
      warn "\nYou must return a hash in scalar context in order to retain"
      . " insertion order with Tie::IxHash.  Insertion order not maintained.";
   }

   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   # If a second index is not specified (or 'end' is specified) then
   # get *all* rows in the column specified.
   #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if( (!defined($numRows)) || ($numRows =~ /end/i) ){ 
      $numRows = $dw->cget(-rows);
   }

   @colArray = $dw->get("0,$index", "$numRows, $index");

   my $n = 0;
   while($n < $numRows){
      $colHash{"$n, $index"} = $colArray[$n];
      $n++;
   }
   
   if(wantarray){ return %colHash }
   else{ return \%colHash }
}
1;
__END__
=head1 NAME

Tk-EMatrix-0.01 - Perl widget derived from Tk::TableMatrix.

=head1 SYNOPSIS

use EMatrix;
my $titleHash = {
 "0,0" => "Header1",
 "0,1" => "Header2",
 "0,2" => "Header3",
 "0,3" => "Header4",
 "0,4" => "Header5",
};

my $table;
$table = $mw->Scrolled('EMatrix',
   -cols          => 5,
   -bd            => 2,
   -bg            => 'white',
   -titlerows     => 1,
   -variable      => $titleHash,
);

$table->tagConfigure('title', 
   -bg => 'tan',
   -fg => 'black',
   -relief => 'raised'
);

$table->pack(-expand => 1, -fill => 'both');


=head1 DESCRIPTION

The EMatrix widget is a derived widget that provides 6 additional methods 
above and beyond the traditional Tk::TableMatrix widget.

=head1 METHODS

B<bindRow(-index => int, -sequence => string, -command => sub ref);>

bindRow binds a particular sequence to the subroutine at the row specified
by the "-index" option.  Note that binding row 0 will bind the column
headers, which may not be what you want. 

You cannot currently bind a range of rows (i.e. -index=>2-5) for now, though 
that is an enhancement I may add in the future.

e.g. $em->bindRow(
	-index    => 2, 
   -sequence => '<Control-g>', 
   -command  => sub{ print "Hello World!" }
);

B<bindCol(-index => int, -sequence => string, -command => sub ref);>

This method is identical to 'bindRow()' above, except that it binds a 
column instead of a row (duh).

B<getRow(index, ?range?);>

Returns the row at specified index as an array in list context, or an array
reference in scalar context.

If the range is omitted (or 'end' is used), it will return the 
contents of all cells in that row (including empty cells).  Otherwise, it
will only return the contents of the cells up to the specified range,
starting at index 0.

B<getRowHash(index, ?range?, ?tie?);>

Returns the row at the specified index as a hash.  The key is the cell value 
('0,1' for example), the value is the content of the cell. 

If a second index is omitted (or 'end' is used), it will return 
the contents of all cells in that row (including empty cells).  Otherwise,
it will only return the contents of the cells up to the specified range
starting at index 0.

If the string 'tie' is included, the hash will be returned in cell order (left
to right).  To use this option you must have the Tie::IxHash module
installed.

B<getCol(index, ?range?);>

Returns the column at the specified index as an array in list context, or an 
array reference in scalar context.  See 'getRow()' for more details.

B<getColHash(index, ?range?, ?tie?);>

Returns the column at the specified index as a hash in list context, or a
hash reference in scalar context.  See 'getRowHash()' above for more details.

If the string 'tie' is included as an argument, the hash will be returned in
cell order (top to bottom).  This requires the Tie::IxHash module.

=head1 FUTURE RELEASES

=item 1 
Cell ranges - allow a range of cells to be selected at a particular index.

e.g. $dw->getRow(0, 3-5); # Would return the contents of cells 3, 4 and 5
at row 0.

=item 2
A row of buttons on the left side to mimic MS Excel behavior.

=item 3
Methods to make importing Excel spreadsheets a snap (via the ParseExcel
module perhaps).

=head1 AUTHOR

Daniel Berger, djberg96@hotmail.com

Many thanks go out to John Cerney for providing help with this module
(especially the bind methods).

=head1 SEE ALSO

Tk::TableMatrix, Tie::IxHash.

=cut
