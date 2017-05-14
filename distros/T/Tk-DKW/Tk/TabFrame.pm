package Tk::TabFrame;

use Tk;
use Tk::ChildNotification;
use Tk::Frame;
use Tk::Label;

use base qw (Tk::Derived Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.01';

Tk::Widget->Construct ('TabFrame');

sub Populate
   {
    my $this = shift;

    my $l_ButtonFrame = $this->{m_ButtonFrame} = $this->Component
       (
        'Frame' => 'ButtonFrame',
        '-borderwidth' => 0,
        '-relief' => 'flat',
        '-height' => 40,
       );

    my $l_ClientFrame = $this->{m_ClientFrame} = $this->Component
       (
        'TabChildFrame' => 'TabChildFrame',
        '-relief' => 'flat',
        '-borderwidth' => 0,
        '-height' => 60,
       );

    my $l_MagicFrame = $this->Component
       (
        'Frame' => 'MagicFrame',
       );

    $l_ButtonFrame->pack
       (
        '-anchor' => 'nw',
        '-side' => 'top',
        '-fill' => 'x',
       );

    $l_ClientFrame->pack
       (
        '-side' => 'top',
        '-expand' => 'true',
        '-fill' => 'both',
       );

    $this->ConfigSpecs
       (
        '-borderwidth' => [['SELF', 'PASSIVE'], 'borderwidth', 'BorderWidth', '1'],
        '-tabcurve' => [['SELF', 'PASSIVE'], 'tabcurve', 'TabCurve', 2],
        '-padx' => [['SELF', 'PASSIVE'], 'padx', 'padx', 5],
        '-pady' => [['SELF', 'PASSIVE'], 'pady', 'pady', 5],
        '-font' => ['METHOD', 'font', 'Font', undef],
        '-current' => ['METHOD'],
        '-raised' => ['METHOD'],

        # These are historical. Their use is deprecated

        '-trimcolor' => ['PASSIVE', 'trimcolor','trimcolor', undef],
        '-bottomedge' => ['PASSIVE', 'bottomedge', 'BottomEdge', undef],
        '-sideedge' => ['PASSIVE', 'sideedge', 'SideEdge', undef],
        '-tabstart' => ['PASSIVE', 'tabstart', 'TabStart', undef],
       );

    $l_ClientFrame->bind ('<Map>' => sub {$this->configure ('-current' => $this->{m_Raised});});
    $this->Delegates ('Construct' => $l_ClientFrame);
    $this->SUPER::Populate (@_);
    return $this;
   }

sub TabCreate
   {
    my ($this, $p_Widget, $p_Caption, $p_Color) = (shift, @_);

    my $l_Previous =
       (
        defined (${$this->{m_ClientList}}[-1]) ?
        $this->{m_ButtonFrame}->Subwidget ('Button_'.${$this->{m_ClientList}}[-1])->Subwidget ('Button') :
        undef
       );

    my $l_TabFrame = $this->{m_ButtonFrame}->Component
       (
        'Frame' => 'Button_'.$p_Widget,
        '-foreground' => $this->cget ('-foreground'),
        '-relief' => 'flat',
        '-borderwidth' => 0,
       );

    my $l_Button = $l_TabFrame->Component
       (
        'Button' => 'Button',
        '-command' => sub {$this->configure ('-current' => $p_Widget);},
        (defined ($p_Color) ? ('-bg' => $p_Color) : ()),
        '-text' => $p_Caption || $p_Widget->name(),
        '-font' => $this->cget (-font),
        '-relief' => 'flat',
        '-borderwidth' => 0,
        '-takefocus' => 1,
        '-padx' => 2,
        '-pady' => 2,
       );

    $l_TabFrame->bind ('<ButtonRelease-1>' => sub {$l_Button->invoke();});
    $l_Button->bind ('<FocusOut>', sub {$l_Button->configure ('-highlightthickness' => 0);});
    $l_Button->bind ('<FocusIn>', sub {$l_Button->configure ('-highlightthickness' => 1);});
    $l_Button->bind ('<Control-Tab>', sub {($this->children())[0]->focus();});
    $l_Button->bind ('<Return>' => sub {$l_Button->invoke();});

    if (defined ($l_Previous))
       {
        $l_Button->bind ('<Shift-Tab>', sub {$l_Previous->focus();});
        $l_Button->bind ('<Left>', sub {$l_Previous->invoke();});
        $l_Previous->bind ('<Tab>', sub {$l_Button->focus();});
        $l_Previous->bind ('<Right>', sub {$l_Button->invoke();});
       }
        
    $this->TabBorder ($l_TabFrame);

    $this->{m_ClientFrame}->configure
       (
        '-borderwidth' => $this->cget ('-borderwidth'),
        '-relief' => 'raised',
       );

    $l_Button->configure
       (
        '-highlightcolor' => $l_Button->Darken ($l_Button->cget (-background), 50),
        '-activebackground' => $l_Button->cget (-background),
       );

    $l_Button->pack
       (
        '-expand' => 'true',
        '-fill' => 'both',
        '-ipadx' => 0,
        '-ipady' => 0,
        '-padx' => 3,
        '-pady' => 3,
       );

    $l_TabFrame->place
       (
        '-width' => ($l_Button->reqwidth() || 20) + 5,
        '-x' => $this->GetButtonRowWidth(),
        '-relheight' => 1.0,
        '-anchor' => 'nw',
       );

    $this->{m_ButtonFrame}->GeometryRequest
       (
        $this->{m_ButtonFrame}->width(),
        $this->GetButtonRowHeight() + 5,
       );

    push (@{$this->{m_ClientList}}, $p_Widget);
    return $this->TabCurrent ($p_Widget);
   }

sub TabRaise
   {
    my ($this, $p_Widget) = (shift, @_);

    my $l_ButtonFrame = $this->{m_ButtonFrame};
    my $l_TabFrame = $l_ButtonFrame->Subwidget ('Button_'.$p_Widget);
    my $l_MagicFrame = $this->Subwidget ('MagicFrame');
    my %l_Hash = $l_TabFrame->placeInfo();

    foreach my $l_Client (@{$this->{m_ClientList}})
       {
        if ($l_Client ne $p_Widget)
           {
            my $l_TabButton = $l_ButtonFrame->Subwidget ('Button_'.$l_Client);
            $l_TabButton->place ('-height' => - 5, '-y' => 5);
            $l_TabButton->lower ($l_TabFrame);
           }
       }

    $l_MagicFrame->place
       (
        '-x' => $l_Hash {'-x'},
        '-y' => $this->{m_ClientFrame}->rooty() - $this->rooty() - 1,
        '-height' => $this->{m_ClientFrame}->cget ('-borderwidth'),
        '-width' => $l_Hash {'-width'},
        '-anchor' => 'nw',
       );

    $l_MagicFrame->configure ('-bg' => $l_TabFrame->cget ('-background'));
    $l_TabFrame->place ('-height' => - 1, '-y' => 1);
    $l_TabFrame->Subwidget ('Button')->focus();
    $l_TabFrame->Subwidget ('Button')->raise();
    $l_MagicFrame->raise ();
    $l_TabFrame->raise();

    foreach my $l_Sibling ($p_Widget->parent()->children())
       {
        $l_Sibling->lower ($p_Widget) if ($l_Sibling ne $p_Widget);
       }

    $p_Widget->raise();
    return $p_Widget;
   }

sub TabBorder
   {
    my ($this, $p_TabFrame) = (shift, @_);
    my $l_LineWidth = $this->cget ('-borderwidth');
    my $l_Background = $this->cget ('-background');
    my $l_InnerBackground = $p_TabFrame->Darken ($l_Background, 120),
    my $l_Curve = $this->cget ('-tabcurve');

    my $l_LeftOuterBorder = $p_TabFrame->Frame
       (
        '-background' => 'white',
        '-borderwidth' => 0,
       );

    my $l_LeftInnerBorder = $p_TabFrame->Frame
       (
        '-background' => $l_InnerBackground,
        '-borderwidth' => 0,
       );

    my $l_TopOuterBorder = $p_TabFrame->Frame
       (
        '-background' => 'white',
        '-borderwidth' => 0,
       );

    my $l_TopInnerBorder = $p_TabFrame->Frame
       (
        '-background' => $l_InnerBackground,
        '-borderwidth' => 0,
       );

    my $l_RightOuterBorder = $p_TabFrame->Frame
       (
        '-background' => 'black',
        '-borderwidth' => 0,
       );

    my $l_RightInnerBorder = $p_TabFrame->Frame
       (
        '-background' => $p_TabFrame->Darken ($l_Background, 80),
        '-borderwidth' => 0,
       );

    $l_LeftOuterBorder->place
       (
        '-x' => 0,
        '-y' => $l_Curve - 1,
        '-width' => $l_LineWidth,
        '-relheight' => 1.0,
       );

    $l_LeftInnerBorder->place
       (
        '-x' => $l_LineWidth,
        '-y' => $l_Curve - 1,
        '-width' => $l_LineWidth,
        '-relheight' => 1.0,
       );

    $l_TopInnerBorder->place
       (
        '-x' => $l_Curve - 1,
        '-y' => $l_LineWidth,
        '-relwidth' => 1.0,
        '-height' => $l_LineWidth,
        '-width' => - ($l_Curve * 2),
       );

    $l_TopOuterBorder->place
       (
        '-x' => $l_Curve - 1,
        '-y' => 0,
        '-relwidth' => 1.0,
        '-height' => $l_LineWidth,
        '-width' => - ($l_Curve * 2),
       );

    $l_RightOuterBorder->place
       (
        '-x' => - ($l_LineWidth),
        '-relx' => 1.0,
        '-width' => $l_LineWidth,
        '-relheight' => 1.0,
        '-y' => $l_Curve,
       );

    $l_RightInnerBorder->place
       (
        '-x' => - ($l_LineWidth * 2),
        '-width' => $l_LineWidth,
        '-relheight' => 1.0,
        '-y' => $l_Curve / 2,
        '-relx' => 1.0,
       );
   }

sub TabCurrent
   {
    return
       (
        defined ($_[1]) ?
        $_[0]->TabRaise ($_[0]->{m_Raised} = $_[1]) :
        $_[0]->{m_Raised}
       );
   }

sub GetButtonRowWidth
   {
    my ($l_Width, $this) = (0, shift, @_);
    my $l_ButtonFrame = $this->{m_ButtonFrame};

    foreach my $l_Client (@{$this->{m_ClientList}})
       {
        $l_Width += $l_ButtonFrame->Subwidget ('Button_'.$l_Client)->Subwidget ('Button')->reqwidth();
       }

    return $l_Width ? $l_Width - 10 : $l_Width;
   }

sub GetButtonRowHeight
   {
    my ($l_Height, $this) = (0, shift, @_);
    my $l_ButtonFrame = $this->{m_ButtonFrame};

    foreach my $l_Client (@{$this->{m_ClientList}})
       {
        my $l_NewHeight = $l_ButtonFrame->Subwidget ('Button_'.$l_Client)->Subwidget ('Button')->reqheight();
        $l_Height = $l_NewHeight if ($l_NewHeight > $l_Height);
       }

    return $l_Height;
   }

sub Font
   {
    my ($this, $p_Font) = (shift, @_);

    return ($this->{m_Font}) unless (defined ($p_Font));

    my $l_ButtonFrame = $this->{m_ButtonFrame};

    foreach my $l_Client (@{$this->{m_ClientList}})
       {
        $l_ButtonFrame->Subwidget ('Button_'.$l_Client)->Subwidget ('Button')->configure
           (
            '-font' => $p_Font,
           );
       }

    return ($this->{m_Font} = $p_Font);
   }

sub current
   {
    shift->TabCurrent (@_);
   }

sub raised
   {
    shift->TabCurrent (@_);
   }

sub font
   {
    shift->Font (@_);
   }

1;

package Tk::TabChildFrame;

use Tk::ChildNotification;
use Tk;

use vars qw ($VERSION @ISA);

use strict;

$VERSION = '1.01';

@ISA = qw (Tk::Widget Tk::Frame);

Tk::Widget->Construct ('TabChildFrame');

sub Populate
   {
    my ($this, $p_Parameters) = (shift, @_);

    $this->SUPER::Populate (@_);

    return $this;
   }

sub QueueLayout
   {
    $_[0]->DoWhenIdle (['ExecuteLayout', $_[0]]) unless ($_[0]->{'LayoutPending'}++);
   }

sub SlaveGeometryRequest
   {
    shift->QueueLayout();
   }

sub LostSlave
   {
    shift->QueueLayout();
   }

sub ExecuteLayout
   {
    my $this = shift;

    $this->{'LayoutPending'} = 0;

    my $l_PadX = $this->parent()->cget ('-padx');
    my $l_PadY = $this->parent()->cget ('-pady');
    my $l_Height = 0;
    my $l_Width = 0;

    foreach my $l_Child ($this->children())
       {
        next unless Exists ($l_Child);

        my @l_Dimensions =
           (
            $l_Child->reqwidth(),
            $l_Child->reqheight(),
           );

        $l_Height = $l_Dimensions [1] if ($l_Dimensions [1] > $l_Height);
        $l_Width = $l_Dimensions [0] if ($l_Dimensions [0] > $l_Width);
       }

    foreach my $l_Child ($this->children())
       {
        next unless Exists ($l_Child);

        $l_Child->MoveResizeWindow
           (
            $l_PadX,
            $l_PadY,
            $l_Width,
            $l_Height,
           );

        $l_Child->MapWindow();
       }

    $this->GeometryRequest
       (
        $l_Width + ($l_PadX * 2),
        $l_Height + ($l_PadY * 2),
       );
   }

sub ChildNotification
   {
    my ($this, $p_Child, $p_Arguments) = (shift, @_);

    $p_Child->packForget();

    $this->ManageGeometry ($p_Child);

    $this->parent()->TabCreate
       (
        $p_Child,
        delete $p_Arguments->{'-caption'},
        delete $p_Arguments->{'-tabcolor'},
       );
   }

1;

__END__

=cut

=head1 NAME

Tk::TabFrame - An alternative to the NoteBook widget : a tabbed geometry manager

=head1 SYNOPSIS

    use Tk::TabFrame;

    $TabbedFrame = $widget->TabFrame
       (
        -font => '-adobe-times-medium-r-normal--20-*-*-*-*-*-*-*',
        -tabcurve => 2,
        -padx => 5,
        -pady => 5,
        [normal frame options...],
       );

    font     - font for tabs
    tabcurve - curve to use for top corners of tabs
    padx     - padding on either side of children
    pady     - padding above and below children

    $CurrentSelection = $l_Window->cget ('-current');
    $CurrentSelection = $l_Window->cget ('-raised');

    current  - (Readonly) currently selected widget
    raised   - (Readonly) currently selected widget

    $child = $TabbedFrame->Frame # can also be Button, Label, etc
       (
        -caption => 'Tab label',
        -tabcolor => 'yellow',
        [widget options...],
       );

    caption  - label text for the widget's tab
    tabcolor - background for the tab button

Values shown above are defaults.

=head1 DESCRIPTION

A tabbed frame geometry manager (like NoteBook). I haven't used
NoteBook so I can't really say what behaviour differences or
similarities there are. This widget uses direct subwidget creation
(no Add methods) and has colors for the tabs.

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

=head1 HISTORY 

January 28, 1998 : Created

February 2, 1999 : raise/lower semantics changed somehow in Tk800.012. Added
                   explicit lower calls for frame and button reordering.

=cut
