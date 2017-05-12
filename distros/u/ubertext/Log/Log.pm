#
# Package Definition
#

package Text::UberText::Log;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Includes
#

use Text::Wrap;

#
# Global Variables
#

use vars qw/$VERSION /;

$VERSION=0.95;

$Text::Wrap::columns=72;

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

sub write
{
my ($self)=shift;
if (@_)
{
	my ($module,$message,$line,$severity)=@_;
	$self->{log}->[$self->{last}]->{module}=$module;
	$self->{log}->[$self->{last}]->{message}=$message;
	$self->{log}->[$self->{last}]->{line}=$line;
	$self->{log}->[$self->{last}]->{severity}=$severity;
	$self->{last}++;
}
return;
}

sub list
{
my ($self)=shift;
my ($fmt)="%s.%s: %s at line %d\n";
if (@{$self->{log}})
{
	my ($entry);
	foreach $entry (@{$self->{log}})
	{
		printf($fmt,$entry->{module},$entry->{severity},
			$entry->{message},$entry->{line});
	}
}
return;
}

sub report
{
my ($self)=shift;
if (@{$self->{log}})
{
	my ($entry);
	print("\n");
	foreach $entry (@{$self->{log}})
	{
		print($entry->{module}.":".$entry->{line},"\n");
		print(wrap("     ","     ",
			$entry->{severity}.":".$entry->{message}),"\n");
	}
}
return;
}

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
$self->{log}=[];
$self->{last}=0;
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

Text::UberText::Log - Record of UberText processing

=head1 SYNOPSIS

 $uber=Text::UberText->new();
 $log=$uber->log();
 $log->write("Dispatch","Object load failure",,"ERROR");
 $log->list();

=head1 DESCRIPTION

Text::UberText::Log is used to debug the parsing of UberText documents.  The 
Parser, the Dispatch table, and other modules record informational or warning 
messages to the log.

=head1 OBJECT METHODS

=over 4

=item $log->write($module,$message,$linenumber,$severity)

Writes a message to the log object.  Module generically refers to which 
UberText module is reporting the error, but it can also be more generic or 
specific to suit the needs of the implementor.  Message is a verbose 
description of the event.  Linenumber indicates at what line of the document 
the error occured (if it occured during parsing). Severity refers to 
the level of importance of the message, and could be set to either "DEBUG", 
"INFO", or "ERROR".

=item $log->list($severity)

Lists all log messages matching the severity level specified, or lists all 
messages if no severity level is specified.

=back

=head1 BUGS/CAVEATS

This is the simplest module in the UberText distribution.

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>     

=head1 SEE ALSO

L<Text::UberText>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
