#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    08/20/2016                                                             #
#    Revised: 01/31/2017                                                             #
#    UMLS Similarity - Binary Search Tree                                            #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                                                                                    #
#                 Binary Search Tree Module For Use With UMLS Similarity Word2Vec    #
#                 Package                                                            #
#    Features:                                                                       #
#    =========                                                                       #
#                 Speeds Up xmlTow2v module's "compoundify" option using BST for     #
#                 Compound Words                                                     #
#                                                                                    #
######################################################################################


package Word2vec::Bst;

use strict;
use warnings;

# Word2Vec Utility Package(s)
use Word2vec::Node;


use vars qw($VERSION);

$VERSION = '0.02';


######################################################################################
#    Constructor
######################################################################################

BEGIN
{
    # CONSTRUCTOR : DO SOMETHING HERE
}


######################################################################################
#    Deconstructor
######################################################################################

END
{
    # DECONSTRUCTOR : DO SOMETHING HERE

    my ( $self ) = @_;
    $self->CleanUp( $self->{ _rootNode } ) if defined( $self->{ _rootNode } );
}


######################################################################################
#    new Class Operator
######################################################################################

sub new
{
    my $class = shift;
    my $self = {
        # Private Member Variables
        _debugLog => shift,                     # Boolean (Binary): 0 = False, 1 = True
        _writeLog => shift,                     # Boolean (Binary): 0 = False, 1 = True
        _rootNode => shift,                     # Node struct
    };
    
    # Set debug log variable to false if not defined
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    $self->{ _rootNode } = Node->new() if !defined ( $self->{ _rootNode } );
    
    bless $self, $class;
}


######################################################################################
#    DESTROY
######################################################################################

sub DESTROY
{
    my ( $self ) = shift;
    $self->DeleteBSTNodes( $self->{ _rootNode } ) if defined( $self->{ _rootNode } );
    undef( $self->{ _rootNode } ) if defined( $self->{ _rootNode } );
}


######################################################################################
#    Module Functions
######################################################################################

sub CreateTree
{
    my ( $self, $aryRef, $start, $end, $parentNode ) = @_;
    
     # Check(s)
    return if !defined ( $aryRef );
    return if !defined ( $start );
    return if !defined ( $end );
    
    my $rootNode = $self->CreateBST( $aryRef, $start, $end, $parentNode );
    $self->SetRootNode( $rootNode );
    
    return 0 if defined( $rootNode );
    return -1 if !defined( $rootNode );
}

sub CreateBST
{
    my ( $self, $aryRef, $start, $end, $parentNode ) = @_;
    
    # Check(s)
    return if !defined ( $aryRef );
    return if !defined ( $start );
    return if !defined ( $end );
    
    # Create BST
    if( $start <= $end )
    {
        my @array = @$aryRef;
        my $midIndex = int( $start + ( $end - $start ) / 2 );
        my $currentNode = Node->new();
        $currentNode->data( $array[ $midIndex ] );
        
        # Split Array Into Smaller Arrays For Performance
        my @rightAry = splice( @array, $midIndex + 1, $end );
        my @leftAry = splice( @array, $start, $midIndex );
        my $leftAryEnd = @leftAry;
        my $rightAryEnd = @rightAry;
        
        # Set Parent, Left Child and Right Child Nodes Of Current Node
        $currentNode->parent( $parentNode );
        $currentNode->leftChild( $self->CreateBST( \@leftAry, $start, $leftAryEnd -1, $currentNode ) );
        $currentNode->rightChild( $self->CreateBST( \@rightAry, $start, $rightAryEnd - 1, $currentNode ) );
        
        return $currentNode;
    }
    
    return undef;
}

sub BSTContainsSearch
{
    my ( $self, $node, $searchWord ) = @_;
    
    # Check(s)
    return undef if !defined ( $searchWord );
    
    # Search Binary Tree
    if( defined ( $node ) && defined( $node->data ) )
    {
        my @searchWordAry = split( ' ', $searchWord );
        my @nodeDataAry = split( ' ', $node->data );
        
        my $searchStr = "";
        my $nodeStr = "";
        
        # Create "Node String" With Same Amount Of Words "Search Word"
        if( @searchWordAry < @nodeDataAry )
        {
            $searchStr = $searchWord;
            @nodeDataAry = splice( @nodeDataAry, 0, @searchWordAry );
            $nodeStr = join( ' ', @nodeDataAry );
        }
        else
        {
            $searchStr = $searchWord;
            $nodeStr = $node->data;
        }
        
        if( index( $node->data, $searchWord ) != 0 || ( $searchStr cmp $nodeStr ) != 0 )
        {
            if( ( $searchWord cmp $node->data ) == -1 )
            {
                $node = $self->BSTContainsSearch( $node->leftChild, $searchWord );
            }
            elsif( ( $searchWord cmp $node->data ) == 1 )
            {
                $node = $self->BSTContainsSearch( $node->rightChild, $searchWord );
            }
        }
        
        return $node;
    }
    
    return undef;
}

sub BSTExactSearch
{
    my ( $self, $node, $searchWord ) = @_;
    
    # Check(s)
    return undef if !defined ( $searchWord );
    
    
    # Search Binary Tree
    if( defined ( $node ) )
    {
        if( defined( $node->data ) && $node->data ne $searchWord )
        {
            if( ( $searchWord cmp $node->data ) == -1 )
            {
                $node = $self->BSTExactSearch( $node->leftChild, $searchWord );
            }
            elsif( ( $searchWord cmp $node->data ) == 1 )
            {
                $node = $self->BSTExactSearch( $node->rightChild, $searchWord );
            }
        }
        
        return $node;
    }
    
    return undef;
}

sub DeleteBSTNodes
{
    my ( $self, $node ) = @_;
    
    return if( !defined ( $node ) );
    
    # Get Left Child Node
    $self->DeleteBSTNodes( $node->leftChild ) if( defined( $node->leftChild ) );
    
    # Get Right Child Node
    $self->DeleteBSTNodes( $node->rightChild ) if( defined( $node->rightChild ) );
    
    # Delete Node
    $node->word( "" );
    $node->data( "" );
    undef( $node );
}

######################################################################################
#    Accessors
######################################################################################

sub GetDebugLog
{
    my ( $self ) = @_;
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    return $self->{ _debugLog };
}

sub GetWriteLog
{
    my ( $self ) = @_;
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    return $self->{ _writeLog };
}

sub GetRootNode
{
    my ( $self ) = @_;
    $self->{ _rootNode } = undef if !defined ( $self->{ _rootNode } );
    return $self->{ _rootNode };
}


######################################################################################
#    Mutators
######################################################################################

sub SetRootNode
{
    my ( $self, $node ) = @_;
    return $self->{ _rootNode } = $node;
}


#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Bst - xmltow2v Basic Binary Search Tree Module

=head1 SYNOPSIS

 use Word2vec::Bst;

 my @sortedArray = ( "Cookie", "Lungs", "Money", "Veterinarian", "Dog", "Urn", "Heart", "Coffee Grounds" );
 @sortedArray = sort( @sortedArray );

 my $sortedArrayRef = \@sortedArray;
 my $arySize = @sortedArray;

 my $bst = Word2vec::Bst->new();
 my $rootNode = $bst->CreateBST( $sortedArrayRef, 0, $arySize, undef );
 $bst->SetRootNode( $rootNode );

 my $node1 = $bst->BSTExactSearch( $rootNode, "Coffee" );
 my $node2 = $bst->BSTContainsSearch( $rootNode, "Coffee" );

 print( "Exact Phrase Match Found - Search Word: \"Coffee\"\n" ) if defined( $node1 );
 print( "Exact Phrase: \"Coffee\" Not Found\n" ) if !defined( $node1 );
 print( "Phrase Containing Word: \"Coffee\" Found\n" ) if defined( $node2 );
 print( "Phrase Containing Word: \"Coffee\" Not Found\n" ) if !defined( $node2 );

 undef( @sortedArray );
 $bst->DESTROY();
 undef( $bst );

=head1 DESCRIPTION

Word2vec::Bst is a basic binary search tree module for use with Word2vec::Xmltow2v.
This module expects a sorted array passed as a function parameter (array reference)
to create a balanced binary search tree.

=head2 Main Functions

=head3 new

Description:

 Returns a new 'Word2vec::Bst' module object.

Input:

 None

Output:

  Word2vec::Bst object.

Example:

 use Word2vec::Bst;
 my $bst = Word2vec::Bst->new();

 print( "Word2vec::Bst object creation successful\n" ) if defined( $bst );
 print( "Word2vec::Bst object creation un-successful\n" ) if !defined( $bst );

 print( "Removing Tree From Memory\n" ) if defined( $bst );
 $bst->DESTROY() if defined( $bst );
 undef( $bst );

=head3 DESTROY

Description:

 Removes binary search tree from memory.

Input:

 None

Output:

 None

Example:

 See above example for "new" function.

 Note: Destroy function is also automatically called during global destruction when exiting the program.

=head3 CreateTree

Description:

 Creates binary search tree with required function parameters and sets member variable root node in 'Word2vec::Bst' object.

 Note: The array must be sorted before calling this method to create a balanced tree.

Input:

 $arrayReference -> Reference to an array containing sorted string data.
 $startIndex     -> Beginning index of sorted array which the function incorporates into the binary tree.
 $endIndex       -> Last index of the sorted array which the function incorporates into the binary tree.
 $parentNode     -> Parent node parameter of type 'Word2vec::Node'. Set to 'undef' during tree instantiation.

Output:

 $value          -> '0' if successful / '-1' if un-successful.

Example:

 use Word2vec::Bst;

 my @sortedArray = ( "Cookie", "Lungs", "Money", "Veterinarian", "Dog", "Urn", "Heart", "Coffee Grounds" );
 @sortedArray = sort( @sortedArray );

 my $sortedArrayRef = \@sortedArray;
 my $arySize = @sortedArray;

 my $bst = Word2vec::Bst->new();
 my $result = $bst->CreateTree( $sortedArrayRef, 0, $arySize, undef );

 print( "Binary Search Tree Created Successfully\n" ) if $result == 0;
 print( "Binary Search Tree Creation Un-Successful\n" ) if $result == -1;

 $bst->DESTROY() if defined( $bst );
 undef( $bst );

=head3 CreateBST

Description:

 Creates binary search tree with required function parameters. Returns the root node.

 Note: The array must be sorted before calling this method to create a balanced tree.

Input:

 $arrayReference  -> Reference to an array containing sorted string data.
 $startIndex      -> Beginning index of sorted array which the function incorporates into the binary tree.
 $endIndex        -> Last index of the sorted array which the function incorporates into the binary tree.
 $parentNode      -> Parent node parameter of type 'Word2vec::Node'. Set to 'undef' during tree instantiation.

Output:

 Word2vec::Node -> Binary Search Tree root node or 'undef'.

Example:

 use Word2vec::Bst;

 my @sortedArray = ( "Cookie", "Lungs", "Money", "Veterinarian", "Dog", "Urn", "Heart", "Coffee Grounds" );
 @sortedArray = sort( @sortedArray );

 my $sortedArrayRef = \@sortedArray;
 my $arySize = @sortedArray;

 my $bst = Word2vec::Bst->new();
 my $rootNode = $bst->CreateBST( $sortedArrayRef, 0, $arySize, undef );
 $bst->SetRootNode( $rootNode );

 $bst->DESTROY() if defined( $bst );
 undef( $bst );

=head3 BSTContainsSearch

Description:

 Searches binary search tree nodes to see if 'node->data' contains passed string parameter,
 beginning with the passed node parameter and propagates down the tree until found.

Input:

 Word2vec::Node   -> Starting tree node to search. (ie. Begin at root node)
 string           -> Search word/phrase.

Output:

 Word2vec::Node -> Returns binary search tree node or 'undef' if not found.

Example:

 use Word2vec::Bst;

 my @sortedArray = ( "Cookie", "Lungs", "Money", "Veterinarian", "Dog", "Urn", "Heart", "Coffee Grounds" );
 @sortedArray = sort( @sortedArray );

 my $sortedArrayRef = \@sortedArray;
 my $arySize = @sortedArray;

 my $bst = Word2vec::Bst->new();
 my $result = $bst->CreateTree( $sortedArrayRef, 0, $arySize, undef );

 print( "Binary Search Tree - Created Successfully\n" ) if $result == 0;
 print( "Binary Search Tree - Creation Un-successful\n" ) if $result == -1;
 die "" if $result == -1;

 my $node = $bst->BSTContainsSearch( $rootNode, "Coffee" );

 print( "Phrase Containing Word: \"Coffee\" Found\n" ) if defined( $node );
 print( "Phrase Containing Word: \"Coffee\" Not Found\n" ) if !defined( $node );

 undef( @sortedArray );
 $bst->DESTROY();
 undef( $bst );

=head3 BSTExactSearch

Description:

 Searches binary search tree for passed string parameter, beginning with passed node and propagates
 down the tree until found.

Input:

 Word2vec::Node   -> Starting tree node to search. (ie. Begin at root node)
 string           -> Search word/phrase.

Output:

 Word2vec::Node -> Returns binary search tree node or 'undef' if not found.

Example:

 use Word2vec::Bst;

 my @sortedArray = ( "Cookie", "Lungs", "Money", "Veterinarian", "Dog", "Urn", "Heart", "Coffee Grounds" );
 @sortedArray = sort( @sortedArray );

 my $sortedArrayRef = \@sortedArray;
 my $arySize = @sortedArray;

 my $bst = Word2vec::Bst->new();
 my $result = $bst->CreateTree( $sortedArrayRef, 0, $arySize, undef );

 print( "Binary Search Tree - Created Successfully\n" ) if $result == 0;
 print( "Binary Search Tree - Creation Un-successful\n" ) if $result == -1;
 die "" if $result == -1;

 my $node = $bst->BSTExactSearch( $rootNode, "Money" );

 print( "Exact Phrase Match Found - Search Word: \"Money\"\n" ) if defined( $node );
 print( "Exact Phrase: \"Money\" Not Found\n" ) if !defined( $node );

 undef( @sortedArray );
 $bst->DESTROY();
 undef( $bst );

=head3 DeleteBSTNodes

Description:

 Recursive function that deletes all parameter node's left and right children that propagates downward. Called by
 DESTROY() function to remove tree from memory.

Input:

 Word2vec::Node -> Starting node of tree to remove from memory. (ie. root node)

Output:

 None

Example:

 use Word2vec::Bst;

 my @sortedArray = ( "Cookie", "Lungs", "Money", "Veterinarian", "Dog", "Urn", "Heart", "Coffee Grounds" );
 @sortedArray = sort( @sortedArray );

 my $sortedArrayRef = \@sortedArray;
 my $arySize = @sortedArray;

 my $bst = Word2vec::Bst->new();
 my $result = $bst->CreateTree( $sortedArrayRef, 0, $arySize, undef );

 print( "Binary Search Tree - Created Successfully\n" ) if $result == 0;
 print( "Binary Search Tree - Creation Un-successful\n" ) if $result == -1;
 die "" if $result == -1;

 print( "Destroying Binary Search Tree\n" );

 $bst->DESTROY();

 undef( @sortedArray );
 undef( $bst );

=head2 Accessor Functions

=head3 GetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Bst object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Bst;

 my $bst = Word2vec::Bst->new();
 my $debugLog = $bst->GetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;

 undef( $bst );

=head3 GetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Bst object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Bst;

 my $bst = Word2vec::Bst->new();
 my $writeLog = $bst->GetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $bst );

=head3 GetRootNode

Description:

 Returns binary search tree root node.

Input:

 None

Output:

 Word2vec::Node -> Binary Search Tree Root Node

Example:

 use Word2vec::Bst;

 my @sortedArray = ( "Cookie", "Lungs", "Money", "Veterinarian", "Dog", "Urn", "Heart", "Coffee Grounds" );
 @sortedArray = sort( @sortedArray );

 my $sortedArrayRef = \@sortedArray;
 my $arySize = @sortedArray;

 my $bst = Word2vec::Bst->new();
 my $result = $bst->CreateTree( $sortedArrayRef, 0, $arySize, undef );

 print( "Binary Search Tree - Created Successfully\n" ) if $result == 0;
 print( "Binary Search Tree - Creation Un-successful\n" ) if $result == -1;
 die "" if $result == -1;

 my $rootNode = $bst->GetRootNode();

 print( "BST Root Node Exists\n" ) if defined( $rootNode );
 print( "BST Root Node Does Not Exist\n" ) if !defined( $rootNode );

 print( "Root Node Contains Data: " . $rootNode->data . "\n" ) if defined( $rootNode ) && defined( $rootNode->data );

 print( "Destroying Binary Search Tree\n" );

 $bst->DESTROY();

 undef( @sortedArray );
 undef( $bst );

=head2 Mutator Functions

=head3 SetRootNode

Description:

 Sets binary search tree root node to passed node parameter.

Input:

 Word2vec::Node -> Binary Search Tree node which will be set to the root node of the tree.

Output:

 None

Example:

 use Word2vec::Bst;

 my @sortedArray = ( "Cookie", "Lungs", "Money", "Veterinarian", "Dog", "Urn", "Heart", "Coffee Grounds" );
 @sortedArray = sort( @sortedArray );

 my $sortedArrayRef = \@sortedArray;
 my $arySize = @sortedArray;

 my $bst = Word2vec::Bst->new();
 my $result = $bst->CreateTree( $sortedArrayRef, 0, $arySize, undef );

 print( "Binary Search Tree - Created Successfully\n" ) if $result == 0;
 print( "Binary Search Tree - Creation Un-successful\n" ) if $result == -1;
 die "" if $result == -1;

 my $rootNode = $bst->GetRootNode();

 print( "BST Root Node Exists\n" ) if defined( $rootNode );
 print( "BST Root Node Does Not Exist\n" ) if !defined( $rootNode );

 $bst->SetRootNode( $rootNode ) if defined( $rootNode );

 print( "Destroying Binary Search Tree\n" );

 $bst->DESTROY();

 undef( @sortedArray );
 undef( $bst );

=head1 Author

 Clint Cuffy, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2016

 Bridget T McInnes, Virginia Commonwealth University
 btmcinnes at vcu dot edu

 Clint Cuffy, Virginia Commonwealth University
 cuffyca at vcu dot edu

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut
