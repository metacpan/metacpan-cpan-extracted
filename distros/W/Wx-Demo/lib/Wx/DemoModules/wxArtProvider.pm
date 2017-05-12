#############################################################################
## Name:        lib/Wx/DemoModules/wxArtProvider.pm
## Purpose:     wxPerl demo helper for Wx::ArtProvider
## Author:      Matthew "Cheetah" Gabeler-Lee
## Modified by: Mattia Barbon
## Created:     11/01/2005
## RCS-ID:      $Id: wxArtProvider.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2005-2006 Matthew "Cheetah" Gabeler-Lee
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxArtProvider;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw(:sizer :checkbox);
use Wx::Event qw(EVT_CHECKBOX);

__PACKAGE__->mk_accessors( qw(icon_browser) );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );

    my $sizer = Wx::BoxSizer->new( wxHORIZONTAL );
    my $plug_provider = Wx::CheckBox->new( $self, -1, "Plug-in art provider" );
    my $browser = Wx::DemoModules::wxArtProvider::Browser->new( $self );

    $sizer->Add( $plug_provider, 0, wxALL, 5 );
    $sizer->Add( $browser, 1, wxGROW|wxALL, 5 );

    $self->SetSizer( $sizer );
    $self->icon_browser( $browser );

    EVT_CHECKBOX( $self, $plug_provider, \&OnPlugProvider );

    return $self;
}

sub OnPlugProvider {
    my( $this, $event ) = @_;

    if ($event->IsChecked) {
        Wx::ArtProvider::PushProvider(Wx::DemoModules::wxArtProvider::Custom->new);
    } else {
        Wx::ArtProvider::PopProvider;
    }
    # refresh list and currently-selected icon
    my $browser = $this->icon_browser;
    if( defined $browser->GetArtClient ) {
        $browser->SetArtClient( $browser->GetArtClient );
    }
    if( defined $browser->GetArtId ) {
        $browser->SetArtId( $browser->GetArtId );
    }
}

sub add_to_tags { qw(misc) }
sub title { 'wxArtProvider' }

package Wx::DemoModules::wxArtProvider::Browser;

use strict;
use base qw(Wx::Panel);

use Wx qw/:panel :window :sizer :listctrl :bitmap :misc :id :window/;
use Wx::Event qw(EVT_LIST_ITEM_SELECTED EVT_CHOICE);
use Wx::ArtProvider qw/:artid :clientid/;

my @artids = (
  wxART_ERROR, wxART_QUESTION, wxART_WARNING, wxART_INFORMATION,
  wxART_ADD_BOOKMARK, wxART_DEL_BOOKMARK, wxART_HELP_SIDE_PANEL,
  wxART_HELP_SETTINGS, wxART_HELP_BOOK, wxART_HELP_FOLDER, wxART_HELP_PAGE,
  wxART_GO_BACK, wxART_GO_FORWARD, wxART_GO_UP, wxART_GO_DOWN,
  wxART_GO_TO_PARENT, wxART_GO_HOME, wxART_FILE_OPEN, wxART_PRINT,
  wxART_HELP, wxART_TIP, wxART_REPORT_VIEW, wxART_LIST_VIEW, wxART_NEW_DIR,
  wxART_FOLDER, wxART_GO_DIR_UP, wxART_EXECUTABLE_FILE, wxART_NORMAL_FILE,
  wxART_TICK_MARK, wxART_CROSS_MARK, wxART_MISSING_IMAGE,
);

my @clientids = (
  wxART_OTHER, wxART_TOOLBAR, wxART_MENU, wxART_FRAME_ICON,
  wxART_CMN_DIALOG, wxART_HELP_BROWSER, wxART_MESSAGE_BOX, wxART_BUTTON,
);

sub new {
  my ( $class, $parent ) = @_;
  my $this = $class->SUPER::new( $parent, -1 );

  # create sizers and widgets
  my $sizer = Wx::BoxSizer->new(wxVERTICAL);
  my $subsizer1 = Wx::BoxSizer->new(wxHORIZONTAL);
  my $subsizer2 = Wx::BoxSizer->new(wxHORIZONTAL);
  my $subsub = Wx::BoxSizer->new(wxVERTICAL);

  my $choice = Wx::Choice->new($this, -1);
  for my $index (0 .. $#clientids) {
    $choice->Append($clientids[$index], $index);
  }

  $this->{list} = Wx::ListCtrl->new($this, -1, wxDefaultPosition, [250, 300],
    wxLC_REPORT | wxSUNKEN_BORDER);
  $this->{list}->InsertColumn(0, 'wxArtID');

  $this->{canvas} = Wx::StaticBitmap->new($this, -1,
    Wx::Bitmap->new(Wx::Demo->get_data_file('artprovider/null.xpm'), wxBITMAP_TYPE_XPM));

  # layout widgets in sizers
  $subsizer1->Add(Wx::StaticText->new($this, -1, "Client:"), 0,
    wxALIGN_CENTER_VERTICAL);
  $subsizer1->Add($choice, 1, wxLEFT, 5);
  $sizer->Add($subsizer1, 0, wxALL | wxEXPAND, 10);
  $subsizer2->Add($this->{list}, 1, wxEXPAND | wxRIGHT, 10);
  $subsub->Add($this->{canvas});
  $subsub->Add(100, 100);
  $subsizer2->Add($subsub);
  $sizer->Add($subsizer2, 1, wxEXPAND | wxLEFT | wxRIGHT, 10);

  $this->SetSizer($sizer);
  $sizer->Fit($this);

  $choice->SetSelection(6); # wxART_MESSAGE_BOX
  $this->SetArtClient(wxART_MESSAGE_BOX);

  EVT_LIST_ITEM_SELECTED($this, $this->{list}, \&OnSelectItem);
  EVT_CHOICE($this, $choice, \&OnChooseClient);

  return $this;
}

sub GetArtId { $_[0]->{artid} }

sub SetArtId {
  my( $this, $artid ) = @_;

  my $bmp = Wx::ArtProvider::GetBitmap($artid, $this->{client});
  $this->{canvas}->SetBitmap($bmp);
  $this->{canvas}->SetSize($bmp->GetWidth, $bmp->GetHeight);
  $this->{artid} = $artid;
}

sub GetArtClient { $_[0]->{client} }

sub SetArtClient {
  my $this = shift;
  my ($client) = @_;

  my $bcur = Wx::BusyCursor->new;

  # funky jazz with image list to get memory management to function
  # correctly
  my $img = Wx::ImageList->new(16, 16);
  $img->Add(Wx::Bitmap->new(Wx::Demo->get_data_file('artprovider/null.xpm'), wxBITMAP_TYPE_XPM));

  $this->{list}->DeleteAllItems;

  for my $index (0 .. $#artids) {
    my $icon = Wx::ArtProvider::GetIcon($artids[$index], $client, [16, 16]);
    my $ind = 0;
    if ($icon->Ok) {
      $ind = $img->Add($icon);
    }
    $this->{list}->InsertImageStringItem($index, $artids[$index], $ind);
    $this->{list}->SetItemData($index, $index);
  }
  $this->{list}->SetImageList($img, wxIMAGE_LIST_SMALL);
  $this->{listimg} = $img; # preserve image list in memory
  $this->{list}->SetColumnWidth(0, wxLIST_AUTOSIZE);

  $this->{client} = $client;
}

sub OnSelectItem {
  my ($this, $event) = @_;
  my $data = $event->GetData;
  $this->SetArtId( $artids[$data] );
}

sub OnChooseClient {
  my ($this, $event) = @_;
  my $data = $event->GetClientData;
  $this->SetArtClient($clientids[$data]);
}

package Wx::DemoModules::wxArtProvider::Custom;

use strict;
use base qw(Wx::PlArtProvider);

use Wx qw/:bitmap/;
use Wx::ArtProvider qw/:artid :clientid/;

sub new {
    my( $class ) = @_;
    my $this = $class->SUPER::new;

    return $this;
}

sub _bitmap {
    return Wx::Bitmap->new( Wx::Demo->get_data_file( "artprovider/$_[0]" ),
                            wxBITMAP_TYPE_XPM );
}

sub CreateBitmap {
    my( $this, $id, $client, $size ) = @_;

    if( $client eq wxART_MESSAGE_BOX ) {
        if( $id eq wxART_INFORMATION ) {
            return _bitmap( 'info.xpm' );
        } elsif( $id eq wxART_ERROR ) {
            return _bitmap( 'error.xpm' );
        } elsif( $id eq wxART_WARNING ) {
            return _bitmap( 'warning.xpm' );
        } elsif( $id eq wxART_QUESTION ) {
            return _bitmap( 'question.xpm' );
        }
    }

    return wxNullBitmap;
}

1;
