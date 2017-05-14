package Tk::IconCanvas;

use Tk;
use Tk::Scrollbar;
use Tk::Frame;

use vars qw ($VERSION $SERIAL_NUMBER @COPYLIST $DRAGDROP $ICON_DEFAULTS);
use base qw (Tk::Derived Tk::Frame Tk::Widget);
use strict;
use Carp;

$SERIAL_NUMBER = 0;
$VERSION = '0.02';
@COPYLIST = ();
$DRAGDROP = 0;

$ICON_DEFAULTS =
   {
    '-font' => '-adobe-times-medium-r-normal--17-*-*-*-*-*-*-*',
    '-title' => '(Untitled)',
    '-pixmap' => undef,
    '-attach' => undef,
    '-menu' => undef,
    '-x' => 50,
    '-y' => 50,
   };

Tk::Widget->Construct ('IconCanvas');

sub Populate
   {
    my $this = shift;

    my $l_Frame = $this->Frame();

    my $l_Canvas = $l_Frame->Scrolled
       (
        'Canvas',
        '-scrollbars' => 'osoe',
        '-scrollregion' => [0, 0, 300, 200],
       );

    $l_Frame->pack
       (
        '-fill' => 'both',
        '-expand' => 'true',
       );

    $l_Canvas->pack
       (
        '-fill' => 'both',
        '-expand' => 'true',
       );

    $l_Canvas = $this->{m_Canvas} = $l_Canvas->Subwidget ('scrolled');

    $this->{'m_NormalCursor'} = $this->cget ('-cursor');

    $this->ConfigSpecs
       (
        'DEFAULT' => [$l_Canvas],
        '-background' => [[$l_Canvas], 'background', 'backGround', 'white'],
        '-normalcolor' => [['PASSIVE'], 'normalcolor', 'normalColor', 'black'],
        '-selectcolor' => [['PASSIVE'], 'selectcolor', 'selectColor', 'red'],
        '-iconspacing' => [['PASSIVE'], 'iconspacing', 'iconSpacing', 20],
        '-dragallowed' => [['PASSIVE'], 'dragallowed', 'dragAllowed', 1],
        '-autoadjust' => [['METHOD'], 'autoadjust', 'autoAdjust', 1],
        '-bg' => [[$l_Canvas], 'bg', 'bg', 'white'],
        '-menuselection' => ['METHOD'],
        '-command' => ['CALLBACK'],
        '-selection' => ['METHOD'],
        '-items' => ['METHOD'],
        '-selected' => ['METHOD'],
        '-opaque' => ['PASSIVE'],
        '-attach' => ['METHOD'],
        '-detach' => ['METHOD'],
        '-menu' => ['PASSIVE'],
       );

    $this->Delegates
       (
        'DEFAULT' => $l_Canvas,
       );

    $this->SUPER::Populate (@_);

    $this->Tk::bind ('<Configure>' => sub {$this->ArrangeItems() if ($this->cget ('-autoadjust'));});

    $l_Canvas->Tk::bind ('<ButtonPress-1>' => sub {$this->SelectionEvent ('', $l_Canvas);});
    $l_Canvas->Tk::bind ('<ButtonPress-2>' => sub {$this->MenuEvent (@_);});
    $l_Canvas->Tk::bind ('<ButtonPress-3>' => sub {$this->MenuEvent (@_);});
    $l_Canvas->Tk::bind ('<Any-Enter>' => sub {$this->DropEvent (@_);});

    unless (defined ($ICON_DEFAULTS->{'-pixmap'}))
       {
        if (defined ($ICON_DEFAULTS->{'-pixmap'} = $this->GetPixmap ('folder')))
           {
            $ICON_DEFAULTS->{'-pixmap'}->{'m_PixmapSource'} = 'folder';
           }
       }

    $this->GeometryRequest (300, 200);
    $this->configure ('-opaque' => 0);
    return $this;
   }

sub Icon
   {
    my ($this, %p_Parameters) = @_;

    my $l_ID = 'Icon_'.++$SERIAL_NUMBER;
    my $l_Canvas = $this->{m_Canvas};
    my $l_Pixmap;
    my $l_Name;

    foreach my $l_Key (keys %{$ICON_DEFAULTS})
       {
        $p_Parameters {$l_Key} = $ICON_DEFAULTS->{$l_Key} unless (defined ($p_Parameters {$l_Key}));
       }

    if (ref ($l_Pixmap = $p_Parameters {'-pixmap'}) ne 'Tk::Pixmap')
       {
        $l_Pixmap = $p_Parameters {'-pixmap'} = $this->GetPixmap ($l_Name = $p_Parameters {'-pixmap'});
        $l_Pixmap->{'m_PixmapSource'} = $l_Name if (defined ($l_Pixmap));
       }

    if (ref ($p_Parameters {'-pixmap'}) ne 'Tk::Pixmap')
       {
        $l_Pixmap = $p_Parameters {'-pixmap'} = $ICON_DEFAULTS->{'-pixmap'};
       }

    my $l_Menu = $p_Parameters {'-menu'};
    my $l_X = $p_Parameters {'-x'};
    my $l_Y = $p_Parameters {'-y'};

    my $l_PictureItem = $l_Canvas->create
       (
        'image',
        $l_X,
        $l_Y,
        -image => $l_Pixmap,
       );

    my $l_TextItem = $l_Canvas->create
       (
        'text',
        $l_X,
        $l_Y,
        '-fill' => $this->cget ('-normalcolor'),
        '-text' => $p_Parameters {'-title'},
        '-font' => $p_Parameters {'-font'},
       );

    $l_Canvas->move
       (
        $l_TextItem,
        (($l_Canvas->bbox ($l_PictureItem)) [2] - ($l_Canvas->bbox ($l_TextItem)) [2]) / 4,
        $l_Pixmap->height() / 2 + 5,
       );

    $l_Canvas->delete ($l_ID);
    $l_Canvas->addtag ($l_ID, 'withtag', $l_TextItem);
    $l_Canvas->addtag ($l_ID, 'withtag', $l_PictureItem);
    $l_Canvas->addtag ('IconImage', 'withtag', $l_PictureItem);
    $l_Canvas->addtag ('IconText', 'withtag', $l_TextItem);
    $l_Canvas->addtag ('Icon', 'withtag', $l_ID);
    $l_Canvas->raise  ($l_ID, 'all');

    $l_Canvas->bind ($l_ID, '<Shift-ButtonPress-1>' => sub {$this->SelectionEvent ($l_ID, @_, 'shifted');});

    if (defined ($l_Menu))
       {
        $l_Canvas->bind ($l_ID, '<ButtonPress-3>' => sub {$this->MenuEvent ($l_Canvas, $l_ID, $l_Menu, @_);});
        $l_Canvas->bind ($l_ID, '<ButtonPress-2>' => sub {$this->MenuEvent ($l_Canvas, $l_ID, $l_Menu, @_);});
       }

    $l_Canvas->bind ($l_ID, '<Double-ButtonPress-1>' => sub {$this->LaunchEvent ($l_ID, @_);});
    $l_Canvas->bind ($l_ID, '<ButtonRelease-1>' => sub {$this->ReleaseEvent ($l_ID, @_);});
    $l_Canvas->bind ($l_ID, '<ButtonPress-1>' => sub {$this->SelectionEvent ($l_ID, @_);});
    $l_Canvas->bind ($l_ID, '<B1-Motion>' => sub {$this->DragEvent ($l_ID, @_);});

    $this->LineAttach ($l_ID, $p_Parameters {'-attach'}) if (defined ($p_Parameters {'-attach'}));
    $this->ArrangeItems() if ($this->cget ('-autoadjust'));
    $this->ItemMove ($l_ID, 0, 0);
    return ($l_ID);
   }

#=========================================================================================
#                                      Event Handlers
#=========================================================================================
sub MenuEvent
   {
    my ($this, $p_Canvas, $p_Item, $p_Menu) = (shift, @_);

    if (Exists ($p_Menu = defined ($p_Menu) ? $p_Menu : $this->cget ('-menu')) && ! $this->{m_MenuActive})
       {
        my $l_Event = $p_Canvas->XEvent();

        ($p_Menu->{m_Canvas} = $this)->{m_MenuSelection} = $p_Item;
        $this->{m_MenuActive} = 1;

        $p_Menu->Popup() if ($Tk::VERSION < 800.005);

        $p_Menu->post
           (
            $l_Event->x() + $p_Canvas->rootx(),
            $l_Event->y() + $p_Canvas->rooty(),
           );
       }

    $this->{m_MenuActive} = defined ($p_Item);
   }

sub LaunchEvent
   {
    return
       (
        defined ($_[0]->cget ('-command')) ?
        &{$_[0]->cget ('-command')} ($_[1], $_[0], $_[2]) :
        undef
       );
   }

sub SelectionEvent
   {
    my ($this, $p_Item, $p_Canvas) = (shift, @_);

    if ($p_Item ne '')
       {
        my $l_Event = $p_Canvas->XEvent();
        $this->SelectItem ($p_Item, $_[-1] eq 'shifted');
        $p_Canvas->raise ($p_Item, 'all');
        $this->{m_SelectionActive} = 1;
        $this->{m_X} = $l_Event->x();
        $this->{m_Y} = $l_Event->y();
       }
    else
       {
        $this->DeselectItem() unless ($this->{m_SelectionActive});
        $this->{m_SelectionActive} = 0;
       }
   }

sub DragEvent
   {
    my ($this, $p_Item, $p_Canvas) = (shift, @_);

    if ($this->cget ('-dragallowed'))
       {
        my $l_Opaque = $this->cget ('-opaque') && $this->cget ('-opaque') ne 'false';
        my $l_PositionX = $this->pointerx() - $this->rootx();
        my $l_PositionY = $this->pointery() - $this->rooty();
        my $l_Event = $p_Canvas->XEvent();
        my @l_DeleteList = ();
        my @l_NewList = ();

        foreach my $l_Item ($this->cget ('-selection'))
           {
            if ($l_PositionX < 0 || $l_PositionY < 0 || $l_PositionX > $this->width() || $l_PositionY > $this->height())
               {
                push (@l_DeleteList, $l_Item);
                $DRAGDROP = 1;
               }
            else
               {
                push (@l_NewList, $l_Item);
               }

            if ($l_Opaque)
               {
                $this->move ($l_Item, $l_Event->x() - $this->{m_X}, $l_Event->y() - $this->{m_Y});
               }
           }

        $this->delete (@l_DeleteList) if ($#l_DeleteList > -1);
        $this->configure ('-cursor' => 'hand1');
        $this->{'m_Selection'} = [@l_NewList];

        if ($l_Opaque)
           {
            $this->{m_X} = $l_Event->x();
            $this->{m_Y} = $l_Event->y();
           }
       }
   }

sub ReleaseEvent
   {
    my ($this, $p_Item, $p_Canvas) = (shift, @_);

    $this->configure ('-cursor' => $this->{'m_NormalCursor'});

    if ($this->cget ('-dragallowed'))
       {
        my $l_Event = $p_Canvas->XEvent();

        foreach my $l_Item ($this->cget ('-selection'))
           {
            $this->move ($l_Item, $l_Event->x() - $this->{m_X}, $l_Event->y() - $this->{m_Y});
            $p_Canvas->raise ($l_Item, 'all');
            $this->CancelDrag();
           }
       }

    if ($this->cget ('-autoadjust'))
       {
        $this->ArrangeItems();
       }

    $p_Canvas->raise ($p_Item, 'all');
   }

sub DropEvent
   {
    my $this = shift;
    $this->paste() if ($DRAGDROP);
    $this->CancelDrag();
   }

sub CancelDrag
   {
    my $this = shift;
    $this->configure ('-cursor' => $this->{'m_NormalCursor'});
    $DRAGDROP = 0;
   }

#=========================================================================================
#                                 Item Manipulation Methods
#=========================================================================================
sub SelectItem
   {
    my ($this, $p_Item, $p_Shifted) = (shift, @_);

    if ($this->IsItemSelected ($p_Item))
       {
        $this->DeselectItem ($p_Item) if ($p_Shifted);
        return;
       }

    my $l_TextID = $this->GetIconComponent ('text', $p_Item);
    $this->DeselectItem() if (! $p_Shifted);
    $this->itemconfigure ($l_TextID, '-fill' => $this->cget ('-selectcolor'));
    push (@{$this->{m_Selection}}, $p_Item);
    return $p_Item;
   }

sub DeselectItem
   {
    my ($this, @p_Items) = (shift, @_);
    my %l_Hash;

    foreach my $l_Item ($#p_Items == -1 ? $this->find ('withtag', 'Icon') : @p_Items)
       {
        my ($l_Tag) = (grep (/^Icon_/, $this->gettags ($l_Item)));
        $l_Hash {$l_Tag} = 1;
       }

    foreach my $l_Item (keys %l_Hash)
       {
        if (defined (my $l_TextItem = $this->GetIconComponent ('text', $l_Item)))
           {
            @{$this->{m_Selection}} = grep (!/^$l_Item$/, @{$this->{m_Selection}});
            $this->itemconfigure ($l_TextItem, '-fill' => 'black');
           }
       }
   }    

sub ItemMove
   {
    my ($this, $p_Item, $p_X, $p_Y) = (shift, @_);
    my $l_Canvas = $this->{m_Canvas};
    my @l_Scroll = @{$l_Canvas->cget ('scrollregion')};
    my %l_Hash;

    foreach my $l_Attachment ($this->FindAttachmentInList ($p_Item, keys %{$this->{m_Attachments}}))
       {
        $l_Hash {${${$this->{m_Attachments}}{$l_Attachment}}[0]} = 1;
       }

    $l_Hash {$p_Item} = 1;

    foreach my $l_Item (keys %l_Hash)
       {
        $l_Canvas->move ($l_Item, $p_X, $p_Y);
       }

    @l_Scroll [2..3] = ($l_Canvas->bbox ('all')) [2..3];
    $l_Canvas->configure ('-scrollregion' => [@l_Scroll]);
    $this->LineAdjust();
   }

sub delete
   {
    my ($this, @p_Parameters) = @_;

    $this->copy (@p_Parameters);

    foreach my $l_ID (@p_Parameters)
       {
        $this->LineDetach ($l_ID);
        $this->{m_Canvas}->delete ($l_ID);
       }
   }

#======================================================================================
# Do not override the following two methods in the subclass, they may potentially get
# lists of items which we don't want to have to handle. The overrideable ones are
# shown afterwards.
#======================================================================================
sub copy
   {
    my ($this, @p_Parameters) = @_;

    @COPYLIST = ();

    foreach my $l_ID (@p_Parameters)
       {
        push (@COPYLIST, $this->CopyInstance ($l_ID));
       }
   }

sub paste
   {
    my ($this, @p_Parameters) = @_;

    foreach my $l_ID (@COPYLIST)
       {
        $this->PasteInstance ($l_ID);
       }

    $this->CancelDrag();
   }

#======================================================================================
# Here, these are the overrideable cut & paste methods. Note that they return a
# reference to the hash table so that any downline methods can modify or replace it
# the hash contains the information used to reinstantiate the icon
#======================================================================================
sub CopyInstance
   {
    my ($this, $p_Item) = @_;

    return unless defined ($p_Item);

    my $l_ImageItem = $this->GetIconComponent ('image', $p_Item);
    my $l_TextItem = $this->GetIconComponent ('text', $p_Item);
    my $l_Pixmap = $this->itemcget ($l_ImageItem, '-image');
    my $l_Text = $this->itemcget ($l_TextItem, '-text');
    my $l_Font = $this->itemcget ($l_TextItem, '-font');

    my $l_HashRef =
       {
        '-pixmap' => $l_Pixmap->{'m_PixmapSource'},
        '-title' => $l_Text,
        '-font' => $l_Font,
       };

    return $l_HashRef;
   }

sub PasteInstance
   {
    my ($this, $p_HashRef) = @_;

    my $l_Return = undef;

    if (ref ($p_HashRef) eq 'HASH')
       {
        $l_Return = $this->Icon
           (
            -x => $this->pointerx() - $this->rootx(),
            -y => $this->pointery() - $this->rooty(),
            %{$p_HashRef},
           );

        #====================================================================
        # I'm not really sure if we should be deleting keys that are specific
        # to this class, but it protects the higher layers from having to
        # concern themselves with avoiding them.
        #====================================================================
        delete $p_HashRef->{'-pixmap'};
        delete $p_HashRef->{'-title'};
        delete $p_HashRef->{'-font'};
       }

    return $l_Return; # This gets passed upwards so that reimplementations can modify it
   }

sub ArrangeItems
   {
    my ($this) = (shift, @_);

    my $l_Canvas = $this->{m_Canvas};
    my %l_Hash;

    foreach my $l_Item ($this->find ('withtag', 'Icon'))
       {
        my ($l_Tag) = (grep (/^Icon_/, $this->gettags ($l_Item)));
        $l_Hash {$l_Tag} = 1;
       }

    my @l_Frame = ($this->width(), $this->height());
    my @l_Region = @{$l_Canvas->cget ('scrollregion')};
    my $l_DefaultSpacing = $this->cget ('-iconspacing');
    my ($l_X, $l_Y, $l_MaxY) = (10, 10, 0, 0);

    foreach my $l_Object (keys %l_Hash)
       {
        my (@l_Bounds) = $l_Canvas->bbox ($l_Object);
        my ($l_DeltaX, $l_DeltaY) = ($l_X - $l_Bounds [0], $l_Y - $l_Bounds [1]);
        $this->move ($l_Object, $l_DeltaX, $l_DeltaY);
        @l_Bounds = $l_Canvas->bbox ($l_Object);
        $l_X = $l_Bounds [2] + $l_DefaultSpacing;
        $l_MaxY = ($l_Bounds [3] > $l_MaxY ? $l_Bounds [3] + 10 : $l_MaxY);

        if ($l_X > $l_Frame [0] - 64)
           {
            $l_Y = $l_MaxY;
            $l_MaxY = 0;
            $l_X = 10;
           }
       }
   }

sub IsItemSelected
   {
    return (defined $_[1] && grep (/^$_[1]$/, @{$_[0]->{m_Selection}}) > 0);
   }

#=========================================================================================
#                                 Component Collection Handling
#=========================================================================================
sub GetIconComponent
   {
    my ($this, $p_Which, $p_Item) = (shift, @_);
    my @l_List = $this->find ('withtag', $p_Item);
    my $l_Return = undef;

    for (my $l_Index = 0; $l_Index <= $#l_List && ! defined ($l_Return); ++$l_Index)
       {
        $l_Return = $l_List [$l_Index] if ($this->type ($l_List [$l_Index]) eq $p_Which);
       }

    return $l_Return;
   }

sub GetPixmap
   {
    my $this = shift;

    my $l_Name = undef;

    my @l_List =
       (
        Tk->findINC ($_[0].'.xpm'),
        Tk->findINC ($_[0]),
        'icon/'.$_[0].'.xpm',
        'icon/'.$_[0],
        $_[0].'.xpm',
        $_[0],
       );

    for (my $l_Index = 0; $l_Index <= $#l_List && ! defined ($l_Name); ++$l_Index)
       {
        $l_Name = $l_List [$l_Index] if (-f $l_List [$l_Index]);
       }

    return
       (
        defined ($this->{'m_PixmapCache'}->{$l_Name}) ? $this->{'m_PixmapCache'}->{$l_Name} :
           (
            -f $l_Name ?
            $this->{'m_PixmapCache'}->{$l_Name} = $this->toplevel()->Pixmap ('-file' => $l_Name) :
            undef
           )
       );
   }

#=========================================================================================
#                                   Attachment Manipulation
#=========================================================================================
sub LineAttach
   {
    my ($this, $p_From, $p_To) = (shift, @_);

    ($p_From, $p_To) = @{$p_From} if (ref ($p_From) eq 'ARRAY');

    return unless (defined ($p_From) && defined ($p_To));

    return if (defined ($this->FindAttachmentByAttachment ($p_From, $p_To)));

    my $l_Canvas = $this->{m_Canvas};
    my @l_FromBox = $l_Canvas->bbox ($this->GetIconComponent ('image', $p_From));
    my @l_ToBox = $l_Canvas->bbox ($this->GetIconComponent ('image', $p_To));

    my $l_ID = $l_Canvas->create
       (
        'line',
        0,0,0,0,
        -fill => 'black',
        -width => '2.0',
       );

    $this->{m_Attachments}->{$l_ID} = [$p_From, $p_To];

    #---------------------------------------------------------------
    # Something strange happens here sometimes. It may be something
    # to do with the cut/paste mechanism, I don't really know. It
    # manifests itself as a "phantom" attachment selection. The
    # attachment selection includes an "invisible" object above the
    # upper left corner of the canvas.
    #---------------------------------------------------------------
    # foreach my $l_Key (keys %{$this->{m_Attachments}})
    #   {
    #    printf ("Attached [%s] to [%s]\n", $l_Key, @{$this->{m_Attachments}->{$l_Key}});
    #   }

    $this->LineAdjust ($p_From, $p_To);
    return $l_ID;
   }

sub LineDetach
   {
    my ($this, $p_From, $p_To) = (shift, @_);

    if (ref ($p_From) eq 'ARRAY')
       {
        ($p_From, $p_To) = @{$p_From};
       }

    foreach my $l_ID ($this->FindAttachmentByAttachment ($p_From, $p_To))
       {
        $this->{m_Canvas}->delete ($l_ID);
        delete ${$this->{m_Attachments}}{$l_ID};
       }
   }

sub LineAdjust
   {
    my ($this, $p_From, $p_To) = (shift, @_);
    my %l_Hash = %{$this->{m_Attachments}};
    my $l_Canvas = $this->{m_Canvas};

    foreach my $l_ID ($this->FindAttachmentByAttachment ($p_From, $p_To))
       {
        next unless (ref ($l_Hash {$l_ID}) eq 'ARRAY' && $#{$l_Hash {$l_ID}} > 0);

        my ($l_From, $l_To) = @{$l_Hash {$l_ID}};
        my @l_FromBox = $l_Canvas->bbox ($this->GetIconComponent ('image', $l_From));
        my @l_ToBox = $l_Canvas->bbox ($this->GetIconComponent ('image', $l_To));

        $l_Canvas->coords
           (
            $l_ID,
            $l_FromBox [0] + (($l_FromBox [2] - $l_FromBox[0]) / 2),
            $l_FromBox [1] + (($l_FromBox [3] - $l_FromBox[1]) / 2),
            $l_ToBox [0] + (($l_ToBox [2] - $l_ToBox[0]) / 2),
            $l_ToBox [1] + (($l_ToBox [3] - $l_ToBox[1]) / 2),
           );

        $l_Canvas->lower ($l_ID);
       }
   }

sub FindAttachmentByID
   {
    return ${$_[0]->{m_Attachments}}{$_[1]};
   }

sub FindAttachmentByAttachment
   {
    my ($this, $p_From, $p_To) = (shift, @_);

    my @l_List = $this->FindAttachmentInList
       (
        $p_To,
        $this->FindAttachmentInList ($p_From, keys %{$this->{m_Attachments}})
       );

    return ($#l_List >= 0 ? @l_List : undef);
   }

sub FindAttachmentInList
   {
    my ($this, $p_IconID, @p_Keys) = (shift, @_);
    my @l_Return = (@p_Keys);

    if ($p_IconID ne '')
       {
        my %l_Hash = %{$this->{m_Attachments}};
        @l_Return = ();

        foreach my $l_ID (@p_Keys)
           {
            my ($l_From, $l_To) = (@{$l_Hash {$l_ID}});
            push (@l_Return, $l_ID) if ($p_IconID eq $l_From || $p_IconID eq $l_To);
           }
       }

    return @l_Return;
   }

#=========================================================================================
#                             ConfigSpec Option Methods
#=========================================================================================
sub menuselection
   {
    return $_[0]->{m_MenuSelection};
   }

sub selection
   {
    return @{$_[0]->{m_Selection}};
   }

sub autoadjust
   {
    $_[0]->{m_AutoAdjust} = $_[1] if (defined ($_[1]));
    $_[0]->ArrangeItems() if ($_[0]->{m_AutoAdjust});
    return $_[0]->{m_AutoAdjust};
  }

sub items
   {
    my $this = shift;

    my %l_Hash;

    foreach my $l_Item ($this->find ('withtag', 'Icon'))
       {
        $l_Hash {(grep (/^Icon_/, $this->gettags ($l_Item)))[0]} = 1;
       }

    return (keys %l_Hash);
   }

#=========================================================================================
#                                         Alias Methods
#=========================================================================================
sub detach
   {
    return LineDetach (@_);
   }

sub attach
   {
    return LineAttach (@_);
   }

sub move
   {
    return ItemMove (@_);
   }

sub selected
   {
    return IsItemSelected (@_);
   }

1;
#=========================================================================================
#                                          END OF MODULE
#=========================================================================================

__END__

=cut

=head1 NAME

Tk::IconCanvas - Canvas with dragable icon management

=head1 SYNOPSIS

    use Tk;

    my $MainWindow = MainWindow->new();

    Tk::MainLoop;

=head1 DESCRIPTION

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

=head1 HISTORY 
 
=cut
