#############################################################################
## Name:        lib/Wx/DemoModules/wxValidator.pm
## Purpose:     wxPerl demo helper
## Author:      Mattia Barbon
## Modified by:
## Created:     15/08/2005
## RCS-ID:      $Id: wxValidator.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxValidator;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx::Event qw(EVT_BUTTON);
use Wx::Perl::TextValidator;

__PACKAGE__->mk_ro_accessors( qw(numeric string) );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( $_[0], -1 );

    # filtered text controls
    my $numval = Wx::Perl::TextValidator->new( '\d' );
    my $charval = Wx::Perl::TextValidator->new( qr/[a-zA-z ]/ );

    Wx::StaticText->new( $self, -1, 'Type numbers', [10, 10] );
    my $t1 = $self->{numeric} = Wx::TextCtrl->new( $self, -1, '', [10, 30] );
    Wx::StaticText->new( $self, -1, 'Type spaces/letters', [10, 60] );
    my $t2 = $self->{string} = Wx::TextCtrl->new( $self, -1, '', [10, 80] );

    $t1->SetValidator( $numval );
    $t2->SetValidator( $charval );

    EVT_BUTTON( $self, Wx::Button->new( $self, -1, 'Validator and dialog',
                                        [10, 120] ),
                sub { Wx::DemoModules::wxValidator::Dialog
                        ->new( $self )->ShowModal } );
    EVT_BUTTON( $self, Wx::Button->new( $self, -1, 'Validator and frame',
                                        [150, 120] ),
                sub { Wx::DemoModules::wxValidator::Frame
                        ->new( $self )->Show( 1 ) } );

    return $self;
}

sub add_to_tags { qw(misc) }
sub title { 'wxValidator' }

package Wx::DemoModules::wxValidator::Validator;

use strict;
use base qw(Wx::Perl::TextValidator);

# trivial class, just to log method calls
sub Validate {
    my $self = shift;

    Wx::LogMessage( "In Validate(): data is '%s'", 
                    $self->GetWindow->GetValue );

    return $self->SUPER::Validate( @_ );
}

sub TransferFromWindow {
    my $self = shift;

    Wx::LogMessage( "In TransferFromWindow(): data is '%s'", 
                    $self->GetWindow->GetValue );

    return $self->SUPER::TransferFromWindow( @_ );
}

sub TransferToWindow {
    my $self = shift;

    # peeking at internals; naughty me...
    Wx::LogMessage( "In TransferToWindow(): data is '%s'",
                    ${$self->{data}} );

    return $self->SUPER::TransferToWindow( @_ );
}

package Wx::DemoModules::wxValidator::Dialog;

use strict;
use base qw(Wx::Dialog);

use Wx qw(wxID_OK wxID_CANCEL);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'Dialog' );

    $self->{data} = $parent->numeric->GetValue;

    # simple numeric validator
    my $numval = Wx::DemoModules::wxValidator::Validator
      ->new( '\d', \($self->{data}) );

    Wx::StaticText->new( $self, -1, 'Type numbers', [10, 10] );
    my $t1 = Wx::TextCtrl->new( $self, -1, '', [10, 30] );

    $t1->SetValidator( $numval );

    # the validation/data transfer phase are automatic for a
    # dialog where the Ok button has ID wxID_OK, otherwise
    # an explicit call to Validate/TransferDataFromWindow is required
    # when closing the dialog
    Wx::Button->new( $self, wxID_OK, "Ok", [10, 60] );
    Wx::Button->new( $self, wxID_CANCEL, "Cancel", [100, 60] );

    return $self;
}

sub get_data { $_[0]->{data} }

package Wx::DemoModules::wxValidator::Frame;

use strict;
use base qw(Wx::Frame);

use Wx::Event qw(EVT_BUTTON);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'Frame' );

    $self->{data} = $parent->string->GetValue;

    my $strval = Wx::DemoModules::wxValidator::Validator
      ->new( '[a-zA-Z ]', \($self->{data}) );

    Wx::StaticText->new( $self, -1, 'Type spaces/letters', [10, 10] );
    my $t1 = Wx::TextCtrl->new( $self, -1, '', [10, 30] );

    $t1->SetValidator( $strval );

    EVT_BUTTON( $self, Wx::Button->new( $self, -1, "Ok", [10, 60] ),
                sub {
                    if( !$self->Validate ) {
                        Wx::LogMessage( "Data is invalid" );
                        return;
                    }
                    if( !$self->TransferDataFromWindow ) {
                        Wx::LogMessage( "Error in data transfer" );
                        return;
                    }
                    $self->Destroy;
                } );

    EVT_BUTTON( $self, Wx::Button->new( $self, -1, "Cancel", [100, 60] ),
                sub {
                    $self->Destroy;
                } );

    $self->TransferDataToWindow;

    return $self;
}

sub get_data { $_[0]->{data} }

1;
