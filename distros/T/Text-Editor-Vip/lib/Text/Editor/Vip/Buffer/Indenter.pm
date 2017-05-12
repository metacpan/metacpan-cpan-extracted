
package Text::Editor::Vip::Buffer::Indenter;

use strict;
use warnings ;
use Carp qw(cluck) ;

BEGIN 
{
use Exporter ();
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01;
@ISA         = qw (Exporter);
@EXPORT      = qw ();
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

=head1 NAME

Text::Editor::Vip::Buffer::Indenter - Default indentiation plugin and documentation for indentation plugins.

=head1 SYNOPSIS

Nothing need to be done for using the default indenter. Read on to learn how to define your own indenters.

If you have an indenter for any "standard" indentation, please contribute it to VIP.

=head1 DESCRIPTION

If Vip::Buffer::Insert() or InsertNewLine() is called with a SMART_INDENTATION argument,
B<IndentNewLine> is called. This lets you define your own indentation strategy.

To define you own indenter, Create a perl module, preferably under Text::Editor::Vip::Buffer::Plugins::Indent::.

The module needs a single function B<IndentNewLine>

  package Text::Editor::Vip::Buffer::Plugins::Indent::MyIndenter ;

  sub IndentNewLine
  {
  # modification position is set at the line to indent
  
  my $buffer = shift ; # the buffer
  my $line_index = shift ; # usefull if we indent depending on previous lines
  
  # code to implement you indenter
  }
  
=head1 USING THE INDENTER

  use Text::Editor::Vip::Buffer ;
  my $buffer = new Text::Editor::Vip::Buffer() ;
  
  $buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Indent::MyIndenter') ;

=head1 INLINED INDENTERS

if you want to play with an indenter but don't want to bother creating a separate file and package.

  use Text::Editor::Vip::Buffer ;
  my $buffer = new Text::Editor::Vip::Buffer() ;

  sub my_indenter
  {
  # modification position is set at the line to indent
  
  my $buffer = shift ; # the buffer
  my $line_index = shift ; # usefull if we indent depending on previous lines
  
  $buffer->Insert('   ') ;  # silly indentation
  $buffer->MarkBufferAsEdited() ;
  }

  $buffer->ExpandWith('IndentNewLine', \&my_indenter) ;
  $buffer->Insert("hi\nThere\nWhats\nYour\nName\n") ;
  
  is($buffer->GetLineText(1), "   There", "Same text") ;

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net
	http:// no web site

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

#-------------------------------------------------------------------------------

sub IndentNewLine
{

=head2 IndentNewLine

Default Line indenter for Vip::Buffer. Does nothing.

=cut

}


#-------------------------------------------------------------------------------

1;

