#======================================================================#
#                User invokes this to add a column 
#======================================================================#
package Tk::ColumnButton;

use Tk::Frame;
use Tk;

use base qw (Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.02';

Tk::Widget->Construct ('ColumnButton');

sub Populate
   {
    my $this = shift;

    my $l_Parent = $this->parent();

    $this->SUPER::Populate (@_);

    $this->{'m_TrimElements'} = [];

    my $l_Image = $this->Component
       (
        'Label' => 'Image',
        '-relief' => 'flat',
        '-anchor' => 'w',
        '-width' => 0,
        '-padx' => 0,
       );

    my $l_Label = $this->Component
       (
        'Label' => 'Label',
        '-relief' => 'flat',
        '-anchor' => 'w',
        '-padx' => 0,
       );

    my $l_Default =
       {
        '-listfont' => $l_Parent->cget ('-listfont') || $l_Label->cget ('-font'),
        '-listbackground' => $l_Parent->cget ('-listbackground') || 'white',
        '-listforeground' => $l_Parent->cget ('-listforeground') || 'black',
        '-listselectmode' => $l_Parent->cget ('-selectmode') || 'browse',
        '-selectcommand' => $l_Parent->cget ('-selectcommand') || undef,
        '-buttoncommand' => $l_Parent->cget ('-buttoncommand') || undef,
        '-foreground' => $l_Parent->cget ('-buttonforeground') || undef,
        '-background' => $l_Parent->cget ('-buttonbackground') || undef,
        '-sortcommand' => $l_Parent->cget ('-sortcommand') || undef,
        '-borderwidth' => $l_Parent->cget ('-borderwidth') || 2,
        '-trimcount' => $l_Parent->cget ('-trimcount') || 2,
        '-font' => $l_Parent->cget ('-buttonfont') || undef,
        '-image' => $l_Parent->cget ('-image') || undef,
        '-sort' => $l_Parent->cget ('-sort') || 'true',
       };

    $this->ConfigSpecs
       (
        '-background' => [['METHOD', 'CHILDREN', 'SELF'], 'background', 'Background',  $l_Default->{'-background'}],
        '-listselectmode' => ['METHOD', 'listselectmode', 'ListSelectMode', $l_Default->{'-listselectmode'}],
        '-listbackground' => ['METHOD', 'listbackground', 'ListBackground', $l_Default->{'-listbackground'}],
        '-listforeground' => ['METHOD', 'listforeground', 'ListForeground', $l_Default->{'-listforeground'}],
        '-selectcommand' => ['PASSIVE', 'selectcommand', 'SelectCommand', $l_Default->{'-selectcommand'}],
        '-buttoncommand' => ['PASSIVE', 'buttoncommand', 'ButtonCommand', $l_Default->{'-buttoncommand'}],
        '-sortcommand' => ['PASSIVE', 'sortcommand', 'Sortcommand', $l_Default->{'-sortcommand'}],
        '-borderwidth' => ['SELF', 'borderwidth', 'Borderwidth', $l_Default->{'-borderwidth'}],
        '-foreground' => ['METHOD', 'foreground', 'Foreground', $l_Default->{'-foreground'}],
        '-trimcount' => ['METHOD', 'trimcount', 'TrimCount', $l_Default->{'-trimcount'}],
        '-listfont' => ['METHOD', 'listfont', 'ListFont', $l_Default->{'-listfont'}],
        '-image' => [$l_Image, 'image', 'Image', $l_Default->{'-image'}],
        '-sort' => ['PASSIVE', 'sort', 'Sort', $l_Default->{'-sort'}],
        '-font' => [$l_Label, 'font', 'Font',  $l_Default->{'-font'}],
       );

    $this->ConfigSpecs
       (
        '-text' => [$l_Label, 'text', 'Text', '(No Title)'],
        '-relief' => ['SELF', 'relief', 'Relief', 'raised'],
        '-slave' => ['METHOD', 'slave', 'Slave', undef],
        '-zoom' => ['METHOD', 'zoom', 'Zoom', undef],
        '-width' => [$l_Label],
        'DEFAULT' => [$l_Label],
       );

    $this->ConfigSpecs
       (
        '-buttonbackground' => '-background',
        '-buttonforeground' => '-foreground',
        '-slavecolor' => '-listbackground',
        '-sortfunction' => '-sortcommand',
        '-buttoncolor' => '-background',
        '-sortmethod' => '-sortcommand',
        '-command' => '-selectcommand',
        '-color' => '-background',
        '-buttonFont' => '-font',
        '-bg' => '-background',
        '-fg' => '-foreground',
       );

    $l_Image->pack
       (
        '-expand' => 'true',
        '-side' => 'left',
        '-fill' => 'both',
        '-anchor' => 'nw',
        '-ipadx' => 0,
        '-padx' => 0,
       );

    $l_Label->pack
       (
        '-expand' => 'true',
        '-side' => 'left',
        '-fill' => 'both',
        '-anchor' => 'nw',
        '-ipadx' => 0,
        '-padx' => 0,
       );

    $this->OnDestroy
       (
        sub
           {
            my $l_Slave = $this->{'Configure'}{'-slave'};
            return unless defined ($l_Slave) && Exists ($l_Slave);
            $l_Slave->destroy();
           }
       );

    $l_Label->bind ('<ButtonPress-1>' => [\&ButtonPress, $this]);
    $l_Label->bind ('<ButtonRelease-1>' => [\&ButtonRelease, $this]);
    $l_Image->bind ('<ButtonRelease-1>' => [\&ButtonRelease, $this]);
    $l_Image->bind ('<ButtonPress-1>' => [\&ButtonPress, $this]);
    $this->DoWhenIdle (['UpdateSizeInfo', $this]);
    $this->configure ('-highlightthickness' => 0);
    return $this;
   }

#-----------------------------Event-Handlers----------------------------------#

sub UpdateSizeInfo
   {
    my ($this) = @_;
    my $l_Label = $this->Subwidget ('Label');
    my $l_Image = $this->Subwidget ('Image');
    $l_Label->{'m_OriginalWidth'} = $l_Label->reqwidth() if ($l_Label->reqwidth() > 1);
    $l_Image->{'m_OriginalWidth'} = $l_Image->reqwidth() if ($l_Image->reqwidth() > 1);
   }

sub SlaveInvoke
   {
    my ($this, $p_Slave) = @_;
    my $l_Command = $this->cget ('-selectcommand');
    return unless (defined ($l_Command) && defined ($p_Slave));
    &{$l_Command} (($p_Slave->curselection())[0]);
   }

sub ResizeStart
   {
    $_[1]->{'Configure'}{'-zoom'} = $_[1]->{'m_Zoomed'} = undef;
    $_[1]->{'m_X'} = $_[1]->pointerx() - $_[1]->rootx();
   }

sub ResizeEnd
   {
    my ($p_EventWidget, $this) = @_;

    return unless defined ($this->{m_X});

    my $l_Label = $this->Subwidget ('Label');
    my $l_Width = $l_Label->width() + $this->pointerx() - $this->rootx() - $this->{'m_X'};

    $l_Label->GeometryRequest ($l_Width > 0 ? $l_Width : 0, $l_Label->reqheight());
    $this->DoWhenIdle ([\&SlaveUpdate, $this]);
    $this->{'Configure'}{'-zoom'} = undef;
    $this->UpdateSizeInfo();
    $this->{'m_X'} = undef;
   }

sub Zoom
   {
    $_[1]->DoWhenIdle (['configure', $_[1], '-zoom' => (defined ($_[2]) ? $_[2] : ! $_[1]->cget ('-zoom'))]);
   }

sub SlaveUpdate
   {
    my ($this, $p_Slave) = (@_, $_[0]->cget ('-slave'));

    my $l_Label = $this->Subwidget ('Label');
    my $l_Image = $this->Subwidget ('Image');

    if ($this->{'Configure'}{'-zoom'} && $l_Label->reqwidth() > 1)
       {
        $l_Label->GeometryRequest (0, $l_Label->reqheight());
        $this->update();
       }

    #================================
    # Correct Label and Image sizes
    #================================

    if ($l_Label->reqwidth() <= 1 && $l_Image->reqwidth() > 1)
       {
        $l_Image->GeometryRequest (0, $l_Image->reqheight());
        $this->update();
       }
    elsif ($l_Label->reqwidth() > 1 && $l_Image->reqwidth() <= 1)
       {
        $l_Image->GeometryRequest ($l_Image->{'m_OriginalWidth'}, $l_Image->reqheight());
        $this->update();
       }

    if ($l_Label->reqwidth() <= 1 && ! $this->{'m_Minimized'})
       {
        foreach my $l_Child ($this->children())
           {
            next unless ($l_Child->name() =~ /^[Tt]rimElement_/);

            unless ($l_Child->name() =~ /^[Tt]rimElement_0$/)
               {
                $l_Child->packForget();
               }
           }

        $this->{'m_Minimized'} = 1;
        $this->update();
       }
    elsif ($this->{'m_Minimized'} && $l_Label->reqwidth() > 1)
       {
        foreach my $l_Child ($this->children())
           {
            next unless ($l_Child->name() =~ /^[Tt]rimElement_/);

            unless ($l_Child->name() =~ /^[Tt]rimElement_0$/)
               {
                $l_Child->pack
                   (
                    '-expand' => 'false',
                    '-side' => 'right',
                    '-anchor' => 'ne',
                    '-fill' => 'y',
                    '-ipadx' => 0,
                    '-padx' => 0,
                    '-pady' => 1,
                   );
               }
           }

        $this->{'m_Minimized'} = 0;
        $this->update();
       }

    #=====================================================
    # Slave the listbox to the current width of the button
    #=====================================================
    if (defined ($p_Slave))
       {
        $p_Slave->GeometryRequest ($this->reqwidth(), $p_Slave->reqheight());
        $p_Slave->update();
       }

    $this->update();
   }

sub ButtonPress
   {
    if ($_[1]->{'Configure'}{'-sort'} || ref ($_[1]->{'Configure'}{'-buttoncommand'}) eq 'CODE')
       {
        $_[0]->DoWhenIdle (['configure', $_[1], '-relief', 'sunken']);
        $_[1]->{'m_Sunken'} = 1;
       }
   }

sub ButtonRelease
   {
    if ($_[1]->{'Configure'}{'-sort'})
       {
        $_[0]->DoWhenIdle (['SortColumn', $_[1]]);
       }
    elsif (ref ($_[1]->{'Configure'}{'-buttoncommand'}) eq 'CODE')
       {
        &{$_[1]->{'Configure'}{'-buttoncommand'}} ($_[1], $_[1]->cget ('-slave'));
       }

    if ($_[1]->{'m_Sunken'})
       {
        $_[0]->DoWhenIdle (['configure', $_[1], '-relief', 'raised']);
        $_[1]->{'m_Sunken'} = undef;
       }
   }

sub SortColumn
   {
    my $this = shift;

    my $l_Listbox = $this->{'Configure'}{'-slave'};

    return unless (defined ($l_Listbox) && ref ($l_Listbox) eq 'Tk::TiedListbox');

    my $l_SortCommand = $this->{'Configure'}{'-sortcommand'};
    my @l_SortedKeys = $l_Listbox->get (0, 'end');
    my @l_NewOrder;
    my %l_Keys;

    for (my $l_Index = 0; $l_Index <= $#l_SortedKeys; ++$l_Index)
       {
        push (@{$l_Keys {$l_SortedKeys [$l_Index]}}, $l_Index);
       }

    if (lc ($l_SortCommand) eq 'numeric')
       {
        $l_SortCommand = '$a <=> $b';
       }
    elsif (! defined ($l_SortCommand))
       {
        $l_SortCommand = 'uc ($a) cmp uc ($b)';
       }

    @l_SortedKeys = sort {eval $l_SortCommand} (keys %l_Keys);

    unless ($l_Listbox->{'m_Reverse'} = ! $l_Listbox->{'m_Reverse'})
       {
        @l_SortedKeys = reverse (@l_SortedKeys);
       }

    foreach my $l_Key (@l_SortedKeys)
       {
        push (@l_NewOrder, @{$l_Keys {$l_Key}});
       }

    foreach my $l_Button ($this->parent()->buttons())
       {
        my $l_Listbox = $l_Button->cget ('-slave');

        next unless defined ($l_Listbox);

        my @l_Contents = $l_Listbox->get (0, 'end');
        my @l_NewContents;

        foreach my $l_NewIndex (@l_NewOrder)
           {
            push (@l_NewContents, $l_Contents [$l_NewIndex]);
           }

        $l_Listbox->delete (0, 'end');
        $l_Listbox->insert ('end', @l_NewContents);
        $l_Button->DoWhenIdle ([\&SlaveUpdate, $l_Button, $l_Listbox]);
       }
   }

#------------------------------- Private methods -----------------------------#

sub __slaveconfigure
   {
    my ($this, $p_Option, $p_Value) = (shift, @_);

    my $l_Slave = $this->{'Configure'}{'-slave'};

    if (defined ($p_Value) && defined ($l_Slave))
       {
        my $l_Method = ($l_Slave->isa ('Tk::Listbox') ? 'Tk::Listbox::configure' : 'configure');
        $this->{'Configure'}{$p_Option} = $p_Value;
        $p_Option =~ s/^\-list/-/;
        $this->DoWhenIdle ([$l_Method, $l_Slave, $p_Option, $p_Value]);
        $this->DoWhenIdle ([\&SlaveUpdate, $this]);
       }

    return $this->{'Configure'}{$p_Option};
   }

#-----------------------------'METHOD'-type-settings--------------------------#

sub slave
   {
    my ($this, $p_Slave) = @_;

    if (defined ($p_Slave) && Exists ($p_Slave))
       {
        ($this->{'Configure'}{'-slave'} = $p_Slave)->bind ('<Double-ButtonPress-1>' => sub {$this->SlaveInvoke ($p_Slave);});

        $this->configure
           (
            '-listfont' => $this->cget ('-listfont'),
            '-listforeground' => $this->cget ('-listforeground'),
            '-listbackground' => $this->cget ('-listbackground'),
            '-listselectmode' => $this->cget ('-listselectmode'),
           );
       }

    return $this->{'Configure'}{'-slave'};
   }

sub trimcount
   {
    my ($this, $p_TrimCount) = (shift, @_);

    if (defined ($p_TrimCount) && $p_TrimCount >= 0)
       {
        my @l_TrimElements = @{$this->{m_TrimElements}};

        $p_TrimCount = 12 if ($p_TrimCount > 12);

        while ($p_TrimCount > $#l_TrimElements + 1)
           {
            my $l_Widget = $this->Component
               (
                'Frame' => 'TrimElement_'.($#l_TrimElements + 1),
                '-cursor' => 'sb_h_double_arrow',
                '-background' => 'white',
                '-relief' => 'raised',
                '-borderwidth' => 1,
                '-width' => 2,
               );

            $l_Widget->pack
               (
                '-expand' => 'false',
                '-side' => 'right',
                '-anchor' => 'ne',
                '-fill' => 'y',
                '-ipadx' => 0,
                '-padx' => 0,
                '-pady' => 1,
               );

            $l_Widget->bind ('<ButtonRelease-1>' => [\&ResizeEnd, $this]);
            $l_Widget->bind ('<ButtonPress-1>' => [\&ResizeStart, $this]);
            $l_Widget->bind ('<ButtonRelease-3>' => [\&Zoom, $this]);
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

sub background
   {
    my ($this, $p_Color) = (shift, @_);

    if (defined ($p_Color))
       {
        my $l_OptionColor = $this->option ('get', 'background', 'Background') || $p_Color;
        my $l_ConfigColor = ${$this->ConfigSpecs()->{'-background'}}[3] || $p_Color;
        my $l_ParentColor = $this->parent()->cget ('-buttonbackground');

        my @l_Compare =
           (
            sprintf ("#%02x%02x%02x", $this->rgb ($p_Color)),
            sprintf ("#%02x%02x%02x", $this->rgb ($l_ConfigColor)),
            sprintf ("#%02x%02x%02x", $this->rgb ($l_OptionColor)),
           );

        $this->{'Configure'}{'-background'} = $p_Color =
           (
            defined ($l_ParentColor) &&
            $l_Compare [0] eq $l_Compare [1] &&
            $l_Compare [0] eq $l_Compare [2] &&
            ! defined ($this->{'m_Initialized'}) ?
            $l_ParentColor :
            $p_Color
           );

        foreach my $l_Child ($this->children())
           {
            $l_Child->configure ('-background' => $p_Color);
           }

        $this->DoWhenIdle (['configure', $this, '-background' => $p_Color]) unless ($this->{'m_Initialized'} >= 2);
        $this->DoWhenIdle ([\&SlaveUpdate, $this]);
        ++$this->{'m_Initialized'};
       }

    return $this->{'Configure'}{'-background'};
   }

sub foreground
   {
    my ($this, $p_Color) = (shift, @_);

    my $l_Label = $this->Subwidget ('Label');

    if (defined ($p_Color) && defined ($l_Label))
       {
        my $l_OptionColor = $this->option ('get', 'foreground', 'Foreground') || $p_Color;
        my $l_ConfigColor = ${$this->ConfigSpecs()->{'-foreground'}}[3] || $p_Color;
        my $l_ParentColor = $this->parent()->cget ('-buttonforeground');

        my @l_Compare =
           (
            sprintf ("#%02x%02x%02x", $this->rgb ($p_Color)),
            sprintf ("#%02x%02x%02x", $this->rgb ($l_ConfigColor)),
            sprintf ("#%02x%02x%02x", $this->rgb ($l_OptionColor)),
           );

        $this->{'Configure'}{'-foreground'} = $p_Color =
           (
            defined ($l_ParentColor) &&
            $l_Compare [0] eq $l_Compare [1] &&
            $l_Compare [0] eq $l_Compare [2] &&
            ! defined ($l_Label->{'m_Initialized'}) ?
            $l_ParentColor :
            $p_Color
           );

        $l_Label->configure ('-foreground' => $p_Color);
        $this->DoWhenIdle ([\&SlaveUpdate, $this]);
        $l_Label->{'m_Initialized'} = 1;
       }

    return $this->{'Configure'}{'-foreground'};
   }

sub listbackground
   {
    return shift->__slaveconfigure ('-listbackground', @_);
   }

sub listforeground
   {
    return shift->__slaveconfigure ('-listforeground', @_);
   }

sub listfont
   {
    return shift->__slaveconfigure ('-listfont', @_);
   }

sub listselectmode
   {
    return shift->__slaveconfigure ('-listselectmode', @_);
   }

sub zoom
   {
    my ($this, $p_State) = @_;

    my $l_Label = $this->Subwidget ('Label');

    if (defined ($p_State) && defined ($l_Label))
       {
        $this->{'Configure'}{'-zoom'} = $p_State;
        $l_Label->GeometryRequest ($p_State ? 0 : $l_Label->{'m_OriginalWidth'}, $l_Label->reqheight());
        $this->DoWhenIdle ([\&SlaveUpdate, $this]);
       }

    return $this->{'Configure'}{'-zoom'};
   }

1;

#======================================================================#
#             This is a private class used only by Columns
#======================================================================#
package Tk::__ButtonContainer;

use strict;

use Carp;

use Tk::Frame;

use base qw (Tk::Frame);

Tk::Widget->Construct ('__ButtonContainer');

sub Populate
   {
    my $this = shift;

    $this->SUPER::Populate (@_);

    $this->{'m_ButtonList'} = [];

    $this->ConfigSpecs
       (
        '-selectcommand' => ['METHOD', 'selectcommand', 'SelectCommand', undef],
        '-buttoncommand' => ['METHOD', 'buttoncommand', 'ButtonCommand', undef],
        '-sortcommand' => ['METHOD', 'sortcommand', 'SortCommand', undef],
        '-borderwidth' => ['METHOD', 'borderwidth', 'BorderWidth', undef],
        '-trimcount' => ['METHOD', 'trimcount', 'TrimCount', undef],
        '-image' => ['METHOD', 'image', 'Image', undef],
        '-sort' => ['METHOD', 'sort', 'Sort', undef],
        '-zoom' => ['METHOD', 'zoom', 'Zoom', undef],
        '-background' => ['METHOD'],
        '-foreground' => ['METHOD'],
        '-master' => ['PASSIVE'],
	'-font' => ['METHOD'],
       );

    $this->ConfigSpecs
       (
        '-buttonbackground' => '-background',
        '-buttonforeground' => '-foreground',
        '-buttoncolor' => '-background',
        '-command' => '-selectcommand',
        '-color' => '-background',
        '-buttonfont' => '-font',
       );

    $this->gridRowconfigure (0, '-weight' => 0);

    return $this;
   }

#-----------------------------Event-Handlers----------------------------------#

sub NoticeChild
   {
    my ($this, $p_Child) = (shift, @_);

    return unless ($p_Child->class() eq 'ColumnButton');

    push (@{$this->{'m_ButtonList'}}, $p_Child);

    my $l_ColumnIndex = $#{$this->{'m_ButtonList'}};

    $p_Child->grid
       (
        '-column' => $l_ColumnIndex,
        '-sticky' => 'nsew',
        '-row' => 0,
        '-ipadx' => 0,
        '-padx' => 0,
       );

    for (my $l_Index = 0; $l_Index <= $l_ColumnIndex; ++$l_Index)
       {
        $this->gridColumnconfigure ($l_Index, '-weight' => 0);
       }

    $this->gridColumnconfigure ($l_ColumnIndex, '-weight' => 1);

    if (defined ($this->{'Configure'}{'-master'}))
       {
        $this->{'Configure'}{'-master'}->NoticeChild (@_);
       }
   }

sub SlaveUpdate
   {
    foreach my $l_Button ($_[0]->buttons())
       {
        $l_Button->SlaveUpdate() if (defined ($l_Button));
       }
   }

sub AdjustButtonList
   {
    my @l_Array;

    foreach my $l_Button ($_[0]->buttons())
       {
        push (@l_Array, $l_Button) if (Exists ($l_Button));
       }

    return @{$_[0]->{'m_ButtonList'} = \@l_Array};
   }

#------------------------------- Private methods -----------------------------#

sub __configall
   {
    if (defined ($_[2]))
       {
        $_[0]->{'Configure'}{$_[1]} = $_[2];

        foreach my $l_Button ($_[0]->buttons())
           {
            $l_Button->configure ($_[1] => $_[2]);
            # $_[0]->DoWhenIdle (['configure', $l_Button, $_[1] => $_[2]]);
           }
       }

    return ($_[0]->{'Configure'}{$_[1]});
   }

#-----------------------------'METHOD'-type-settings--------------------------#

sub buttoncommand {return shift->__configall ('-buttoncommand', @_);}
sub selectcommand {return shift->__configall ('-selectcommand', @_);}
sub sortcommand   {return shift->__configall ('-sortcommand', @_);}
sub borderwidth   {return shift->__configall ('-borderwidth', @_);}
sub background    {return shift->__configall ('-background', @_);}
sub foreground    {return shift->__configall ('-foreground', @_);}
sub trimcount     {return shift->__configall ('-trimcount', @_);}
sub font          {return shift->__configall ('-font', @_);}
sub sort          {return shift->__configall ('-sort', @_);}
sub zoom          {return shift->__configall ('-zoom', @_);}
sub image         {return shift->__configall ('-image', @_);}

#------------------------------- Public methods -----------------------------#

sub buttons
   {
    return @{$_[0]->{'m_ButtonList'}};
   }

sub labels
   {
    return map {$_->cget ('-text')} ($_[0]->buttons());
   }

sub buttonhash
   {
    return {map {$_->cget ('-text'), $_} ($_[0]->buttons())};
   }

*hash = \&Tk::__ButtonContainer::listhash;

sub listhash
   {
    return {map {$_->cget ('-text'), $_->cget ('-slave')} ($_[0]->buttons())};
   }

sub buttoncontainer
   {
    return $_[0];
   }

*buttonwidth = \&Tk::__ButtonContainer::columnwidth;
*width = \&Tk::__ButtonContainer::columnwidth;

sub columnwidth
   {
    my ($this, $p_Column, $p_Width) = @_;
    
    my $l_Button = $this->indexedbutton ($p_Column);

    return unless defined ($l_Button);

    return $l_Button->cget ('-width') unless ($p_Width >= 0 && $p_Width <= 1024);

    $l_Button->configure ('-width' => $p_Width);

    return $p_Width;
   }

1;

#======================================================================#
#   This is a private class used only by the Columns
#======================================================================#
package Tk::__ListContainer;

use Tk::TiedListbox;
use Tk::Frame;
use Tk;

use base qw (Tk::Frame);
use strict;
use Carp;

Tk::Widget->Construct ('__ListContainer');

sub Populate
   {
    my $this = shift;

    $this->SUPER::Populate (@_);

    $this->{'m_Lists'} = [];

    $this->ConfigSpecs
       (
        '-background' => ['METHOD', 'background', 'Background', 'white'],
 	'-selectmode' => ['METHOD', 'selectmode', 'SelectMode', 'single'],
        '-foreground' => ['METHOD', 'foreground', 'Foreground', 'black'],
        '-master' => ['PASSIVE'],
	'-font' => ['METHOD'],
       );

    $this->ConfigSpecs
       (
        '-listforeground' => '-foreground',
        '-listbackground' => '-background',
        '-listselectmode' => '-selectmode',
        '-listcolor' => '-background',
        '-color' => '-background',
        '-listfont' => '-font',
       );

    return $this;
   }

#-----------------------------Event-Handlers----------------------------------#

sub NoticeChild
   {
    my ($this, $p_Child) = (shift, @_);

    my $l_Length = ($#{$this->{'m_Lists'}} > -1 ? ${$this->{'m_Lists'}}[0] : $p_Child)->size();
    my @l_ListArray;

    foreach my $l_Slave ($this->lists())
       {
        $l_Slave->pack ('-expand' => 'false');
       }

    for (my $l_Index = 0; $l_Index < $l_Length; ++$l_Index)
       {
        push (@l_ListArray, undef);
       }

    $p_Child->DoWhenIdle (['insert', $p_Child, 'end', @l_ListArray]) if ($#l_ListArray > -1);
    push (@{$this->{'m_Lists'}}, $p_Child);
    @l_ListArray = ();

    foreach my $l_Slave ($this->lists())
       {
        push (@l_ListArray, $l_Slave) if ($l_Slave->class() eq 'Listbox');
       }

    $p_Child->pack ('-side' => 'left', '-anchor' => 'nw', '-expand' => 'true', '-fill' => 'both', '-padx' => 0); 
    $l_ListArray[0]->tie ('all', [@l_ListArray [1..$#l_ListArray]]);
    $this->eventGenerate ('<Expose>');
   }

#------------------------------- Private methods -----------------------------#

sub __configall
   {
    my ($this, $p_Option, $p_Value) = @_;

    if (defined ($p_Value))
       {
        $this->{'Configure'}{$p_Option} = $p_Value;

        foreach my $l_List ($this->lists())
           {
            $this->DoWhenIdle
               (
                [
                 $l_List->isa ('Tk::Listbox') ? 'Tk::Listbox::configure' : 'configure',
                 $l_List,
                 $p_Option => $p_Value
                ]
               );
           }

        $this->DoWhenIdle (sub {$this->SlaveUpdate();});
       }

    return ($this->{'Configure'}{$p_Option});
   }

#-----------------------------'METHOD'-type-settings--------------------------#

sub background {return shift->__configall ('-background', @_);}
sub foreground {return shift->__configall ('-foreground', @_);}
sub selectmode {return shift->__configall ('-selectmode', @_);}
sub font       {return shift->__configall ('-font', @_);}

#------------------------------- Public methods -----------------------------#

sub lists
   {
    return @{$_[0]->{'m_Lists'}};
   }

sub size
   {
    return ($#{$_[0]->{'m_Lists'}} > -1 ? ${$_[0]->{'m_Lists'}}[0]->size() : 0);
   }

sub rows
   {
    return $_[0]->size();
   }

sub listcontainer
   {
    return $_[0];
   }

sub selection
   {
    ${$_[0]->{'m_Lists'}}[0]->selection (@_) if ($#{$_[0]->{'m_Lists'}} > -1);
   }

sub curselection
   {
    return ($#{$_[0]->{'m_Lists'}} > -1 ? ${$_[0]->{'m_Lists'}}[0]->curselection() : ());
   }

sub activate
   {
    ${$_[0]->{'m_Lists'}}[0]->activate (@_) if ($#{$_[0]->{'m_Lists'}} > -1);
   }

sub nearest
   {
    return ($#{$_[0]->{'m_Lists'}} > -1 ? ${$_[0]->{'m_Lists'}}[0]->nearest (@_) : undef);
   }

sub see
   {
    ${$_[0]->{'m_Lists'}}[0]->see (@_) if ($#{$_[0]->{'m_Lists'}} > -1);
   }

1;

#======================================================================#
#
#======================================================================#
package Tk::Columns;

use Tk::Frame;
use Tk::Pane;
use Tk;

use base qw (Tk::Frame);
use strict;
use Carp;

Tk::Widget->Construct ('Columns');

sub ClassInit
   {
    $_[1]->bind ($_[0], '<Visibility>', ['CheckScrollbars']);
    $_[1]->bind ($_[0], '<Expose>', ['CheckScrollbars']);
   }

sub Populate
   {
    my $this = shift;

    $this->SUPER::Populate (@_);

    my $l_ButtonPane = $this->Component
       (
        'Pane' => 'ButtonPane',
        '-sticky' => 'nsew',
        '-borderwidth' => 0,
       );

    my $l_SlavePane = $this->Component
       (
        'Pane' => 'SlavePane',
        '-sticky' => 'nsew',
        '-borderwidth' => 0,
       );

    my $l_HScrollbar = $this->Component
       (
        'Scrollbar' => 'HScroll',
        '-elementborderwidth' => 1,
        '-orient' => 'horizontal',
       );

    my $l_VScrollbar = $this->Component
       (
        'Scrollbar' => 'VScroll',
        '-elementborderwidth' => 1,
        '-orient' => 'vertical',
       );

    my $l_ButtonContainer = $l_ButtonPane->Component
       (
        '__ButtonContainer' => 'ButtonContainer',
        '-master' => $this,
       );

    my $l_ListContainer = $l_SlavePane->Component
       (
        '__ListContainer' => 'ListContainer',
        '-background' => 'white',
        '-borderwidth' => 0,
        '-master' => $this,
       );

    my $l_UR = $this->Frame
       (
        '-relief' => 'raised',
        '-borderwidth' => 0,
        '-height' => 0,
        '-width' => 0,
       );

    my $l_Shadow = $l_UR->Frame
       (
        '-background' => $l_UR->Darken ($l_UR->cget ('-background'), 50),
        '-relief' => 'flat',
        '-borderwidth' => 1,
        '-height' => 0,
        '-width' => 1,
       );

    my $l_BR = $this->Frame
       (
        '-relief' => 'flat',
        '-borderwidth' => 0,
        '-height' => 0,
        '-width' => 0,
       );

    $this->ConfigSpecs
       (
        '-buttonbackground' => [$l_ButtonContainer],
        '-buttonforeground' => [$l_ButtonContainer],
        '-buttoncommand' => [$l_ButtonContainer],
        '-selectcommand' => [$l_ButtonContainer],
        '-listforeground' => [$l_ListContainer],
        '-listbackground' => [$l_ListContainer],
        '-borderwidth' => [$l_ButtonContainer],
        '-buttoncolor' => [$l_ButtonContainer],
        '-buttonfont' => [$l_ButtonContainer],
        '-trimcount' => [$l_ButtonContainer],
	'-selectmode' => [$l_ListContainer],
        '-background' => [$l_ListContainer],
        '-foreground' => [$l_ListContainer],
        '-command' => [$l_ButtonContainer],
        '-listcolor' => [$l_ListContainer],
        '-listfont' => [$l_ListContainer],
        '-image' => [$l_ButtonContainer],
        '-zoom' => [$l_ButtonContainer],
        '-font' => [$l_ListContainer],
        '-columns' => ['METHOD'],
        'DEFAULT' => [$l_ButtonContainer],
       );

    $this->ConfigSpecs
       (
        '-command' => '-selectcommand',
        '-columnlabels' => '-columns',
        '-font' => '-listfont',
        '-bg' => '-background',
       );

    $l_ButtonContainer->ConfigSpecs
       (
        '-listbackground' => [$l_ListContainer],
        '-listforeground' => [$l_ListContainer],
        '-listselectmode' => [$l_ListContainer],
        '-listfont' => [$l_ListContainer],
       );

    $this->Delegates
       (
        'buttoncontainer' => $l_ButtonContainer,
        'SlaveUpdate' => $l_ButtonContainer,
        'columnwidth' => $l_ButtonContainer,
        'buttonwidth' => $l_ButtonContainer,
        'buttonhash' => $l_ButtonContainer,
        'Construct' => $l_ButtonContainer,
        'listhash' => $l_ButtonContainer,
        'DEFAULT' => $l_ButtonContainer,
        'buttons' => $l_ButtonContainer,
        'labels' => $l_ButtonContainer,
        'width' => $l_ButtonContainer,
        'hash' => $l_ButtonContainer,
       );

    $this->Delegates
       (
        'listcontainer' => $l_ListContainer,
        'curselection' => $l_ListContainer,
        'selection' => $l_ListContainer,
        'activate' => $l_ListContainer,
        'nearest' => $l_ListContainer,
        'lists' => $l_ListContainer,
        'size' => $l_ListContainer,
        'rows' => $l_ListContainer,
        'see' => $l_ListContainer,
       );

    $l_ListContainer->Delegates
       (
        'SlaveUpdate' => $l_ButtonContainer,
        'buttoncontainer' => $l_ButtonContainer,
        'buttons' => $l_ButtonContainer,
       );

    $l_HScrollbar->configure
       (
        '-command' => sub
           {
            $l_ButtonPane->xview (@_);
            $l_SlavePane->xview (@_);
           }
       );

    $l_ButtonPane->configure ('-xscrollcommand' => sub {$l_HScrollbar->set (@_);});
    $l_SlavePane->configure ('-xscrollcommand' => sub {$l_HScrollbar->set (@_);});
    $l_ButtonContainer->bind ('<Expose>', sub {$this->CheckScrollbars();});
    $l_ListContainer->bind ('<Expose>', sub {$this->CheckScrollbars();});
    $this->GridConfigure();

    $l_ButtonContainer->pack ('-side' => 'left', '-anchor' => 'nw', '-expand' => 'true', '-fill' => 'x');
    $l_ListContainer->pack ('-side' => 'left', '-anchor' => 'nw', '-expand' => 'true', '-fill' => 'both');
    $l_Shadow->pack ('-side' => 'left', '-anchor' => 'nw', '-expand' => 'false', '-fill' => 'y',); 
    $l_ButtonPane->grid ('-sticky' => 'nsew', '-column' => 0, '-row' => 0);
    $l_SlavePane->grid ('-sticky' => 'nsew', '-column' => 0, '-row' => 1);
    $l_HScrollbar->grid ('-sticky' => 'nsew', '-column' => 0, '-row' => 2);
    $l_VScrollbar->grid ('-sticky' => 'nsew', '-column' => 1, '-row' => 1);
    $l_UR->grid ('-sticky' => 'nsew', '-column' => 1, '-row' => 0);
    $l_BR->grid ('-sticky' => 'nsew', '-column' => 1, '-row' => 2);

    return $this;
   }

#-----------------------------Event-Handlers----------------------------------#

sub GridConfigure
   {
    $_[0]->gridColumnconfigure ( 0, '-minsize' => 0, '-weight' => 1); 
    $_[0]->gridColumnconfigure ( 1, '-minsize' => 0, '-weight' => 0); 
    $_[0]->gridRowconfigure ( 0, '-weight' => 0);
    $_[0]->gridRowconfigure ( 1, '-minsize' => 0, '-weight' => 1);
    $_[0]->gridRowconfigure ( 2, '-minsize' => 0, '-weight' => 0);
   }

sub CheckScrollbars
   {
    my $l_HScrollbar = $_[0]->Subwidget ('HScroll');
    my $l_VScrollbar = $_[0]->Subwidget ('VScroll');

    if ($l_VScrollbar->Needed() && ! $l_VScrollbar->IsMapped())
       {
        $l_VScrollbar->grid ('-sticky' => 'nsew', '-column' => 1, '-row' => 1);
       }
    elsif (! $l_VScrollbar->Needed() && $l_VScrollbar->IsMapped())
       {
        $l_VScrollbar->gridForget();
       }

    if ($l_HScrollbar->Needed() && ! $l_HScrollbar->IsMapped())
       {
        $l_HScrollbar->grid ('-sticky' => 'nsew', '-column' => 0, '-row' => 2);
       }
    elsif (! $l_HScrollbar->Needed() && $l_HScrollbar->IsMapped())
       {
        $l_HScrollbar->gridForget();
       }
   }

sub NoticeChild
   {
    my ($this, $p_Child) = (shift, @_);

    return unless ($p_Child->class() eq 'ColumnButton');

    my $l_List = $this->listcontainer()->Listbox
       (
        '-highlightthickness' => 0,
        '-exportselection' => 0,
        '-borderwidth' => 0,
        '-relief' => 'flat',
       );

    $this->DoWhenIdle (['configure', $p_Child, '-slave' => $l_List]);
    $this->DoWhenIdle (['ScrollbarBind', $this]);
   }

sub ScrollbarBind
   {
    my $this = shift;

    return if (defined ($this->{'m_PrimaryList'}) && Exists ($this->{'m_PrimaryList'}));

    my $l_PrimaryList = $this->{'m_PrimaryList'} = ($this->lists())[0];
    my $l_VScrollbar = $this->Subwidget ('VScroll');

    return unless (defined ($l_PrimaryList) && defined ($l_VScrollbar));

    $l_VScrollbar->configure
       (
        '-command' => sub {$l_PrimaryList->yview (@_);}
       );

    $l_PrimaryList->configure
       (
        '-yscrollcommand' => sub {$l_VScrollbar->set (@_);},
       );
   }

#------------------------------- Private methods -----------------------------#

sub __insert
   {
    my ($this, $p_Where, @p_Data) = @_;

    my @l_ColumnList = $this->lists();
    my $l_ColumnHash = $this->hash();

    my $l_Cursor = 0;
    my @l_ColumnData;
    my %l_Indices;

    #=============================
    # Build mutual cross references
    #=============================

    foreach my $l_Key (keys %{$l_ColumnHash})
       {
        for (my $l_Index = 0; $l_Index <= $#l_ColumnList; ++$l_Index)
           {
            $l_Indices {$l_Key} = $l_Index if ($l_ColumnList [$l_Index] eq $l_ColumnHash->{$l_Key});
           }
       }

    #=============================
    # Build Columnar data arrays
    #=============================

    foreach my $l_Datum (@p_Data)
       {
        if ((ref ($l_Datum) eq 'HASH' || ref ($l_Datum) eq 'ARRAY') && $l_Cursor > 0)
           {
            while ($l_Cursor <= $#l_ColumnList)
               {
                push (@{$l_ColumnData [$l_Cursor++]}, '');
               }

            $l_Cursor = 0;
           }

        if (ref ($l_Datum) eq 'HASH')
           {
            foreach my $l_Key (keys %{$l_ColumnHash})
               {
                push (@{$l_ColumnData [$l_Indices {$l_Key}]}, $l_Datum->{$l_Key});
               }
           }
        elsif (ref ($l_Datum) eq 'ARRAY')
           {
            for (my $l_Index = 0; $l_Index <= $#l_ColumnList; ++$l_Index)
               {
                push (@{$l_ColumnData [$l_Index]}, ${$l_Datum}[$l_Index]);
               }
           }
        else
           {
            push (@{$l_ColumnData [$l_Cursor++]}, $l_Datum);
           }
       }

    while ($l_Cursor <= $#l_ColumnList && $l_Cursor > 0)
       {
        push (@{$l_ColumnData [$l_Cursor++]}, '');
       }

    #=============================
    # Insert Column data by column
    #=============================
    for (my $l_Index = 0; $l_Index <= $#l_ColumnList; ++$l_Index)
       {
        next if ($p_Where eq '');
        $l_ColumnList [$l_Index]->insert ($p_Where, @{$l_ColumnData [$l_Index]});
       }

    $this->buttoncontainer()->SlaveUpdate();
   }

sub __update
   {
    my ($this, $p_Code, @p_Contents) = (shift, @_);

    $this->__delete ($p_Code, $p_Code);
    $this->__insert ($p_Code, @p_Contents);
   }

sub __delete
   {
    my $this = shift;

    foreach my $l_Column ($this->lists())
       {
        next unless ($_[0] ne '');
        $l_Column->delete (@_);
       }
   }

#-----------------------------'METHOD'-type-settings--------------------------#

*columnlabels = \&Tk::Columns::columns;

sub columns
   {
    my $this = shift;

    foreach my $l_Item (@{$_[0]})
       {
        if (ref ($l_Item) eq 'ARRAY')
           {
            $this->addcolumn (@{$l_Item});
           }
        elsif (ref ($l_Item) eq '')
           {
            $this->addcolumn ('-text' => $l_Item);
           }
       }
   }

#------------------------------- Public methods -----------------------------#

*Column = \&Tk::Columns::addcolumn;
*Button = \&Tk::Columns::addcolumn;
*column = \&Tk::Columns::addcolumn;
*button = \&Tk::Columns::addcolumn;

sub addcolumn
   {
    return shift->ColumnButton (@_);
   }

sub insert
   {
    $_[0]->DoWhenIdle (['__insert', @_]);
   }

*replace = \&Tk::Columns::update;

sub update
   {
    $_[0]->DoWhenIdle (['__update', @_]);
   }

sub delete
   {
    $_[0]->DoWhenIdle (['__delete', @_]);
   }

sub bbox
   {
    my $l_Listbox = $_[0]->indexedlist ($_[2] || 0);

    return (defined ($l_Listbox) ? $l_Listbox->bbox ($_[1]) : ());
   }

sub get # This returns a list of references to row data arrays
   {
    my $this = shift;
    my @l_Return;

    foreach my $l_Listbox ($this->lists())
       {
        my $l_Index = 0;

        foreach my $l_Datum ($l_Listbox->get (@_))
           {
            push (@{$l_Return [$l_Index++]}, $l_Datum);
           }
       }

    return (@l_Return);
   }

sub index
   {
    my ($l_Column) = (shift->lists());

    return (defined ($l_Column) ? $l_Column->index (@_) : undef);
   }

sub indexedbutton
   {
    return
       (
        ($_[1] =~ /^[0-9][0-9]*$/ || ! defined ($_[1])) ?
        ($_[0]->buttons())[int ($_[1])] :
        $_[0]->buttonhash()->{$_[1]}
       );
   }

sub indexedlist
   {
    return
       (
        ($_[1] =~ /^[0-9][0-9]*$/ || ! defined ($_[1])) ?
        ($_[0]->lists())[int ($_[1])] :
        $_[0]->listhash()->{$_[1]}
       );
   }

1;

__END__


=cut

=head1 NAME

Tk::Columns - A multicolumn list widget with sortable & sizeable columns

=head1 SYNOPSIS

    use Tk::Columns;

    $Columns = $parent->B<Columns>
       (
        '-columnlabels' => [qw (column1 column2)]
        '-listbackground' => 'white',
        '-listforeground' => 'black',
        '-buttonforeground' => 'black',
        '-buttonbackground' => 'blue',
       );

    $ColumnHeader = $Columns->B<ColumnButton>
       (
        '-listfont' => '-adobe-new century schoolbook-medium-r-normal--14-*-*-*-*-*-*-*',
        '-buttoncolor' => 'beige',
        '-text' => 'column3',
        '-width' => 15,
        '-trimcount' => 2,
        '-listbackground' => 'white',
        '-listforeground' => 'black',
        '-buttonforeground' => 'black',
        '-buttonbackground' => 'blue',
        '-sort' => 'true',
        '-sortcommand' => '$a cmp $b',
        '-image' => $icon_image,
        '-buttoncommand' => sub {...},
        '-selectcommand' => sub {...}
       );

   $Columns->insert ('end', ['List', 'Row', 'Contents']);
   $Columns->insert ('end', {'column1' => 'List', 'column2' => 'Row', 'column3' => 'Contents'});
   $Columns->insert ('end', 'List', 'Row', 'Contents');
   $Columns->delete (0, 'end');

   ...

   Tk::MainLoop;

=head1 DESCRIPTION

Implements a multicolumn list with resizeable, scrollable columns and configurable
sorting by column. Other features include column selection callbacks and row selection
callbacks, global and per-column color and font selection, and column insertion
data specified by column label (hash) or by index (list).


=head1 STANDARD OPTIONS

=over 4

=item Columns

I<-background -foreground -font -bg>

=back

=over 4

=item ColumnButton

I<-font -image -foreground -background -borderwidth -relief -text -width -bg>

=back

See I<Tk> for details of the standard options.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:	B<buttonbackground>

=item Class:	B<ButtonBackground>

=item Switch:	B<-buttonbackground>

=item Aliases:	B<-buttoncolor> B<-color>

Specifies the background (surface) color for all existing buttons

=back

=over 4

=item Name:	B<buttoncommand>

=item Class:	B<ButtonCommand>

=item Switch:	B<-buttoncommand>

Specifies a callback to be executed when a column header is clicked. The
callback is passed the list index. When specified, this callback is
registered for every existing listbox and sets the default for new ones.
If the B<-sort> option is turned on, it overrides this option but does
not negate it, allowing it to return when the B<-sort> option is turned off.

=back

=over 4

=item Name:	B<buttonfont>

=item Class:	B<ButtonFont>

=item Switch:	B<-buttonfont>

Specifies the font to use for all the existing column header labels

=back

=over 4

=item Name:	B<columns>

=item Class:	B<Columns>

=item Switch:	B<-columns>

=item Aliases:	B<-columnlabels>

This option takes a reference to a list of options. If the list consists of
scalar values, these are assumed to be the labels for column headers. These
elements are created with default options which should normally be alright.
If the list consists of references to arrays, then these are assumed to be
key => value pairs specifying the options to pass to $Columns->B<addcolumn>.

=back

=over 4

=item Name:	B<image>

=item Class:	B<Image>

=item Switch:	B<-image>

Setting this to a reference to a Tk::Image causes that image to be set for all
of the column labels and sets the default for all future columns. By default
column headers are displayed without icons.

See L<Tk::Label>

=over 4

=item Name:	B<listbackground>

=item Class:	B<ListBackground>

=item Switch:	B<-listbackground>

=item Aliases:	B<-listcolor> B<-background> B<-bg>

Specifies the background (surface) color for all existing listboxes and sets the default for all new ones. Default is 'white'

=back

=over 4

=item Name:	B<listfont>

=item Class:	B<ListFont>

=item Switch:	B<-listfont>

=item Alias:	B<-font>

Specifies the font for all existing listboxes and sets the default for all
new ones. The default is to use the system default font.

=back

=over 4

=item Name:	B<listforeground>

=item Class:	B<ListForeground>

=item Switch:	B<-listforeground>

Specifies the foreground (writing) color for all existing listboxes and sets the default for all new ones. Default is 'black'

=back

=over 4

=item Name:	B<selectcommand>

=item Class:	B<SelectCommand>

=item Switch:	B<-selectcommand>

=item Aliases:	B<-command>

Specifies a callback to be executed when a list entry is double-clicked.
The callback is passed the list index. When specified, this callback is
registered for every existing listbox and sets the default for new ones.

=back

=over 4

=item Name:	B<selectmode>

=item Class:	B<SelectMode>

=item Switch:	B<-selectmode>

Sets the selection mode for all existing listboxes and sets the default to
use for new ones. The default is 'browse'.

=back

=over 4

=item Name:	B<trimcount>

=item Class:	B<TrimCount>

=item Switch:	B<-trimcount>

Specifies the number of button trim 'handles' for all existing buttons.

=back

=over 4

=item Name:	B<zoom>

=item Class:	B<Zoom>

=item Switch:	B<-zoom>

This option takes a boolean argument. When set to 1, all the existing columns
are 'zoomed', that is, reduced to their smallest width. When set to 0, all the
columns are returned to the original widths

=back


=head1 WIDGET METHODS

=over 4

=item I<$Button> = I<$Columns>->B<ColumnButton> (I<option> => B<value>, ...)

=item I<$Button> = I<$Columns>->B<addcolumn> (I<option> => B<value>, ...)

=item I<$Button> = I<$Columns>->B<Column> (I<option> => B<value>, ...)

=item I<$Button> = I<$Columns>->B<Button> (I<option> => B<value>, ...)

=item I<$Button> = I<$Columns>->B<column> (I<option> => B<value>, ...)

Creates a column header and an attached listbox. The listbox is 'tied' to any preexisting
ones. The new listbox is padded with empty rows to match its siblings. This method really
invokes an instantiation of the ColumnButton class. All the options given apply to the
ColumnButton. The widget reference returned can be used to alter the column's behaviour
later. The following options are available :-

=over 8

Z<>

=item B<-background> => B<color>

=item B<-buttonbackground> => B<color>

=item B<-bg> => B<color>

=item B<-buttoncolor> => B<color>

=item B<-color> => B<color>

Specifies the button's background (surface) color.

=back

=over 8

Z<>

=item B<-buttoncommand> => B<callback>

Specifies a callback to be executed when a column header is clicked. The
callback is passed the list index. If the B<-sort> option is turned on,
it overrides this option but does not negate it, allowing it to return
when the B<-sort> option is turned off.

=back

=over 8

Z<>

=item B<-font> => B<fontspec>

=item B<-buttonfont> => B<fontspec>

Specifies the font for the text in the button label.

=back

=over 8

Z<>

=item B<-foreground> => B<color>

=item B<-buttonforeground> => B<color>

=item B<-fg> => B<color>

Specifies the button's foreground (text) color. Defaults to black.

=back

=over 8

Z<>

=item B<-image> => B<image>

Setting this to a reference to a Tk::Image causes that image to be displayed in the
column label.

See L<Tk::Label>

=back

=over 8

Z<>

=item B<-listbackground> => B<color>

=item B<-slavecolor> => B<color>

Sets the background color for the attached listbox

=back

=over 8

Z<>

=item B<-listfont> => B<fontspec>

Specifies the font for the text in the attached listbox.

=back

=over 8

Z<>

=item B<-listforeground> => B<color>

Sets the foreground (text) color for the attached listbox.

=back

=over 8

Z<>

=item B<-listselectmode> => B<mode>

Sets the selection mode for the attached listbox.

=back

=over 8

Z<>

=item B<-selectcommand> => B<callback>

=item B<-command> => B<callback>

Specifies a callback to be executed when a list entry is double-clicked.
The callback is passed the list index.

=back

=over 8

Z<>

=item B<-slave> => B<widget>

DO NOT USE ! This option is use to inform the button which widget it must
manage. It is provided here only for completeness.

=back

=over 8

Z<>

=item B<-sort> => B<boolean>

Setting this to boolean 'true' allows all columns to be sorted by this column
when the button is pressed. Each invocation reverses the sort order. The sort
method can be specified with B<-sortcommand>. Setting this to boolean false (0)
disables the sorting. When active, this option overrides any existing
B<-buttoncommand>. When inactive, any preexisting B<-buttoncommand> is re-enabled.

=back

=over 8

Z<>

=item B<-sortcommand> => B<string>

=item B<-sortfunction> => B<string>

=item B<-sortmethod> => B<string>

This specifies the sort function to pass to the B<sort> Perl function for sorting
of this column. The default is '{lc ($a) cmp lc ($b)}' for (caseless) alphanumeric
comparison.

Read the B<perlfunc> documentation for more details on B<sort>.

=back

=over 8

Z<>

=item B<-trimcount> => B<integer>

Specifies the number of trim 'handles' for the button. It defaults to 2.
Setting it to 0 makes the column unresizeable.

=back

=over 8

Z<>

=item B<-width> => B<integer>

Set this to the desired width of the column, in characters. The default is the natural
width of the text and image parts combined.

=back

=over 8

Z<>

=item B<-zoom> => B<boolean>

This option takes a boolean argument. When set to 1, the column is 'zoomed',
that is, its width is reduced to the smallest possible setting. When set to 0,
the column is returned to its original width.

=back

=back

=over 4

=item I<$Columns>->B<activate>(I<index>) 

Sets the row element to the one indicated by index. If index is outside the
range of elements in the listbox then the closest element is activated. The
active element is drawn with an underline when the widget has the input focus,
and its index may be retrieved with the index active. 

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<bbox>(I<index>, I<[columnspec]>)

Returns a list of four numbers describing the bounding box of the text in the
element given by index in the listbox specified by B<column> or the first listbox
in the composite. The first two elements of the list give the x and y coordinates
of the upper-left corner of the screen area covered by the text (specified in pixels
relative to the widget) and the last two elements give the width and height of the
area, in pixels. If no part of the element given by index is visible on the screen,
or if index refers to a non-existent element, then the result is an empty string;
if the element is partially visible, the result gives the full area of the element,
including any parts that are not visible. 

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<buttonhash>()

Returns a hash of column buttons keyed by column label

=back

=over 4

=item I<$Columns>->B<buttons>()

Returns an ordered list of the column buttons

=back

=over 4

=item I<$Columns>->B<buttonwidth>(I<columnspec>, I<?newwidth?>)

=item I<$Columns>->B<columnwidth>(I<columnspec>, I<?newwidth?>)

=item I<$Columns>->B<width>(I<columnspec>, I<?newwidth?>)

This uses the numeric or textual B<columnspec> to locate a column header and sets the
width to B<newwidth> if present, or returns the current width of that column. It the
column doesn't exist then the return value 0 is quietly returned.

=back

=over 4

=item I<$Columns>->B<columnlabels>(I<array reference>)

=item I<$Columns>->B<columns>(I<array reference>)

This invokes I<$Columns>->configure (I<-columnlabels> => B<array reference>). See B<-columnlabels>
for details as this is a convenience method.

=back

=over 4

=item I<$Columns>->B<curselection>()

Returns a list containing the numerical indices of all of the elements in the
listbox that are currently selected. If there are no elements selected in the
listbox then an empty string is returned. 

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<delete>(I<where>, I<where>)

This has identical behaviour to listbox->B<delete>.

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<get>(I<from>, I<to>)

Retrieves the rows in the range I<from> .. I<to>. This method is an
analog of the I<listbox>->B<get> method. The data returned is
an array of references to the row lists specified.

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<index>(I<index>)

Returns the integer index value that corresponds to index. If index is end the
return value is a count of the number of elements in the listbox (not the index
of the last element). 

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<indexedbutton>(I<columnspec>)

Returns the column button associated with the numeric column index or the textual column
name.

=back

=over 4

=item I<$Columns>->B<indexedlist>(I<columnspec>)

Returns the listbox associated with the numeric column index or the textual column
name.

=back

=over 4

=item I<$Columns>->B<insert>(I<where>, ?<option>?, ...)

This method inserts rows across all listboxes. B<where> is the same as documented in the
B<listbox> pod. The following options can be a list of scalars, a list of references to
hashes, or a list of references to arrays. These can appear in any order. A list of scalars
will be interpreted up to an array reference or the end of the parameter list, whichever comes
first. The list is padded out so it can be applied to all listboxes. It is then inserted using
B<where>.

An array reference is dereferenced and applied just as the inline list. A hash is assumed to
be keyed by the column header labels. It is converted into a list using the column header order
and applied normally after 'padding'.

NOTE: The insertions are 'cached' and then applied to each listbox at once, avoiding flicker and
slow updates.

=back

=over 4

=item I<$Columns>->B<labels>()

Returns an ordered list of the column names

=back

=over 4

=item I<$Columns>->B<listhash>()

=item I<$Columns>->B<hash>()

Returns a hash of listboxes keyed by column label

=back

=over 4

=item I<$Columns>->B<lists>()

Returns an ordered list of the column listboxes

=back

=over 4

=item I<$Columns>->B<nearest>(I<y>)

Given a y-coordinate within the listbox window, this command returns the index of the
(visible) listbox element nearest to that y-coordinate. 

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<selection> (I<option>, I<argument>)

Adjusts the selection. It has several forms, depending on B<option>.

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<see>(I<index>)

Makes row I<index> visible.

See I<listbox> for more details.

=back

=over 4

=item I<$Columns>->B<size>()

=item I<$Columns>->B<rows>()

Returns the number of rows.

=back

=over 4

=item I<$Columns>->B<update>(I<where>, ...)

=item I<$Columns>->B<replace>(I<where>, ...)

This takes the same options as <$Columns>->B<insert> but deletes the row found there first.

=back

=head1 BINDINGS

=over 4

=item B<[1]>

Pressing and releasing the left mouse button on a columns label will cause the B<-sortcommand> or the default
sort method to be invoked if the B<-sort> option has been enabled. Otherwise, the callback
specified in B<-buttoncommand> is invoked if it is defined.

=item B<[2]>

Double-clicking the left mouse button on any listbox will cause the callback specified by
B<-selectcommand> to be invoked with the row index of the selected listbox item.

=item B<[3]>

Pressing and releasing the right mouse button on the column label trim elements will cause that column to 'zoom'.
That is, it will collapse the column to its smallest size without the need to drag it. When pressed
again, the column will return to its original size. The mouse pointer will change to a 'resize' form
when this action is possible.

=item B<[4]>

Pressing the left mouse button on the column label trim elements will initiate resizing of that column. The edge of
the column will follow the mouse horizontally until the button is released whereupon the column will remain
at the selected size. The mouse pointer will change to a 'resize' form when this action is possible.

=back

=head1 REQUIREMENTS

=over 4

=item B<Tk::TiedListbox> from B<Tk-Contrib-0.06>

=back

=head1 CAVEATS

I regret that there appears to be no way to justify the listboxes. If anyone knows, please
tell me how.

=head1 AUTHORS

Damion K. Wilson, dwilson@ibl.bm, http://pwp.ibl.bm/~dkw

=head1 COPYRIGHT

Copyright (c) 1999 Damion K. Wilson.

All rights reserved.

This program is free software, you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 HISTORY 

=over 4

=item B<July 4, 1999>: fixed scrollbar redisplay failure after insertion bug

=item B<September 1, 1999>: Rewrite with legacy support

=item B<November 25, 1999>: Fixed index and delete methods

=back

=cut
