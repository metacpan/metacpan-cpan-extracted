#
# Package Definition
#

package Text::UberText;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Includes
#

use Text::UberText::Parser;
use Text::UberText::Dispatch;
use Text::UberText::Log;

#
# Global Variables
#

use vars qw/$VERSION $ImportMap @ImportList /;

$VERSION=0.95;

$ImportMap={
	"none" => [ ],
	"minimal" => [ "Text::UberText::Modules::Info" 
		],
	"standard" => [ "Text::UberText::Modules::Info",
		"Text::UberText::Modules::Variables",
		"Text::UberText::Modules::Loop",
		],
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

sub read
{
my ($self)=shift;
my ($file)=shift;
my ($l,$par,@input);
open (F, $file) || return undef;
(@input)=<F>;
close(F);
$self->{parser}->log($self->{log});
$self->{parser}->dispatch($self->{dispatch});
$self->{parser}->input(@input);
return;
}

sub parse
{
my ($self)=shift;
return $self->{parser}->parse();
}

sub extend
{
my ($self)=shift;
$self->{dispatch}->extend(@_);
return;
}

sub log
{
my ($self)=shift;
return $self->{log};
}

sub parser
{
my ($self)=shift;
return $self->{parser};
}

sub dispatch
{
my ($self)=shift;
return $self->{dispatch};
}

#
# Import method
sub import
{
shift;
my ($modules)=shift;
if ($modules)
{
	$modules=lc($modules);
} else {
	$modules="standard";
}
(@ImportList)=@{$ImportMap->{$modules}};
return;
}

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
$self->{log}=Text::UberText::Log->new(-main => $self);
$self->{parser}=Text::UberText::Parser->new(-main => $self);
$self->{dispatch}=Text::UberText::Dispatch->new( -main => $self);
# Import requested UberText tag namespaces
$self->_loadModules();
#$self->{dispatch}->extend("Text::UberText::Modules::Variables");
return;
}

sub _loadModules
{
my ($self)=shift;
my ($m);
foreach $m (@ImportList)
{
	$self->{dispatch}->extend($m);
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

Text::UberText - Customizable Template Engine

=head1 SYNOPSIS

 use Text::UberText qw(standard);

 $ub=Text::UberText->new();
 $ub->read(@array);
 $ub->extend($acme_invoice);
 $doctree=$ub->parse();
 if ($doctree)
 {
     $doctree->run();
     print($doctree->output());
 }

=head1 DESCRIPTION

Text::UberText is an expandable template system designed to let programmers 
write their own commands and tie those commands to program code.  UberText 
reads command tags in documents, and then calls perl modules based on 
the tag.

=head1 SAMPLE DOCUMENT

The following is an example of a document that uses the UberText template 
system.

 Invoice#: [uber.print string:([acme.invoice number]) fmt:(%010d)]
 Date:     [uber.date date fmt:(MM/DD/YYYY)]

 Ship To: [acme.invoice address:(shipping) ]

 Tracking number: [acme.invoice tracking-number vendor:(ups)]

 [acme.invoice itemlist -> ]
  Item: [acme.invoice itemnumber] [acme.invoice description]
 [<- acme.invoice itemlist ]

 [acme.invoice terms]

The template is designed by a programmer that has designated the "acme.invoice" 
namespace is to be used for his code.  He then writes Perl modules that 
interface with Text::UberText when the document is parsed.

=head1 UBERTEXT FORMAT

UberText documents are plain text mixed with command tags.  A very simple 
command tag contains a namespace and a command.

 [uber.info version]

In this case, the namespace is C<uber.info> and the command is C<version>.  

Commands can have values passed to them.

 [uber.info version:"full"]

Commands can also have additional options, and those options can have 
values.

 [uber.var name:(variable) value:"This is the value of the variable"]

Values for commands or options are specified by following the command 
or options with a colon, and then enclosing the value in 
paranthesis or double quotes.

An UberText command can also be wrapped around portions of text or other 
UberText commands.  These are considered block commands.

 [uber.transform indent class:(quote) ->]
   "You can reach be anytime at my work number [per.info phonenum:(work)]"
 [<- uber.transform ]

Command options can be placed in either the tag that starts the block, 
or the tag that ends the block.  This example....

 [uber.loop count:(20) -> ]
   This text will repeat 10 times
 [<- uber.loop start:(11) ]

Is identical to.....
 [uber.loop count:(20) start:(11) -> ]
  This text will repeat 10 times
 [<- uber.loop ]

You can also insert UberText commands in the values of options or 
commands.

 [uber.var name:(version) value:([uber.info version])]

 [uber.print string:(The fruit is [uber.rand words:(orange,apple,banana)]) ]

But you cannot use block commands inside the values to options or 
commands.

UberText command tags can span multiple lines.

 [
	uber.var name:(customer) 
		value : "John Q. Public"
 ]

Leading and trailing whitespace within an UberText command is eliminated.  
Some whitespace is needed to seperate the namespace, the command and  
options, but that's it.  Whitespace within values to commands and 
options is kept intact.  Also, whitespace after the command tag (including 
carriage returns) is kept intact as well.

=head1 LOADING

UberText comes with a set of modules handling a small set of basic 
functions.  All of the modules are in the Text::UberText::Modules 
Perl namespace.  You can specify which of those modules are loaded 
on the use line.

 use Text::UberText qw(minimal);

The modules are not actually loaded until an UberText object is initiated.

The following is a list of module sets.

=over 4

=item none

None of the included UberText modules are loaded.

=item minimal

Only the Text::UberText::Modules::Info module is loaded

=item standard

The modules Text::UberText::Modules::(Info,Version) are loaded.

=back

=head1 METHODS

=over 4

=item $ubt=Text::UberText->new();

Creates a new UberText object.  The parser, the dispatch table, and the log 
are all initialized.

=item $ubt->read(@input);

Reads in the passed array and passes it to the parser.

=item $tree=$ubt->parse();

Runs the parser against the input.  At this time, the commands and the document 
text are sorted out and placed in a Text::UberText::Tree object, which keeps 
track of the document.  The tree object is then returned from the method call.

=item $ubt->extend($object);

Sends an object to the Text::UberText::Dispatch object, which controls all 
methods that interface with the command nodes.  $object is either a 
Perl object, or just the name of a class.  In either case, the Dispatch 
object searches for a method called C<uberText> and runs it.  It then takes 
data returned from the call and uses it to expand its internal dispatch table.

=back

=head1 BUGS/CAVEATS

UberText is pretty complex.  There's probably bugs floating around because I 
haven't even conceived of all of the possible input errors or third party 
module errors that it needs to deal with.

=head1 AUTHOR

Chris Josephes E<lt>cpj1@cpj1.comE<gt>

=head1 SEE ALSO

For documentation on the code, read 
L<Text::UberText::Tree>, 
L<Text::UberText::Dispatch>, 
L<Text::UberText::Parser>

For general documentation, read 
L<Text::UberText::Overview>, and 
L<Text::UberText::NewModule>.

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
