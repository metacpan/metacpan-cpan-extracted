#############################################################################
## Name:        lib/Wx/DemoModules/wxClipboard.pm
## Purpose:     wxPerl demo helper for Wx::Clipboard
## Author:      Mattia Barbon
## Modified by:
## Created:     12/09/2001
## RCS-ID:      $Id: wxClipboard.pm 3082 2011-07-04 16:40:16Z mdootson $
## Copyright:   (c) 2001, 2003, 2006, 2011 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::DND;

package Wx::DemoModules::wxClipboard;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw(:dnd wxTheClipboard wxNullBitmap);
use Wx::Event qw(EVT_BUTTON);

use Wx::DemoModules::lib::DataObjects;

__PACKAGE__->mk_ro_accessors( qw(text image) );

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( $_[0], -1 );

  my $copy = Wx::Button->new( $this, -1, 'Copy Text', [ 20, 20 ] );
  my $paste = Wx::Button->new( $this, -1, 'Paste', [ 120, 20 ] );
  my $copy_im = Wx::Button->new( $this, -1, 'Copy Image', [ 20, 50 ] );

  $this->{text} = Wx::StaticText->new( $this, -1, '', [ 220, 20 ] );
  $this->{image} = Wx::StaticBitmap->new( $this, -1, wxNullBitmap,
                                          [ 220, 150 ], [ 100, 100 ] );

  EVT_BUTTON( $this, $copy, \&OnCopyText );
  EVT_BUTTON( $this, $paste, \&OnPaste );
  EVT_BUTTON( $this, $copy_im, \&OnCopyImage );

  my $copy_both = Wx::Button->new( $this, -1, 'Copy Both', [ 20, 80 ] );
  EVT_BUTTON( $this, $copy_both, \&OnCopyBoth );

  # this does NOT work on WinXP
  my $copy_pd = Wx::Button->new( $this, -1, 'Copy Data', [ 20, 110 ] );
  EVT_BUTTON( $this, $copy_pd, \&OnCopyData );

  # wxTheClipboard->UsePrimarySelection( 0 );

  return $this;
}

sub _Copy {
  my $data = shift;

  wxTheClipboard->Open;
  wxTheClipboard->SetData( $data );
  wxTheClipboard->Close;
}

sub OnCopyText {
  my( $this, $event ) = @_;

  _Copy( get_text_data_object() );
  Wx::LogMessage( "Copied some text" );
}

sub OnCopyImage {
  my( $this, $event ) = @_;

  _Copy( get_bitmap_data_object() );
  Wx::LogMessage( "Copied an image" );
}

sub OnCopyBoth {
  my( $this, $event ) = @_;

  _Copy( get_text_bitmap_data_object() );
  Wx::LogMessage( "Copied both text and image" );
}

sub OnCopyData {
  my( $this, $event ) = @_;
  my $PerlData = { fruit => 'lemon', colour => 'yellow' };
  _Copy( get_perl_data_object( $PerlData ) );
  Wx::LogMessage( "Copied perl data object: fruit=$PerlData->{fruit}, colour=$PerlData->{colour}" );
}

sub OnPaste {
  my( $this, $event ) = @_;

  wxTheClipboard->Open;

  my $text = '';
  
  # The cliboard may contain a composite object
  # in which case, for GTK at least, we need to
  # check for wxDF_UNICODETEXT in addition to
  # wxDF_TEXT.
  # wxDF_UNICODETEXT may not be wrapped in the 
  # version of Wx installed, so we may have to use
  # a workaround.
  
  my $unicodetext_wxwidgets_id = 13;
  my $unicodetextformat = ( defined(&Wx::wxDF_UNICODETEXT) ) 
    ? wxDF_UNICODETEXT() : Wx::DataFormat->newNative( $unicodetext_wxwidgets_id );
  
  if( wxTheClipboard->IsSupported( wxDF_TEXT ) || wxTheClipboard->IsSupported( $unicodetextformat ) ) {
    my $data = Wx::TextDataObject->new;
    my $ok = wxTheClipboard->GetData( $data );
    if( $ok ) {
      Wx::LogMessage( "Pasted text data" );
      $text = $data->GetText;
    } else {
      Wx::LogMessage( "Error pasting text data" );
      $text = '';
    }
  }
  
  $this->text->SetLabel( $text );

  my $bitmap = wxNullBitmap;
  if( wxTheClipboard->IsSupported( wxDF_BITMAP ) ) {
    my $data = Wx::BitmapDataObject->new;
    my $ok = wxTheClipboard->GetData( $data );
    if( $ok ) {
      Wx::LogMessage( "Pasted bitmap data" );
      $bitmap =  $data->GetBitmap;
    } else {
      Wx::LogMessage( "Error pasting bitmap data" );
      $bitmap = wxNullBitmap;
    }
  }
  $this->image->SetBitmap( $bitmap );

  # testing the perl data object
  my $data = get_perl_data_object();
  Wx::LogMessage( "Testing if clipboard supports: " . $data->GetFormat->GetId() );
  if( wxTheClipboard->IsSupported( $data->GetFormat ) ) {
    Wx::LogMessage( "It does: get data from clipboard" );
    my $ok = wxTheClipboard->GetData( $data );
    if( $ok ) {
      Wx::LogMessage( "Pasted perl data object" );
      my $PerlData = $data->GetPerlData();
      foreach (keys %$PerlData) {
          $text .= "$_ = $PerlData->{$_} ";
      }
    } else {
      Wx::LogMessage( "Error pasting perl data object" );
      $text = '';
    }
    $this->text->SetLabel( $text );
  }

  wxTheClipboard->Close;
}

sub add_to_tags { qw(dnd) }
sub title { 'wxClipboard' }

1;
