#=============================================================================#
#        This is public class Tk::DockPort used by Tk::DockFrame
#=============================================================================#
package Tk::DockPort;

use Tk::Frame;
use Tk;

use base qw (Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.03';

Tk::Widget->Construct ('DockPort');

1;

#=============================================================================#
# This is a private class used by Tk::DockFrame::Win32 & Tk::DockFrame::X11
#=============================================================================#
package Tk::DockFrame::Base;

use Tk::Toplevel;
use Tk::Frame;
use Tk;

use base qw (Tk::Frame Tk::Toplevel);
use strict;
use Carp;

Tk::Widget->Construct ('DockFrame::Base');

#------------------------------- Private methods -----------------------------#

sub __trimrelease
   {
    foreach my $l_Widget (@{$_[0]->{m_TrimElements}})
       {
        $l_Widget->grabRelease();
       }
   }

#-----------------------------Event-Handlers----------------------------------#

sub ButtonPressEvent
   {
    my ($this, $p_EventWidget) = @_;

    $this->undock();
    $this->Tk::raise();
    $this->__trimrelease();

    $this->{'m_Offsets'} =
       [
        $p_EventWidget->pointerx() - $this->rootx(),
        $p_EventWidget->pointery() - $this->rooty(),
       ];
   }

sub ButtonReleaseEvent
   {
    $_[0]->{'m_CantDockYet'} = undef;
    $_[0]->__trimrelease();
    $_[0]->Tk::raise();
   }

sub DragEvent
   {
    my ($this, $p_EventWidget) = @_;

    return unless ($this->toplevel() eq $this);

    $this->MoveToplevelWindow
       (
        $p_EventWidget->pointerx() - ${$this->{'m_Offsets'}}[0],
        $p_EventWidget->pointery() - ${$this->{'m_Offsets'}}[1],
       );

    $this->idletasks();

    my $l_Sensitivity = $this->cget ('-sensitivity');
    my $l_DockWidget;
    my $l_Found = 0;

    my @l_Box =
       (
        $this->rootx(),
        $this->rooty(),
        $this->width() + $this->rootx(),
        $this->height() + $this->rooty(),
       );

    foreach my $l_Child ($this->parent()->children())
       {
        next if (ref ($l_Child) ne 'Tk::DockPort' || defined ($l_Child->{'m_Client'}));

        my @l_Coords = ($l_Child->rootx(), $l_Child->rooty());

        my $l_Test =
           (
            $l_Coords [0] >= $l_Box [0] - $l_Sensitivity &&
            $l_Coords [0] <= $l_Box [2] + $l_Sensitivity &&
            $l_Coords [1] >= $l_Box [1] - $l_Sensitivity &&
            $l_Coords [1] <= $l_Box [3] + $l_Sensitivity
           );

        if (! $l_Test)
           {}
        elsif ($this->{'m_CantDockYet'})
           {
            $l_Found = 1;
           }
        else
           {
            $l_DockWidget = $l_Child;
           }
       }

    $this->dock ($l_DockWidget) if (defined ($l_DockWidget));
    $this->{'m_CantDockYet'} = undef unless ($l_Found);
    $this->Tk::raise();
    $this->idletasks();
   }

#-----------------------------'METHOD'-type-settings--------------------------#

sub trimcount
   {
    my ($this, $p_TrimCount) = (shift, @_);

    $this->{'m_TrimElements'} = [] unless (defined ($this->{'m_TrimElements'}));

    if (defined ($p_TrimCount) && $p_TrimCount >= 0)
       {
        my @l_TrimElements = @{$this->{m_TrimElements}};

        $p_TrimCount = 12 if ($p_TrimCount > 12);

        while ($p_TrimCount > $#l_TrimElements + 1)
           {
            my $l_Widget = $this->Component
               (
                'Frame' => 'TrimElement_'.($#l_TrimElements + 1),
                '-cursor' => 'fleur',
                '-relief' => 'raised',
                '-borderwidth' => 1,
                '-width' => 2,
               );

            $l_Widget->pack
               (
                '-side' => 'left',
                '-anchor' => 'nw',
                '-fill' => 'y',
                '-ipadx' => 0,
                '-padx' => 1,
                '-pady' => 1,
               );

            $l_Widget->bind ('<ButtonRelease-1>' => sub {$this->ButtonReleaseEvent ($l_Widget);});
            $l_Widget->bind ('<ButtonPress-1>' => sub {$this->ButtonPressEvent ($l_Widget);});
            $l_Widget->bind ('<B1-Motion>' => sub {$this->DragEvent ($l_Widget);});
            push @l_TrimElements, $l_Widget;
           }

        while ($p_TrimCount <= $#l_TrimElements)
           {
            (pop @l_TrimElements)->destroy();
           }

        $this->{m_TrimElements} = [@l_TrimElements];
       }

    return $#{$this->{m_TrimElements}} + 1;
   }

1;


#=============================================================================#
#             This is a private class used by Tk::DockFrame
#=============================================================================#
package Tk::DockFrame::X11;

use strict;
use Carp;

use base qw (Tk::Frame Tk::Toplevel Tk::DockFrame::Base);

Tk::Widget->Construct ('DockFrame::X11');

#------------------------------- Private methods -----------------------------#

sub Populate
   {
    my $this = shift;

    $this->SUPER::Populate (@_);

    my $l_ClientFrame = $this->Component
       (
        'Frame' => 'ClientFrame',
       );

    my $l_Spacer = $this->Component
       (
        'Frame' => 'Spacer',
       );

    $this->Delegates
       (
        'Construct' => $l_ClientFrame,
        'DEFAULT' => $l_ClientFrame,
       );

    $this->ConfigSpecs
       (
        '-dock' => ['METHOD', 'dock', 'Dock', 0],
        '-trimcount' => ['METHOD', 'trimcount', 'TrimCount', 1],
        '-sensitivity' => ['PASSIVE', 'sensitivity', 'Sensitivity', 10],
        '-decorate' => ['PASSIVE', 'decorate', 'Decorate', 0],
        '-trimgap' => ['PASSIVE', 'trimgap', 'TrimGap', 2],
        'DEFAULT' => [$l_ClientFrame],
       );

    $l_ClientFrame->pack
       (
        '-expand' => 'true',
        '-fill' => 'both',
        '-side' => 'left',
       );

    $this->configure
       (
        '-relief' => 'raised',
        '-borderwidth' => 1,
       );

    $this->bind ('<Expose>' => sub {$this->ExposeEvent();});

    return $this;
   }

#-----------------------------Event-Handlers----------------------------------#

sub ButtonPressEvent
   {
    my ($this, $p_EventWidget) = (shift, @_);
    $this->SUPER::ButtonPressEvent (@_);
    $p_EventWidget->grab();
   }

sub ExposeEvent
   {
    my $this = shift;

    my ($l_Spacer, $l_ClientFrame) =
       (
        $this->Subwidget ('Spacer'),
        $this->Subwidget ('ClientFrame')
       );

    if (defined ($l_Spacer) && defined ($l_ClientFrame))
       {
        $l_Spacer->pack
           (
            '-before' => $l_ClientFrame,
            ($#{$this->{m_TrimElements}} > -1 ? ('-after' => ${$this->{m_TrimElements}} [-1]) : ()),
            '-ipadx' => $this->cget ('-trimgap'),
            '-side' => 'left',
           );
       }

    unless (defined ($this->cget ('-dock')))
       {
        $this->MoveToplevelWindow
           (
            $this->rootx() || $this->parent()->toplevel()->rootx(),
            $this->rooty() || $this->parent()->toplevel()->rooty(),
           );

        $this->raise();
       }
   }

#------------------------------- Public methods -----------------------------#

sub dock
   {
    my ($this, $p_Dock) = (shift, @_);

    unless (defined ($p_Dock))
       {
        return $this->{'Configure'}{'-dock'};
       }

    unless ($p_Dock)
       {
        $this->DoWhenIdle (sub {$this->undock();});
        return;
       }

    unless ($this->IsMapped())
       {
        $this->DoWhenIdle (sub {$this->dock ($p_Dock);});
        $this->MapWindow();
        return ($p_Dock);
       }

    if ($this->toplevel() eq $this)
       {
        $this->resizable (1, 1);
        $this->wmCapture();
       }

    $this->DoWhenIdle
       (
        sub
           {
            my @l_SlaveList = $p_Dock->packSlaves();
            # $this->pack ('-fill' => 'both', '-after' => $p_Dock);
            $this->__trimrelease();

            $this->pack
               (
                '-expand' => 'true',
                '-in' => $p_Dock,
                '-side' => 'left',
                '-fill' => 'both',
                '-anchor' => 'nw',
                ($#l_SlaveList > -1 ? ('-before' => $l_SlaveList [0]) : ()),
               );

            $p_Dock->GeometryRequest (1, 1);
           }
       );

    return ($this->{'Configure'}{'-dock'} = $p_Dock);
   }

sub undock
   {
    my @l_Coords = ($_[0]->rootx(), $_[0]->rooty());

    if ($_[0]->toplevel() ne $_[0])
       {
        my %l_PackInfo = eval {$_[0]->packInfo();};
        my $l_DockPort = $l_PackInfo {'-in'};

        $_[0]->packForget();
        $_[0]->parent()->update();
        $_[0]->wmRelease();

        if (defined ($l_DockPort))
           {
            my @l_Slaves = $l_DockPort->packSlaves();
            $l_DockPort->GeometryRequest (0, 0) if ($#l_Slaves == -1);
           }
       }

    $_[0]->{'m_CantDockYet'} = 1;
    $_[0]->{'Configure'}{'-dock'} = undef;
    $_[0]->overrideredirect ($_[0]->{'Configure'}{'-decorate'} ? 0 : 1);
    $_[0]->resizable (0, 0);
    $_[0]->deiconify();
    $_[0]->MapWindow();
    $_[0]->MoveToplevelWindow (@l_Coords);
    $_[0]->idletasks();
   }

1;


#=============================================================================#
#             This is a private class used by Tk::DockFrame
#=============================================================================#
package Tk::DockFrame::Win32;

use base qw (Tk::Toplevel Tk::DockFrame::Base);

Tk::Widget->Construct ('DockFrame::Win32');

*Ev = \&Tk::Ev;

#------------------------------- Private methods -----------------------------#

sub Populate
   {
    my $this = shift;

    $this->SUPER::Populate (@_);

    my $l_Spacer = $this->Component
       (
        'Frame' => 'Spacer',
       );

    $this->ConfigSpecs
       (
        '-sensitivity' => ['PASSIVE', 'sensitivity', 'Sensitivity', 10],
        '-decorate' => ['PASSIVE', 'decorate', 'Decorate', 0],
        '-trimgap' => ['PASSIVE', 'trimgap', 'TrimGap', 2],
        '-trimcount' => ['METHOD', 'trimcount', 'TrimCount', 1],
        '-dock' => ['METHOD', 'dock', 'Dock', 0],
       );

    $this->configure
       (
        '-relief' => 'raised',
        '-borderwidth' => 1,
        '-takefocus' => 0,
       );

    $this->bind ('<Expose>' => sub {$this->ExposeEvent();});

    return $this;
   }

#-----------------------------Event-Handlers----------------------------------#

sub ExposeEvent
   {
    my $this = shift;

    my $l_Spacer = $this->Subwidget ('Spacer');
    my $l_ClientFrame;

    foreach my $l_Widget ($this->children())
       {
        next if ($l_Widget->name() eq 'spacer' || $l_Widget->name() =~ /^trimElement\_/);
        $l_ClientFrame = $l_Widget;
        last;
       }

    $l_Spacer->pack
       (
        ($#{$this->{m_TrimElements}} > -1 ? ('-after' => ${$this->{m_TrimElements}} [-1]) : ()),
        (defined ($l_ClientFrame) ? ('-before' => $l_ClientFrame) : ()),
        '-ipadx' => $this->cget ('-trimgap'),
        '-side' => 'left',
       );
   }

sub CheckDockEvent
   {
    my ($p_EventWidget, $this, $p_Count, $p_Width, $p_Height, $p_X, $p_Y, $p_SendEvent, $p_Type) = @_;

    my $l_MirrorFrame = $this->{'m_Mirror'};

    if ($p_Count + $p_Width + $p_Height + $p_X + $p_Y + $p_SendEvent && $l_MirrorFrame)
       {
        $this->MoveResizeWindow
           (
            $l_MirrorFrame->rootx(),
            $l_MirrorFrame->rooty(),
            $l_MirrorFrame->width(),
            $l_MirrorFrame->height()
           );

        $this->Tk::raise();
       }
    else
       {
        Tk::break;
       }
   }

sub ResizeEvent
   {
    my ($p_EventWidget, $this) = @_;

    my $l_MirrorFrame = $this->{'m_Mirror'};

    return unless (defined ($l_MirrorFrame));

    $this->MoveResizeWindow
       (
        $l_MirrorFrame->rootx(),
        $l_MirrorFrame->rooty(),
        $l_MirrorFrame->width(),
        $l_MirrorFrame->height()
       );

    $this->Tk::raise();

    Tk::break;
   }

sub MapEvent
   {
    my ($p_EventWidget, $this) = @_;

    my $l_MirrorFrame = $this->{'m_Mirror'};

    return unless (defined ($l_MirrorFrame));

    $l_MirrorFrame->IsMapped() ? $this->MapWindow() : $this->UnmapWindow();
   }

#------------------------------- Public methods -----------------------------#

sub dock
   {
    my ($this, $p_Dock) = (shift, @_);

    if (! defined ($p_Dock) || defined ($this->{'m_Mirror'}))
       {
        return $this->{'Configure'}{'-dock'};
       }

    unless ($p_Dock)
       {
        $this->DoWhenIdle (sub {$this->undock();});
        return;
       }

    unless ($this->IsMapped())
       {
        $this->DoWhenIdle (sub {$this->undock(); $this->dock ($p_Dock);});
        $this->MapWindow();
        return ($p_Dock);
       }

    my @l_SlaveList = $p_Dock->packSlaves();

    my $l_MirrorFrame = $this->{'m_Mirror'} = $p_Dock->parent()->Frame
       (
        '-width' => $this->reqwidth(),
        '-height' => $this->reqheight(),
       );

    $l_MirrorFrame->bind
       (
        '<Configure>' => [\&ResizeEvent, $this]
       );

    $l_MirrorFrame->bind
       (
        '<Map>' => [\&MapEvent, $this]
       );

    $l_MirrorFrame->bind
       (
        '<Unmap>' => [\&MapEvent, $this]
       );

    $l_MirrorFrame->bind
       (
        '<Expose>' => [\&CheckDockEvent, $this, Ev('c'), Ev('w'), Ev('h'), Ev('x'), Ev('y'), Ev('E'), Ev('T')]
       );

    $l_MirrorFrame->pack
       (
        '-expand' => 'true',
        '-in' => $p_Dock,
        '-side' => 'left',
        '-fill' => 'both',
        '-anchor' => 'nw',
        ($#l_SlaveList > -1 ? ('-before' => $l_SlaveList [0]) : ()),
       );

    $p_Dock->GeometryRequest (1, 1);
    $this->__trimrelease();
    $this->overrideredirect (1);
    $this->deiconify();
    $this->idletasks();
    $p_Dock->toplevel()->Tk::raise();
    $p_Dock->toplevel()->focus();
    return ($this->{'Configure'}{'-dock'} = $p_Dock);
   }

sub undock
   {
    my $this = shift;

    my $l_MirrorFrame = $this->{'m_Mirror'};

    if (defined ($l_MirrorFrame))
       {
        my %l_PackInfo = eval {$l_MirrorFrame->packInfo();};
        my $l_DockPort = $l_PackInfo {'-in'};

        $l_MirrorFrame->packForget();
        $l_MirrorFrame->parent()->update();
        $this->geometry (join ('x', $this->reqwidth(), $this->reqheight()));
        $this->{'m_CantDockYet'} = 1;
        $this->{'m_Mirror'} = undef;
        $l_MirrorFrame->destroy();

        if (defined ($l_DockPort))
           {
            my @l_Slaves = $l_DockPort->packSlaves();
            $l_DockPort->GeometryRequest (0, 0) if ($#l_Slaves == -1);
           }
       }

    $this->overrideredirect ($this->cget ('-decorate') ? 0 : 1);
    $this->deiconify();
    $this->idletasks();
   }

1;


#=============================================================================#
#                    This is public class Tk::DockFrame
#=============================================================================#
package Tk::DockFrame;

use base ($^O eq 'MSWin32' ? qw (Tk::DockFrame::Win32) : qw (Tk::DockFrame::X11));

use vars qw ($VERSION);

$VERSION = '2.0';

Tk::Widget->Construct ('DockFrame');

1;


#=============================================================================#
#                                   END
#=============================================================================#

__END__


=cut

=head1 NAME

Tk::DockFrame - A multicolumn list widget with sortable & sizeable columns

=head1 SYNOPSIS

    use Tk::DockFrame;

    $DockPort = $parent->DockPort();

    $DockPort->pack();

    $DockFrame = $parent->DockFrame
       (
        '-dock' => $DockPort,
        '-trimcount' => 1,
        '-sensitivity' => 10,
        '-decorate' => 0,
        '-trimgap' => 2
       );

    $DockFrame->Widget (...)->pack();

    ...

    Tk::MainLoop;

=head1 DESCRIPTION

The two public classes in this module combine to implement a dockable widget subsystem.

Objects of class DockFrame are simple frames which can be made to "float" free as Toplevel
widgets or packed as Frames. Dockframes can have any number of direct children but the
favored use is to pack a single Frame based child widget and add widgets to that
using any geometry manager.

DockPorts are simple frame widgets which must be managed by the packer. They normally
have no width or height and are thus rendered invisible. DockFrame children of the same
parentage, when dragged over them, will be converted from "floating" Toplevels into Frame
widgets rendered within the DockPort, resizing it accordingly.

=item IMPORTANT UPDATE

The DockFrames are now managed WITHIN the DockPorts, therefore any geometry manager
can be used with all the widgets described here

=head1 STANDARD OPTIONS

=over 4

=item DockFrame

I<-background -borderwidth -relief -bg -width -height>

=back

=over 4

=item DockPort

I<none>

=back

See I<Tk> for details of the standard options.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:	B<dock>

=item Class:	B<Dock>

=item Switch:	B<-dock>

Used to "dock" a DockFrame to a DockPort. The parameter passed must be
a reference to a DockPort and nothing else. If a DockPort is not specified
in this manner on creation, then the DockFrame will initially "float" free.

=back

=over 4

=item Name:	B<trimcount>

=item Class:	B<TrimCount>

=item Switch:	B<-trimcount>

Specifies the number of button trim drag 'handles'. Specifying 0 will prevent
attachment/detachment of the DockFrame.

=back

=over 4

=item Name:	B<sensitivity>

=item Class:	B<Sensitivity>

=item Switch:	B<-sensitivity>

The DockFrame will "dock" when it gets within the specified number of pixels of the DockPort.

=back

=over 4

=item Name:	B<decorate>

=item Class:	B<Decorate>

=item Switch:	B<-decorate>

Boolean value indicating whether or not to instruct the window manager to add decoration
(titlebar, etc) to the undocked DockFrame. It is important to note here that, due to the
nature of the event handling, dragging the DockFrame by the titlebar will not cause it to
dock.

=back

=over 4

=item Name:	B<trimgap>

=item Class:	B<Trimgap>

=item Switch:	B<-trimgap>

This option specifies the number of pixels to leave between the "handles" and the first
child widget

=back

=head1 WIDGET METHODS

=over 4

=item I<$DockFrame>->B<dock> (B<$DockPort>)

Immediately docks the DockFrame to the specified DockPort

=back

=over 4

=item I<$DockFrame>->B<undock>() 

Immediately undocks the DockFrame

=back

=head1 BINDINGS

=over 4

=item B<[1]>

Pressing and holding the left mouse button on a DockFrame trim element allows movement
of that DockFrame. If the DockFrame is "dragged" over a DockPort, it will "dock" and
dragging will cease until the "handle" is released and then selected again.

=back

=head1 AUTHORS

Damion K. Wilson, dwilson@ibl.bm, http://pwp.ibl.bm/~dkw

=head1 COPYRIGHT

Copyright (c) 1999 Damion K. Wilson.

All rights reserved.

This program is free software, you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 HISTORY 

=over 4

=item B<October 1, 1999>: Written to replace experimental Tk::DockingGroup with no legacy support

=back

=cut
