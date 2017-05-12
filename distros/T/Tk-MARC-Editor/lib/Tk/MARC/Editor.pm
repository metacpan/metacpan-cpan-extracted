$Tk::MARC::Editor::VERSION = '1.0';

package Tk::MARC::Editor;

=head1 NAME

Tk::MARC::Editor - a free-form editor for MARC::Record objects

=head1 SYNOPSIS

 use Tk;
 use Tk::MARC::Editor;

 # Get a MARC::Record to play with
 use MARC::File::USMARC;
 my $file = MARC::File::USMARC->in( "path/to/marc/record/file.mrc" );
 my $marc = $file->next();
 $file->close();
 undef $file;

 my $mw = MainWindow->new;
 $mw->title("A free-form MARC editor");

 my $FRAME = $mw->Frame()->pack(-side => 'top');

 # Create the editor, passing in the record to edit
 my $ed = $FRAME->Editor(-record => $marc, 
			 -background => 'white'
 			 )->pack(-side => 'top');

 # Or better yet, a scrollable editor
 my $ed = $FRAME->Scrolled('Editor', 
			   -scrollbars => 'e', 
			   -record => $marc, 
			   -background => 'white',
			   )->pack(-side => 'top');

 # Create a space to write information to 
 my $ln = $FRAME->Text(-background => 'lightgray', -height => 10)->pack(-side => 'top');

 # ...and some buttons to do neat things
 my $b1 = $mw->Button( -text => "Get MARC", 
		       -command => sub { my $marc = $ed->Contents();
					 print $marc->as_usmarc();
				     }
		       )->pack(-side => 'left');
 my $b2 = $mw->Button( -text => "Lint", 
		       -command => sub { my $s = $ed->Lint();
					 $ln->Contents( $s );
				     }
		       )->pack(-side => 'left');
 my $b3 = $mw->Button( -text => "Errorchecks", 
		       -command => sub { my $s = $ed->Errorchecks();
					 $ln->Contents( $s );
				     }
		       )->pack(-side => 'left');

 # This one shows that the leader gets updated properly:
 my $b4 = $mw->Button( -text => "Get MARC and reload it", 
		       -command => sub { my $marc = $ed->Contents();
					 $ed->Contents( $marc );
				     }
		       )->pack(-side => 'left');

 MainLoop;

=head1 DESCRIPTION

Module for editing MARC records as text.  It is derived from
Tk::Text; the Contents method is overriden to handle MARC::Record
objects. 

Right-clicking on the editor will bring up a menu which lets you
add fields/subfields (and tells you what they are).  

You can, of course, simply use the [Enter] key to open up a new 
line, and type in your new field from scratch.  When the entry
cursor moves off that line, the color formatting is applied.

You can use the mouse or keyboard to select and delete text as
if this were any other text editor (in fact, you can do almost
anything that you could do with C<Tk::Text>).

Only certain elements of the leader are editable (the rest, such
as 'record length', are handled internally by C<MARC::Record>.

There are a couple of example programs in the C<pl> directory.

=head1 WIDGET-SPECIFIC OPTIONS

-record => I<marc>

=over

Specify the C<MARC::Record> object to edit.  Required.  You can
change the record being edited later using the C<Configure( $record )>
method.

=back

=head1 INSERT VS. OVERSTRIKE MODE

=over

All areas (field designation, indicators, subfield designation,
fixed-field data, etc) will always be in Overstrike mode.

Pressing the I<Insert> key while in a data region (for example,
while in the actual words of the title) will toggle between
insert and overstrike, I<but only for the data regions>.

If you are in Insert mode in a data region, any other region
is still in Overstrike mode.  When you return to a data region,
you will be returned to Insert mode (that is, it remembers what
mode you were using the last time you were in a data region).

=back

=head1 COLOR

You can completely configure the colour scheme by specifying
any combination of the following switches:

 -fieldfg       -fieldbg
 -ind1fg        -ind1bg
 -ind2fg        -ind2bg
 -subfieldfg    -subfieldbg
 -datafg        -databg
 -fixedfg       -fixedbg
 -leaderfg      -leaderbg
 -leadereditfg  -leadereditbg

So, for example, to create the editor to look like one
of the old amber-on-black terminals (remember those?),
you could do something like this:

 my $ed = $FRAME->Scrolled('Editor', 
			   -scrollbars => 'e', 
			   -record => $marc, 
			   -background => 'black',
			   -leaderbg => 'yellow',
			   -leaderfg => 'black',
			   -fieldbg => 'black',
			   -fieldfg => 'yellow',
			   -ind1bg => 'black',
			   -ind1fg => 'yellow',
			   -ind2bg => 'black',
			   -ind2fg => 'yellow',
			   -subfieldbg => 'yellow',
			   -subfieldfg => 'black',
			   -databg => 'black',
			   -datafg => 'yellow',
			   -fixedbg => 'black',
			   -fixedfg => 'yellow',
			   )->pack(-side => 'top');

You can, of course, always use the configure( -attribute => value ); form
to deal with colors individually.  For example, $ed->configure( -leaderbg => 'darkgreen' );

You can also use the C<ColorScheme> method to get or set all the colors at once. 

=cut

# Revision history for Tk::MARC::Editor
# -------------------------------------
# 1.0 2006.02.24
#     - renamed module from Tk::MARC_Editor to Tk::MARC::Editor on the
#       advice of the kind folks at modules [at] perl.org
# 0.9 2006.01.06
#     - file dialog problems in the sample app under windows
#     - shift key acts as a delete key
# 0.8 2006.01.04
#     - added ColorScheme method to get or set all colors
#       as a unit.
# 0.7 2006.01.04
#     - handle configure and cget in the Tk way (using ConfigSpecs)
# 0.6 2006.01.04
#     - fixed leader bug (allow re-editing of editable fields)
#     - proper positioning of insertion cursor re: leaderedit tag						  
# 0.5 2005.12.29
#     - fixed leader bug (leader was being returned as a 26-character string!)
# 0.4 2005.12.22
#     - proper event bindings
#     - specify colors
#     - POD
# 0.3 2005.12.21
#     - better leader handling :-)
# 0.2 2005.12.20
#     - leader handling
# 0.1 2005.12.19
#     - original version

use Tk qw(Ev);
use Tk::widgets qw(Text);
use base qw/Tk::Derived Tk::Text/;
use Carp;
use MARC::Record;
use MARC::Descriptions;
use MARC::Lint;
use MARC::Errorchecks;
use Data::Dumper;
use strict;

Construct Tk::Widget 'Editor';

our (
     $TD,
     %pos,
     %ldrpos,
     );

sub ClassInit {
    my ($class, $mw) = @_;
    $TD = MARC::Descriptions->new;
    %pos = ( field    => { start => 0, length => 3 },
	     ind1     => { start => 4, length => 1 },
	     ind2     => { start => 5, length => 1 },
	     subfield => { start => 8, length => 1 },
	     data     => { start => 9, length => undef },
	     );
    %ldrpos = ( "A Logical record length"       => { start => 0, length => 5, editable => 0 },
		"B Record status"               => { start => 5, length => 1, editable => 1 },
		"C Type of record"              => { start => 6, length => 1, editable => 1 },
		"D Bibliographic level"         => { start => 7, length => 1, editable => 1 },
		"E Type of control"             => { start => 8, length => 1, editable => 1 },
		"F Character coding scheme"     => { start => 9, length => 1, editable => 0 },
		"G Indicator count"             => { start => 10, length => 1, editable => 0 },
		"H Subfield code count"         => { start => 11, length => 1, editable => 0 },
		"I Base address of data"        => { start => 12, length => 5, editable => 0 },
		"J Encoding level"              => { start => 17, length => 1, editable => 1 },
		"K Descriptive cataloging form" => { start => 18, length => 1, editable => 1 },
		"L Linked record requirement"   => { start => 19, length => 1, editable => 1 },
		"M Entry map"                   => { start => 20, length => 4, editable => 0 },
		);

    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ($self, $args) = @_;
    
    my $record = delete $args->{'-record'};
    croak "Missing -record" unless $record;
    croak "Not a MARC::Record" unless (ref($record) eq "MARC::Record");

    $self->ConfigSpecs('-fieldfg'      => ['METHOD',undef,undef,'darkgreen']);
    $self->ConfigSpecs('-fieldbg'      => ['METHOD',undef,undef,undef]);
    $self->ConfigSpecs('-ind1fg'       => ['METHOD',undef,undef,'yellow']);
    $self->ConfigSpecs('-ind1bg'       => ['METHOD',undef,undef,'darkslategrey']);
    $self->ConfigSpecs('-ind2fg'       => ['METHOD',undef,undef,'yellow']);
    $self->ConfigSpecs('-ind2bg'       => ['METHOD',undef,undef,'darkslategrey']);
    $self->ConfigSpecs('-subfieldfg'   => ['METHOD',undef,undef,'darkgoldenrod']);
    $self->ConfigSpecs('-subfieldbg'   => ['METHOD',undef,undef,undef]);
    $self->ConfigSpecs('-datafg'       => ['METHOD',undef,undef,'blue']);
    $self->ConfigSpecs('-databg'       => ['METHOD',undef,undef,undef]);
    $self->ConfigSpecs('-fixedfg'      => ['METHOD',undef,undef,'black']);
    $self->ConfigSpecs('-fixedbg'      => ['METHOD',undef,undef,undef]);
    $self->ConfigSpecs('-leaderfg'     => ['METHOD',undef,undef,'black']);
    $self->ConfigSpecs('-leaderbg'     => ['METHOD',undef,undef,undef]);
    $self->ConfigSpecs('-leadereditfg' => ['METHOD',undef,undef,'blanchedalmond']);
    $self->ConfigSpecs('-leadereditbg' => ['METHOD',undef,undef,'white']);

    $self->SUPER::Populate($args);
    $self-> bindtags([$self, ref($self), $self->toplevel, 'all']); # take first crack at events
    $self->_bind_for_record();
    $self->OverstrikeMode(1);
    $self->menu( $self->configure_menu( $self->Menu() ));

    # Set up some default colors
    my %color = ( "field"      => { fg => 'darkgreen',     bg => undef },
		  "ind1"       => { fg => 'yellow',        bg => 'darkslategrey' },
		  "ind2"       => { fg => 'yellow',        bg => 'darkslategrey' },
		  "subfield"   => { fg => 'darkgoldenrod', bg => undef },
		  "data"       => { fg => 'blue',          bg => undef },
		  "fixed"      => { fg => 'black',         bg => undef },
		  "leader"     => { fg => 'black',         bg => 'blanchedalmond' },
		  "leaderedit" => { fg => 'black',         bg => 'white' },
		  );
    $self->{colors} = \%color;
    foreach my $key (sort keys %color) {
	foreach my $elem (sort keys %{ $color{$key} }) {
	    $color{$key}{$elem} = delete $args->{"-$key$elem"} if ($args->{"-$key$elem"});
	}
    }
    foreach my $key (sort keys %color) {
	$self->tagConfigure($key, 
			    'foreground' => $color{$key}{fg},
			    'background' => $color{$key}{bg},
			    );
    }
    $self->tagConfigure('leaderedit', 'borderwidth' => 1, 'relief' => 'groove');


    # If the user clicks anywhere in the leader, move to the first editable leader field
    # (and set up for leader-bindings rather than field-bindings)
    $self->tagBind('leader', '<ButtonRelease>', sub { $self->markSet('insert', 
								     #$self->index('leaderedit.first + 1 chars')
								     $self->index('leaderedit.first')
								     );
						      $self->_bind_for_leader();
						      $self->OverstrikeMode(1);
						      Tk->break;
						  });
    $self->tagBind('field',    '<ButtonRelease>', sub { $self->_bind_for_record(); $self->OverstrikeMode(1); });
    $self->tagBind('ind1',     '<ButtonRelease>', sub { $self->_bind_for_record(); $self->OverstrikeMode(1); });
    $self->tagBind('ind2',     '<ButtonRelease>', sub { $self->_bind_for_record(); $self->OverstrikeMode(1); });
    $self->tagBind('subfield', '<ButtonRelease>', sub { $self->_bind_for_record(); $self->OverstrikeMode(1); });
    $self->tagBind('data',     '<ButtonRelease>', sub { $self->_bind_for_record(); 
							# set the overstrike mode for data to whatever it
							# was the last time the user was in data.
							$self->OverstrikeMode( $self->{dataOverstrikeMode} );
						    });
    $self->tagBind('fixed',    '<ButtonRelease>', sub { $self->_bind_for_record(); $self->OverstrikeMode(1); });

    $self->{menuSubfields} = "";
    $self->{dataOverstrikeMode} = 1;
    $self->Contents( $record );
}


=head1 METHODS

=head2 Lint()

=over

Returns the result of using C<MARC::Lint> on the record being edited,
as a string.

=back

=cut

sub Lint {
    my $self = shift;

    my $marc = $self->Editor_get();
    my $lint = new MARC::Lint;
    $lint->check_record( $marc );
    
    my $s;

    # Print the errors that were found
    $s .= join( "\n", $lint->warnings ) . "\n";

    return $s;
}

=head2 Errorchecks()

=over

Returns the result of using C<MARC::Errorchecks> on the record being edited,
as a string.

=back

=cut

sub Errorchecks {
    my $self = shift;

    my $marc = $self->Editor_get();
    my $s = join( "\n", @{ MARC::Errorchecks::check_all_subs($marc) }) . "\n";

    return $s;
}

=head2 Contents( I<marc> )

=over

Load the given C<MARC::Record> object into the editor.

When invoked without a parameter, gets the contents of the editor
converted into a C<MARC::Record> object.

=back

=cut

sub Contents {
    my $self = shift;
    my ($marc) = @_;

    if ($marc) {
	return $self->Editor_load( $marc );
    } else {
	return $self->Editor_get();
    }
}

=head2 ColorScheme( I<href> )

=over

Set or retrieve the current color scheme.

When invoked without a parameter, gets the color scheme - 
a hash of the following form:

    %color = ( "field"      => { fg => 'darkgreen',     bg => undef },
	       "ind1"       => { fg => 'yellow',        bg => 'darkslategrey' },
	       "ind2"       => { fg => 'yellow',        bg => 'darkslategrey' },
	       "subfield"   => { fg => 'darkgoldenrod', bg => undef },
	       "data"       => { fg => 'blue',          bg => undef },
	       "fixed"      => { fg => 'black',         bg => undef },
	       "leader"     => { fg => 'black',         bg => 'blanchedalmond' },
	       "leaderedit" => { fg => 'black',         bg => 'white' },
	       "background" => 'white',
	       );

Note that you can always use the C<configure( -attribute => value );> form
to deal with colors individually.  For example, C<$ed->configure( -leaderbg => 'darkgreen' );>

=back

=cut

sub ColorScheme {
    my $self = shift;
    my $href = shift;

    if ($href) {
	foreach my $key (qw/field ind1 ind2 subfield data fixed leader leaderedit/) {
	    $self->tagConfigure($key, 'foreground' => $href->{$key}{fg}) if ($href->{$key}{fg});
	    if ($href->{$key}{bg}) {
		$self->tagConfigure($key, 'background' => $href->{$key}{bg});
	    } else {
		$self->tagConfigure($key, 'background' => $href->{background}) if ($href->{background});
	    }
	}
	$self->configure(-background => $href->{background}) if ($href->{background});
    } else {
	foreach my $key (qw/field ind1 ind2 subfield data fixed leader leaderedit/) {
	    $href->{$key}{fg} = $self->tagCget($key, '-foreground');
	    $href->{$key}{bg} = $self->tagCget($key, '-background');
	}
	$href->{background} = $self->cget('-background');
    }
    return $href;
}

sub _build_leader {
    my $self = shift;
    my $line = shift;
    $line =~ s/^LDR (.*)/$1/;
    $self->insert('end', "LDR ", 'leader');
    foreach my $key (sort keys %ldrpos) {
	my $s = substr($key, 2) . "[";
	$self->insert('end', $s, 'leader');
	$s = substr($line, $ldrpos{$key}{start}, $ldrpos{$key}{length});
	if ($ldrpos{$key}{editable}) {
	    $self->insert('end', $s, 'leaderedit');
	} else {
	    $self->insert('end', $s, 'leader');
	}
	$s = "]  ";
	$self->insert('end', $s, 'leader');
    }
    $self->insert('end', "\n", 'leader');
}

sub _extract_leader {
    my $self = shift;
    my $line = shift;
    my $leader;

    my @elements = split /\]/, $line;
    foreach my $elem (@elements) {
	$elem =~ s/^.*\[(.+)/$1/;
	$leader .= $elem;
    }
    $leader = substr($leader,0,24);
    return $leader;
}

sub Editor_load {
    my $self = shift;
    my ($marc) = @_;

    croak "Not a MARC::Record" unless (ref($marc) eq "MARC::Record");
    #    $self->SUPER::Contents( $marc->as_formatted );
    $self->delete('1.0','end');

    my $s = $marc->as_formatted();
    my @lines = split /\n/, $s;

    foreach my $line (@lines) {
	if ($line =~ /^LDR /) {
	    $self->_build_leader($line);
	} else {

	    $self->insert('end', $line);
	    $self->markSet('insert','end');
	    $self->_apply_tags();
	    $self->insert('end', "\n");
	}
    }
    #print STDERR $self->GetTextTaggedWith('data');
    $self->markSet('insert', $self->index('2.0'));
}

sub Editor_get {
    my $self = shift;
    my $marc = new MARC::Record;

    my $s = $self->SUPER::Contents();
    my @lines = split /\n/, $s;
    my $fld;
    my $current_field = "";
    my $ind1; 
    my $ind2; 
    my @sfld_data = ();
    my $leader;

    my $marc_field_as_text = "";
    foreach my $line (@lines) {

	my $t_field = substr $line, $pos{field}->{start},  $pos{field}->{length};
	my $t_leader;
	my $t_ind1;
	my $t_ind2;
	my $t_subfield;
	my $t_data;

	if ($t_field =~ /^LDR$/) {
	    # leader
	    $t_leader = $self->_extract_leader($line);
	    #print STDERR "Line  : [" . $line . "]\n";
	    #print STDERR "Leader: [" . $t_leader . "]\n";
	    #print STDERR "The leader is [" . length($t_leader) . "] characters long\n\n";
	    $leader = $self->_extract_leader($line);
	} elsif (($t_field =~ /^\w\w\w/) && ($t_field lt "010")) {
	    # fixed field
	    $t_data = $line;
	    $t_data =~ s/^\w\w\w\s+(\w.*)/$1/;
	    $fld = MARC::Field->new($t_field, $t_data);
	    $marc->append_fields($fld);
	    $fld = undef;
	} elsif ($t_field =~ /^\w\w\w/) {
	    # finish previous field
	    if ($current_field) {
		$fld = MARC::Field->new($current_field, $ind1, $ind2, @sfld_data);
		$marc->append_fields($fld);
		$fld = undef;
		@sfld_data = ();
	    }

	    # new MARC field
	    $current_field = $t_field;
	    $ind1       = substr $line, $pos{ind1}{start},     $pos{ind1}{length};
	    $ind2       = substr $line, $pos{ind2}{start},     $pos{ind2}{length};
	    $t_subfield = substr $line, $pos{subfield}{start}, $pos{subfield}{length};
	    $t_data     = substr $line, $pos{data}{start};
	    push @sfld_data, ( $t_subfield => $t_data );
	} else {
	    # MARC field continuation
	    $t_subfield = substr $line, $pos{subfield}{start}, $pos{subfield}{length};
	    $t_data     = substr $line, $pos{data}{start};
	    push @sfld_data, ( $t_subfield => $t_data );
	}
    }

    # Don't forget the last field!
    if ($current_field) {
	$fld = MARC::Field->new($current_field, $ind1, $ind2, @sfld_data);
	$marc->append_fields($fld);
    }

    # now update the leader bits (well, the updatable bits, anyway)
    $self->_update_leader($leader, $marc);

    #print STDERR $marc->as_usmarc();
    #print STDERR "\n" . $marc->as_formatted() . "\n";

    return $marc;
}

sub _update_leader {
    my $self = shift;
    my ($leader, $marc) = @_;

    my $new_leader = $leader;
    my $blob = $marc->as_usmarc();
    #    $new_leader = $self->_update_leader_element("A Logical record length", $new_leader, $marc);
    foreach my $key (sort keys %ldrpos) {
	# if it is a non-editable leader field, replace the text version with the
	# 'real' version from the marc blob
	if (!($ldrpos{$key}{editable})) {
	    $new_leader = $self->_update_leader_element($key, $new_leader, $blob);
	}
    }
    #print STDERR "New leader: [$new_leader]\n";
    $marc->leader($new_leader);
}

# Extract a value from the leader in a MARC blob, and put it into a string
# in place of the existing value in that string.
sub _update_leader_element {
    my $self = shift;
    my ($key, $leader, $blob) = @_;

    my $oldval = substr($leader,
			$ldrpos{$key}{start},
			$ldrpos{$key}{length},
			substr($blob,
			       $ldrpos{$key}{start},
			       $ldrpos{$key}{length}
			       )
			);
    return $leader;
}

sub _find_index_range {
    my $self = shift;
    my ($tag, $ref_iStart, $ref_iEnd) = @_;

    my $i1; my $i2;
    $i1 = "insert linestart + " . $pos{$tag}{start} . " chars";
    if (defined $pos{$tag}{length}) {
	$i2 = "insert linestart + " . ($pos{$tag}{start} + $pos{$tag}{length}) . " chars";
    } else {
	$i2 = "insert lineend";
    }

    $$ref_iStart = $self->index($i1);
    $$ref_iEnd   = $self->index($i2);
}

sub _apply_tags {
    my $self = shift;
    my $index_insert = $self->index('insert');
    my $index_start = $self->index('insert linestart');
    my $index_end = $self->index('insert lineend');

    my $iStart;
    my $iEnd;

    my @tags = qw( field ind1 ind2 subfield data );
    foreach my $tag (@tags) {
	$self->_find_index_range($tag, \$iStart, \$iEnd); # find proper range
	$self->tagRemove($tag,$index_start,$index_end);   # remove from line
	my $mfld = $self->get($iStart, $iEnd); 
	if ($mfld =~ /\S/) {                              # if there's any text,
	    $self->tagAdd($tag, $iStart, $iEnd);          #   add to proper range
	    if (($tag eq 'field') && ($mfld lt "010")) {  # fixed field
		$self->tagAdd('fixed', 
			      $self->index("$iEnd + 5 chars"),
			      $self->index("$iEnd lineend")
			      );
		last;  # and bail out of the tag processing
	    }
	}
    }
}

sub _add_field {
    my $self = shift;
    my $field_to_add = shift;

    my $field_num = $field_to_add;
    $field_num =~ s/^\[(.*)\].*$/$1/;
    my $description = $field_to_add;
    $description =~ s/^\[.*\]\s+(.*)$/$1/;

    #print STDERR "Add field [$field_num]\n";
    my $marc = $self->Editor_get();
    my $field;
    if ($field_num lt "010") {
	$field = MARC::Field->new( $field_num, $description );
    } else {
	$field = MARC::Field->new( $field_num, ' ',' ', 'a' => $description );
    }
    $marc->insert_grouped_field( $field );
    $self->Editor_load( $marc );
    $self->markSet('insert',$self->search(-backwards, 
					  -regexp, 
					  "^$field_num", 
					  $self->index('end')
					  )
		   );
    $self->see($self->index('insert'));
}

sub _add_subfield {
    my $self = shift;
    my ($field_num, $subfield, $description, $idxFieldTag) = @_;

#    print STDERR "_add_subfield: Field [$field_num], Subfield [$subfield], Description [$description]\n";
    my ($index, $junk) = $self->tagNextrange('field', $idxFieldTag);     # this gets the current field
    ($index, $junk) = $self->tagNextrange('field', "$index + 4 chars");  # this gets the next one, if there is one.
    if ($index) {     
	$self->markSet('insert', "$index - 1 lines");        
	$self->markSet('insert', "insert lineend");
    } else {                                                          # we're dealing with the last field
	$self->markSet('insert', 'end');
    }
    $self->Insert("\n       _$subfield$description");        # and stuff the text in
    $self->_apply_tags();
    $self->{menuSubfields} = undef;
}

sub check_for_type {
    my $self = shift;
    my ($type, $index) = @_;
    my $retval = 0;
    my @applied_tags = $self->tagNames($index);
    foreach my $applied (@applied_tags) {
	next unless ($applied eq $type);
	$retval = 1;
	last;
    }
    return $retval;
}


#-----------------------------------------------------------------------------------
# Bindings  (subroutines are named by tagname_Event)
#-----------------------------------------------------------------------------------
sub _bind_for_leader {
    my $self = shift;

    $self->bind('<Up>' => "");
    $self->bind('<Down>' => "");
    $self->bind('<Down>' => \&keydown );
    $self->bind('<Left>' => "");
    $self->bind('<Left>' => \&leader_keyleft);
    $self->bind('<Right>' => "");
    $self->bind('<Right>' => \&leader_keyright);
    $self->bind('<Insert>' => "");
    $self->bind('<Tab>' => \&leader_keyright);
    $self->bind('<Shift-Tab>' => \&leader_keyleft);
    $self->bind('<Home>' => \&leader_home);
    $self->bind('<End>' => \&leader_end);
    $self->bind('<Delete>' => \&leader_delete);
    $self->bind('<space>' => \&leader_delete);
    $self->bind('<KeyPress>' => [\&leader_keypress, Ev('K'), Ev('k') ]);
}

sub _bind_for_record {
    my $self = shift;

    $self->bind('<Up>'        => \&keyup );
    $self->bind('<Down>'      => \&keydown );
    $self->bind('<Left>'      => "");
    $self->bind('<Left>'      => \&keyleft );
    $self->bind('<Right>'     => "");
    $self->bind('<Right>'     => \&keyright );
    $self->bind('<Insert>'    => \&keyinsert );
    $self->bind('<Tab>'       => "");
    $self->bind('<Shift-Tab>' => "");
    $self->bind('<Home>'      => "");
    $self->bind('<End>'       => "");
    $self->bind('<Delete>'    => "");
    $self->bind('<space>'     => "");
#    $self->bind('<KeyPress>'  => "");
    $self->bind('<KeyPress>'  => [\&record_keypress, Ev('K'), Ev('k') ]);
}

sub leader_home {
    my $self = shift;
    $self->markSet('insert', $self->index('leaderedit.first'));
    Tk->break;
}

sub leader_end {
    my $self = shift;
    $self->markSet('insert', $self->index('leaderedit.last - 1 chars'));
#    $self->markSet('insert', $self->index('leaderedit.last'));
    Tk->break;
}

sub leader_delete {
    my $self = shift;
    $self->delete( 'insert' );
    $self->insert( 'insert', ' ', 'leaderedit' );
    $self->markSet( 'insert', $self->index('insert') . " - 1 chars");
    Tk->break;
}

sub leader_keypress {
    my $self = shift;
    my ($keysym, $keycode) = @_;

    # The only editable fields are single-character.
    
    if ($keysym =~ /^\w$/) {
	$self->delete( 'insert' );
	$self->insert( 'insert', $keysym, 'leaderedit' );
	$self->markSet( 'insert', $self->index('insert') . " - 1 chars");
	$self->leader_keyright();

#    } else {
#	print STDERR "keypress: [" . $keysym . "]";
#	print STDERR " in " . $self->tagNames('insert') . "\n";

    }
    Tk->break;
}

sub leader_keyright {
    my $self = shift;
    my ($next_editable, $junk) = $self->tagNextrange('leaderedit',
						     $self->index('insert') . " + 1 chars",
						     $self->index('insert lineend'));
    $self->markSet('insert', $next_editable) if $next_editable;
    $self->leader_end() unless $next_editable;
    Tk->break;
}

sub leader_keyleft {
    my $self = shift;
    my ($prev_editable, $junk) = $self->tagPrevrange('leaderedit',
						     $self->index('insert'),
						     $self->index('insert linestart'));
    $self->markSet('insert', $prev_editable) if $prev_editable;
    $self->leader_home() unless $prev_editable;
    Tk->break;
}

sub keyup {
    my $self = shift;
    $self->_apply_tags();
    $self->markSet('insert', $self->index('insert - 1 lines'));

    if ($self->check_for_type('data','insert')) {
	$self->OverstrikeMode( $self->{dataOverstrikeMode} );
    } else {
	$self->OverstrikeMode(1);
    }

    if ($self->check_for_type('leader','insert')) {
	$self->_bind_for_leader();
	# Move to the first editable leader field.
	$self->markSet('insert', $self->index('leaderedit.first'));
    }
    $self->see('insert');
    Tk->break;
}

sub keydown {
    my $self = shift;
    $self->_apply_tags() unless ($self->check_for_type('leaderedit','insert'));
    $self->markSet('insert', $self->index('insert + 1 lines'));

#    $self->OverstrikeMode(1) unless ($self->check_for_type('data','insert'));
    if ($self->check_for_type('data','insert')) {
	$self->OverstrikeMode( $self->{dataOverstrikeMode} );
    } else {
	$self->OverstrikeMode(1);
    }

    if (!($self->check_for_type('leader','insert'))) {
	$self->_bind_for_record();
    }
    $self->see('insert');
    Tk->break;
}

sub keyleft {
    my $self = shift;
    $self->_apply_tags();
    $self->markSet('insert', $self->index('insert - 1 chars'));

#    $self->OverstrikeMode(1) unless ($self->check_for_type('data','insert'));
    if ($self->check_for_type('data','insert')) {
	$self->OverstrikeMode( $self->{dataOverstrikeMode} );
    } else {
	$self->OverstrikeMode(1);
    }

    if ($self->check_for_type('leader','insert')) {
	$self->_bind_for_leader();
    }
    $self->see('insert');
    Tk->break;
}

sub keyright {
    my $self = shift;
    $self->_apply_tags();
    $self->markSet('insert', $self->index('insert + 1 chars'));

#    $self->OverstrikeMode(1) unless ($self->check_for_type('data','insert'));
    if ($self->check_for_type('data','insert')) {
	$self->OverstrikeMode( $self->{dataOverstrikeMode} );
    } else {
	$self->OverstrikeMode(1);
    }

    if (!($self->check_for_type('leader','insert'))) {
	$self->_bind_for_record();
    }
    $self->see('insert');
    Tk->break;
}

sub keyinsert {
    my $self = shift;
    # Can only go into Insert mode in 'data' tag
    if ($self->check_for_type('data','insert')) {
	if ( $self->{dataOverstrikeMode} ) {
	    $self->{dataOverstrikeMode} = 0;
	} else {
	    $self->{dataOverstrikeMode} = 1;
	}
	$self->OverstrikeMode($self->{dataOverstrikeMode});
    } else {
	$self->OverstrikeMode(1);
    }
    Tk->break;
}

sub record_keypress {
    my $self = shift;
    my ($keysym, $keycode) = @_;

#    print STDERR "keypress: [" . $keysym . "]";
#    print STDERR " in " . $self->tagNames('insert') . "\n";

    # Handle the Shift-acts-as-delete problem.
    if ($keysym =~ /^Shift_L$/) {
	Tk->break;
    }
}


#-----------------------------------------------------------------------------------
# "Menu" configuration (MARC field and subfield names)
#-----------------------------------------------------------------------------------
sub configure_menu {
    my $self = shift;
    my $menu = shift;

    my $mFieldList = $menu->Menu();

    my $submenu_0XX = $menu->Menu();
    $self->_add_submenu_items($submenu_0XX,"010","099");
    $mFieldList->add("cascade", -label => "0XX", -menu => $submenu_0XX);

    my $submenu_1XX = $menu->Menu();
    $self->_add_submenu_items($submenu_1XX,"100","199");
    $mFieldList->add("cascade", -label => "1XX", -menu => $submenu_1XX);

    my $submenu_2XX = $menu->Menu();
    $self->_add_submenu_items($submenu_2XX,"200","299");
    $mFieldList->add("cascade", -label => "2XX", -menu => $submenu_2XX);

    my $submenu_3XX = $menu->Menu();
    $self->_add_submenu_items($submenu_3XX,"300","399");
    $mFieldList->add("cascade", -label => "3XX", -menu => $submenu_3XX);

    my $submenu_4XX = $menu->Menu();
    $self->_add_submenu_items($submenu_4XX,"400","499");
    $mFieldList->add("cascade", -label => "4XX", -menu => $submenu_4XX);

    my $submenu_5XX = $menu->Menu();
    $self->_add_submenu_items($submenu_5XX,"500","599");
    $mFieldList->add("cascade", -label => "5XX", -menu => $submenu_5XX);

    my $submenu_6XX = $menu->Menu();
    $self->_add_submenu_items($submenu_6XX,"600","699");
    $mFieldList->add("cascade", -label => "6XX", -menu => $submenu_6XX);

    my $submenu_7XX = $menu->Menu();
    $self->_add_submenu_items($submenu_7XX,"700","799");
    $mFieldList->add("cascade", -label => "7XX", -menu => $submenu_7XX);

    my $submenu_8XX = $menu->Menu();
    $self->_add_submenu_items($submenu_8XX,"800","899");
    $mFieldList->add("cascade", -label => "8XX", -menu => $submenu_8XX);

    my $submenu_9XX = $menu->Menu();
    $self->_add_submenu_items($submenu_9XX,"900","999");
    $mFieldList->add("cascade", -label => "9XX", -menu => $submenu_9XX);

    $menu->add("cascade",
	       -label   => 'Fields Reference',
	       -menu    => $mFieldList,
	       );



    $menu->add("command",
	       -label       => 'Subfields Reference',
	       -command     => sub {my $idxFieldTag;
				    my $junk;
				    if ($self->index('insert') == $self->index('insert linestart')) {
					$idxFieldTag = $self->index('insert');
				    } else {
					($idxFieldTag, $junk) = $self->tagPrevrange('field',
										    $self->index('insert'));
				    }
				    my $field = $self->get($idxFieldTag,
							   "$idxFieldTag + 3 chars"
							   );

				    #print STDERR "Invoking popup for field [$field]\n";

				    $self->{menuSubfields} = $menu->Menu();
				    my $href = $TD->get($field, "subfields");
				    #print Dumper($href);

				    # MARC::Descriptions is going through some changes to support localization.
				    # Check if the version we have supports different languages or not.
				    my ($k,@otherstuff) = keys %$href;             # get a single key to test against

				    if (ref($href->{$k}{description}) eq "HASH") {
					if (exists $href->{$k}{description}{eng}) {
					    foreach my $subfield (sort keys %$href) {
						my $s = "[" . $subfield . "] " . $href->{$subfield}{description}{eng};
						#print STDERR "$s\n";
						$self->{menuSubfields}->add('command', 
									    -label => $s,
									    -command => sub {
										$self->_add_subfield($field,
												     $subfield,
												     $href->{$subfield}{description}{eng},
												     $idxFieldTag,
												     );
									    }
									    );
					    }
					}
				    } else {
					foreach my $subfield (sort keys %$href) {
					    my $s = "[" . $subfield . "] " . $href->{$subfield}{description};
					    #print STDERR "$s\n";
					    $self->{menuSubfields}->add('command', 
									-label => $s,
									-command => sub {
									    $self->_add_subfield($field,
												 $subfield,
												 $href->{$subfield}{description},
												 $idxFieldTag,
												 );
									}
									);
					}
				    }
				    $self->{menuSubfields}->Popup(qw/-popover cursor/);
				    #print STDERR "Done popup\n";
				}
	       );

    return $menu;
}


sub _add_submenu_items {
    my $self = shift;
    my ($sm, $first, $last) = @_;

    my @submenu_items = ();
    
    for (my $i = $first; $i <= $last; $i++) {
	my $tag = sprintf("%03s",$i);
	my $s = $TD->get($tag,"description");
	if ($s) {
	    push @submenu_items, "[$tag] $s";
	}
    }

    foreach my $item (@submenu_items) {
	$sm->add('command', 
		 -label => $item,
		 -command => sub {
		     #my $field = $item;
		     #$self->_add_field($field);
		     $self->_add_field($item);
		 }
		 );
    }
}

#--------------------------------------------------------------------
# ConfigSpecs methods
#--------------------------------------------------------------------
sub fieldfg {
    my ($self, $value) = @_;
    $self->tagConfigure('field','foreground' => $value) if (@_ > 1);
#    return $self->cget( '-fieldfg' );
}
sub fieldbg {
    my ($self, $value) = @_;
    $self->tagConfigure('field','background' => $value) if (@_ > 1);
#    return $self->cget( '-fieldbg' );
}
sub ind1fg {
    my ($self, $value) = @_;
    $self->tagConfigure('ind1','foreground' => $value) if (@_ > 1);
#    return $self->cget( '-ind1fg' );
}
sub ind1bg {
    my ($self, $value) = @_;
    $self->tagConfigure('ind1','background' => $value) if (@_ > 1);
#    return $self->cget( '-ind1bg' );
}
sub ind2fg {
    my ($self, $value) = @_;
    $self->tagConfigure('ind2','foreground' => $value) if (@_ > 1);
#    return $self->cget( '-ind2fg' );
}
sub ind2bg {
    my ($self, $value) = @_;
    $self->tagConfigure('ind2','background' => $value) if (@_ > 1);
#    return $self->cget( '-ind2bg' );
}
sub subfieldfg {
    my ($self, $value) = @_;
    $self->tagConfigure('subfield','foreground' => $value) if (@_ > 1);
#    return $self->cget( '-subfieldfg' );
}
sub subfieldbg {
    my ($self, $value) = @_;
    $self->tagConfigure('subfield','background' => $value) if (@_ > 1);
#    return $self->cget( '-subfieldbg' );
}
sub datafg {
    my ($self, $value) = @_;
    $self->tagConfigure('data','foreground' => $value) if (@_ > 1);
#    return $self->cget( '-datafg' );
}
sub databg {
    my ($self, $value) = @_;
    $self->tagConfigure('data','background' => $value) if (@_ > 1);
#    return $self->cget( '-databg' );
}
sub fixedfg {
    my ($self, $value) = @_;
    $self->tagConfigure('fixed','foreground' => $value) if (@_ > 1);
#    return $self->cget( '-fixedfg' );
}
sub fixedbg {
    my ($self, $value) = @_;
    $self->tagConfigure('fixed','background' => $value) if (@_ > 1);
#    return $self->cget( '-fixedbg' );
}
sub leaderfg {
    my ($self, $value) = @_;
    $self->tagConfigure('leader','foreground' => $value) if (@_ > 1);
#    return $self->cget( '-leaderfg' );
}
sub leaderbg {
    my ($self, $value) = @_;
    $self->tagConfigure('leader','background' => $value) if (@_ > 1);
#    return $self->cget( '-leaderbg' );
}
sub leadereditfg {
    my ($self, $value) = @_;
    $self->tagConfigure('leaderedit','foreground' => $value) if (@_ > 1);
#    return $self->cget( '-leadereditfg' );
}
sub leadereditbg {
    my ($self, $value) = @_;
    $self->tagConfigure('leaderedit','background' => $value) if (@_ > 1);
#    return $self->cget( '-leadereditbg' );
}

=head1 REQUIREMENTS

Tk::MARC::Editor requires MARC::Record, MARC::Descriptions,
MARC::Lint, and MARC::Errorchecks

=head1 SEE ALSO

=over

=item * perl4lib (L<http://perl4lib.perl.org>)

A mailing list devoted to the use of Perl in libraries.

=item * Library of Congress MARC pages (L<http://www.loc.gov/marc/>)

The definative source for all things MARC.

=back

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

=head1 AUTHOR

David Christensen, C<< <David dot A dot Christensen at gmail dot com> >>

=cut

1;
