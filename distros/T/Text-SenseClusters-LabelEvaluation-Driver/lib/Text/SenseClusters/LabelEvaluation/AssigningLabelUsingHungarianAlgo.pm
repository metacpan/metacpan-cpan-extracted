# Defining the Package for the modules.
package Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo;

use Algorithm::Munkres;


# Defining the class variables.
my $matrixToArrangeRef= "matrixRef";
my $columnHeaderRef = "colHeaderRef";
my $rowHeaderRef = "rowHeaderRef";

my $INFINTE_NUMBER = 999999999;

#######################################################################################################################

=head1 Name 

Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo - Module which uses Hungarian Algorithm for assigning labels to the clusters. 

=head1 SYNOPSIS

	The following code snippet will show how to use this module.

	# Including the AssigningLabelUsingHungarianAlgo Module.
	use Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo;
	
	# Defining the matrix which contains the similarity scores for labels and clusters.
	my @mat = ( [ 2, 4, 7 ], [ 3, 9, 5 ], [ 8, 2, 9 ], );

	# Defining the header for these matrix.
	my @topicHeader = ("BillClinton", "TonyBlair", "EhudBarak");
	my @clusterHeader = ("Cluster0", "Cluster1", "Cluster2");
	
	# Uncomment these to test unbalanced scenarios where number of cluster and labels are different.
	# Test Case 2:	
	#my @mat = ( [ 7, 1, 6, 8, 4 ], [ 8, 6, 5, 9, 8 ], [ 7, 6, 5, 8, 2 ], );
	#my @topicHeader = ("BillClinton", "TonyBlair", "EhudBarak", "SaddamHussien", "VladmirPutin");
	#my @clusterHeader = ("Cluster0", "Cluster1", "Cluster2");
	
	# Test Case 3:	
	#my @mat = ( [ 7, 1, 6 ], [ 8, 6, 5 ], [ 7, 6, 5 ], [ 8, 9, 8 ], [ 1, 0, 1 ]);
	#my @topicHeader = ("BillClinton", "TonyBlair", "SaddamHussien");
	#my @clusterHeader = ("Cluster0", "Cluster1", "Cluster2", "Cluster3", "Cluster4");


	# Creating the Hungarian object.
	my $hungarainObject = Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo
						->new(\@mat, \@topicHeader, \@clusterHeader);

	# Assigning the labels to clusters using Hungarian algorithm.
	my $accuracy = $hungarainObject->reAssigningWithHungarianAlgo();

	# Assigning the labels to clusters using Hungarian algorithm. In this case,
	# user will get new matrix which contains the mapping between clusters and labels.
	#my ($accuracy,$finalMatrixRef,$newColumnHeaderRef) = 
	#		$hungarainObject->reAssigningWithHungarianAlgo();

	# Following function will just print matrix for you.
	#Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo::printMatrix 
	#		($finalMatrixRef, $newColumnHeaderRef, \@clusterHeader);

	print "\n\nAccuracy of labels is $accuracy. ";
	print "\n";


=head1 DESCRIPTION 
	
This module assign labels for the clusters using the hungarian algorithm.

Please refer the following for detailed explaination of hungarian algorithm:
http://search.cpan.org/~tpederse/Algorithm-Munkres-0.08/lib/Algorithm/Munkres.pm

=cut
##########################################################################################





##########################################################################################

=head1 Constructor: new()   

This is the constructor which will create object for this class.
Reference : http://perldoc.perl.org/perlobj.html

This constructor takes these argument and intialize it for the class:
	1. Matrix :  
			This is the two dimensional array, containing the similarity
			score. We will take the inverse of these scores for hungarian
			algorithm. As the Hungarian algorithm, uses the minimum scores
			in assignment(as diagonal score) while we need the maximum scores
			for the assignment.
			
	2. Column Header:
			This is 1D array, which contains the header information for each
			Column.
			
	2. Row Header:
			This is 1D array, which contains the header information for each
			Row.
					
=cut

##########################################################################################
sub new {
	# Creating the object.
	my $class        = shift;
	my $hungrarianObject = {};

	# Explicit association is created by the built-in bless function.
	bless $hungrarianObject, $class;

	# Getting the Reference of Matrix-to-print as the argument.
	my $matRef = shift;
	# Getting the matrix from the reference.
	$hungrarianObject->{$matrixToArrangeRef} = $matRef;
	
	# Getting the Reference of Column-Header matrix as the argument.
	my $columnHeadersRef = shift;
	# Getting the matrix from the reference.
	$hungrarianObject->{$columnHeaderRef} = $columnHeadersRef;

	# Getting the Reference of Column-Header matrix as the argument.
	my $rowHeadersRef = shift;
	# Getting the matrix from the reference.
	$hungrarianObject->{$rowHeaderRef} = $rowHeadersRef;
	
	# Returning the blessed hash refered by $self.
	return $hungrarianObject;
}	


##########################################################################################
=head1 function: reAssigningWithHungarianAlgo

This method will assign the labels to each cluster using the Hugarian Algorithm.
While assigning the labels it will consider the similarity score of these labels
with the gold standard keys. 
	 
@argument	: $hungrarianObject	DataType(Reference of the object of this class)
					
@return		: $accuracy : DataType(Float)
				Indicates the overall accuracy of the assignments. 

OR
 
@return		: $accuracy : DataType(Float)
					Indicates the overall accuracy of the assignments.
			  \@final  : DataType(Reference of 2-D Array.)
			  		Reference of two dimensional array whose diagonal values contains
			  		the similarity score for clusters labels and gold standard keys.  
			  \@newColumnHeader: DataType(Reference of 1-D Array.)
			  		Reference to new order of the column headers which corresponds
			  		to changed diagonal elements. 
	
@description	:
	1). It will read the Matrix contianing the similarity score of each cluster
	    labels and gold keys data.
	2). It will than call a function which will inverse the similarity scores.
	3). Then, it will call the 'assign' function from the "Algorithm::Munkres" with
		 this similarity scores.
	4). It will calculate the accuracy for the assignment as
	
			 					Sum (Diagonal Scores)
		  		Accuracy =	 -------------------------
		 						Sum (All the Scores)
	5). Finally, the new arrangement is used to determine the new headers for
		each column. 
	
=cut
##########################################################################################
sub reAssigningWithHungarianAlgo{
	
	# Getting the Reference of Matrix-to-print as the argument.
	my $hungrarianObject = shift;
	
	# Getting the matrix-to-rearranged from the class object.
	my $matRef = $hungrarianObject->{$matrixToArrangeRef};
	my @mat = @$matRef;
	
	# Getting the Column-Header-Matrix as Array from the class object.
	my $columnHeaderRefer = $hungrarianObject->{$columnHeaderRef};
	my @columnHeaderArray = @$columnHeaderRefer;
	
	# Getting the Row-Header matrix as Array from the class object.
	my $rowHeaderRefer = $hungrarianObject->{$rowHeaderRef};
	my @rowHeaderArray = @$rowHeaderRefer;

	# Variable to store the total count of the matrix.
	my $totalMatrixCount = 0;	
	
	# Variable to store the total diagonal count of the matrix.
	my $totalDiagonalCount = 0;
	 
	# Variable used to storing the final matrix.
	my @final;
	
	# Variable used for iteration of the matrix.
	my $rowIndex = 0;
	
	print STDERR "\nOriginal Contigency Matrix: \n ";
	printMatrix(\@mat,\@columnHeaderArray,\@rowHeaderArray);
	
	my $inversedMatrixRef = inverseMatrixCellValue(\@mat);
	my @inversedMatrix = @$inversedMatrixRef;
	
	# Calling the "Algorithm::Munkres" to calculate the assignment.
	assign( \@inversedMatrix, \@out_mat );


	# Rearranging the original matrix to get the new matrix.
	foreach $row (0..@out_mat-1){
		foreach $col (0..@out_mat-1){	
			if($mat[$row][$out_mat[$col]]){
				$final[$row][$col]=$mat[$row][$out_mat[$col]];
			}else{
				$final[$row][$col]= 0;
			}
			# Getting the diagonal Count.
			if($row == $col){
				$totalDiagonalCount = $totalDiagonalCount + $final[$row][$col];
			}
			# Getting the total Count of the matrix.
			$totalMatrixCount = $totalMatrixCount + $final[$row][$col];	
		}
	}	

	
	# This array will hold the rearranged column information.
	my @newColumnHeader = (); 
	my $newColIndex=0;

	# Getting the new rearranged Column header.
	foreach $col (0..@out_mat-1){	
		if($columnHeaderArray[$out_mat[$col]]){
			$newColumnHeader[$newColIndex++] = $columnHeaderArray[$out_mat[$col]];	
		}else{
			$newColumnHeader[$newColIndex++] = "Unknown";
		}
	}
	
	print STDERR " \n\n\nContigency Matrix after Hungarian Algorithm: \n ";
	printMatrix(\@final, \@newColumnHeader,\@rowHeaderArray);
	print STDERR "\n\n\nFinal Conclusion using Hungarian Algorithm::";
	$rowIndex = 0;
	foreach my $colValue (@newColumnHeader){
		if($rowHeaderArray[$rowIndex]){
			print STDERR "\n\t$rowHeaderArray[$rowIndex]\t<-->\t$colValue";
		}else{
			print STDERR "\n\tUnknown\t\t<-->\t$colValue";
		}	
		$rowIndex++;
	}
	
	print STDERR "\n\n";
	
	my $accuracy = 0;
	
	# Calculating the total accuracy of the assignment.
	if($totalMatrixCount !=0 ){
		$accuracy = ($totalDiagonalCount / $totalMatrixCount);
	}
	
	#print STDERR "\n\nAccuracy of labels is  $accuracy-->$totalDiagonalCount-->$totalMatrixCount-->\n\n\n";
	# Reference : http://perldoc.perl.org/functions/wantarray.html
	return wantarray ? ($accuracy,\@final,\@newColumnHeader) : $accuracy;	
}


##########################################################################################
=head1 function: inverseMatrixCellValue

Method will inverse the value of the cell of the input matrix.
	 
@argument	: $matRef	: DataType(Reference of the 2-D Matrix)
				This is 2-D array containing the integeral values which will be
				inversed. 
					
@return		: $inverseMatrixRef  : DataType(Reference of the 2-D Matrix)
				This is 2-D array containing the inversed values for the input
				2-D array.
				
@description	:
	1). For the input 2-D array containing the array, each value is inversed
	    and store in the new 2-D array 
	
			 						1
		  		New-value = -------------------
		 						Original-Value
		 						
	2). If the Original-Value = 0, New-value = 0. 
	
=cut
##########################################################################################
sub inverseMatrixCellValue{
	# Getting the Reference of Matrix as the argument.
	my $matRef = shift;
	# Getting the matrix from the reference.
	my @mat = @$matRef;
	# Defining the matix which will contains the inverse values of the original matrix.
	my @inversedMatrix = ();
	
	foreach $row (0..@mat-1){
		foreach $column (0..@{$mat[$row]}-1){
			# If the matrix is zero, than do not divide it by zero.
			if($mat[$row][$column]==0){
				$inverseMatrix[$row][$column] = $INFINTE_NUMBER;
				next;
			}
	    	$inverseMatrix[$row][$column] = 1/$mat[$row][$column] ;
	  	}
	}
	# Returning the inversed matrix.
	return \@inverseMatrix;
}


##########################################################################################
=head1 function: printMatrix

Method will print the content of 2-D array in the matrix format.
	 
@argument1	: $matRef		  : DataType(Reference of the 2-D Array)
				This is 2-D array which has to be printed in the matrix format.
@argument2	: $colHeaderRef : DataType(Reference of the 1-D array)
					Reference to array containing header info for columns
@argument3	: $rowHeaderRef : DataType(Reference of the 1-D array)				
					Reference to array containing header info for rows.
					
@description	:
		1. Method for printing the matrix. If user provide his/her own headers 
 		   then this method will use it, otherwise this method will present 
 		   default headers.
	
=cut
##########################################################################################

sub printMatrix{
	
	# Getting the Reference of Matrix-to-print as the argument.
	my $matrixToPrintRef = shift;
	# Getting the matrix from the reference.
	my @matrixToPrint = @$matrixToPrintRef;

	# Getting the Reference of Column-Header matrix as the argument.
	my $columnHeaderRef = shift;
	# Getting the matrix from the reference.
	my @columnHeader = @$columnHeaderRef;

	# Getting the Reference of Column-Header matrix as the argument.
	my $rowHeaderRef = shift;
	# Getting the matrix from the reference.
	my @rowHeader = @$rowHeaderRef;

	# Defining the row index.
	my $rowIndex = 0;
	
	# Printing the Column Header. If user provide the column header, then use it
	# otherwise use the default one. 
	if(@columnHeader){
		print STDERR "\n";
		foreach my $colIndex (@columnHeader){
			print STDERR "\t$colIndex"; 
		}
	}else{
		print STDERR "\tColumn1\tColumn2\tColumn3";
	}
	
	# Printing the Content of the Matrix.
	print STDERR "\n-------------------------------------------------";
	foreach $row (0..@matrixToPrint-1){
		# If user provide its own row header then use it, otherwise print default header.
		if($rowHeader[$rowIndex]){
			print STDERR "\n ".$rowHeader[$rowIndex++];
		}else{
			print STDERR "\n Row".++$rowIndex."\t";
		}
		# Printing the cell of the matrix.
		foreach $column (0..@{$matrixToPrint[$row]}-1){
	  		print STDERR "\t$matrixToPrint[$row][$column]";
	  	}
	  	print STDERR "\n-------------------------------------------------";
	}
}
	
1;


#######################################################################################################
=pod

=head1 SEE ALSO

http://senseclusters.cvs.sourceforge.net/viewvc/senseclusters/LabelEvaluation/ 
 
Last modified by :
$Id: AssigningLabelUsingHungarianAlgo.pm,v 1.5 2013/03/07 23:19:41 jhaxx030 Exp $

=head1 AUTHORS

 	Anand Jha, University of Minnesota, Duluth
 	jhaxx030 at d.umn.edu

 	Ted Pedersen, University of Minnesota, Duluth
 	tpederse at d.umn.edu


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012,2013 Ted Pedersen, Anand Jha 

See http://dev.perl.org/licenses/ for more information.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to: 
 
	
	The Free Software Foundation, Inc., 59 Temple Place, Suite 330, 
	Boston, MA  02111-1307  USA
	
	
=cut
#######################################################################################################
