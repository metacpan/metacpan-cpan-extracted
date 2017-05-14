######################################################################
# Modified on January  4, 1998 to correct order of insertion problem #
# Modified on January  7, 1998 to add slider decoration              #
# Modified on January  9, 1998 to correct color name problem         #
# Modified on January 27, 1998 to correct inaccurate border layout   #
# Modified on January 27, 1998 to use proper notify method overload  #
# Modified on January 27, 1998 added -padafter and -padbefore params #
#                              for controlling size of inner widget  #
# Modified on April 6, 1998    Incorporated into release library     #
######################################################################
#                       THIS IS THE CORRECT ONE                      #
######################################################################

package Tk::SplitFrame;

use Tk;
use Tk::ChildNotification;
use Tk::Derived;
use Tk::Widget;
use Tk::Frame;

use base qw (Tk::Derived Tk::Widget Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.02';

Tk::Widget->Construct ('SplitFrame');

sub Populate
   {
    my ($this) = (shift, @_);

    $this->SUPER::Populate (@_);

    my $l_LastBorder = $this->Component
       (
        'Frame' => 'LastBorder',
        '-relief' => 'sunken',
       );

    my $l_FirstBorder = $this->Component
       (
        'Frame' => 'FirstBorder',
        '-relief' => 'sunken',
       );

    my $l_Slider = $this->Component
       (
        'Frame' => 'Slider',
        '-relief' => 'sunken',
        '-borderwidth' => 0,
        '-relief' => 'flat',
       );

    $l_Slider->bind ('<ButtonRelease-1>' => sub {$this->SliderReleased();});
    $l_Slider->bind ('<ButtonPress-1>' => sub {$this->SliderClicked();});
    $l_Slider->bind ('<B1-Motion>' => sub {$this->SliderMoved();});
    $this->bind ('<Configure>' => sub {$this->Redraw();});
    $this->bind ('<Map>' => sub {$this->Redraw();});

    $this->Advertise (FirstBorder => $l_FirstBorder);
    $this->Advertise (LastBorder => $l_LastBorder);
    $this->Advertise (Slider => $l_Slider);

    my $l_BaseColor = $this->cget ('-background');

    $this->ConfigSpecs
       (
        '-orientation' => [['SELF', 'PASSIVE'], 'orientation', 'Orientation', 'vertical'],
        '-trimcolor'   => [['SELF', 'PASSIVE'], 'trimcolor','trimcolor', $l_BaseColor],
        '-background'  => ['SELF','background', 'Background', $l_BaseColor],
        '-borderwidth' => ['METHOD', 'borderwidth', 'BorderWidth', 2],
        '-sliderposition' => ['METHOD', 'sliderposition', 'SliderPosition', 60],
        '-sliderwidth' => [['SELF', 'PASSIVE'], 'SliderWidth', 'SliderWidth', 7],
        '-relief'      => [['SELF', 'PASSIVE'], 'relief', 'Relief', 'flat'],
        '-height'      => [['SELF', 'PASSIVE'], 'height', 'Height', 100],
        '-width'       => [['SELF', 'PASSIVE'], 'width', 'Width', 100],
        '-opaque'      => [['SELF', 'PASSIVE'], 'opaque', 'Opaque', 1],
        '-trimcount'   => [['SELF', 'PASSIVE'], 'trimCount', 'TrimCount', 5],
        '-padbefore'   => [['SELF', 'PASSIVE'], 'padbefore', 'PadBefore', 0],
        '-padafter'    => [['SELF', 'PASSIVE'], 'padafter', 'PadAfter', 0],
       );

    return $this;
   }

sub Redraw
   {
    my ($l_Cursor, $this) = (undef, shift, @_);

    my ($l_FirstClient, $l_LastClient) = @{$this->{m_ClientList}};
    my $l_FirstBorderWidth = $this->cget ('-borderwidth');
    my $l_LastBorderWidth = $this->cget ('-borderwidth');
    my $l_Foreground = $this->cget ('-trimcolor');
    my $l_Background = $this->cget ('-background');
    my $l_FirstBorder = $this->Subwidget ('FirstBorder');
    my $l_LastBorder = $this->Subwidget ('LastBorder');
    my $l_Slider = $this->Subwidget ('Slider');
    my $l_Position = $this->cget ('-sliderposition');
    my $l_SliderWidth = $this->cget ('-sliderwidth');
    my @l_FirstDimensions = (0, 0, 0, 0);
    my @l_LastDimensions = (0, 0, 0, 0);
    my $l_Height = $this->height();
    my $l_Width = $this->width();

    $l_FirstBorder->configure
       (
        '-borderwidth' => $l_FirstBorderWidth,
        '-background' => $l_Foreground,
       );

    $l_LastBorder->configure
       (
        '-borderwidth' => $l_LastBorderWidth,
        '-background' => $l_Foreground,
       );

    if ($l_FirstClient->class() eq $this->class())
       {
        $l_FirstBorder->configure ('-borderwidth' => 0, '-relief' => 'flat');
        $l_FirstBorderWidth = 0;
       }

    if ($l_LastClient->class() eq $this->class())
       {
        $l_LastBorder->configure ('-borderwidth' => 0, '-relief' => 'flat');
        $l_LastBorderWidth = 0;
       }

    if ($this->cget ('-orientation') eq 'vertical')
       {
        $l_Slider->place
           (
            '-x' => $l_Position,
            '-y' => 0,
            '-width' => $l_SliderWidth,
            '-height' => $l_Height,
           );

        $l_FirstBorder->place
           (
            '-x' => $l_FirstDimensions [0] = 0,
            '-y' => $l_FirstDimensions [1] = 0,
            '-width' => $l_FirstDimensions [2] = $l_Position,
            '-height' => $l_FirstDimensions [3] = $l_Height,
           );

        $l_LastBorder->place
           (
            '-x' => $l_LastDimensions [0] = $l_Position + $l_SliderWidth,
            '-y' => $l_LastDimensions [1] = 0,
            '-width' => $l_LastDimensions [2] = $l_Width - ($l_Position + $l_SliderWidth),
            '-height' => $l_LastDimensions [3] = $l_Height,
           );

        $l_Cursor = 'sb_h_double_arrow';
       }
    else
       {
        $l_Slider->place
           (
            '-x' => 0,
            '-y' => $l_Position,
            '-width' => $l_Width,
            '-height' => $l_SliderWidth,
           );

        $l_FirstBorder->place
           (
            '-x' => $l_FirstDimensions [0] = 0,
            '-y' => $l_FirstDimensions [1] = 0,
            '-width' => $l_FirstDimensions [2] = $l_Width,
            '-height' => $l_FirstDimensions [3] = $l_Position,
           );

        $l_LastBorder->place
           (
            '-x' => $l_LastDimensions [0] = 0,
            '-y' => $l_LastDimensions [1] = $l_Position + $l_SliderWidth,
            '-width' => $l_LastDimensions [2] = $l_Width,
            '-height' => $l_LastDimensions [3] = $l_Height - ($l_Position + $l_SliderWidth),
           );

        $l_Cursor = 'sb_v_double_arrow';
       }

    if (Exists ($l_FirstClient))
       {
        $this->Advertise (FirstClient => $l_FirstClient);
        $this->Advertise (LastClient => $l_FirstClient);
        $l_FirstClient->packForget();

        $l_FirstClient->place
           (
            '-x' => $l_FirstDimensions [0] + $l_FirstBorderWidth,
            '-y' => $l_FirstDimensions [1] + $l_FirstBorderWidth,
            '-width' => $l_FirstDimensions [2] - ($l_FirstBorderWidth * 2),
            '-height' => $l_FirstDimensions [3] - ($l_FirstBorderWidth * 2),
           );

        $l_FirstClient->GeometryRequest
           (
            $l_FirstDimensions [2] - ($l_FirstBorderWidth * 2),
            $l_FirstDimensions [3] - ($l_FirstBorderWidth * 2),
           );
       }

    if (Exists ($l_LastClient))
       {
        $this->Advertise (LastClient => $l_LastClient);

        $l_LastClient->packForget();

        $l_LastClient->place
           (
            '-x' => $l_LastDimensions [0] + $l_LastBorderWidth,
            '-y' => $l_LastDimensions [1] + $l_LastBorderWidth,
            '-width' => $l_LastDimensions [2] - ($l_LastBorderWidth * 2),
            '-height' => $l_LastDimensions [3] - ($l_LastBorderWidth * 2),
           );

        $l_LastClient->GeometryRequest
           (
            $l_LastDimensions [2] - ($l_LastBorderWidth * 2),
            $l_LastDimensions [3] - ($l_LastBorderWidth * 2),
           );
       }

    $l_Slider->configure
       (
        '-background' => $l_Foreground,
        '-cursor' => $l_Cursor,
       );

    $this->RedrawTrim();
   }

sub SliderClicked
   {
    my ($this) = (shift, @_);

    if ((my $l_Slider = $this->Subwidget ('Slider'))->IsMapped())
       {
        $l_Slider->{m_Offset} =
           (
            $this->cget ('-orientation') eq 'vertical' ?
            $l_Slider->pointerx() - $l_Slider->rootx()  :
            $l_Slider->pointery() - $l_Slider->rooty()
           );
       }
   }

sub SliderMoved
   {
    my ($this) = (shift, @_);

    if ((my $l_Slider = $this->Subwidget ('Slider'))->IsMapped())
       {
        my $l_BorderWidth = ($this->cget ('-borderwidth') || 1) * 2;
        my $l_Vertical = $this->cget ('-orientation') eq 'vertical';
        my $l_PadBefore = $this->cget ('-padbefore');
        my $l_PadAfter = $this->cget ('-padafter');

        my $l_Limit =
           (
            $l_Vertical ?
            $this->width() :
            $this->height()
           ) - ($l_PadAfter + $l_BorderWidth);

        my $l_Position =
           (
            $l_Vertical ?
            $this->pointerx() - $this->rootx() :
            $this->pointery() - $this->rooty()
           );

        if ($l_Position > $l_Limit)
           {
            $l_Position = $l_Limit;
           }
        elsif ($l_Position < $l_BorderWidth + $l_PadBefore)
           {
            $l_Position = $l_BorderWidth + $l_PadBefore;
           }

        $this->configure
            (
             '-sliderposition' => $l_Position - $l_Slider->{m_Offset}
            );
       
        $this->Redraw() if ($this->cget ('-opaque'));
       }
   }

sub SliderReleased()
   {
    $_[0]->Redraw() if (! $_[0]->cget ('-opaque'));
   }

sub RedrawTrim
   {
    my $this = shift;

    if (Exists (my $l_Slider = $this->Subwidget ('Slider')))
       {
        my $l_Horizontal = $this->cget ('-orientation') eq 'vertical' ? 0 : 1;
        my $l_Count = $this->cget ('-trimcount');

        for (my $l_Index = 0; $l_Index < $l_Count && $l_Count >= 0; ++$l_Index)
           {
            my $l_Widget;

            if (! Exists ($l_Widget = $l_Slider->Subwidget ('Trim_'.$l_Index)))
               {
                $l_Widget = $l_Slider->Component
                   (
                    'Frame' => 'Trim_'.$l_Index,
                    '-borderwidth' => 2,
                    '-relief' => 'raised',
                    '-width' => ($l_Horizontal ? 25 : 2),
                    '-height' => ($l_Horizontal ? 2 : 25),
                    '-background' => 'white',
                   );

                $l_Widget->bind ('<ButtonPress-1>' => sub {$this->SliderClicked();});
                $l_Widget->bind ('<B1-Motion>' => sub {$this->SliderMoved();});
               }

            my $l_Where = (($l_Index - int ($l_Count / 2)) * 3) + 1;

            $l_Widget->place
               (
                '-relx' => 0.5,
                '-rely' => 0.5,
                '-x' => ($l_Horizontal ? 0 : $l_Where),
                '-y' => ($l_Horizontal ? $l_Where : 0),
                '-anchor' => 'center',
               );
           }

        $l_Slider->raise();
       }
   }

sub borderwidth
   {
    my ($this, $p_BorderWidth) = (shift, @_);
    $this->{m_BorderWidth} = $p_BorderWidth if (defined ($p_BorderWidth));
    return $this->{m_BorderWidth};
   }

sub sliderposition
   {
    my ($this, $p_SliderPosition) = (shift, @_);

    if (defined ($p_SliderPosition))
       {
        $this->{m_SliderPosition} = $p_SliderPosition;
        $this->Redraw() if ($this->ismapped());
       }

    return $this->{m_SliderPosition};
   }

sub ChildNotification
   {
    my ($this, $p_Child) = (shift, @_);
    my $l_Name = $p_Child->name();

    if ($l_Name ne 'lastBorder' && $l_Name ne 'firstBorder' && $l_Name ne 'slider')
       {
        push (@{$this->{m_ClientList}}, $p_Child);
        $p_Child->packForget();
       }
   }

1;

__END__

=cut

=head1 NAME

Tk::SplitFrame - a geometry manager for scaling two subwidgets

=head1 SYNOPSIS

    use Tk;

    use Tk::SplitFrame;

    my $MainWindow = MainWindow->new();

    my $SplitFrame = $MainWindow->SplitFrame
       (
        '-orientation' => 'vertical',
        '-trimcolor'  => '#c7c7c7',
        '-background'  => 'white',
        '-sliderposition' => 60,
        '-borderwidth' => 2,
        '-sliderwidth' => 7,
        '-relief'      => 'sunken',
        '-height'      => 100,
        '-width'       => 100,
        '-padbefore'   => 0,
        '-padafter'    => 0
       );

    # Values shown above are defaults.

    my $LeftLabel = $SplitFrame->Label ('-text' => 'Left');

    my $RightLabel = $SplitFrame->Label ('-text' => 'Right');

    $SplitFrame->pack (-expand => true, -fill => both);

    $SplitFrame->configure ('-sliderposition' => 22);

    Tk::MainLoop;

=head1 DESCRIPTION

A SplitFrame is a geometry manager for the two subwidgets instantiated
against it. It has a sliding divider between them which, when moved, resizes
them so that they each remain in contact with it.

The divider can be arranged vertically or horizontally at create time. The
children our arranged in the order that they are instantiated, from left to
right or from top to bottom. After instantiation, the order is fixed. The children
should NOT be packed or placed, the split frame is responsible for this.

The split frame will adjust itself initially to the preferred size of the
children.

It is a basic frame itself and can be packed or placed wherever needed in other
frames or toplevel windows.

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

Based on the split windows that you see all the time in Windows, Mac, Java, etc.

=head1 HISTORY 
 
October 1997: Actually started using it

=cut
