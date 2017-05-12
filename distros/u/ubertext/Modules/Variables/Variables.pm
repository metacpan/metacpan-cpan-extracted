#
# Package Definition
#

package Text::UberText::Modules::Variables;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Includes
#

#
# Global Variables
#

use vars qw/$Dispatch $VERSION /;

$Dispatch={
	"name" => \&name,
};

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

# UberText method needs to know whether it was called from a class method
# or an object method!
sub uberText
{
my ($this)=shift;
my ($object);
if (ref($this))
{
	$object=$this;
} else {
	# $object=Text::UberText::Modules::Variables->new();
	$object=$this->new();
}
return ($object,"uber.var",$Dispatch);
}

#
# UberText Methods
#

sub name
{
my ($self,$node)=@_;
my ($name,$value,$set,$print);
(undef,$name)=$node->command();
($set,$value)=$node->getOpt("value");
($print)=$node->getOpt("print");
if ($value)
{
	$self->{table}->{$name}=$value;
}
if ($print || !$set)
{
	return $self->{table}->{$name};
}
return "";
}

#
# Other Methods
#

sub variable
{
my ($self)=shift;
my ($name)=shift;
if (@_)
{
	my ($value)=shift;
	$self->{table}->{$name}=$value;
}
return $self->{table}->{$name};
}

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
$self->{table}={};
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

Text::UberText::Modules::Variables - UberText Variables Modules

=head1 SYNOPSIS

 [uber.var name:(fruit) value:(apple)]

 The value of "fruit" is [uber.var name:(fruit)]

 We are resetting "fruit" to [uber.var name:(fruit) value:(pear) print]

=head1 DESCRIPTION

The Variables module creates an internal table of variables that 
can be manipulated within an UberText document.  It is also possible to 
set and retrieve variables directly from the Variables module, or 
other perl modules.

=head1 METHODS

=over 4

=item $value=$variable->variable($varname,$value);

Sets the variable $varname to $value.  Also returns the current value 
of $varname.

=back

=head1 DOCUMENT COMMANDS

=over 4

=item [uber.var name:(varname)]

The name command identifies a variable in the internal table.  To change 
the value of the variable, you need to use the value option.  The output 
from this tag is the value of the variable.

=item [uber.var name:(varname) value:(value) print]

This is an example of using the name command with the value option.  There 
is no output from this tag unless the print option is also specified 
in the tag.

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
