#############################################################################
## Name:        lib/Wx/DemoModules/wxHtmlWindow.pm
## Purpose:     wxPerl demo helper for wxHtmlWindow
## Author:      Mattia Barbon
## Modified by:
## Created:     12/09/2001
## RCS-ID:      $Id: wxHtmlWindow.pm 3120 2011-11-18 18:50:54Z mdootson $
## Copyright:   (c) 2001, 2004, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Html;

package Wx::DemoModules::wxHtmlWindow;

use strict;
use base qw(Wx::Panel);

use Wx qw(:sizer);
use Wx::Event qw)EVT_BUTTON);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( $_[0], -1 );

  my $html = $this->{HTML} =
    Wx::DemoModules::wxHtmlWindow::Derived->new( $this, -1 );
  my $top_s = Wx::BoxSizer->new( wxVERTICAL );

  my $but_s = Wx::BoxSizer->new( wxHORIZONTAL );
  my $print = Wx::Button->new( $this, -1, 'Print' );
  my $forward = Wx::Button->new( $this, -1, 'Forward' );
  my $back = Wx::Button->new( $this, -1, 'Back' );
  my $preview = Wx::Button->new( $this, -1, 'Preview' );
  my $pages = Wx::Button->new( $this, -1, 'Page Setup' );
  
  # my $prints = Wx::Button->new( $this, -1, 'Printer Setup' );

  $but_s->Add( $back );
  $but_s->Add( $forward );
  $but_s->Add( $preview );
  $but_s->Add( $print );
  $but_s->Add( $pages );
  # $but_s->Add( $prints );

  $top_s->Add( $html, 1, wxGROW|wxALL, 5 );
  $top_s->Add( $but_s, 0, wxALL, 5 );

  $this->SetSizer( $top_s );
  $this->SetAutoLayout( 1 );

  EVT_BUTTON( $this, $print, \&OnPrint );
  EVT_BUTTON( $this, $preview, \&OnPreview );
  EVT_BUTTON( $this, $forward, \&OnForward );
  EVT_BUTTON( $this, $back, \&OnBack );
  EVT_BUTTON( $this, $pages, \&OnPageSetup );
  
  #  EVT_BUTTON( $this, $prints, \&OnPrinterSetup );

  $this->{PRINTER} = Wx::HtmlEasyPrinting->new( 'wxPerl demo' );

  return $this;
}

sub html { $_[0]->{HTML} }
sub printer { $_[0]->{PRINTER} }

sub OnPrint {
  my( $this, $event ) = @_;

  $this->printer->PrintFile( $this->html->GetOpenedPage );
}

sub OnPageSetup {
  my $this = shift;

  $this->printer->PageSetup();
}

#sub OnPrinterSetup {
#  my $this = shift;
#
#  $this->printer->PrinterSetup();
#}

sub OnPreview {
  my( $this, $event ) = @_;

  $this->printer->PreviewFile( $this->html->GetOpenedPage );
}

sub OnForward {
  my( $this, $event ) = @_;

  $this->html->HistoryForward();
}

sub OnBack {
  my( $this, $event ) = @_;

  $this->html->HistoryBack();
}

sub tags { [ 'windows/html' => 'wxHtmlWindow' ] }
sub add_to_tags { 'windows/html' }
sub title { 'Simple' }

package Wx::DemoModules::wxHtmlWindow::Derived;

use strict;
use base qw(Wx::HtmlWindow);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( @_ );

  $this->LoadPage( Wx::Demo->get_data_file( 'html/index.html' ) );
  print $this->ToText, "\n";

  Wx::LogMessage( Wx::Demo->get_data_file( 'html/index.html' ) );
  return $this;
}

sub OnLinkClicked {
  my( $this, $link ) = @_;

  Wx::LogMessage( 'Link clicked: href="%s"', $link->GetHref() );
  $this->SUPER::OnLinkClicked( $link );
}

1;
