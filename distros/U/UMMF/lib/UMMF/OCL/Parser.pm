package UMMF::OCL::Parser;

use 5.6.1;
use strict;
#use warnings;


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/10/05 };
our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::OCL::Parser - A OCL (Object Constraint Language) Parser.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/10/05

=head1 SEE ALSO

L<UMMF|UMMF>

=head1 VERSION

$Revision: 1.1 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Object);

#######################################################################


our $grammar 
q{

ExpressionInOclCS ::= OclExpressionCS


[A] OclExpressionCS ::= PropertyCallExpCS
[B] OclExpressionCS ::= VariableExpCS
[C] OclExpressionCS ::= LiteralExpCS
[D] OclExpressionCS ::= LetExpCS
[E] OclExpressionCS ::= OclMessageExpCS
[F] OclExpressionCS ::= IfExpCS


VariableExpCS ::= simpleNameCS


simpleNameCS ::= <String>


pathNameCS ::= simpleNameCS (’::’ pathNameCS )?


[A] LiteralExpCS ::= EnumLiteralExpCS
[B] LiteralExpCS ::= CollectionLiteralExpCS
[C] LiteralExpCS ::= TupleLiteralExpCS
[D] LiteralExpCS ::= PrimitiveLiteralExpCS


EnumLiteralExpCS ::= pathNameCS ’::’ simpleNameCS


[A] CollectionTypeIdentifierCS ::= ’Set’
[B] CollectionTypeIdentifierCS ::= ’Bag’
[C] CollectionTypeIdentifierCS ::= ’Sequence’
[D] CollectionTypeIdentifierCS ::= ’Collection’
[E] CollectionTypeIdentifierCS ::= ’OrderedSet’


CollectionLiteralPartsCS[1] = CollectionLiteralPartCS ( ’,’ CollectionLiteralPartsCS[2] )?


[A] CollectionLiteralPartCS ::= CollectionRangeCS
[B] CollectionLiteralPartCS ::= OclExpressionCS


CollectionRangeCS ::= OclExpressionCS[1] ’..’ OclExpressionCS[2]


[A] PrimitiveLiteralExpCS ::= IntegerLiteralExpCS
[B] PrimitiveLiteralExpCS ::= RealLiteralExpCS
[C] PrimitiveLiteralExpCS ::= StringLiteralExpCS
[D] PrimitiveLiteralExpCS ::= BooleanLiteralExpCS



TupleLiteralExpCS :: 'Tuple’ '|' VariableDeclarationListCS '|’


IntegerLiteralExpCS ::= <String>


RealLiteralExpCS ::= <String>


[A] BooleanLiteralExpCS ::= ’true’
[B] BooleanLiteralExpCS ::= ’false’


[A] PropertyCallExpCS ::= ModelPropertyCallExpCS
[B] PropertyCallExpCS ::= LoopExpCS


[A] LoopExpCS ::= IteratorExpCS
[B] LoopExpCS ::= IterateExpCS


[A] IteratorExpCS ::= OclExpressionCS[1] ’->’ simpleNameCS
’(’ (VariableDeclarationCS[1],
(’,’ VariableDeclarationCS[2])? ’|’ )?
OclExpressionCS[2]
’)’
[B] IteratorExpCS ::= OclExpressionCS ’.’ simpleNameCS ’(’argumentsCS?’)’
[C] IteratorExpCS ::= OclExpressionCS ’.’ simpleNameCS
[D] IteratorExpCS ::= OclExpressionCS ’.’ simpleNameCS
(’[’ argumentsCS ’]’)?
[E] IteratorExpCS ::= OclExpressionCS ’.’ simpleNameCS
(’[’ argumentsCS ’]’)?



IterateExpCS ::= OclExpressionCS[1] ’->’ ’iterate’
’(’ (VariableDeclarationCS[1] ’;’)?
VariableDeclarationCS[2] ’|’
OclExpressionCS[2]
’)’


VariableDeclarationCS ::= simpleNameCS (’:’ typeCS)?
( ’=’ OclExpressionCS )?


[A] typeCS ::= pathNameCS
[B] typeCS ::= collectionTypeCS
[C] typeCS ::= tupleTypeCS


collectionTypeCS ::= collectionTypeIdentifierCS ’(’ typeCS ’)’


tupleTypeCS ::= ’Tuple’ ’(’ variableDeclarationListCS? ’)’


variableDeclarationListCS[1] = VariableDeclarationCS
(’,’variableDeclarationListCS[2] )?


[A] ModelPropertyCallExpCS ::= OperationCallExpCS
[B] ModelPropertyCallExpCS ::= AttributeCallExpCS
[C] ModelPropertyCallExpCS ::= NavigationCallExpCS


[A] OperationCallExpCS ::= OclExpressionCS[1]
simpleNameCS OclExpressionCS[2]
[B] OperationCallExpCS ::= OclExpressionCS ’->’ simpleNameCS ’(’
argumentsCS? ’)’
[C] OperationCallExpCS ::= OclExpressionCS ’.’ simpleNameCS
’(’ argumentsCS? ’)’
[D] OperationCallExpCS ::= simpleNameCS ’(’ argumentsCS? ’)’
[E] OperationCallExpCS ::= OclExpressionCS ’.’ simpleNameCS
isMarkedPreCS ’(’ argumentsCS? ’)’
[F] OperationCallExpCS ::= simpleNameCS isMarkedPreCS ’(’ argumentsCS? ’)’
[G] OperationCallExpCS ::= pathNameCS ’(’ argumentsCS? ’)’
[H] OperationCallExpCS ::= simpleNameCS OclExpressionCS


[A] AttributeCallExpCS ::= OclExpressionCS ’.’ simpleNameCS isMarkedPreCS?
[B] AttributeCallExpCS ::= simpleNameCS isMarkedPreCS?
[C] AttributeCallExpCS ::= pathNameCS


[A] NavigationCallExpCS ::= AssociationEndCallExpCS
[B] NavigationCallExpCS ::= AssociationClassCallExpCS


[A] AssociationEndCallExpCS ::= OclExpressionCS ’.’ simpleNameCS
(’[’ argumentsCS ’]’)? isMarkedPreCS?
[B] AssociationEndCallExpCS ::= simpleNameCS
(’[’ argumentsCS ’]’)? isMarkedPreCS?


[A] AssociationClassCallExpCS ::= OclExpressionCS ’.’ simpleNameCS
(’[’ argumentsCS ’]’)? isMarkedPreCS?
[B] AssociationClassCallExpCS ::= simpleNameCS
(’[’ argumentsCS ’]’)? isMarkedPreCS?


isMarkedPreCS ::= ’@’ ’pre’


argumentsCS[1] ::= OclExpressionCS ( ’,’ argumentsCS[2] )?


LetExpCS ::= ’let’ VariableDeclarationCS
LetExpSubCS


[A] LetExpSubCS[1] ::= ’,’ VariableDeclarationCS LetExpSubCS[2]
[B] LetExpSubCS ::= ’in’ OclExpressionCS


[A] OclMessageExpCS ::= OclExpressionCS ’^^’
simpleNameCS ’(’ OclMessageArgumentsCS? ’)’
[B] OclMessageExpCS ::= OclExpressionCS ’^’
simpleNameCS ’(’ OclMessageArgumentsCS? ’)’


OclMessageArgumentsCS[1] ::= OclMessageArgCS
( ’,’ OclMessageArgumentsCS[2] )?


[A] OclMessageArgCS ::= ’?’ (’:’ typeCS)?
[B] OclMessageArgCS ::= OclExpressionCS


-- comment '\n'

'/*' comment '*/'

 
};


#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/10/05 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

