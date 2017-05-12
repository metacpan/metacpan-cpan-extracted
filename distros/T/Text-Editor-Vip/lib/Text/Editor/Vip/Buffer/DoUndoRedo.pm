
package Text::Editor::Vip::Buffer::DoUndoRedo;
use strict;
use warnings ;

BEGIN 
{
use Exporter ();
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01_1;
@ISA         = qw (Exporter);
@EXPORT      = 
		qw (
		DecrementUndoStackLevel
		GetDoScript
		GetDoPosition
		GetUndoScript
		IncrementUndoStackLevel
		PushUndoStep
		Redo
		Undo
		);
		
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

=head1 NAME

Text::Editor::Vip::Buffer::DoUndoRedo - non optional plugin for a Text::Editor::Vip::Buffer

=head1 DESCRIPTION

The do, undo, redo functionality of Text::Editor::Vip::Buffer is implemented by this package.
This package automatically extends a Text::Editor::Vip::Buffer when a Text::Editor::Vip::Buffer
instance is created.

This package manipulated the data structures used to implement a do, undo and redo functionality.
Text::Editor::Vip uses perl as it building block to implement such functionality. Perl "scripts" are the base 
for implementing this functionality.

=head1 MEMBER FUNCTIONS

=cut

#-------------------------------------------------------------------------------

sub IncrementUndoStackLevel
{

=head2 IncrementUndoStackLevel

Increments the do and undo prefix for the perl "scripts' used to implement do and undo.

=cut

my ($buffer, $do_prefix, $undo_prefix) = @_;

$buffer->{DO_PREFIX} .= $do_prefix ;
$buffer->{UNDO_PREFIX} .= $undo_prefix;
}

#-------------------------------------------------------------------------------

sub DecrementUndoStackLevel
{

=head2 DecrementUndoStackLevel

Decrements the do and undo prefix for the perl "scripts' used to implement do and undo.

=cut

my ($buffer, $do_prefix, $undo_prefix) = @_;

substr $buffer->{DO_PREFIX}, -(length($do_prefix)), length($do_prefix),  '' ;
substr $buffer->{UNDO_PREFIX}, -(length($undo_prefix)), length($undo_prefix), '';
}

#-------------------------------------------------------------------------------

sub PushUndoStep
{

=head2 PushUndoStep

Adds a do "script"  to the do  command list and an undo "script" to the undo command list.
The scripts are prepended with the prefixes defined by L<IncrementUndoStackLevel> and L<DecrementUndoStackLevel>

=cut

my $buffer = shift ;
my $do   = shift ;
my $undo = shift ;

my ($package, $file_name, $line, $sub) = caller(1) ;
my $description = "'$sub' @ $file_name:$line" ;

my $do_text = '' ;
if('ARRAY' eq ref $do)
	{
	$do_text .= join(" #continued\n", map{"$buffer->{DO_PREFIX}$_"} @$do) ;
	}
else
	{
	$do_text = "$buffer->{DO_PREFIX}$do" ;
	}
	
#~ $do_text = "#$description\n$do_text" ;
push @{$buffer->{DO_STACK}}, $do_text ;

my $undo_text = '' ;
if('ARRAY' eq ref $undo)
	{
	$undo_text .= join(" #continued\n", map{"$buffer->{UNDO_PREFIX}$_"} @$undo) ;
	}
else
	{
	$undo_text = "$buffer->{UNDO_PREFIX}$undo" ;
	}

#~ $undo_text = "#$description\n$undo_text" ;
push @{$buffer->{UNDO_STACK}}, $undo_text ;
}

#-------------------------------------------------------------------------------

sub Undo
{

=head2 Undo

Undoes the commands the commands that have been executed on a buffer.

  $buffer->Undo(1) ; # undoes one high level command
  
=cut

my $buffer = shift ;
my $number_of_undo_steps = shift ;

# not very effective to copy what could be a huge undo stack
# specialy since we modify it directely later and it's trivial to write better !
my $undo_command_list = $buffer->GetUndoCommandList() ;

my $undo_steps = 0 ;
my $uncommented_undo_script = '' ;
my $comments = 0 ;

while(defined (my $undo_step = shift @$undo_command_list) && $number_of_undo_steps)
	{
	$undo_steps++ ;
	
	if($undo_step =~ /^\s*#/)
		{
		$comments++ ;
		}
	else
		{
		$uncommented_undo_script .= "$undo_step\n" ;
		}
	
	unless($undo_step =~ /^\s/)
		{
		#~ $buffer->PrintPositionData() ;
		#~ diag "Undo steps: $undo_steps $comments comments\n"  ;
		#~ diag "$uncommented_undo_script\n*******\n" ;
		
		# move do stuff to redo stack
		my $position = $buffer->GetDoPosition() ;
		
		my @redo_step = @{$buffer->{DO_STACK}}[$position - $undo_steps .. $position - 1] ;
		unshift @{$buffer->{REDO_STACK}}, @redo_step ;
		
		# run undo script
		$buffer->Do($uncommented_undo_script) ;
		
		# remove newly added commands from do and undo stack
		splice(@{$buffer->{DO_STACK}}, ($position - $undo_steps) );
		splice(@{$buffer->{UNDO_STACK}}, ($position - $undo_steps) );
		
		$uncommented_undo_script = '' ;
		$undo_steps = 0 ;
		$comments = 0 ;
		
		$number_of_undo_steps-- ;
		}
	}
}

#-------------------------------------------------------------------------------

sub GetDoPosition
{

=head2 GetDoPosition

Gets the current index of the do command list. This index can be later passes to L<GetUndoScript> to
get a selected amount of undo commands.

This index can also be used to get a selected amound of do commands to implement a macro facility.

  my $start_position = $buffer->GetDoPosition() ;

  $buffer->DoLotsOfStuff() ;
  $buffer->DoEvenMoreStuff() ;
  
  # get scripts that would undo everything since we got the do position
  $undo = $buffer->GetUndoScript($start_position) ;
  
  # get scripts that correspond sto what has been done since we got the do position
  $do = $buffer->GetDoScript($start_position) ;

=cut

my $buffer = shift ;

return(scalar(@{$buffer->{DO_STACK}})) ;
}

#-------------------------------------------------------------------------------

sub GetUndoScript
{

=head2 GetUndoScript

This sub is given a start and and end index. those indexes are used to retrieve undo commands.

If not arguments are passed, the start index will be set to zero (first undo command) and the last available
undo command. Thus returning a list of all the commands in the undo stack.


See L<GetDoPosition>

=cut

my $buffer = shift ;

my $start =  shift || 0 ;
my $end = shift || $#{$buffer->{UNDO_STACK}} ;

my @undo_buffer = @{$buffer->{UNDO_STACK}}[$start .. $end] ;
@undo_buffer  = reverse @undo_buffer ;

my($modification_line, $modification_character) = $buffer->GetModificationPosition() ;

return("# Current position: $modification_line, $modification_character\n" . join("\n", @undo_buffer) . "\n") ;
}

#-------------------------------------------------------------------------------

sub GetUndoCommandList
{

=head2 GetUndoCommandList

This sub is given a start and and end index. those indexes are used to retrieve undo commands.

If not arguments are passed, the start index will be set to zero (first undo command) and the last available
undo command. Thus returning a list of all the commands in the undo stack.

See L<GetDoPosition>

=cut

my $buffer = shift ;

my $start =  shift || 0 ;
my $end = shift || $#{$buffer->{UNDO_STACK}} ;

my @undo_command_list = @{$buffer->{UNDO_STACK}}[$start .. $end] ;
@undo_command_list = reverse @undo_command_list;

return(\@undo_command_list) ;
}

#-------------------------------------------------------------------------------

sub GetDoScript
{

=head2 GetDoScript

This sub is given a start and and end index. those indexes are used to retrieve do commands.

If not arguments are passed, the start index will be set to zero (first do command) and the last available
do command. Thus returning a list of all the commands in the do stack.

See L<GetDoPosition>

=cut

my $buffer = shift ;

my $start =  shift || 0 ;
my $end =  shift || $#{$buffer->{DO_STACK}} ;

return(join("\n",@{$buffer->{DO_STACK}}[$start .. $end]) . "\n") ;
}

#-------------------------------------------------------------------------------

sub GetDoCommandList
{

=head2 GetDoCommandList

This sub is given a start and and end index. those indexes are used to retrieve do commands.

If not arguments are passed, the start index will be set to zero (first do command) and the last available
do command. Thus returning a list of all the commands in the do stack.

See L<GetDoPosition>

=cut

my $buffer = shift ;

my $start =  shift || 0 ;
my $end =  shift || $#{$buffer->{DO_STACK}} ;

my @do_command_list = @{$buffer->{DO_STACK}}[$start .. $end] ;

return(\@do_command_list) ;
}

#-------------------------------------------------------------------------------

sub Redo
{

=head2 Redo

Redoes the commands that have been undone.

=cut

my $buffer = shift ;
my $number_of_redo_steps = shift ;

for( 1 .. $number_of_redo_steps)
	{
	# do this inline to avoid using memory!
	my @redo_command_list = @{$buffer->{REDO_STACK}} ;

	my $uncommented_redo_script = shift @redo_command_list ;
	my $redo_steps = 1 ;
	my $comments = 0 ;
		
	my $in_same_command = 1 ;
	while(defined (my $redo_step = shift @redo_command_list) && $in_same_command)
		{
		if($redo_step =~ /^\s/)
			{
			$redo_steps++ ;
			
			if($redo_step =~ /^\s+#/)
				{
				$comments++ ;
				}
			else
				{
				$uncommented_redo_script .= "$redo_step\n" ;
				}
			}
		else
			{
			unshift @redo_command_list, $redo_step ;
			$in_same_command = 0 ;
			}
		}
		
	#~ $buffer->PrintPositionData() ;
	#~ diag "redo steps: $redo_steps $comments comments\n"  ;
	#~ diag "$uncommented_redo_script\n*******\n" ;
	
	# run redo script
	$buffer->Do($uncommented_redo_script) ;
	
	# remove  commands from redo stack
	splice(@{$buffer->{REDO_STACK}}, 0, $redo_steps);
	}
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

