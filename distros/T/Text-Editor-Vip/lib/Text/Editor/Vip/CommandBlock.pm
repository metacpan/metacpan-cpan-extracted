
package Text::Editor::Vip::CommandBlock;

use strict;
use warnings ;

use Text::Editor::Vip::Buffer::DoUndoRedo ;

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

#-------------------------------------------------------------------------------

=head1 NAME

Text::Editor::Vip::CommandBlock - Allows grouping of do and undo commands 

=head1 SYNOPSIS

  use Text::Editor::Vip::CommandBlock

  my $undo_block = new Text::Editor::Vip::CommandBlock
  			(
  			$buffer
  			, "\$buffer->Insert(\"$stringified_text_to_insert\", $use_smart_indentation) ;", '   #'
  			, "# undo for \$buffer->Insert(\"$stringified_text_to_insert\", $use_smart_indentation)", '   '
  			) ;

=head1 DESCRIPTION

Text::Editor::Vip::CommandBlock allows grouping of undo blocks by automatically manipulating
and decrementing the do and undo stack prefix. See L<DoUndoRedo.pm>

=cut

#----------------------------------------------------------------------------

sub new
{

=head2 new

Creates a new instance of Text::Editor::Vip::CommandBlock. See L<SYNOPSIS> for and example.

B<new> takes five arguments:

=over 2

=item * A buffer object

=item * A do command

=item * An indentation string for the do buffer

=item * An undo command

=item * An indentation string for the undo buffer

=back

See L<DoUndoRedo.pm> to understand how this is used

=cut

my ($class, $buffer, $do, $do_prefix, $undo, $undo_prefix) = @_;

$do ||= '' ;
$do_prefix ||= '' ;
$undo ||= '' ;
$undo_prefix ||= '' ;

PushUndoStep($buffer, $do, $undo) ;
IncrementUndoStackLevel($buffer, $do_prefix, $undo_prefix) ;

my $this = bless 
		(
		{ BUFFER => $buffer, DO_PREFIX => $do_prefix, UNDO_PREFIX => $undo_prefix}
		, ref ($class) || $class
		);

return ($this);
}

#-------------------------------------------------------------------------------

sub DESTROY
{

=head2 DESTROY

This sub is automatically called by perl when a command block goes out of scope. This sub
will decrement the do/undo stack level.

This sub is private and should only be called by perl.

=cut

my $this = shift ;

DecrementUndoStackLevel($this->{BUFFER}, $this->{DO_PREFIX}, $this->{UNDO_PREFIX}) ;
}

#-------------------------------------------------------------------------------

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
