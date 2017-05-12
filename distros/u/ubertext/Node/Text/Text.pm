#
# Package Definition
#

package Text::UberText::Node::Text;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Includes
#

use Text::UberText::Node;

#
# Global Variables
#

use vars qw/@ISA $EscapeChar $VERSION /;

$VERSION=0.95;

# Text within a block that can be replaced with other characters
# An escape sequence within an UberText doc would look like this:
# %pc; (percent sign)

$EscapeChar={
        "lb" => "[",
        "rb" => "]",
        "pc" => "%",
        "lp" => "(",
        "rp" => ")",
        "dq" => "\"",
        "sq" => "'",
        "co" => ":",
	"sc" => ";",
};


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
$self->{output}=quickReplace($self->{input});
return;
}

sub quickReplace
{
my ($string)=shift;
$string=~s/\%(\w\w);/$EscapeChar->{$1}/g;
return $string;
}

#
# Hidden Methods
#

#
# Exit Block
#
1;

#
# POD Documentation
#

=head1 NAME

Text::UberText::Node::Text - UberText Text Node

=head1 DESCRIPTION

The Node::Text module handles processing an UberText text segment 
embedded within an UberText file.  It is a subclass of the Text::UberText::Node 
class.

=head1 ESCAPE SEQUENCES

UberText files cannot contain certain characters, as a result of which, they 
need to be specified with escape sequences.

Escape sequences start with a percent sign (%), and end with a semi-colon (;).  Two 
alpabetic characters in the middle specify what character they intend to replace.

=over 4

=item %pc;

Percent sign (%)

=item %dq;

Double quote (")

=item %sq;

Single quote (')

=item %co;

Colon (:)

=item %sc;

Semi-colon (;)

=item %lb;

Left bracket ([)

=item %rb;

Right bracket (])

=item %lp;

Left parenthesis (()

=item %rp;

Right parenthesis ())

=back

=head1 METHODS

The following methods are overriden from the Text::UberText::Node module to 
perform specific functions on passed input.

=over 4

=item $node->process();

Generates the output, replacing all escape sequences.

=item $node->quickReplace();

Performs the actual escape sequence replacement.

=item $node->run();

The run method does nothing.  All processing of the text is performed before 
the document tree is actually run.

=back

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>     

=head1 SEE ALSO

L<Text::UberText::Node>,
L<Text::UberText::Node::Command>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
