package Tk::ComboEntry;

use Tk::Listbox;
use Tk::Entry;
use Tk;

use base qw (Tk::Derived Tk::Frame);
use vars qw ($VERSION);
use strict;

$VERSION = '0.03';

*listheight = \&Tk::ComboEntry::ListHeight;
*state = \&Tk::ComboEntry::SelectionState;
*itemlist = \&Tk::ComboEntry::SelectionList;
*list = \&Tk::ComboEntry::SelectionList;
*listfont = \&Tk::ComboEntry::ListFont;
*invoke = \&Tk::ComboEntry::Invoke;

Tk::Widget->Construct ('ComboEntry');

sub ClassInit
   {
    $_[1]->bind ($_[0], '<Configure>', 'Configure');
    $_[1]->bind ($_[0], '<Map>', 'Configure');
    return $_[0];
   }

sub Populate
   {
    my $this = shift;

    eval
       {
        my $l_Bitmask = pack
           (
            "b8"x8,
            "..........",
            ".11111111.",
            "..111111..",
            "..111111..",
            "...1111...",
            "...1111...",
            "....11....",
            "....11....",
           );

        $this->toplevel->DefineBitmap
           (
            'downtriangle' => 8, 8, $l_Bitmask
           );
       };

    my $l_Entry = $this->Component
       (
        'Entry' => 'Entry',
        '-highlightthickness' => 1,
        '-borderwidth' => 0,
        '-relief' => 'flat',
        '-takefocus' => 1,
        '-width' => 0,
       );

    my $l_Button = $this->Component
       (
        'Button' => 'Button',
        '-bitmap' => 'downtriangle',
        '-command' => sub {$this->ButtonPressed();},
        '-highlightthickness' => 1,
        '-relief' => 'raised',
        '-borderwidth' => 1,
        '-takefocus' => 1,
        '-width' => 0,
       );

    my $l_Popup = $this->Component
       (
        'Toplevel' => 'Popup',
        '-relief' => 'raised',
        '-borderwidth' => 1,
       );

    my $l_ListBox = $l_Popup->Scrolled
       (
        'Listbox',
        '-cursor' => 'top_left_arrow',
        '-highlightthickness' => 1,
        '-selectmode' => 'browse',
        '-scrollbars' => 'osoe',
        '-relief' => 'flat',
        '-takefocus' => 1,
       );

    my $l_ActualListBox = $this->{'m_ListBox'} = $l_ListBox->Subwidget
       (
        'scrolled',
       );

    ($this->{'m_ScrollBarY'} = $l_ListBox->Subwidget ('yscrollbar'))->configure
       (
        '-borderwidth' => 1,
       );

    $l_ActualListBox->selection
       (
        'set',
        '0',
       );

    $l_Entry->bind
       (
        '<Return>' => sub {$this->DoInvokeCallback();},
       );

    $l_Popup->bind
       (
        '<ButtonPress-1>' => sub {$this->AutoHide ($l_Popup);},
       );

    $l_Button->bind
       (
        '<Return>' => sub {$l_Button->invoke();},
       );

    $l_ActualListBox->bind
       (
        '<Escape>' => sub {$this->Hide();},
       );

    $l_ActualListBox->bind
       (
        '<ButtonRelease-1>' => sub {$this->Select();},
       );

    $l_ActualListBox->bind
       (
        '<ButtonPress-3>' => sub {$this->MenuSelect();},
       );

    $l_ActualListBox->bind
       (
        '<Motion>' => sub {$this->Traverse (@_);},
       );

    $l_ActualListBox->bind
       (
        '<KeyRelease>' => [sub {$this->KeySeek (@_);}, Ev ('A')],
       );

    $l_ActualListBox->bind
       (
        '<Return>' => sub {$this->Select();},
       );

    $l_ListBox->pack
       (
        '-expand' => 'true',
        '-fill' => 'both',
        '-padx' => 0,
        '-pady' => 0,
       );

    $l_Entry->pack
       (
        '-expand' => 'true',
        '-fill' => 'both',
        '-anchor' => 'nw',
        '-side' => 'left',
        '-ipadx' => 0,
        '-ipady' => 0,
        '-padx' => 0,
        '-pady' => 0,
       );

    $l_Button->pack
       (
        '-side' => 'right',
        '-anchor' => 'ne',
        '-fill' => 'y',
        '-ipadx' => 0,
        '-ipady' => 0,
        '-padx' => 0,
        '-pady' => 0,
       );

    $this->ConfigSpecs
       (
        '-background' => [['SELF', 'METHOD', $l_Entry, $l_ListBox], 'background', 'Background', 'white'],
        '-listfont' => ['METHOD', 'font', 'Font', '-*-Times-Bold-R-Normal--*-120-*-*-*-*-*-*'],
        '-scrollbarwidth' => ['METHOD', 'scrollbarwidth', 'ScrollbarWidth', undef],
        '-borderwidth' => [['SELF', $l_Button], 'borderwidth', 'BorderWidth', 1],
        '-popupwidth' => ['METHOD', 'popupwidth', 'PopupWidth', undef],
        '-listheight' => ['METHOD', 'listheight', 'ListHeight', 90],
        '-showmenu' => ['PASSIVE', 'showmenu', 'ShowMenu', 1],
        '-state' => ['METHOD', 'state', 'State', 'normal'],
        '-selectmode' => [$l_ListBox],
        '-itemlist' => ['METHOD'],
        '-invoke' => ['METHOD'],
        '-list' => ['METHOD'],
        '-bg' => '-background',
       );

    $this->configure ('-relief' => 'sunken');
    $this->ConfigSpecs ("DEFAULT" => [$l_Entry]);
    $this->Delegates (DEFAULT => $l_Entry);
    $this->SUPER::Populate (@_);
    $this->Hide();
    return $this;
   }

sub Configure
   {
    my $this = shift;

    $this->Subwidget ('Entry')->configure
       (
        '-state' => $this->SelectionState,
       );

    $this->Subwidget ('Button')->configure
       (
        '-width' => $this->height() - ($this->cget ('-borderwidth') * 4),
       );
   }

sub ButtonPressed
   {
    $_[0]->{'m_Visible'} ? $_[0]->Hide() : $_[0]->Show();
   }

sub SelectionList
   {
    $_[0]->{m_ListBox}->delete ('0', 'end');

    foreach my $l_Entry (sort (ref ($_[1]) eq 'ARRAY' ? @{$_[1]} : @_))
       {
        chomp $l_Entry;
        $_[0]->{m_ListBox}->insert ('end', $l_Entry);
       }
   }

sub ListHeight
   {
    return ($_[0]->{'m_ListHeight'} = (defined ($_[1] && $_[1] > 2) ? $_[1] : $_[0]->{m_ListHeight}));
   }

sub ListFont
   {
    $_[0]->{m_ListBox}->configure ('-font' => $_[1]) if defined ($_[1]);
    return $_[0]->{m_ListBox}->cget ('-font');
   }

sub Invoke
   {
    return (defined ($_[1]) ? $_[0]->{m_Invoke} = $_[1] : $_[0]->{m_Invoke});
   }

sub SelectionState
   {
    return ($_[0]->{m_SelectionState}) unless (defined ($_[1]));
    $_[0]->Subwidget ('Entry')->configure ('-state' => ($_[0]->{m_SelectionState} = $_[1]));
    return ($_[0]->{m_SelectionState});
   }

sub Hide
   {
    my $this = shift;
    my $l_Popup = $this->Subwidget ('Popup');
    $l_Popup->overrideredirect (1);
    $l_Popup->transient();
    $l_Popup->withdraw();
    $l_Popup->grabRelease();
    $this->{m_Visible} = 0;
    $this->Subwidget ('Button')->focus();
   }

sub Show
   {
    my $this = shift;

    my ($l_Popup, $l_Entry) =
       (
        $this->Subwidget ('Popup'),
        $this->Subwidget ('Entry'),
       );

    my $l_Geometry =
       (
        ($this->cget ('-popupwidth') || $this->width()).
        'x'.
        ($this->{m_ListHeight} || 40).
        '+'.
        $l_Entry->rootx().
        '+'.
        ($this->rooty() + $this->height())
       );

    $l_Popup->geometry ($l_Geometry);
    $l_Popup->deiconify();
    $l_Popup->transient();
    $l_Popup->raise();
    $l_Popup->grabGlobal();

    $this->{m_ListBox}->focus();
    $this->{m_Visible} = 1;
   }

sub Select
   {
    my $this = shift;
    my $l_Entry = $this->Subwidget ('Entry');
    my $l_ListBox = $this->{m_ListBox};
    my @l_Array = ();

    $l_Entry->configure ('-state' => 'normal');
    $l_Entry->delete ('0', 'end');

    foreach my $l_Row ($l_ListBox->curselection())
       {
        push (@l_Array, $l_ListBox->get ($l_Row));
       }

    $l_Entry->insert ('0', join (',', @l_Array));
    $l_Entry->configure ('-state' => $this->{m_SelectionState});
    $this->Hide();
    $this->DoInvokeCallback();
   }

sub MenuSelect
   {
    my $this = shift;

    return unless $this->cget ('-showmenu');

    my $l_Entry = $this->Subwidget ('Entry');
    my $l_ListBox = $this->{m_ListBox};

    return unless Exists ($l_ListBox);

    my $l_Event = $l_ListBox->XEvent();
    my $l_Menu = $this->toplevel()->Subwidget ('ComboEntryMenu');

    $l_ListBox->activate
       (
        $l_ListBox->nearest ($l_Event->y())
       );

    unless (Exists ($l_Menu))
       {
        $l_Menu = $this->toplevel()->Component
           (
            'Menu' => 'ComboEntryMenu',
            '-tearoff' => 0,
           );

        $l_Menu->add
           (
            'command',
            '-label' => 'Enlarge',

            '-command' => sub
               {
                $this->configure ('-listheight' => $this->cget ('-listheight') + 10);
                $this->Show();
               },
           );

        $l_Menu->add
           (
            'command',
            '-label' => 'Reduce',

            '-command' => sub
               {
                $this->configure ('-listheight' => $this->cget ('-listheight') - 10);
                $this->Show();
               },
           );

        $l_Menu->add
           (
            'command',
            '-label' => 'Delete',
            '-command' => sub {$l_ListBox->delete ($l_ListBox->index ('active'));},
           );
       }

    if (Exists ($l_Menu))
       {
        $this->Subwidget ('Popup')->grabRelease();

        $l_Menu->Popup() if ($Tk::VERSION < 800.005);

        $l_Menu->post
           (
            $l_Event->x() + $l_ListBox->rootx(),
            $l_Event->y() + $l_ListBox->rooty(),
           );
       }
   }

sub DoInvokeCallback
   {
    if (ref ($_[0]->{'m_Invoke'}) eq 'CODE' || ref ($_[0]->{'m_Invoke'}) eq 'Tk::Callback')
       {
        $_[0]->afterIdle ([$_[0]->{m_Invoke}, $_[0]]);
       }
   }

sub Traverse
   {
    $_[0]->{m_ListBox}->activate
       (
        $_[0]->{m_ListBox}->nearest ($_[0]->{m_ListBox}->XEvent()->y())
       );
   }

sub AutoHide
   {
    my ($l_X, $l_Y, $l_RootX, $l_RootY, $l_Width, $l_Height) =
       (
        $_[1]->pointerx(),
        $_[1]->pointery(),
        $_[1]->rootx(),
        $_[1]->rooty(),
        $_[1]->width(),
        $_[1]->height(),
       );

    return unless
       (
        $l_X >= $l_RootX + $l_Width ||
        $l_Y >= $l_RootY + $l_Height ||
        $l_X <= $l_RootX ||
        $l_Y <= $l_RootY
       );

    $_[0]->Hide();
   }

sub background
   {
    my ($this, $p_Color) = @_;

    return ($this->{m_BackgroundColor}) unless (defined ($p_Color));

    my $l_Button = $this->Subwidget ('Button');
    my $l_Entry = $this->Subwidget ('Entry');

    $this->{m_BackgroundColor} = $p_Color;

    $l_Button->configure
       (
        '-activebackground' => $l_Button->cget ('-background'),
        '-highlightbackground' => $p_Color,
       );

    $l_Entry->configure
       (
        '-highlightbackground' => $p_Color,
       );

    return ($p_Color);
   }

sub scrollbarwidth
   {
    $_[0]->{'m_ScrollBarY'}->configure ('width' => $_[1]) if ($_[1] > 1);
    return $_[0]->{'m_ScrollBarY'}->cget ('width');
   }

sub popupwidth
   {
    $_[0]->{'Configure'}{'-popupwidth'} = $_[1] if ($_[1] > 1 && $_[1] < 256);
    return $_[0]->{'Configure'}{'-popupwidth'};
   }

sub KeySeek
   {
    my ($this, $p_ListBox, $p_Key) = @_;
    my $l_Index = $p_ListBox->size() - 1;
    my $p_Key = ord ($p_Key);

    return unless ($p_Key > 32);

    while ($l_Index && ord (substr ($p_ListBox->get ($l_Index), 0, 1)) > $p_Key)
       {
        --$l_Index;
       }

    $p_ListBox->selectionClear (0, 'end');
    $p_ListBox->selectionSet ($l_Index, $l_Index);
    $p_ListBox->see ($l_Index);
   }

1;

__END__

=cut

=head1 NAME

Tk::ComboEntry - Drop down list entry widget

=head1 SYNOPSIS

    use Tk;

    my $MainWindow = MainWindow->new();

    Tk::MainLoop;

=head1 DESCRIPTION

A Drop down listbox + entry widget with nice keyboard bindings

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

=head1 HISTORY 
 
=cut
