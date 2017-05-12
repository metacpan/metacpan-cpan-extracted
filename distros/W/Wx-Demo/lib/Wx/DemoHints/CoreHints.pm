#############################################################################
## Name:        lib/Wx/DemoHints/CoreHints.pm
## Purpose:     wxPerl demo hint helper for Wx::BannerWindow
## Author:      Mark Dootson
## Created:     26/03/2012
## RCS-ID:      $Id: CoreHints.pm 3480 2013-04-16 10:48:42Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

# this file contains hints for all the wx core modules
# for an example of a standalone file that an external
# module might add, see Wx/DemoHints/wxBannerWindow.pm

use strict;
use warnings;
use Wx;

package Wx::DemoHints::CoreHints;

our @hintpackages = ();

sub hint_packages { return @hintpackages; }

#------------------------------------------------------------

package 
    Wx::DemoHints::Base;

#------------------------------------------------------------

use strict;

use base qw(Wx::Panel);
use Wx qw(:sizer);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );
    my $sizer = Wx::BoxSizer->new( wxVERTICAL );
    my $msg = $self->hint_message;
    my $display = Wx::StaticText->new($self, -1, $msg );
    $sizer->Add($display, 1, wxEXPAND|wxALL, 30);
    $self->SetSizer($sizer);
    return $self;
}

sub title { 'unknown' }

sub add_to_tags { qw( fail ) }

sub hint_message { 'this module could not be loaded'; }

sub file {
	my $rc = shift;
	my $class = ( ref($rc) ) ? ref($rc) : $rc;
	my $rfname = $class . '.pm';
	$rfname =~ s{::}{/}g;
	my $outname = $INC{$rfname};
	$outname =~ s{Wx/DemoHints/}{Wx/DemoModules/};
	return $outname;
}

#-------------------------------------------------------

package 
    Wx::DemoHints::CoreHintBase;

#-------------------------------------------------------
use base qw( Wx::DemoHints::Base );

sub register_hint { push(@Wx::DemoHints::CoreHints::hintpackages, $_[0]); }

sub file {
	my $rc = shift;
	my $class = ( ref($rc) ) ? ref($rc) : $rc;
	my $rfname = $class . '.pm';
	$rfname =~ s{::}{/}g;
	$rfname =~ s{Wx/DemoHints/}{Wx/DemoModules/};
	my $firstinc = $INC{'Wx/DemoHints/CoreHints.pm'};
	$firstinc =~ s{Wx/DemoHints/CoreHints.pm}{$rfname};
	return $firstinc if -e $firstinc;
	
	# maybe we are loaded from a different path to module
	# if we have a defautl rule for an external module
	my $checkpath;
	for my $incpath ( @INC ) {
		$checkpath = qq($incpath/$rfname);
		last if -e $checkpath;
	}
	unless( $checkpath && -e $checkpath ) {
		# we must return a filepath or Demo will crash
		# so return this file.
		# It shouldn't be possible to actually
		# get here - but .....
		$checkpath = $INC{'Wx/DemoHints/CoreHints.pm'};
	}
	return $checkpath;
}

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxPropertyGrid;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { eval { return Wx::_wx_optmod_propgrid(); }; }
sub title { 'wxPropertyGrid' }
sub hint_message { 'Wx::PropertyGrid requires Wx >= 0.9905 and wxWidgets >= 2.9.3'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxRichToolTip;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { eval { return Wx::_wx_optmod_propgrid(); }; }
sub title { 'wxRichToolTip' }
sub hint_message { 'Wx::RichToolTip requires Wx >= 0.9906 and wxWidgets >= 2.9.3'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxInfoBar;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { defined(&Wx::InfoBar::new); }
sub title { 'wxInfoBar' }
sub hint_message { 'Wx::InfoBar requires Wx >= 0.9906 and wxWidgets >= 2.9.3'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxTimePickerCtrl;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { defined(&Wx::TimePickerCtrl::new); }
sub title { 'wxTimePickerCtrl' }
sub hint_message { 'Wx::TimePicker requires Wx >= 0.9906 and wxWidgets >= 2.9.3'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxHeaderCtrl;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { defined &Wx::HeaderCtrl::new; }
sub title { 'wxHeaderCtrl' }
sub hint_message { 'Wx::PlHeaderCtrl requires wxWidgets >= 2.9.0'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxHeaderCtrlSimple;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { defined &Wx::HeaderCtrlSimple::new; }
sub title { 'wxHeaderCtrlSimple' }
sub hint_message { 'Wx::HeaderCtrlSimple requires wxWidgets >= 2.9.0'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxWebView;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { eval { return Wx::_wx_optmod_webview(); }; }
sub title { 'wxWebView' }
sub hint_message { 'Wx::WebView requires wxWidgets >= 2.9.3, Wx >= 0.9906 and an available backend on your system'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxRibbonControl;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { eval { return Wx::_wx_optmod_ribbon(); }; }
sub title { 'wxRibbonControl' }
sub hint_message { 'Wx::RibbonControl requires wxWidgets >= 2.9.3 and Wx >= 0.9905'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxTreeListCtrl;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { (Wx::wxVERSION < 2.009) }
sub title { 'wxTreeListCtrl' }
sub hint_message { 'Wx::TreeListCtrl from CPAN cannot work with wxWidgets >= 2.9.0'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxNativeTreeListCtrl;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { defined &Wx::PlTreeListItemComparator::new; }
sub title { 'wxTreeListCtrl (native)' }
sub hint_message { 'The Native Wx::TreeListCtrl requires Wx >= 0.9906 and wxWidgets >= 2.9.3. For wxWidgets 2.8.x you can use the Wx::TreeListCtrl module from CPAN.'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxGraphicsContext;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { defined &Wx::GraphicsContext::Create; }
sub title { 'wxGraphicsContext' }
sub hint_message { 'Your wxWidgets was not compiled with wxGraphicsContext support'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxOverlay;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { eval { my $olay = Wx::Overlay->new; }; ( $@ ) ? 0 : 1; }
sub title { 'wxOverlay' }
sub hint_message { 'Your Wx + wxWidgets version combination does not support wxOverlay'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxMediaCtrl;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { local $@; eval { require Wx::Media }; defined &Wx::MediaCtrl::new; }
sub title { 'wxMediaCtrl' }
sub hint_message { 'Your wxWidgets was not compiled with wxMediaCtrl support'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxPrintPaperDatabase;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { require Wx::Print; return defined(&Wx::PrintPaperDatabase::FindPaperTypeById); }
sub title { 'wxPrintPaperDatabase' }
sub hint_message { 'wxPrintPaperDatabase requires Wx >= 0.9909'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxRearrangeCtrl;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { return defined(&Wx::RearrangeCtrl::new); }
sub title { 'wxRearrangeCtrl' }
sub hint_message { 'wxRearrangeCtrl requires Wx >= 0.9914 and wxWidgets >= 2.9.4'; }

#---------------------------------------------------------------------------
package
	Wx::DemoHints::wxCommandLinkButton;
use base qw( Wx::DemoHints::CoreHintBase );
__PACKAGE__->register_hint;
sub can_load { return defined(&Wx::CommandLinkButton::new); }
sub title { 'wxCommandLinkButton' }
sub hint_message { 'wxCommandLinkButton requires Wx >= 0.9922 and wxWidgets >= 2.9.2'; }


1;

