#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    09/17/2016                                                             #
#    Revised: 01/31/2017                                                             #
#    UMLS Similarity - Word2Vec Binary Search Tree Node                              #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                 Binary Search Tree Node Module For Use With Binary Search Tree     #
#                                                                                    #
######################################################################################


package Word2vec::Node;

use strict;
use warnings;


# Standard Package(s)
use Class::Struct;


use vars qw($VERSION);

$VERSION = '0.02';

# Declare struct for storing data.
struct( Node => {
    word       => '$',
    data       => '$',
    parent     => '$',
    leftChild  => '$',
    rightChild => '$',
} );

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Node - Binary Search Tree Node Module.

=head1 SYNOPSIS

 use Word2vec::Node;

 my $node = Word2vec::Node->new();
 my $parentNode = Word2vec::Node->new();

 die "Error creating Node (Word2vec::Node)\n" if !defined( $node );
 die "Error creating Parent Node (Word2vec::Node)\n" if !defined( $parentNode );

 $node->word( "Cookie" );
 $node->data( "08/13/2016" );
 $node->parent( $parentNode );

 print( "Node->word: " . $node->word ) if defined( $node->word );
 print( "Node->data: " . $node->data ) if defined( $node->data );
 print( "Node has parent!" ) if defined( $node->parent );
 print( "Node has no left child!" ) if !defined( $node->leftChild );
 print( "Node has no right child!" ) if !defined( $node->rightChild );

 undef( $parentNode );
 undef( $node );

=head1 DESCRIPTION

Word2vec::Node is a binary search tree node module for Word2vec::Bst and Word2vec::W2vbst.

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
