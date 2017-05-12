
package Text::Editor::Vip::Buffer::Plugins::File;

use strict;
use warnings ;

use Text::Editor::Vip::CommandBlock ;
use Text::Editor::Vip::Buffer::Constants;

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

Text::Editor::Vip::Buffer::Plugins::File - File handling plugin for Vip::Buffer

=head1 SYNOPSIS

  use Text::Editor::Vip::Plugins::File
  
=head1 DESCRIPTION

This modules adds File reading and wrtting capability to Vip::Buffer

=head1 FUNCTIONS

=cut

#---------------------------------------------------------------------------

sub InsertFile
{

=head2 InsertFile

Inserts a file at the current modification position.

=cut

my $buffer        = shift ;
my $a_file_name = shift ;

my $undo_block = new Text::Editor::Vip::CommandBlock($buffer, "# InsertFile('$a_file_name')", '   ', "# undo for InsertFile('$a_file_name')", '   ') ;

my $file_read_ok = 0 ;

if(open(SOURCE_CODE, "<", $a_file_name))
	{
	my @text = <SOURCE_CODE> ;
	close(SOURCE_CODE) ;
	
	$buffer->Insert(\@text, NO_SMART_INDENTATION) ;
	$file_read_ok = 1 ;
	}
else
	{
	$buffer->PrintError("Can't open $a_file_name : $!") ;
	}

return($file_read_ok) ;
}

#---------------------------------------------------------------------------

1 ;

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
