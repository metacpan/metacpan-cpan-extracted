package Wx::Perl::RadioBoxDialog;

use 5.12.0;
use warnings FATAL => 'all';

=head1 NAME

Wx::Perl::RadioBoxDialog - wxSingleChoiceDialog with RadioBox

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use Wx qw( wxID_ANY wxDEFAULT_DIALOG_STYLE wxDefaultPosition wxDefaultSize wxVERTICAL 
		   wxEXPAND wxBOTTOM wxALL wxOK wxCANCEL wxRESIZE_BORDER wxRA_SPECIFY_ROWS 
		   wxNOT_FOUND );

use parent -norequire => qw( Wx::Dialog );

=head1 SYNOPSIS

Dialog like a wxSingleChoiceDialog, just with a RadioBox.

    use Wx::Perl::RadioBoxDialog;

    my $dlg = Wx::Perl::RadioBoxDialog->new(
    	undef,
		"Testmessage",
		'Testcaption',
		[ qw( a b c d e ) ],
    );
    $dlg->ShowModal;
    $dlg->Destroy;

=head1 METHODS

=head2 new

Parameter:

	Wx::Window $parent
	String $message
	String $caption
	Arrayref $choices = []
	$style = wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER
	Wx::Point $pos = undef
	Wx::Size $size = undef
	Int $id = wxID_ANY

If pos is not defined, the Dialog is centered.

If size is not defined, the Dialog try to Fit in Best Size

=cut

sub new {
	my ( $class, $parent, $message, $caption, $choices, $style, $pos, $size, $id ) = @_;
	
	my $centre = defined $pos  ? 0 : 1;
	my $fit    = defined $size ? 0 : 1;
	
	$style //= wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER;
	$id    //= wxID_ANY;	
	$pos   //= wxDefaultPosition;
	$size  //= wxDefaultSize;
	
	my $this = $class->SUPER::new( $parent, $id, $caption, $pos, $size, $style );
	
	$this->{choices} = $choices;
	
	$this->initialize;
	$this->SetMessage( $message );
	
	$this->Centre if $centre;	
	
	$this->Fit if $fit;
	
	return $this;
}

=head2 GetSelection

Returns the index of the selected item or wxNOT_FOUND if no item is selected. 

=cut

sub GetSelection {
	my $this = shift;
	
	$this->{radioBox}->GetSelection;
}

=head2 GetStringSelection

Returns the selected string or undef, if no item is selected 

=cut

sub GetStringSelection {
	my $this = shift;
	
	my $selection = $this->GetSelection;
	return undef if $selection == wxNOT_FOUND;
	return $this->{choices}[ $selection ];
}

=head2 SetSelection( $selection )

Sets the selection to the given item.

=cut

sub SetSelection {
	my ( $this, $selection ) = @_;
	
	return $this->{radioBox}->SetSelection( $selection );
}

=head2 SetStringSelection( $string );

Sets the selection to the given string. Does nothing if the string is not found

=cut

sub SetStringSelection {
	my ( $this, $string ) = @_;
	
	my $i = 0;
	for my $choice ( @{ $this->{choices} } ) {
		if ( $choice eq $string ) {
			return $this->SetSelection( $i );
		}
		$i++;
	}
	
	return 0;
}

=head2 ShowModal

Shows the dialog, returning either wxID_OK or wxID_CANCEL. 

=cut

sub ShowModal {
	my $this = shift;
	
	return $this->SUPER::ShowModal( @_ );
}

# TODO ..

#sub ShowDialog {
#	my $this = shift;
#	
#	
#}

=head2 SetMessage( $message )

=cut

sub SetMessage {
	my ( $this, $message ) = @_;
	
	$this->{message}->SetLabel( $message );
}

=head1 INTERNAL METHODS

=head2 initialize

=cut

sub initialize {
	my $this = shift;
	
	$this->{message}  = Wx::StaticText->new( $this, wxID_ANY, '' );
	$this->{radioBox} = Wx::RadioBox->new( 
		$this, wxID_ANY, '', 
		wxDefaultPosition, wxDefaultSize,
		$this->{choices},
		0, wxRA_SPECIFY_ROWS
	);
	
	my $sizerMain = Wx::BoxSizer->new( wxVERTICAL );
	my $sizerRand = Wx::BoxSizer->new( wxVERTICAL );
	
	$sizerRand->Add( $this->{message}, 0, wxEXPAND | wxBOTTOM, 5 );
	$sizerRand->Add( $this->{radioBox}, 0, wxBOTTOM | wxEXPAND, 10 );
	$sizerRand->AddStretchSpacer( 1 );
	$sizerRand->Add( $this->CreateSeparatedButtonSizer( wxOK | wxCANCEL ), 0, wxEXPAND );
	
	$sizerMain->Add( $sizerRand, 1, wxEXPAND | wxALL, 10 );
	
	$this->SetSizer( $sizerMain );
	$this->SetAutoLayout( 1 );
	1;
	
}


=head1 AUTHOR

Tarek Unger, C<< <tu2 at gmx.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-wx-perl-radioboxdialog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx-Perl-RadioBoxDialog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Wx::Perl::RadioBoxDialog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Wx-Perl-RadioBoxDialog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Wx-Perl-RadioBoxDialog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Wx-Perl-RadioBoxDialog>

=item * Search CPAN

L<http://search.cpan.org/dist/Wx-Perl-RadioBoxDialog/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Tarek Unger.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Wx::Perl::RadioBoxDialog
