#
# Package Definition
#

package Text::UberText::Modules::Loop;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Global Variables
#

use vars qw/$Dispatch $VERSION /;

$VERSION=0.95;

$Dispatch={
	"count" => \&count,
	"list" => \&list,
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

#
# UberText Method
#

sub uberText
{
my ($this)=shift;
my ($object);
if (ref($this))
{
        $object=$this;
} else {
        $object=$this->new();
}
return ($object,"uber.loop",$Dispatch);
}

#
# Document Methods
#

sub count
{
my ($self,$node)=@_;
my ($count,$start,$tree,$disp,$vo,$vname,$index,$output);
$tree=$node->tree();
($count)=$node->commandValue();
($start)=$node->getOptValue("start");
($vname)=$node->getOptValue("variable");
$start=1 unless ($start);
if ($vname)
{
	$disp=$tree->dispatch();
	$vo=$disp->fetch("uber.var");
	$vo->variable($vname,$start);
}
$index=$node->index();
while ($start<=$count)
{
	# Run through the child elements
	$tree->run($index);

	$output.=$tree->output($index);
	# Increment the counter
	$start++;
	if ($vo)
	{
		$vo->variable($vname,$start);
	}
}
return $output;
}

sub list
{
my ($self,$node)=@_;
my ($output,$index,$vname,$tree,$item,$vo,@list);
$tree=$node->tree();
$index=$node->index();
$vname=$node->getOptValue("variable");
if ($vname)
{
	my ($disp);
	$disp=$tree->dispatch();
	$vo=$disp->fetch("uber.var");
}
(@list)=split(/,/,$node->commandValue());
foreach $item (@list)
{
	if ($vo)
	{
		$vo->variable($vname,$item);
	}
	$tree->run($index);
	$output.=$tree->output($index);
}
return $output;
}

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
$self->{blocks}=[];
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

Text::UberText::Modules::Loop - UberText Loop Commands

=head1 SYNOPSIS

 [uber.loop count:(10) -> ]
 This text will repeat 10 times.
 [<- uber.loop ]

 [uber.loop list:(randy,kyle,nick) variable:(bf) -> ]
  My current boyfriend is [uber.var name:(bf)]
 [<- uber.loop ]

=head1 DESCRIPTION

The Loop module controls simple looping directives that are identical 
to a for loop for integers, or a foreach loop for strings.

=head1 DOCUMENT COMMANDS

=over 4

=item [uber.loop count:(int) start:(int) variable:(varname) -> ]

Initiates a loop.  The count value refers to the number of loop iterations.  
The start option indicates that the incrementor should start at an integer 
other than 1.  The variable option saves the internal value of the 
iterator to a variable that can be displayed or further modified.

=item [uber.loop list:(itemlist) variable:(varname) -> ]

Initiates a loop, one cycle for each item in the list.  Items in the list are 
seperated by commas.  If the variable option is set, the variable will 
be passed the value of the current item in the list.

=back

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>     

=head1 SEE ALSO

L<Text::UberText>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
