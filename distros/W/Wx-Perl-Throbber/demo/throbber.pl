#############################################################################
## Name:        throbber.pl
## Purpose:     Wx::Perl::Throbber demo
## Author:      Simon Flack
## Modified by: $Author: simonflack $ on $Date: 2004/04/17 22:22:44 $
## Created:     19/03/2004
## RCS-ID:      $Id: throbber.pl,v 1.1 2004/04/17 22:22:44 simonflack Exp $
#############################################################################

use strict;
use Wx;
use Wx::Perl::Carp;

package MyThrobber_App;
use vars '@ISA';
@ISA = 'Wx::App';

sub OnInit {
    my $self = shift;
    my $frame = MyThrobber_Frame->new('Wx::Perl::Throbber demo',
                                      Wx::wxDefaultPosition(),
                                      Wx::wxDefaultSize(),
                                      );
    $self -> SetTopWindow ($frame);
    $frame -> Show(1);
    1;
}

package MyThrobber_Frame;
use vars '@ISA';
@ISA = 'Wx::Frame';

use FindBin;
use Wx::XRC;
use Wx qw(:everything);
use Wx::Perl::Throbber 'EVT_UPDATE_THROBBER';
use Wx::Event qw/EVT_UPDATE_UI EVT_MENU EVT_BUTTON EVT_CHECKBOX EVT_SPINCTRL
                 EVT_TEXT/;
use File::Spec::Functions ':ALL';

sub new {
    my $class = shift;
    my ($title, $pos, $size) = @_;

    my $no_resize = wxDEFAULT_FRAME_STYLE ^ (wxRESIZE_BORDER | wxMAXIMIZE_BOX);
    my $self = $class->SUPER::new (undef, -1, $title, $pos, $size, $no_resize);
    $self -> SetIcon (Wx::GetWxPerlIcon());

    my $filemenu = new Wx::Menu;
    my $helpmenu = new Wx::Menu;
    my $menubar = new Wx::MenuBar;
    my $exit_id = Wx::NewId;
    my $about_id = Wx::NewId;
    $filemenu -> Append ($exit_id, 'E&xit');
    $helpmenu -> Append ($about_id, '&About');
    $menubar -> Append ($filemenu, '&File');
    $menubar -> Append ($helpmenu, '&Help');
    $self -> SetMenuBar ($menubar);
    EVT_MENU ($self, $exit_id, sub {$self -> Close(1)});
    EVT_MENU ($self, $about_id, \&OnAbout);

    $self -> {xrc} = new Wx::XmlResource();
    $self -> {xrc} -> InitAllHandlers;
    $self -> {xrc} -> Load (catfile ($FindBin::RealBin, 'main.xrc'));
    $self -> {panel} = $self -> {xrc} -> LoadPanel ($self, 'main_panel');

    # Add the throbbers
    Wx::InitAllImageHandlers;
    $self -> {throbber_frame}     = throbber_frames    ($self, [34, 34]);
    $self -> {throbber_composite} = throbber_composite ($self, [48, 48]);

    $self -> {xrc} -> AttachUnknownControl('main_throbber_frame',
                                           $self -> {throbber_frame});
    $self -> {xrc} -> AttachUnknownControl('main_throbber_comp',
                                           $self -> {throbber_composite});

    # Set the best size for this frame
    my $bestsize = $self -> {panel} -> GetBestSize;
    $bestsize = [$bestsize -> GetWidth + 10, $bestsize -> GetHeight + 10];
    $self -> SetClientSize($self->{panel}->GetBestSize);
# XXX
#    $self -> {panel} -> SetClientSize ($bestsize);

    # Layout
    my $sizer = new Wx::BoxSizer (wxVERTICAL);
    $sizer -> Add ($self -> {panel}, 1, wxALIGN_CENTRE|wxEXPAND);
    $self  -> SetSizer ($sizer);
    $sizer -> Layout();
    $self  -> _init();

    return $self;
}

sub find_window {
    my $self = shift;
    return $self -> {panel} -> FindWindow (Wx::XmlResource::GetXRCID(shift));
}

sub _init {
    my $self = shift;

    my %ctrl = (
        gauge           => $self -> find_window ('main_gauge'),
        txt_tlabel      => $self -> find_window ('main_txt_tlabel'),
        spin_framedelay => $self -> find_window ('main_spin_framedelay'),
        chk_tlabel      => $self -> find_window ('main_chk_tlabel'),
        chk_overlay     => $self -> find_window ('main_chk_overlay'),
        chk_reverse     => $self -> find_window ('main_chk_reverse'),
        btn_tlabel      => $self -> find_window ('main_btn_tlabel'),
        btn_start       => $self -> find_window ('main_btn_start'),
        btn_pause       => $self -> find_window ('main_btn_pause'),
        btn_stop        => $self -> find_window ('main_btn_stop'),
        btn_reverse     => $self -> find_window ('main_btn_reverse'),
    );

    my $throbber_f = $self -> {throbber_frame};
    my $throbber_c = $self -> {throbber_composite};
    $throbber_f -> SetToolTip ('Throbber with individual frames');
    $throbber_c -> SetToolTip ('Throbber using a composite bitmap');

    # Load the defaults from the controls
    foreach my $throbber ($throbber_f, $throbber_c) {
        $throbber -> SetFrameDelay  ($ctrl {spin_framedelay} -> GetValue);
        $throbber -> SetLabel       ($ctrl {txt_tlabel} -> GetValue);
        $throbber -> ShowLabel      ($ctrl {chk_tlabel} -> IsChecked);
        $throbber -> SetOverlay     (throbber_overlay());
        $throbber -> ShowOverlay    ($ctrl {chk_overlay} -> IsChecked);
        $throbber -> SetAutoReverse ($ctrl {chk_reverse} -> IsChecked);
    }

    # Button Actions
    EVT_BUTTON($self, $ctrl {btn_start},
        sub {$throbber_f -> Start(); $throbber_c -> Start()});
    EVT_BUTTON($self, $ctrl {btn_pause},
        sub {$throbber_f -> Stop(); $throbber_c -> Stop()});
    EVT_BUTTON($self, $ctrl {btn_stop},
        sub {$throbber_f -> Rest(); $throbber_c -> Rest()});
    EVT_BUTTON($self, $ctrl {btn_reverse},
        sub {$throbber_f -> Reverse(); $throbber_c -> Reverse()});
    EVT_BUTTON($self, $ctrl {btn_tlabel},
        sub {
            $throbber_f -> SetLabel($ctrl {txt_tlabel} -> GetValue);
            $throbber_c -> SetLabel($ctrl {txt_tlabel} -> GetValue);
        });

    # Enable/Disable stop, start and pause buttons
    EVT_UPDATE_UI($self, $ctrl {btn_start},
        sub {$_[1]->Enable(!$throbber_f -> IsRunning)});
    EVT_UPDATE_UI($self, $ctrl {btn_pause},
        sub {$_[1]->Enable($throbber_f -> IsRunning)});
    EVT_UPDATE_UI($self, $ctrl {btn_stop},
        sub {$_[1]->Enable( # throbbers running or not at frame 0
           $throbber_f -> IsRunning
        || ($throbber_f -> GetCurrentFrame() != 0
            && $throbber_c -> GetCurrentFrame() != 0)
        )});
    EVT_UPDATE_UI($self, $ctrl {btn_reverse},
        sub {$_[1]->Enable($throbber_f -> IsRunning)});

    # Set the frame delay
    my $set_delay = sub {
        my $frameDelay = $ctrl {spin_framedelay}->GetValue;
        $throbber_f -> SetFrameDelay ($frameDelay);
        $throbber_c -> SetFrameDelay ($frameDelay);
    };
    EVT_SPINCTRL($self, $ctrl {spin_framedelay}, $set_delay);
    EVT_TEXT    ($self, $ctrl {spin_framedelay}, $set_delay);

    # Throbber properties/styles
    EVT_CHECKBOX($self, $ctrl {chk_reverse},
        sub {
            $throbber_f -> SetAutoReverse($_[1]->IsChecked);
            $throbber_c -> SetAutoReverse($_[1]->IsChecked);
        });
    EVT_CHECKBOX($self, $ctrl {chk_tlabel},
        sub {
            $throbber_f -> ShowLabel($_[1]->IsChecked);
            $throbber_c -> ShowLabel($_[1]->IsChecked);
        });
    EVT_CHECKBOX($self, $ctrl {chk_overlay},
        sub {
            $throbber_f -> ShowOverlay($_[1]->IsChecked);
            $throbber_c -> ShowOverlay($_[1]->IsChecked);
        });

    # Throbber Event
    $ctrl {gauge} -> SetRange (100);
    EVT_UPDATE_THROBBER($throbber_f, sub {$self -> ShowGauge(@_)});
}

sub throbber_frames {
    my ($parent, $size) = @_;

    my $bitmap_path = catfile($FindBin::RealBin, 'images');
    my @bitmaps;
    push @bitmaps, new Wx::Bitmap(catfile($bitmap_path, 'rest.png'),
                                 wxBITMAP_TYPE_PNG);
    for (1 .. 30) {
        my $name = sprintf "%03d.png", $_;
        my $bitmap = new Wx::Bitmap(catfile($bitmap_path, $name),
                                    wxBITMAP_TYPE_PNG);
        push @bitmaps, $bitmap;
    }

    return new Wx::Perl::Throbber($parent, -1, \@bitmaps, wxDefaultPosition,
                                  $size);
}

sub throbber_composite {
    my ($parent, $size) = @_;

    my $bitmap_path = catfile($FindBin::RealBin, 'images');
    my $bitmap = new Wx::Bitmap(catfile($bitmap_path, 'eclouds.png'),
                                wxBITMAP_TYPE_PNG);
    return new Wx::Perl::Throbber($parent, -1, $bitmap, wxDefaultPosition,
                                  $size, undef, 12, 48);
}

sub throbber_overlay {
    my $bitmap_path = catfile($FindBin::RealBin, 'images');
    my $bitmap = new Wx::Bitmap(catfile($bitmap_path, 'logo.png'),
                                wxBITMAP_TYPE_PNG);
}

sub ShowGauge {
    my ($self, $throbber, $evt) = @_;

    my $gauge = $self -> find_window ('main_gauge');
    my $curval = $gauge -> GetValue() || 1;
    if (++$curval == 101) {
        $curval = 1;
    }
    $gauge -> SetValue ($curval);
    $evt -> Skip;
}

sub OnAbout {
    my ($self, $evt) = @_;
    my $about = <<ABOUT;
    Wx::Perl::Throbber $Wx::Perl::Throbber::VERSION
    Author:  Simon Flack
    CPAN ID: SIMONFLK
ABOUT
    Wx::MessageBox ($about,"Wx::Perl::Throbber demo", Wx::wxOK(), $self);
}

##############################################################################

package main;
use vars '$VERSION';
$VERSION = sprintf'%d.%02d', q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;

my $demo = new MyThrobber_App;
$demo -> MainLoop;
