$Tk::MARC::Field::VERSION = '0.11';

package Tk::MARC::Field;

=head1 NAME

Tk::MARC::Field - megawidget for editing MARC::Field objects.

=head1 SYNOPSIS

 use Tk;
 use Tk::MARC::Field;
 use MARC::Field

 my $mw = MainWindow->new;
 my $field = MARC::Field->new('245','','',
                              'a' => 'The Case for Mars: ',
                              'b' => 'The plan to settle the red
 planet, and why we must.'
                             );
 $mw->MARC_Field(-field => $field
                )->pack(-anchor => 'w');

 MainLoop;

=head1 DESCRIPTION

This is a megawidget that allows editing of a MARC::Field object.
The widget itself does not change the MARC::Field - that is
up to the widget's parent.

The widget allows you to indicate your desire to delete/undelete
the field by clicking a button (which will change the color of
the tag).

It allows you to add new subfields by selecting from a list (you 
can indicate your desire to delete a subfield by clicking a 
button)... and it knows what subfields are valid for this field 
(by using MARC::Descriptions).

You will likely never use a Tk::MARC::Field directly - it is simply
a component of Tk::MARC::Editor.

=cut

# Revision history for Tk::MARC::field.
# -------------------------------------
# 0.11 January 20, 2004
#      - added check for missing -field
#      - added check for missing -subfields
#
# 0.10 January 17, 2004
#      - renamed to Tk::MARC::Field (capitalized 'Field') to better
#        match MARC::Field and avoid confusion (thanks Andy!)
#
# 0.9 January 16, 2004
#     - properly handle get() for fields < '010'
# 
# 0.8 January 15, 2004
#     - get() routine
# 
# 0.7 January 14, 2004
#     - first bit of POD
# 
# 0.6 January 14, 2004
#     - handle tags <= 010 (i.e. no subfields, just data)
# 
# 0.5 January 14, 2004
#     - proper _add_subfield routine
# 
# 0.4 January 14, 2004
#     - menu for adding subfields
# 
# 0.3 January 12, 2004
#     - built a couple of sample routines in pl/
#     - t/01-use.t
# 
# 0.2 January 09, 2004
#     - now uses the newly-written MARC::Descriptions module
#       (which is available on the CPAN)
# 
# 0.1 January 06, 2004
#     - original version
#

use Tk::widgets;
use base qw/Tk::Frame/;
use Tk::MARC::Subfield;
use Tk::MARC::Indicators;
use MARC::Descriptions;
use MARC::Field;
use Carp;
use strict;

Construct Tk::Widget 'MARC_Field';

our (
     $TD,
     );

sub ClassInit {
    my ($class, $mw) = @_;
    $TD = new MARC::Descriptions;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ($self, $args) = @_;

    my $field = delete $args->{'-field'};
    my $tag = delete $args->{'-tag'};
    my $ind1 = delete $args->{'-ind1'};
    my $ind2 = delete $args->{'-ind2'};
    my $subfields = delete $args->{'-subfields'};
    if (defined $field) {
	croak "Not a MARC::Field" unless (ref($field) eq 'MARC::Field');
	$self->{MARCField} = $field;
    } else {
	croak "Missing -tag" unless (defined $tag);
	croak "Missing -subfields" unless (defined $subfields);
	$self->{MARCField} = MARC::Field->new( $tag,
					       $ind1,
					       $ind2,
					       @$subfields
					       );
    }

    $self->SUPER::Populate($args);
    $self->{"fixed_font"} = "-adobe-courier-medium-r-normal--14-100-75-75-m-60-iso8859-2";

    my $FRAME = $self->Frame(-relief => 'ridge',
			     -borderwidth => 1,
			     )->pack(-side => 'top',
				     -expand => 1,
				     -fill => 'both');
    my $FRAME_LABEL = $FRAME->Frame(-relief => 'raised',
				   -borderwidth => 1,
				   )->pack(-side => 'left',
					   -expand => 0,
					   -fill => 'y');
    my $FRAME_TAG = $FRAME_LABEL->Frame()->pack(-side => 'top',
						-expand => 0,
						-fill => 'x');
    my $FRAME_IND = $FRAME_LABEL->Frame()->pack(-side => 'top',
						-expand => 1,
						-fill => 'both');
    
#    my $FRAME_EDIT = $self->Frame()->pack(-side => 'left',
#					  -expand => 1,
#					  -fill => 'both');
    my $FRAME_EDIT = $FRAME->Frame()->pack(-side => 'left',
					   -expand => 1,
					   -fill => 'both');
    my $FRAME_DESC = $FRAME_EDIT->Frame()->pack(-side => 'top',
						-expand => 1,
						-fill => 'x');
    my $FRAME_SUBS = $FRAME_EDIT->Frame()->pack(-side => 'top',
						-expand => 1,
						-fill => 'both');
    
    my $LABEL = $FRAME_TAG->Label(-text => $self->{'MARCField'}->tag(),
				  -anchor => 'nw',
				  -justify => 'left',
				  )->pack(-side => 'left',
					  -expand => 0,
					  -fill => 'both');
    my $DEFAULT_TAG_COLOR = $LABEL->cget(-background);
    $self->{DELETED} = "no";
    my $B_DELETE = $FRAME_TAG->Button(-text => "X",
				      -font => $self->{"fixed_font"},
				      -width => 1,
				      -height => 1,
				      -padx => 0,
				      -pady => 0,
				      -command => sub {
					  $self->{DELETED} = "yes";
					  $LABEL->configure(-background => "red");
				      }
				      )->pack(-side => 'right');
    my $B_UNDELETE = $FRAME_TAG->Button(-text => "O",
					-font => $self->{"fixed_font"},
					-width => 1,
					-height => 1,
					-padx => 0,
					-pady => 0,
					-command => sub {
					    $self->{DELETED} = "no";
					    $LABEL->configure(-background => $DEFAULT_TAG_COLOR);
					}
					)->pack(-side => 'right');
    my $s;
    $s = $TD->get($self->{'MARCField'}->tag(), "description");
    $s = "No description from MARC::Descriptions" unless defined $s;
    my $DESCRIPTION = $FRAME_DESC->Label(-text => $s,
					 -width => 42,
					 -anchor => 'nw',
					 -justify => 'left',
					 )->pack(-side => 'left',
						 -expand => 0,
						 -fill => 'x');


    if ($self->{MARCField}->tag() ge '010') {
	#
	# Menu for adding subfields
	#
	my @menu_subfields;
	my $ref_menu_subfields;
	@menu_subfields = ();
	my $href = $TD->get($self->{'MARCField'}->tag(), "subfields");
	foreach my $subfield (sort keys %$href) {
	    push @menu_subfields,['command' => "[" . $subfield . "] " . $href->{$subfield}{description},
				  -command => sub { 
				      $self->_add_subfield($self->{MARCField}->tag(), $FRAME_SUBS, $subfield);
				      }
				  ];
	}
	my $B_NEWSUBFLD = $FRAME_DESC->Menubutton(-text => "New subfield",
						  -font => $self->{"fixed_font"},
						  -padx => 0,
						  -pady => 0,
						  -tearoff => 0,
						  -indicatoron => 1,
						  -menuitems => \@menu_subfields,
						  )->pack(-side => 'left');
	
	#
	# Subfields
	#
	my @subfields = $self->{MARCField}->subfields();
	$self->{subfields} = ();
	my $i = 0;
	foreach my $subfield (@subfields) {
	    $self->{subfields}[$i++] = $FRAME_SUBS->MARC_Subfield(-field => $self->{MARCField}->tag(),
								  -label => @$subfield[0],
								  -value => @$subfield[1]
								  )->pack(-anchor => 'w');
	}
    } else {
	#
	# Tag is <= 010
	#
	$self->{data} = $FRAME_SUBS->MARC_Subfield(-field => $self->{MARCField}->tag(),
						   -label => 'DATA',
						   -value => $self->{MARCField}->data()
						   )->pack(-anchor => 'w');
    }

    #
    # indicators
    #
    if ($self->{MARCField}->tag() ge '010') {
	$self->{indicators} = $FRAME_IND->MARC_Indicators(-field => $self->{MARCField}->tag(),
							  -ind1  => $self->{MARCField}->indicator(1),
							  -ind2  => $self->{MARCField}->indicator(2),
							  )->pack(-anchor => 'w');
    }

    $self->ConfigSpecs( '-field' => [ 'PASSIVE', , , undef],
			'-tag'   => [ 'PASSIVE', , , undef],
			'-ind1'  => [ 'PASSIVE', , , undef],
			'-ind2'  => [ 'PASSIVE', , , undef],
			'-subfields' => [ 'PASSIVE', , , undef],
			);
}


sub _add_subfield {
    my $self = shift;
    my ($tag, $f, $subfield) = @_;
    push @{ $self->{subfields} }, $f->MARC_Subfield(-field => $tag,
						    -label => $subfield,
						    -value => "New subfield",
						    )->pack(-anchor => 'w');
}

sub get {
    my $self = shift;

    my $fld = undef;

    if ($self->{DELETED} eq "no") {
	if ($self->{MARCField}->tag() lt '010') {
	    $fld = MARC::Field->new($self->{MARCField}->tag(),
				    $self->{data}->get(),
				    );
	} else {
	    #
	    # Tag >= 010
	    #
	    my $sf = undef;
	    my $i = -1;
	    
	    # Find the first (non-deleted) subfield
	    while (($i < $#{ $self->{subfields} })
		   && (not defined $sf)
		   ) {
		$i++;
		$sf = $self->{subfields}[$i]->get();
	    }
	    
	    # Did we find a valid subfield before falling off the end?
	    if (defined $sf) {
		$fld = MARC::Field->new($self->{MARCField}->tag(),
					$self->{indicators}->get(1),
					$self->{indicators}->get(2),
					@$sf[0] => @$sf[1],
					);
		$i++;
		while ($i <= $#{ $self->{subfields} }) {
		    $sf = $self->{subfields}[$i++]->get();
		    if (defined $sf) {
			$fld->add_subfields( @$sf );
		    }
		}
	    } else {
		# all subfields were deleted, so no Field is possible.
	    }
	}
    }
    return $fld;
}

=head1 AUTHOR

David Christensen, <DChristensenSPAMLESS@westman.wave.ca>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by David Christensen

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
