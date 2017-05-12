$Tk::MARC::Record::VERSION = '0.11';

package Tk::MARC::Record;

=head1 NAME

Tk::MARC::Record - megawidget for editing MARC::Record objects.

=head1 SYNOPSIS

 use Tk;
 use Tk::MARC::Record;
 use MARC::Record
 use MARC::File::USMARC;

 # Get a record
 my $file = MARC::File::USMARC->in( "records.mrc" );
 my $record = $file->next();
 $file->close();
 undef $file

 my $mw = MainWindow->new;
 my $TkMARC = $mw->MARC_Record(-record => $record)->pack;

 my $new_rec;
 $mw->Button(-text = "Save", -command => sub { $new_rec = $TkMARC->get() } );

 MainLoop;

=head1 DESCRIPTION

This is a megawidget that allows editing of a MARC::Record object.
The widget does not change the MARC::Record, it creates a new
MARC::Record when the get() routine is invoked.

The widget is basically a collection of Tk::MARC::Field widgets,
which handle the editing of individual fields within the record.

=cut

# Revision history for Tk::MARC::Record.
# --------------------------------------
# 0.11 January 20, 2004
#      - added check for missing -record
#
# 0.10 January 17, 2004
#      - renamed to Tk::MARC::Record (capitalized 'Record') to better
#        match MARC::Record and avoid confusion (thanks Andy!)
#
# 0.9 January 16, 2004
#     - now uses Tk::MARC::leader
#     - added marvin, the MARc Visual Interactive
#       stream editor (in pl/) as an example.
# 
# 0.8 January 16, 2004
#     - added get() routine... suddenly we are useful!
# 
# 0.7 January 15, 2004
#     - now uses Tk::MARC::indicators
# 
# 0.6 January 14, 2004
#     - first bit of POD
# 
# 0.5 January 14, 2004
#     - menu for adding fields
#     - proper _add_submenu_items routine
# 
# 0.4 January 13, 2004
#     - now uses a scrollable pane for the fields
# 
# 0.3 January 12, 2004
#     - built a couple of sample routines in pl/
#     - t/01-use.t
# 
# 0.2 January 09, 2004
#     - now uses the newly-written MARC::Descriptions module
#       (which is available on the CPAN)
# 
# 0.1 January 08, 2004
#      - original version
# 

use Tk::widgets;
use base qw/Tk::Frame/;
use Carp;
use Tk;
use Tk::Pane;
use Tk::MARC::Field;
use Tk::MARC::Leader;
use MARC::Record;
use strict;

Construct Tk::Widget 'MARC_Record';

our (
     $TD,
     );

sub ClassInit {
    my ($class, $mw) = @_;
    $TD = MARC::Descriptions->new;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ($self, $args) = @_;

    my $record = delete $args->{'-record'};
    croak "Missing -record" unless $record;
    croak "Not a MARC::Record" unless (ref($record) eq "MARC::Record");

    $self->SUPER::Populate($args);

    $self->{"fixed_font"} = "-adobe-courier-medium-r-normal--14-100-75-75-m-60-iso8859-2";

    my $FRAME = $self->Frame()->pack(-side => 'top',
				     -expand => 1,
				     -fill => 'x');
    my $FRAME_EDIT = $FRAME->Scrolled('Pane',
				      -height => 400,
				      -width => 600,
				      )->pack(-side => 'top',
					      -expand => 1,
					      -fill => 'x');
    my $FRAME_CONTROL = $FRAME->Frame()->pack(-side => 'bottom',
					      -expand => 1,
					      -fill => 'x');
    # LEADER
    $self->{LEADER} = $FRAME_EDIT->MARC_Leader(-record => $record
					       )->pack(-anchor => 'w');

    # FIELD LOOP
    my @fields = $record->fields();
    $self->{fields} = ();
    foreach my $fld ( @fields ) {
	push @{ $self->{fields} }, $FRAME_EDIT->MARC_Field(-field => $fld
							   )->pack(-anchor => 'w'); 
    }

    my $mNewField = $FRAME_CONTROL->Menubutton(-text => "New field",
					       -font => $self->{"fixed_font"},
					       -padx => 0,
					       -pady => 0,
					       -tearoff => 1,
					       -indicatoron => 1,
					       -menuitems => [[ 'cascade' => "0XX" ],
							      [ 'cascade' => "1XX" ],
							      [ 'cascade' => "2XX" ],
							      [ 'cascade' => "3XX" ],
							      [ 'cascade' => "4XX" ],
							      [ 'cascade' => "5XX" ],
							      [ 'cascade' => "6XX" ],
							      [ 'cascade' => "7XX" ],
							      [ 'cascade' => "8XX" ],
							      [ 'cascade' => "9XX" ],
							      ]
					       )->pack(-side => 'left');
    my $submenu_0XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_0XX,"010","099");
    $mNewField->entryconfigure("0XX", -menu => $submenu_0XX);

    my $submenu_1XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_1XX,"100","199");
    $mNewField->entryconfigure("1XX", -menu => $submenu_1XX);

    my $submenu_2XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_2XX,"200","299");
    $mNewField->entryconfigure("2XX", -menu => $submenu_2XX);

    my $submenu_3XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_3XX,"300","399");
    $mNewField->entryconfigure("3XX", -menu => $submenu_3XX);

    my $submenu_4XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_4XX,"400","499");
    $mNewField->entryconfigure("4XX", -menu => $submenu_4XX);

    my $submenu_5XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_5XX,"500","599");
    $mNewField->entryconfigure("5XX", -menu => $submenu_5XX);

    my $submenu_6XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_6XX,"600","699");
    $mNewField->entryconfigure("6XX", -menu => $submenu_6XX);

    my $submenu_7XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_7XX,"700","799");
    $mNewField->entryconfigure("7XX", -menu => $submenu_7XX);

    my $submenu_8XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_8XX,"800","899");
    $mNewField->entryconfigure("8XX", -menu => $submenu_8XX);

    my $submenu_9XX = $mNewField->menu->Menu;
    $self->_add_submenu_items($submenu_9XX,"900","999");
    $mNewField->entryconfigure("9XX", -menu => $submenu_9XX);

    $self->Advertise( 'pane', $FRAME_EDIT );
    $self->ConfigSpecs( '-record' => [ 'PASSIVE', undef, undef, undef ],
			);
    $self->Delegates( 'DEFAULT' => $FRAME_EDIT );
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
	$sm->add('command', -label => $item,
		 -command => sub {
		     my $tag = $item;
		     $tag =~ s/^\[(.*)\] .*$/$1/;
		     push @{ $self->{fields} }, $self->MARC_Field(-tag => $tag,
								  -ind1 => " ",
								  -ind2 => " ",
								  -subfields => [ 'a' => "New subfield" ],
								  )->pack(-anchor => 'w');
		 }
		 );
    }
}

sub get {
    my $self = shift;

    my $marc = MARC::Record->new();
    $marc->leader( $self->{LEADER}->get() );
    foreach my $TkFld (@{ $self->{fields} }) {
	my $fld = $TkFld->get();
	if (defined $fld) {
	    $marc->insert_fields_ordered( $fld );
	}
    }
    return $marc;
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
