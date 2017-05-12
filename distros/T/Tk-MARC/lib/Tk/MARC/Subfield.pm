$Tk::MARC::Subfield::VERSION = '0.8';

package Tk::MARC::Subfield;

=head1 NAME

Tk::MARC::Subfield - megawidget for editing MARC::Field subfields.

=head1 SYNOPSIS

 use Tk;
 use Tk::MARC::Subfield;

 my $mw = MainWindow->new;
 $mw->MARC_Subfield(-field => '245',
                    -label => 'a',
                    -value => 'Spam: The wonders of canned luncheon meat.',
                   )->pack(-anchor => 'w');
 MainLoop;

=head1 DESCRIPTION

This is a megawidget that allows editing of a MARC::Field subfield.
The widget itself does not change the MARC::Field subfield - that is
up to the widget's parent.

The widget indicates (by changing the text background color to green) 
when you have changed the text.

It allows you to revert to the original text by clicking a button
(which also resets the text background to white).

It also allows you to indicate your desire to delete the subfield, also
by clicking a button (this changes the text background to red).

You will likely never use a Tk::MARC::Subfield directly - it is simply
a component of Tk::MARC::Field.

=cut

# Revision history for Tk::MARC::Subfield.
# ----------------------------------------
# 0.8  January 20, 2004
#      - now uses Carp
#      - croak on missing -field or missing -label
#
# 0.7  January 17, 2004
#      - renamed to Tk::MARC::Subfield (capitalized 'Subfield')
#        to be consistant with Tk::MARC::Field
#
# 0.6  January 16, 2004
#      - properly handle get() for fields < '010'
# 
# 0.5  January 15, 2004
#      - added get() routine
# 
# 0.4  January 14, 2004
#      - first bit of POD
# 
# 0.3  January 14, 2004
#      - built a couple of sample routines in pl/
#      - t/01-use.t
# 
# 0.2  January 09, 2004
#      - now uses the newly-written MARC::Descriptions module
#      (which is available on the CPAN)
# 
# 0.1  January 06, 2004
#      - original version

use Tk::widgets;
use base qw/Tk::Frame/;
use MARC::Descriptions;
use Carp;
use strict;

Construct Tk::Widget 'MARC_Subfield';

our (
     $TD,        # MARC::Descriptions tag data
     );

sub ClassInit {
    my ($class, $mw) = @_;
    $TD = new MARC::Descriptions;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ($self, $args) = @_;

    my $field = delete $args->{'-field'};
    croak "Missing -field" unless (defined $field);
    my $label = delete $args->{'-label'};
    croak "Missing -label" unless (defined $label);
    my $value = delete $args->{'-value'};
    $value = 'New subfield' unless (defined $value);

    $self->SUPER::Populate($args);
    $self->{"fixed_font"} = "-adobe-courier-medium-r-normal--14-100-75-75-m-60-iso8859-2";

    my $FRAME = $self->Frame()->pack(-side => 'top',
				     -expand => 1,
				     -anchor => 'nw',
				     -fill => 'x');
    my $LABEL =  $FRAME->Label(-text => $label,
			       -font => $self->{"fixed_font"},
			       )->pack(-side => 'left',
				       -fill => 'x');
    $self->{FIELD} = $field;
    $self->{SF} = $label;
    $self->{VALUE} = $value;
    $self->{ORIGINAL_VALUE} = $value;
    my $ENTRY = $FRAME->Entry(-textvariable => \$self->{VALUE},
			   -width => 40,
			   -background => "white",
			   )->pack(-side => 'left',
				   -expand => 0,
				   -fill => 'x');
    $self->{DELETED} = "no";
    $ENTRY->bind("<KeyPress>", sub { if ($self->{DELETED} eq "no")
				     {
					 $ENTRY->configure(-background => "green");
				     }
				 });
    my $B_ORIG = $FRAME->Button(-text => "O",
				-font => $self->{"fixed_font"},
				-width => 1,
				-height => 1,
				-padx => 0,
				-pady => 0,
				-command => sub {
				    $self->{VALUE} = $self->{ORIGINAL_VALUE};
				    $ENTRY->configure(-background => "white");
				    $self->{DELETED} = "no";
				}
				)->pack(-side => 'left');
    my $B_DEL = $FRAME->Button(-text => "X",
			       -font => $self->{"fixed_font"},
			       -width => 1,
			       -height => 1,
			       -padx => 0,
			       -pady => 0,
			       -command => sub {
				   $self->{DELETED} = "yes";
				   $ENTRY->configure(-background => "red");
			       }
			       )->pack(-side => 'left');
    
    my $s;
    $s = $TD->get($field,"subfields",$label,"description");
    my $DESCRIPTION = $FRAME->Label(-text => $s,
				 -font => $self->{"fixed_font"},
				 -anchor => 'nw',
				 -justify => 'left',
				 )->pack(-side => 'left',
					 -expand => 0,
					 -fill => 'x');

    $self->Advertise( 'entry', $ENTRY );
    $self->Advertise( 'label', $LABEL );
    $self->ConfigSpecs( '-field' => [ 'PASSIVE', , ,'245'],
			'-label' => [ 'PASSIVE', , ,'Label'],
			'-value' => [ 'PASSIVE', , ,'New subfield'],
			'DEFAULT' => [$ENTRY],
			);
    $self->Delegates( 'DEFAULT' => $ENTRY );
}

sub get {
    my $self = shift;
    if (defined $self->{VALUE}) {
	if ($self->{DELETED} eq "no") {
	    my $sf;
	    if ($self->{FIELD} lt '010') {
		$sf = $self->{VALUE};
	    } else {
		$sf = [ $self->{SF}, $self->{VALUE} ];
	    }
	    return $sf;
	} else {
	    return undef;
	}
    } else {
	return undef;
    }
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
