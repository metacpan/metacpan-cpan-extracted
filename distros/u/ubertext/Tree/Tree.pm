#
# Package Definition
#

package Text::UberText::Tree;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Includes
#

use Text::UberText::Node::Command;
use Text::UberText::Node::Text;

#
# Global Variables
#

use vars qw/$VERSION /;

$VERSION=0.95;

#
# Methods
#

sub new
{
my ($class)=shift;
my ($object);
$object={};
bless ($object,$class);
$object->_init(@_);
return $object;
}

sub addNode
{
my ($self)=shift;
my ($x,$line,$class,$string,$obj);
while (@_)
{
	($x)=shift;
	if ($x eq "-text")
	{
		($string)=shift;
	} elsif ($x eq "-line")
	{
		($line)=shift;
	} elsif ($x eq "-class")
	{
		$class=shift;
	}
}
if ($string && $line && $class)
{
	$obj=$class->new(-text => $string, -line => $line, -tree => $self);
	$self->_addObject($obj);
}
return;
}

sub insertNode
{
my ($self)=shift;
my ($x,$string,$line,$class,$after,$before,$obj);
while (@_)
{
	($x)=shift;
	if ($x eq "-text")
	{
		($string)=shift;
	} elsif ($x eq "-line")
	{
		($line)=shift;
	} elsif ($x eq "-class")
	{
		$class=shift;
	} elsif ($x eq "-after")
	{
		($after)=shift;
	} elsif ($x eq "-before")
	{
		($before)=shift;
	}
}
if ($string && $line && $class)
{
	$obj=$class->new(-text => $string, -line => $line, -tree => $self );
	if ($after)
	{
		$self->_insertObj($obj, -after => $after);
	} elsif ($before)
	{
		$self->_insertObj($obj, -before => $before);
	}
}
return;
}

sub flush
{
my ($self)=shift;
$self->{output}="";
return;
}

sub output
{
my ($self)=shift;
my ($n,$x,@list);
$self->{output}="";
if (@_)
{
	$n=shift;
} else {
	$n=0;
}
(@list)=$self->children($n);
while(@list)
{
	$x=shift(@list);
	$self->{output}.=$self->{tree}->[$x]->{obj}->output();
}
return $self->{output};
}

sub debugOutput
{
my ($self)=shift;
my ($n,$x,@list);
if (@_)
{
       $n=shift;
} else {
       $n=0;
}
$self->{debugOutput}="";
(@list)=$self->children($n);
while(@list)
{
       $x=shift(@list);
       #$self->{debugOutput}.=$self->{tree}->[$x]->{obj}->output(); 
       $self->{debugOutput}.="($x)".$self->{tree}->[$x]->{obj}->output();
}
return $self->{debugOutput};
}

sub treeOutput
{
my ($self)=shift;
my ($n,$x,$text,$ind,@remaining,@list);
if (@_)
{
	$n=shift;
} else {
	$n=0;
}
(@remaining)=();
(@list)=$self->children($n);
while (@list)
{
	$x=shift(@list);
	$text=$self->{tree}->[$x]->{obj}->output();
	$text=~s/\n//g;
	$ind=scalar(@remaining)*6;
	if (length($text) > (62-$ind))
	{
		$text=substr($text,0,(67-$ind))."...";
	}
	printf("%*s [%3d] %s\n",$ind,"",$x,$text);
	if ($self->children($x))
	{
		push(@remaining,[ @list ]);
		(@list)=$self->children($x);
	}
	if (!@list && @remaining)
	{
		(@list)=@{ pop (@remaining) };
	}
}
return;
}

sub children
{
my ($self)=shift;
my ($id);
if (@_)
{
	$id=shift;
} else {
	$id=0;
}
if ($self->{tree}->[$id]->{children})
{
	return @{$self->{tree}->[$id]->{children}};
} else {
	return undef;
}
}

sub showTree
{
my ($self)=shift;
my ($n,$x,$text,$ind,@remaining,@list);
if (@_)
{
	$n=shift;
} else {
	$n=0;
}
(@remaining)=();
(@list)=$self->children($n);
while (@list)
{
	$x=shift(@list);
	$text=$self->{tree}->[$x]->{obj}->input();
	$text=~s/\n//g;
	$ind=scalar(@remaining)*6;
	$text=" (".$self->{tree}->[$x]->{obj}->parent().") ".$text;
	printf("%*s [%3d] %s\n",$ind,"",$x,$text);
	if ($self->children($x))
	{
		push(@remaining,[ @list ]);
		(@list)=$self->children($x);
	}
	if (!@list && @remaining)
	{
		(@list)=@{ pop(@remaining) };
	}
}
return;
}

sub run
{
my ($self)=shift;
my ($n,$x,@list);
if (@_)
{
	$n=shift;
} else {
	$n=0;
}
(@list)=$self->children($n);
while (@list)
{
	$x=shift(@list);
	$self->{tree}->[$x]->{obj}->run();
	#$self->{output}.=$self->{tree}->[$x]->{obj}->output();
}
return;
}

sub node
{
my ($self,$id)=@_;
return $self->{tree}->[$id]->{obj};
}

sub parentId
{
my ($self,$id)=@_;
if ($self->{tree}->[$id])
{
	return $self->{tree}->[$id]->{parent};
}
}

sub dispatch
{
my ($self)=shift;
if (@_)
{
	$self->{dispatch}=shift;
}
return $self->{dispatch};
}

sub log
{
my ($self)=shift;
if (@_)
{
	$self->{log}=shift;
}
return $self->{log};
}

sub parser
{
my ($self)=shift;
if (@_)
{
	$self->{parser}=shift;
}
return $self->{parser};
}

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
my ($a);
while (@_)
{
	($a)=shift;
	if ($a eq "-noBlocks")
	{
		$self->{opts}->{noblocks}=1;
	} elsif ($a eq "-parser")
	{
		$self->{parser}=shift;
	}
}
# At this point, we should get the log and the dispatch table!
if ($self->{parser})
{
	my ($uber)=$self->{parser}->main();
	$self->{log}=$uber->log();
	$self->{dispatch}=$uber->dispatch();
}
$self->{tree}=[];
$self->{tree}->[0]={};
$self->{curParent}=0;
return;
}

sub _addObject
{
my ($self,$obj)=@_;
$obj->tree($self);
$self->_determineIndex($obj);
$self->_determineParent($obj);
$self->{tree}->[$self->{index}]->{obj}=$obj;
$self->{tree}->[$self->{index}]->{parent}=$obj->parent();
push(@{$self->{tree}->[$obj->parent()]->{children}},$self->{index});
$self->{index}++;
$obj->inserted();
return;
}

sub _insertObj
{

return;
}

sub _determineIndex
{
my ($self,$obj)=@_;
unless (defined($self->{index}))
{
	$self->{index}=1;
}
$obj->index($self->{index});
return;
}

sub _determineParent
{
my ($self,$obj)=@_;
unless (defined($self->{nextParent}))
{
	$self->{nextParent}=0;
}
$obj->parent($self->{nextParent});
if ($obj->class() eq "Command")
{
	if ($obj->startBlock())
	{
		$self->{nextParent}=$self->{index};
	} elsif ($obj->endBlock())
	{
		$self->{nextParent}=
			$self->{tree}->[$self->{nextParent}]->{parent};
	} else {
	}
}
return;
}

#
# Exit Block
#
1;

#
# POD Documentation
#

=head1 NAME

Text::UberText::Tree - Tree Representation Of UberText Document

=head1 DESCRIPTION

An UberText document can have command blocks that enclose other commands 
or text within the document.  Because of this, the document needs to be 
structured like a tree to keep track of the relationships of the commands and 
text.  Some parts of the document are siblings in relation, others have 
children, and all parts have a parent.

Each broken down portion of the document is refered to as a node, and each 
node can represent either a command, or a piece of text.  If the command 
acts as a container block, it will have an understanding of several child 
nodes that must also be processed when the command is run by the 
L<Text::UberText::Dispatch> object.

=head1 METHODS

=over 4

=item $tree=Text::UberTree->new();

Creates a new tree object.

=item $tree->addNode(-text => $string, -line $line, -class => $class);

Adds a hunk of text to the tree.  The $string variable refers to the raw 
text, and $line refers to the line number in the source document.  The 
$class variable points to which Node class this data should be 
assigned to (either Text::UberText::Node::Text, or Text::UberText::Node::Command).

=item $tree->showTree();

Shows the breakdown of the document tree, which may be useful for 
debugging purposes.

=item $tree->run();

Processes each top level node in the tree.  If nodes at this level have 
children, they are expected to handle processing the child nodes themselves.

=item $tree->children($node_id);

Returns a list of children for a particular node id.  Zero (0) is used by 
default, and is considered the topmost node in the document.

=item $tree->output($node_id);

Returns the output of the tree for all child nodes of $node_id.  Zero (0) 
is used by default since it is the highest node in the tree.

=item $tree->debugOutput($node_id);

Returns the document output like the output() method, but prefixes the 
actual node output with the id number of the node.

=item $tree->node($node_id);

Returns a single Node object, based on the ID passed to it.

=back

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>     

=head1 SEE ALSO

L<Text::UberText::Node>,
L<Text::UberText::Dispatch>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
