$Tk::MARC::Indicators::VERSION = '0.4';

package Tk::MARC::Indicators;

=head1 NAME

Tk::MARC::Indicators - megawidget for editing MARC::Field indicators.

=head1 SYNOPSIS

 use Tk;
 use Tk::MARC::Indicators;

 my $mw = MainWindow->new;
 $mw->MARC_Indicators(-field => '245',
                      -ind1 => '0',
                      -ind2 => '7',
                     )->pack(-anchor => 'w');
 MainLoop;

=head1 DESCRIPTION

This is a megawidget that allows editing of MARC::Field indicators.
The widget itself does not change the MARC::Field indicators - that is
up to the widget's parent.

The widget provides a menu of valid indicator values (and their
descriptions) for the given MARC field and indicator (1 or 2).

You will likely never use a Tk::MARC::Indicators directly - it is simply
a component of Tk::MARC::field.

=cut

# Revision history for Tk::MARC::Indicators.
# ------------------------------------------
# 0.4  January 20, 2004
#      - croak on missing -field
#
# 0.3  January 17, 2004
#      - renamed to Tk::MARC::Indicators (capitalized 'Indicators')
#        to be consistant with Tk::MARC::Field
#
# 0.2  January 15, 2004
#      - added get() routine
# 
# 0.1  January 15, 2004
#      - original version

use Tk::widgets;
use base qw/Tk::Frame/;
use MARC::Descriptions;
use Carp;
use strict;

Construct Tk::Widget 'MARC_Indicators';

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
    my $ind1 = delete $args->{'-ind1'};
    $ind1 = ' ' unless (defined $ind1);
    my $ind2 = delete $args->{'-ind2'};
    $ind2 = ' ' unless (defined $ind2);

    $self->SUPER::Populate($args);
    $self->{"fixed_font"} = "-adobe-courier-medium-r-normal--14-100-75-75-m-60-iso8859-2";

    my $FRAME = $self->Frame()->pack(-side => 'top',
				     -expand => 1,
				     -anchor => 'nw',
				     -fill => 'x');

    if ($field ge '010') {
	my $FRAME_IND1 = $FRAME->Frame()->pack(-side => 'top',
					       -expand => 0,
					       -fill => 'x');
	my $IND1_LABEL = $FRAME_IND1->Label(-text => ' Ind1')->pack(-side => 'left',
								    -fill => 'x');
	if (defined $ind1) {
	    $self->{IND1_ENTRY} = $FRAME_IND1->Entry(-textvariable => \$ind1,
						     -width => 1,
						     -background => "yellow",
						     )->pack(-side => 'left',
							     -expand => 0,
							     -fill => 'none');
	}
	my @menu_ind1 = ();
	my $ind1_href = $TD->get( $field, "ind1");
	foreach my $key (sort keys %$ind1_href) {
	    #print $ind1_href->{"$key"}->{description} . $/;
	    push @menu_ind1, ['command' => "$key $ind1_href->{$key}->{description}",
			      -command => sub { $ind1 = "$key" } ];
	}
	$FRAME_IND1->Menubutton(-text => "",
				-font => $self->{"fixed_font"},
				-width => 1,
				-height => 1,
				-padx => 0,
				-pady => 0,
				-tearoff => 0,
				-indicatoron => 1,
				-menuitems => \@menu_ind1,
				)->pack(-side => 'left');
	
	#
	# Indicator 2
	#
	my $FRAME_IND2 = $FRAME->Frame()->pack(-side => 'top',
					       -expand => 0,
					       -fill => 'x');
	my $IND2_LABEL = $FRAME_IND2->Label(-text => ' Ind2')->pack(-side => 'left',
								    -fill => 'x');
	if (defined $ind2) {
	    $self->{IND2_ENTRY} = $FRAME_IND2->Entry(-textvariable => \$ind2,
						     -width => 1,
						     -background => "yellow",
						     )->pack(-side => 'left',
							     -expand => 0,
							     -fill => 'none');
	}
	my @menu_ind2 = ();
	my $ind2_href = $TD->get( $field, "ind2");
	foreach my $key (sort keys %$ind2_href) {
	    #print $ind1_href->{"$key"}->{description} . $/;
	    push @menu_ind2, ['command' => "$key $ind2_href->{$key}->{description}",
			      -command => sub { $ind2 = "$key" } ];
	}
	$FRAME_IND2->Menubutton(-text => "",
				-font => $self->{"fixed_font"},
				-width => 1,
				-height => 1,
				-padx => 0,
				-pady => 0,
				-tearoff => 0,
				-indicatoron => 1,
				-menuitems => \@menu_ind2,
				)->pack(-side => 'left');
	
    }

    $self->Advertise( 'ind1', $self->{IND1_ENTRY} );
    $self->Advertise( 'ind2', $self->{IND2_ENTRY} );
    $self->ConfigSpecs( '-field' => [ 'PASSIVE', , ,'245'],
			'-ind1'  => [ 'PASSIVE', , ,' '],
			'-ind2'  => [ 'PASSIVE', , ,' '],
			'DEFAULT' => [$FRAME],
			);
    $self->Delegates( 'DEFAULT' => $FRAME );
}

sub get {
    my $self = shift;
    my $ind = shift;

    if (defined $ind) {
	if ($ind == 1) {
	    if (defined $self->{IND1_ENTRY}) {
		return $self->{IND1_ENTRY}->get();
	    } else {
		return undef;
	    }
	} elsif ($ind == 2) {
	    if (defined $self->{IND2_ENTRY}) {
		return $self->{IND2_ENTRY}->get();
	    } else {
		return undef;
	    }
	} else {
	    croak "Tk::MARC::Indicators->get - invalid indicator #";
	}
    } else {
	croak "Tk::MARC::Indicators->get - must specify an indicator #";
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
