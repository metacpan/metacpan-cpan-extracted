#
# Package Definition
#

package Text::UberText::Node;

#
# Compiler Directives
#

use strict;
use warnings;

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

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
my ($x,$text,$line,$tree);
while (@_)
{
	($x)=shift;
	if ($x eq "-text")
	{
		$text=shift;
	} elsif ($x eq "-line")
	{
		$line=shift;
		$self->lineNumber($line);
	} elsif ($x eq "-tree")
	{
		$tree=shift;
		$self->tree($tree);
	}
}
if ($text)
{
	$self->input($text);
}
return;
}

sub input
{
my ($self)=shift;
if (@_)
{
	$self->{input}=shift;
	$self->process();
}
return $self->{input};
}

sub output
{
my ($self)=shift;
return $self->{output};
}

sub index
{
my ($self)=shift;
if (@_)
{
	$self->{index}=shift;
}
return $self->{index};
}

sub parent
{
my ($self)=shift;
if (@_)
{
	$self->{parent}=shift;
}
return $self->{parent};
}

sub lineNumber
{
my ($self)=shift;
if (@_)
{
	$self->{linenum}=shift;
}
return $self->{linenum};
}

sub class
{
my ($self)=shift;
my ($class)=ref($self);
my (@c);
(@c)=split(/::/,$class);
($class)=pop(@c);
return $class;
}

sub process
{
my ($self)=shift;

return;
}

sub inserted
{
my ($self)=shift;
# $self->process();
return;
}

sub info
{
my ($self)=shift;

return;
}

sub run
{
my ($self)=shift;

return;
}

sub tree
{
my ($self)=shift;
if (@_)
{
	$self->{tree}=shift;
}
return $self->{tree};
}

#
# Exit Block
#
1;

#
# POD Documentation
#

=head1 NAME

Text::UberText::Node - Superclass Node Object

=head1 DESCRIPTION

Text::UberText::Node is a super-class for the L<Text::UberText::Node::Text> and
L<Text::UberText::Node::Command> classes.  The methods listed below are 
implemented in both subclasses.  The POD documentation for both classes only 
lists methods that are unique to the particular module, or methods that have 
different bahavior from the methods listed below.

=head1 COMMON METHODS

=over 4

=item $node=Text::UberText::Node->new();

Creates a new node object.

=item $node->input($string);

Text string to be processed by the node.

=item $text=$node->output();

Output generated after the node has been processed and run

=item $node->process();

Parsing and examination of the node input, completed before it is 
actually run.

=item $node->run();

Process external commands using data from the node object.

=item $node->info();

Returns information on the data within the node

=item $node->tree();

Returns the $tree object that created the node.

=item $node->index();

Returns the tree index pointer for the node.

=item $node->class();

Returns the lest segment of the Perl class for the node.  For example, if 
the actual class is "Text::UberText::Node::Command:, "Command" is returned.

=item $node->lineNumber();

Returns the line number of the source input that the node text started on.

=back

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>

=head1 SEE ALSO

L<Text::UberText::Node::Command>,
L<Text::UberText::Node::Text>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
