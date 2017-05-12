#############################################################################
## Name:        lib/Wx/DemoModules/lib/DataObjects.pm
## Purpose:     wxPerl demo helper
## Author:      Mattia Barbon
## Modified by:
## Created:     12/09/2001
## RCS-ID:      $Id: DataObjects.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::DND;

package Wx::DemoModules::lib::DataObjects;

use strict;
use base qw(Exporter); # for Perl 5.8.1 or earlier

use Wx qw(:brush :pen :bitmap);

our @EXPORT = qw(get_image get_perl_data_object get_bitmap_data_object
                 get_text_data_object get_text_bitmap_data_object);

sub get_image {
  my $bitmap = Wx::Bitmap->new( 100, 100 );
  my $dc = Wx::MemoryDC->new;
  $dc->SelectObject( $bitmap );

  my @brushes = ( wxWHITE_BRUSH, wxBLUE_BRUSH, wxGREEN_BRUSH,
                  wxGREY_BRUSH, wxCYAN_BRUSH );
  $dc->SetBrush( @brushes[rand(5)] );
  $dc->DrawRectangle( 0, 0, 100, 100 );

  $dc->SetPen( wxBLACK_PEN );
  $dc->SetBrush( new Wx::Brush( 'yellow', wxSOLID ) );

  $dc->DrawEllipse( 1, 1, 98, 98 );

  $dc->SetBrush( wxWHITE_BRUSH );
  $dc->DrawEllipse( 20, 20, 25, 25 );
  $dc->DrawEllipse( 100 - 45, 20, 25, 25 );

  $dc->SelectObject( wxNullBitmap );

  return $bitmap;
}

sub get_bitmap_data_object {
  return Wx::BitmapDataObject->new( get_image() );
}

sub get_text_data_object {
  return Wx::TextDataObject->new( "Hello, wxPerl!" );
}

sub get_text_bitmap_data_object {
  my $data = Wx::DataObjectComposite->new;
  my $text = <<EOT;
This is a yellow face.
EOT
  $text =~ s/\n/\r\n/g;

  $data->Add( Wx::TextDataObject->new( $text ) );
  $data->Add( Wx::BitmapDataObject->new( get_image() ), 1 );

  return $data;
}

sub get_perl_data_object {
    return Wx::DemoModules::lib::DataObjects::Perl->new( @_ );
}

package Wx::DemoModules::lib::DataObjects::Perl;

use strict;
use base qw(Wx::PlDataObjectSimple);

use Storable qw(freeze thaw);

sub new {
    my( $class, $data ) = @_;
    my $self = $class->SUPER::new( Wx::DataFormat->newUser( __PACKAGE__ ) );
	$self->{Data} = $data;
    return $self;
}

sub SetData {
    my( $self, $data ) = @_;
    $self->{Data} = thaw $data ;
    return 1;
}

sub GetDataHere {
    my ($self) = @_;
    return freeze $self->{Data} if ref $self->{Data};
}

sub GetDataSize {
    my( $self ) = @_;
    return length freeze $self->{Data} if ref $self->{Data};
}

sub GetPerlData { $_[0]->{Data} }

1;
