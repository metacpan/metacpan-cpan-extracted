#############################################################################
## Name:        lib/Wx/DemoHints/wxBannerWindow.pm
## Purpose:     wxPerl demo hint helper for Wx::BannerWindow
## Author:      Mark Dootson
## Created:     26/03/2012
## RCS-ID:      $Id: wxBannerWindow.pm 3246 2012-03-26 17:22:01Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################
use strict;
use warnings;

package Wx::DemoHints::wxBannerWindow;
use Wx;
use base qw( Wx::DemoHints::Base );

sub can_load { defined(&Wx::BannerWindow::new); }

sub title { 'wxBannerWindow' }

sub hint_message { 'Wx::BannerWindow requires Wx >= 0.9906 and wxWidgets >= 2.9.3'; }

1;

