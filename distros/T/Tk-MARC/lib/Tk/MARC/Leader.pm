$Tk::MARC::Leader::VERSION = '0.3';

package Tk::MARC::Leader;

=head1 NAME

Tk::MARC::Leader - megawidget for editing MARC::Record leader.

=head1 SYNOPSIS

 use Tk;
 use Tk::MARC::Leader;
 use MARC::Record;
 use MARC::File::USMARC;

 my $file = MARC::File::USMARC->in( "pl/tcfm.mrc" );
 my $record = $file->next();
 $file->close();
 undef $file;
 
 my $mw = MainWindow->new;
 $mw->title("leader Test");
 $mw->MARC_Leader(-record => $record)->pack;

 MainLoop;

=head1 DESCRIPTION

This is a megawidget that allows editing of a MARC::Record leader.
The widget itself does not change the MARC::Record leader - that is
up to the widget's parent.

WARNING: As with the MARC::Record->leader() function (on which this
is based), NO ERROR CHECKING IS DONE on the leader.  This widget
basically exists so that, in future, it will be easy to add leader
error checking....

You will likely never use a Tk::MARC::Leader directly - it is simply
a component of Tk::MARC::record.

=cut

# Revision history for Tk::MARC::Leader.
# --------------------------------------
# 0.3  January 20, 2004
#      - croak on missing -record
#
# 0.2  January 17, 2004
#      - renamed to Tk::MARC::Leader (capitalized 'Leader')
#        to be consistant with Tk::MARC::Field
#
# 0.1  January 16, 2004
#      - original version

use Tk::widgets;
use base qw/Tk::Frame/;
use MARC::Descriptions;
use Carp;
use strict;

Construct Tk::Widget 'MARC_Leader';

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

    my $record = delete $args->{'-record'};
    $self->SUPER::Populate($args);
    $self->{"fixed_font"} = "-adobe-courier-medium-r-normal--14-100-75-75-m-60-iso8859-2";

    croak "Missing -record" unless defined($record);
    croak "Not a MARC::Record" unless (ref($record) eq "MARC::Record");
    $self->{VALUE} = $record->leader();
    $self->{ORIGINAL_VALUE} = $self->{VALUE};

    my $FRAME = $self->Frame()->pack(-side => 'top',
				     -expand => 1,
				     -anchor => 'nw',
				     -fill => 'x');

    my $LABEL = $FRAME->Label(-text => 'LEADER',
			      -font => $self->{"fixed_font"}
			      )->pack(-side => 'left',
				      -fill => 'x');
    my $ENTRY = $FRAME->Entry(-textvariable => \$self->{VALUE},
			      -width => 24,
			      -background => "gray",
			      )->pack(-side => 'left',
				      -expand => 0,
				      -fill => 'x');
    
    $ENTRY->bind("<KeyPress>", sub { $ENTRY->configure(-background => "green");
				 });
    my $B_ORIG = $FRAME->Button(-text => "O",
				-font => $self->{"fixed_font"},
				-width => 1,
				-height => 1,
				-padx => 0,
				-pady => 0,
				-command => sub {
				    $self->{VALUE} = $self->{ORIGINAL_VALUE};
				    $ENTRY->configure(-background => "gray");
				}
				)->pack(-side => 'left');
    
    $self->Advertise( 'leader', $ENTRY );
    $self->ConfigSpecs( '-record' => [ 'PASSIVE', undef, undef, undef],
			'DEFAULT' => [$FRAME],
			);
    $self->Delegates( 'DEFAULT' => $FRAME );
}

sub get {
    my $self = shift;

    return $self->{VALUE};
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
