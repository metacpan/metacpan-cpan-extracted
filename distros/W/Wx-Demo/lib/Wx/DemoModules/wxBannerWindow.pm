#############################################################################
## Name:        lib/Wx/DemoModules/wxBannerWindow.pm
## Purpose:     wxPerl demo helper for Wx::BannerWindow
## Author:      Mark Dootson
## Created:     19/03/2012
## RCS-ID:      $Id: wxBannerWindow.pm 3229 2012-03-19 04:05:07Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxBannerWindow;

use strict;
use Wx;
use base qw(Wx::Panel);
use Wx qw( :sizer :bitmap :id);
use Wx::Event;

our $VERSION = '0.01';

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent,  wxID_ANY );
    
	#get our logo
	my $logo = Wx::Bitmap->new(
			Wx::Demo->get_data_file( qq(bannerwindow/demologo.png) ),
			wxBITMAP_TYPE_PNG );
	
	my $top = Wx::BannerWindow->new($self, wxTOP);
	$top->SetBitmap( $logo );
	
	my $left = Wx::BannerWindow->new($self, wxLEFT);
	$left->SetText('Welcome to the banner demo page!',
				   qq(This is a default wxLEFT banner with some text.\nThe banner on the top uses a bitmap.));
	
	my $right = Wx::BannerWindow->new($self, wxRIGHT);
	$right->SetText('Custom Banner', 'You can change the gradient colours');
	$right->SetGradient(Wx::Colour->new(127,127,127),
						Wx::Colour->new(255,255,255));
	
	my $bottom = Wx::BannerWindow->new($self, wxBOTTOM);
	$bottom->SetText('Too Many Banners', 'Perhaps you should only use one banner on a panel?');
	$bottom->SetGradient(Wx::Colour->new(255,255,255),
						 Wx::Colour->new(255,127,127));
	
    my $msizer = Wx::BoxSizer->new(wxHORIZONTAL);
	my $vsizer = Wx::BoxSizer->new(wxVERTICAL);
    $msizer->Add($left,0, wxALL|wxEXPAND, 0);
	
	$vsizer->Add($top,0, wxALL|wxEXPAND, 0);
	$vsizer->AddStretchSpacer(1);
	$vsizer->Add($bottom,0, wxALL|wxEXPAND, 0);
	
	$msizer->Add($vsizer, 1, wxLEFT|wxRIGHT|wxEXPAND, 5);
	$msizer->Add($right,0, wxALL|wxEXPAND, 0);
    $self->SetSizerAndFit($msizer);
	
    return $self;
}

sub add_to_tags { qw(new windows) }
sub title { 'wxBannerWindow' }


#Skip loading if no native wxTreeListCtrl
return defined(&Wx::BannerWindow::new);
