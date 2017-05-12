package Wx::Perl::BrowseButton;

=head1 NAME

Wx::Perl::BrowseButton - a file/directory browse control

=head1 SYNOPSIS

    use Wx::Perl::BrowseButton qw(:everything);

    my $browse = Wx::Perl::BrowseButton->new
        ( $parent, $id, '/home/mbarbon', $position, $size, wxPL_BROWSE_FILE,
          $validator );
    $browse->SetPath( 'C:\\Program Files' );
    my $path = $browse->GetPath

    EVT_PL_BROWSE_PATH_CHANGED( $handler, $browse->GetId, sub {
        my( $self, $event ) = @_;
        print 'New path: ', $event->GetPath;
    };

=head1 DESCRIPTION

This simple control displays a text input field asociated with a browse
button. The user can either type the path inside the text field or click
the browse button to open a file/directory browser.

The control sends a 'path changed' event when either the path is set using
the browse dialog or the control loses focus after the contents of the input
field have been changed using the keyboard.

=cut

use strict;
use Wx 0.26;
use Wx qw(:filedialog :dirdialog wxID_OK wxDefaultValidator);
use Wx::Locale qw(:default);
use Wx::Event qw(EVT_BUTTON EVT_KILL_FOCUS);
use File::Spec 0.80;

use base qw(Wx::PlWindow Exporter);

our $VERSION = 0.01;
our @EXPORT_OK = qw(wxPL_BROWSE_DIR wxPL_BROWSE_FILE
                    EVT_PL_BROWSE_PATH_CHANGED);
our %EXPORT_TAGS = ( 'everything'   => \@EXPORT_OK,
                     'event'        => [ qw(EVT_PL_BROWSE_PATH_CHANGED) ],
                    );

=head1 CONSTANTS

=over 4

=item wxPL_BROWSE_DIR

browse for a directory

=item wxPL_BROWSE_FILE browse for a file

=back

=cut

sub wxPL_BROWSE_DIR() { 0x4000 }
sub wxPL_BROWSE_FILE() { 0x2000 }

my $mask_out = ~( wxPL_BROWSE_DIR | wxPL_BROWSE_FILE );

=head1 EVENTS

=over 4

=item EVT_PL_BROWSE_PATH_CHANGED( $handler, $id, $function )

Called when the path is changed using the browse button or the path
is typed directly in the input field and the field loses focus.

=back

=cut

my $evt_change = Wx::NewEventType;

sub EVT_PL_BROWSE_PATH_CHANGED($$$) { $_[0]->Connect( $_[1], -1, $evt_change, $_[2] ) }

=head1 METHODS

=head2 new

    my $browse = Wx::Perl::BrowseButton->new
        ( $parent, $id, $initial_path, $position, $size, $style, $validator );

Creates a new browse button.

=cut

sub new {
    my( $class, $parent, $id, $path, $pos, $size, $style, $validator ) = @_;
    my $self = $class->SUPER::new( $parent, $id, $pos || [-1, -1],
                                   $size || [-1, -1], 0 );

    $self->SetValidator( $validator || wxDefaultValidator );

    $self->{style} = $style;
    $self->{input} = Wx::TextCtrl->new( $self, -1, $path );
    $self->{browse} = Wx::Button->new( $self, -1, gettext( "&Browse" ) );
    $self->{old_path} = '';

    EVT_BUTTON( $self, $self->{browse}, \&_OnBrowse );
    EVT_KILL_FOCUS( $self->{input}, \&_OnFocus );

    return $self;
}

sub DoMoveWindow {
    my( $self, $x, $y, $w, $h ) = @_;
    my $browse_x = $w - $self->{browse}->GetSize->x;

    $self->SUPER::DoMoveWindow( $x, $y, $w, $h );
    $self->{browse}->Move( $browse_x, 0 );
    $self->{input}->SetSize( 0, 0, $browse_x - 5, -1 );
}

sub DoGetBestSize {
    my( $self ) = @_;
    my( $bro_bs, $in_bs ) = map { $_->GetBestSize } @{$self}{qw(browse input)};

    return Wx::Size->new( $bro_bs->x + $in_bs->x + 5,
                          $bro_bs->y > $in_bs->y ? $bro_bs->y : $in_bs->y );
}

sub Enable {
    my( $self, $enable ) = @_;

    $self->{browse}->Enable( $enable );
    $self->{input}->Enable( $enable );

    return $self->SUPER::Enable( $enable );
}

=head2 GetPath

    my $path = $browse->GetPath;

Returns the path currently displayed in the input field.

=head2 SetPath

    $browse->SetPath( $path );

Sets the path displayed in the input field. It does not send a 'path changed'
event.

=cut

sub GetPath {
    my $self = shift;

    return $self->{input}->GetValue;
}

sub SetPath {
    my( $self, $value ) = @_;

    $self->{input}->SetValue( $value );
    $self->{old_path} = $value;
}

sub _OnFocus {
    my( $input, $event ) = @_;
    my $self = $input->GetParent;

    if( $self->GetPath ne $self->{old_path} ) {
        my $event =
          Wx::Perl::BrowseButton::Event->new( $evt_change, $self->GetId );

        $event->SetPath( $self->GetPath );
        $self->GetEventHandler->ProcessEvent( $event );
        $self->{old_path} = $self->GetPath;
    }
}

sub _OnBrowse {
    my( $self, $event ) = @_;
    my( $dir, $file ) = ( '', '' );

    if( length $self->GetPath ) {
        if( $self->{style} & wxPL_BROWSE_DIR ) {
            $dir = $self->GetPath;
        } else {
            my( $v, $d, $f ) =
              File::Spec->splitpath( $self->GetPath );
            $file = $f;
            $dir = File::Spec->catpath( $d, $f, '' );
        }
    }

    my $dialog;

    if( $self->{style} & wxPL_BROWSE_DIR ) {
        $dialog = Wx::DirDialog->new( $self, gettext( "Choose a directory" ),
                                      $dir, $self->{style} & $mask_out );
    } else {
        $dialog = Wx::FileDialog->new( $self, gettext( "Choose a file" ),
                                       $dir, $file,
                                       wxFileSelectorDefaultWildcardStr,
                                       $self->{style} & $mask_out );
    }

    if( $dialog->ShowModal == wxID_OK ) {
        my $event =
          Wx::Perl::BrowseButton::Event->new( $evt_change, $self->GetId );

        $self->SetPath( $dialog->GetPath );
        $event->SetPath( $dialog->GetPath );
        $self->GetEventHandler->ProcessEvent( $event );
    }
}

package Wx::Perl::BrowseButton::Event;

use strict;
use base qw(Wx::PlCommandEvent);

sub new {
    my( $class, $type, $id ) = @_;
    my $self = $class->SUPER::new( $type, $id );

    return $self;
}

sub SetPath { $_[0]->{path} = $_[1] }
sub GetPath { $_[0]->{path} }

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2005 Mattia Barbon <mbarbon@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself
