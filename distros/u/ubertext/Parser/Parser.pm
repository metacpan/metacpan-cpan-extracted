#
# Package Definition
#

package Text::UberText::Parser;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Includes
#

use Text::UberText::Tree;

#
# Global Variables
#

use vars qw/$DefaultTagChars $DefaultBlockChars $VERSION /;

$VERSION=0.95;

$DefaultTagChars={
	"st" => "[",
	"et" => "]",
};

$DefaultBlockChars={
	"st" => "->",
	"et" => "<-",
};

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

sub quickie
{
my ($mainParser)=shift;
my ($parser,$tree,$uber);
# Create a new parser object
$uber=$mainParser->main();
$parser=Text::UberText::Parser->new(-noBlocks, -cmdOpt, -main => $uber);
# Pass along the main log and dispatch objects to the new parser
$parser->log($uber->log());
$parser->dispatch($uber->dispatch());
$parser->input(@_);
$tree=$parser->parse();
$tree->run();
return $tree->output();
}

sub input
{
my ($self)=shift;
push (@{$self->{input}},@_);
return;
}

sub clear
{
my ($self)=shift;
$self->{input}=[];
return;
}

sub parse
{
my ($self)=shift;
my ($st,$et,$input,$linenum,$nodenum,$x,$level,$chunk,$log,@chars);
$self->_opts(@_);
if (defined($self->{opts}->{noBlocks}))
{
	$self->{tree}=Text::UberText::Tree->new(-noBlocks, -parser => $self);
} else {
	$self->{tree}=Text::UberText::Tree->new(-parser => $self);
}
$self->{tree}->dispatch($self->{dispatch});
$self->{tree}->log($self->{log});
$st=$DefaultTagChars->{st};
$et=$DefaultTagChars->{et};
$input=join("",@{$self->{input}});
return undef unless ($input);
(@chars)=split(//,$input);
$linenum=1;
$nodenum=1;
$chunk="";
$level=0;
while (@chars)
{
	($x)=shift(@chars);
	if ($x eq $st)
	{
		$level++;
		if ($level==1)
		{
			# Close out the previous node (if any)
			$self->_addNode($chunk,$linenum);
			# Start a new node
			$chunk=$x;
			$nodenum++;
			next;
		}
	} elsif ($x eq $et)
	{
		$level--;
		if ($level==0)
		{
			# Close out the current node
			$chunk.=$x;
			$chunk=$self->_checkCmd($chunk);
			$self->_addNode($chunk,$linenum);
			# Start a new node
			$chunk="";
			$nodenum++;
			next;
		} elsif ($level < 0)
		{
			$self->{log}->write("Parser",
				"Too many closing brackets",$linenum,"ERROR");
		}
	} elsif ($x eq "\n")
	{
		$linenum++;
	} 
	$chunk.=$x;
}
if ($chunk)
{
	$self->_addNode($chunk,$linenum);
}
if ($level > 0)
{
	$self->{log}->write("Parser",
		"Unmatched opening block",$linenum,"ERROR");
}
if ($self->{log})
{
	if (defined($self->{opts}->{cmdblock}))
	{
		$self->{log}->write("Parser/cmdblock",
			"Parsed $linenum lines, $nodenum nodes",
			$linenum,"NOTICE");
	} else {
		$self->{log}->write("Parser/main",
			"Parsed $linenum lines, $nodenum nodes"
			,$linenum,"NOTICE");
	}
}
return $self->{tree};
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

sub main
{
my ($self)=shift;
if (@_)
{
	$self->{main}=shift;
}
return $self->{main};
}

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
$self->{blocks}=[];
while (@_)
{
	($a)=shift;
	if ($a eq "-main")
	{
		$self->{main}=shift;
	} elsif ($a eq "-cmdOpt")
	{
		$self->{opts}->{cmdblock}=1;
	} elsif ($a eq "-noBlocks")
	{
		$self->{opts}->{noblocks}=1;
	}
}
return;
}

sub _opts
{
my ($self)=shift;
while (@_)
{
	($a)=shift;
	if ($a eq "-noBlocks")
	{
		# Command container blocks are not allowed
		$self->{opts}->{noblocks}=1;
	} elsif ($a eq "-cmdOpt")
	{
		print("PARSING IN A COMMAND BLOCK!\n");
		# We are parsing the option to a command
		$self->{opts}->{cmdblock}=1;
	}
}
return;
}

sub _checkCmd
{
my ($self)=shift;
if (@_)
{
	my ($chunk)=@_;
	my ($st,$et);
	$st=$DefaultBlockChars->{st};
	$et=$DefaultBlockChars->{et};
	if ($chunk =~ /(^\[\s*$et|$st\s*\]$)/ && $self->{noblocks})
	{
		$chunk=~s/(^\[\s*$et|$st\s*\]$)//g;
	}
	return $chunk;
}
}

sub _addNode
{
my ($self)=shift;
my ($text,$line)=@_;
if ($text =~ /^\[.*\]$/s)
{
	# command node
	$self->{tree}->addNode( -text => $text,
		-line => $line,
		-class => "Text::UberText::Node::Command");
} elsif ($text ne "")
{
	# text node
	$self->{tree}->addNode( -text => $text,
		-line => $line,
		-class => "Text::UberText::Node::Text");
} else {
	print("Empty node!\n");
	# empty node
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

Text::UberText::Parser - Main parser for UberText streams

=head1 SYNOPSIS

Text::UberText::Parser methods are not normally called directly

=head1 DESCRIPTION

The UberText::Parser module handles the incoming text stream and breaks it 
up into the text and command nodes.  The nodes are then handed off to a 
Text::UberText::Tree object which creates the Text::UberText::Node objects 
and inserts them at the appropriate part of the document tree.

=head1 METHODS

=over 4

=item $parser=Text::UberText::Parser->new();

Creates a new parser object.

=item $parser->input(@array);

Takes the passed text and saves it for further parsing.  If called multiple 
times, it appends the new text to any previous text passed.

=item $tree=$parser->parse();

Runs the parsing routines to break apart the document.  The commands and text 
of the document are seperated into nodes and passed to the Text::UberText::Tree 
object which places them in the appropriate order.  The tree object is 
then returned so it can be run or further manipulated.

=item $parser->clear();

Wipes out the internal document input data.

=item $parser->quickie(@array);

Designed to quickly process small streams (like the values tied to 
commands or options in a Command node), the quickie method takes the input, 
and sends it to a new parser object, processes the input, returns a new 
tree, runs the tree, and then returns the output from the tree object.

The quickie method is actually very complex because it needs to create a 
seperate Tree object, but it also needs to refer back to the main Dispatch 
and Log objects.  Every time a value is used in an option or command, it 
is treated like an entirely seperate UberText document.

=back

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>

=head1 SEE ALSO

L<Text::UberText::Tree>,
L<Text::UberText::Node>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
