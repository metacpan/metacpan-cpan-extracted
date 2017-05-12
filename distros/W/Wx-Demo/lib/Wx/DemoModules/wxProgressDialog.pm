#############################################################################
## Name:        lib/Wx/DemoModules/wxProgressDialog.pm
## Purpose:     wxPerl demo helper for Wx::ProgressDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     28/08/2002
## RCS-ID:      $Id: wxProgressDialog.pm 3488 2013-04-16 22:02:47Z mdootson $
## Copyright:   (c) 2002, 2005-2006, 2013 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxProgressDialog;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw(:progressdialog);
use Wx::Event qw(EVT_BUTTON);

__PACKAGE__->mk_ro_accessors( qw(max_progress) );


my $ver29 = ( $Wx::wxVERSION >= 2.009001 );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );

    my $progress = Wx::Button->new( $self, -1, 'Progress dialog',
                                    [ 100, 10 ] );
    $self->{max_progress} = Wx::TextCtrl->new( $self, -1, 20, [10, 10] );

    EVT_BUTTON( $self, $progress, \&on_progress );

    return $self;
}

sub on_progress {
    my( $self, $event ) = @_;
    my( $max ) = $self->max_progress->GetValue;
    my $flags = wxPD_CAN_ABORT|wxPD_AUTO_HIDE|wxPD_APP_MODAL|wxPD_ELAPSED_TIME|
                wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME;
                
    my $ver30 = ( $Wx::wxVERSION >= 2.009001 );
    
    if( $ver30 ) {
        $flags |= wxPD_CAN_SKIP;
    }

    my $dialog = Wx::ProgressDialog->new( 'Progress dialog example',
                                          'An informative message',
                                          $max, $self, $flags );

    my $continue;
    foreach my $i ( 1 .. $max ) {
        sleep 1;
        if( $i == $max ) { 
            $continue = $dialog->Update( $i, "That's all, folks!" );
        } elsif( $i == int( $max / 2 ) ) {
            $continue = $dialog->Update( $i, "Only a half left" );
        } else {
            $continue = $dialog->Update( $i );
        }
        last unless $continue;
    }
    unless( $continue ) {
       if($ver30) {
           my $reason = ( $dialog->WasCancelled ) ? 'Cancelled' : 'Skipped';
           my $remains = $dialog->GetValue;
           Wx::LogMessage(qq(User $reason Progress Dialog with value at $remains));
       } else {
           Wx::LogMessage(qq(User Cancelled Progress Dialog));
       }
    } else {
       Wx::LogMessage( qq(Countdown from $max completed));
    }

    

    $dialog->Destroy;
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxProgressDialog' }

1;
