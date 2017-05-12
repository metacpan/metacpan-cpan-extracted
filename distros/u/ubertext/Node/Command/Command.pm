#
# Package Definition
#

package Text::UberText::Node::Command;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Includes
#

use Text::UberText::Node;
use Text::UberText::Parser;

#
# Global Variables
#

use vars qw/@ISA $VERSION/;

$VERSION=0.95;

#
# Inheritance
#

@ISA=("Text::UberText::Node");

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

sub process
{
my ($self)=shift;
my ($arg,$value,$argCount);
$argCount=0;
$self->{dispatch}=$self->{tree}->{dispatch};
$self->_prep();
$self->_determineBlockStatus();
$self->{warray}=[ split(//,$self->{working}) ];
$self->_setNameSpace();
while (@{$self->{warray}})
{
	($arg,$value)=_getOpt($self->{warray});
	if ($argCount==0)
	{
		$self->command($arg,$value);
	} else {
		$self->setOpt($arg,$value);
	}
	$argCount++;
}
return;
}

sub inserted
{
my ($self)=@_;
if ($self->{endBlock})
{
	$self->_sendArgsToParent();
}
return;
}

sub startBlock
{
my ($self)=shift;

return $self->{startBlock};
}

sub endBlock
{
my ($self)=shift;

return $self->{endBlock};
}

sub command
{
my ($self)=shift;
if (@_)
{
        my ($cmd,$arg)=@_;
	my ($parser);
	$parser=$self->{tree}->parser();
        $self->{command}=$cmd;
	$arg=_trimArg($arg);
	if ($arg)
	{
		$self->{commandArg}=$parser->quickie($arg);
	}
}
return ($self->{command},$self->{commandArg});
}

sub commandValue
{
my ($self)=@_;
return $self->{commandArg};
}

sub namespace
{
my ($self)=shift;
return $self->{namespace};
}

sub setOpt
{
my ($self,$optName,$value)=@_;
if ($value)
{
	# Identify the option as being set
	$self->{opt}->{$optName}->{set}=1;
	# Trim the surrounding parenthesis or double-quotes
	if ($value=~/^(.*)$/)
	{
		$self->{opt}->{$optName}->{enclosure}="parenthesis";
	} else {
		$self->{opt}->{$optName}->{enclosure}="double-quotes";
	}
	$value=_trimArg($value);
	# Create a new parser, and go through the value to parse it
	my ($parser);
	$parser=$self->{tree}->parser();
	$self->{opt}->{$optName}->{value}=$parser->quickie($value);
} else {
	# Only identify the option as being set
	$self->{opt}->{$optName}->{set}=1;
}
return;
}

sub getOpt
{
my ($self,$optName)=@_;
my ($set,$value);
if ($self->{opt}->{$optName}->{set})
{
	$set=1;
	$value=$self->{opt}->{$optName}->{value};
} else {
	$set=0;
}
return ($set,$value);
}

sub getOptValue
{
my ($self,$optName)=@_;
if ($self->{opt}->{$optName})
{
	return $self->{opt}->{$optName}->{value};
}
}

sub opts
{
my ($self)=shift;
return keys(%{$self->{opt}});
}

sub info
{
my ($self)=shift;
my ($cm,$ca,$a);
($cm,$ca)=$self->command();
$ca=_trimArg($ca);
print("NAMESPACE: ",$self->namespace(),"\n");
print("COMMAND: $cm\n");
print("COMMAND ARG: $ca\n");
print("OPTS:\n");
foreach $a (keys(%{$self->{opt}}))
{
	print("\t$a: ",_trimArg($self->{opt}->{$a}->{value}),"\n");
}
return;
}

# run notes
# need access to tree and dispatch table

sub run
{
my ($self)=shift;
my ($module);
unless ($self->endBlock())
{
	$self->{output}=$self->{dispatch}->involke($self);
} else {
	$self->{output}="";
}
return;
}

#
# Hidden Methods
#

# Make a copy of the input, remove the surrounding brackets ( [] )
sub _prep
{
my ($self)=shift;
$self->{working}=$self->{input};
$self->{working}=~s/(^\[\s*|\s*\]$)//g;
return;
}

sub _truncSpace
{
my ($input)=@_;
my ($c);
while (@{$input})
{
	($c)=shift(@{$input});
	if ($c !~ /\s/)
	{
		unshift(@{$input},$c);
		return;
	}
}
return;
}

sub _trimArg
{
my ($string)=@_;
if ($string)
{
	$string=~s/(^"|^\(|\)$|"$)//g;
}
return $string;
}

# See if it is an opening or closing block, remove the arrows, but set the
# appropriate flags
sub _determineBlockStatus
{
my ($self)=shift;
if ($self->{working}=~/->$/s)
{
	$self->{working}=~s/\s*->//;
	$self->{startBlock}=1;
} elsif ($self->{working}=~/^<-/s)
{
	$self->{working}=~s/^<-\s*//;
	$self->{endBlock}=1;
}
return;
}

sub _setNameSpace
{
my ($self)=shift;
my ($ns,$x);
while (@{$self->{warray}})
{
	($x)=shift(@{$self->{warray}});
	last if ($x =~/\s/);
	$ns.=$x;
}
if ($ns=~/^\w[\w.]*$/)
{
	$self->{namespace}=$ns;
}
return;
}

sub _getOpt
{
my ($chars)=@_;
my ($c,$arg,$value);
while (@{$chars})
{
        ($c)=shift(@{$chars});
        if ($c=~/\s/)
        {
                _truncSpace($chars);
                ($c)=shift(@{$chars});
                if ($c eq ":" )
                {
                        _truncSpace($chars);
                        $value=_getValue($chars);
                } else {
                        unshift(@{$chars},$c);
                }
                last;
        } elsif ($c eq ":")
        {
                _truncSpace($chars);
                $value=_getValue($chars);
        } else {
                $arg.=$c;
        }
}
return ($arg,$value);
}

sub _getValue
{
my ($chars)=@_;
my ($c,$value);
while (@{$chars})
{
        ($c)=shift(@{$chars});
        if ($c eq "(")
        {
                $value.=$c;
                my ($level)=1;
                while (@{$chars})
                {
                        ($c)=shift(@{$chars});
                        if ($c eq "[")
                        {
                                $level++;
                        } elsif ($c eq "]")
                        {
                                $level--;
                        }
                        $value.=$c;
                        if ($c eq ")" && $level==1)
                        {
                                return $value;
                        }
                }
                
        }
        elsif ($c eq "\"")
        {
                $value.=$c;
                my ($level)=1;
                while (@{$chars})
                {
                        ($c)=shift(@{$chars});
                        if ($c eq "[")
                        {
                                $level++;
                        } elsif ($c eq "]")
                        {
                                $level--;
                        }
                        $value.=$c;
                        if ($c eq "\"" && $level==1)
                        {
                                return $value;
                        }
                }
        }
}
return ($value);
}

sub _extractCommand
{
my ($self)=shift;
my ($cmd,$carg,$x,@chars);
$self->{working}=~s/^\s*//;
(@chars)=split(//,$self->{working});
while (@chars)
{
	($x)=shift(@chars);
	last if ($x !~ /\w/);
	$cmd.=$x;
}
if ($x =~/\s/)
{
	while (@chars)
	{
		($x)=shift(@chars);
		last if ($x !~ /\s/);
	}
}
return;
}

sub _sendArgsToParent
{
my ($self)=shift;
my ($sid,$pid,$parent,$cmd,$value,$opt);
$sid=$self->index();
$pid=$self->{tree}->parentId($sid);
$parent=$self->{tree}->node($pid);
# Do the command first
$cmd=$self->{command};
$value=$self->{commandArg};
if ($cmd)
{
	if ($value)
	{
		$parent->{opt}->{$cmd}->{value}=$value;
	}
	$parent->{opt}->{$cmd}->{set}=1;
	$parent->{opt}->{$cmd}->{closing}=1;
}
# Now the args
foreach $opt ($self->opts())
{
	$parent->{opt}->{$opt}->{value}=$self->{opt}->{$opt}->{value};
	$parent->{opt}->{$opt}->{set}=$self->{opt}->{$opt}->{set};
	$parent->{opt}->{$opt}->{enclosure}=$self->{opt}->{$opt}->{enclosure};
	$parent->{opt}->{$opt}->{closing}=1;
}
# And the namespace
$parent->{closingNamespace}=$self->namespace();
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

Text::UberText::Node::Command - UberText Command Node

=head1 DESCRIPTION

The Node::Command module handles processing an UberText command statement 
embedded within an UberText file.  It is a subclass of the Text::UberText::Node 
class.

=head1 METHODS

The following methods are unique to the Node::Command module.  For a full 
listing of the methods available, also check the Text::UberText::Node 
documentation.

=over 4

=item $node->namespace();

Returns the namespace portion of the UberText command.  Namespaces are 
an alphanumeric sequence, with the first character being a letter and are segmented 
with periods to create a hierarchial namespace.

Namespaces are case-insensitive and internally represented by transforming all 
characters to lowerspace.

The "uber.*" namespace is reserved and should not be used for private modules.

=item ($command,$value)=$node->command();

Returns the command portion of the UberText command, and the value that 
was passed to the command (if any).

=item ($value)=$node->commandValue();

Returns the value that was assigned to the command.

=item ($bool,$value)=$node->getOpt($opt);

Returns whether or not a particular option was set, and the value 
passed along with the option (if any).

Options and values to options are, well, optional.  Implementors need to make 
sure they test whether or not an option was set, and what value was passed 
to the option.

=item $node->setOpt($opt,$value);

Identifies an option as set, and specifies a value to go along with 
it.

=item ($value)=$node->getOptValue($opt);

Returns only the value of an option.  This routine may be easier to use 
when it comes to handling conditional evaluation.

=item $node->startBlock();

Identifies whether or not this Command node contains child elements.

=item $node->endBlock();

Identifies whether or not this Command node is the last element in a string 
of child elements.

=item $node->process();

Runs through the command string to break apart the namespace, the command, 
command value, and options.

=item $node->info();

Reports on the namespace, command, command value, and options.

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>     

=head1 SEE ALSO

L<Text::UberText::Node>,
L<Text::UberText::Text>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
