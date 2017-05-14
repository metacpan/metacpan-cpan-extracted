package Tk::TableEdit;

use Tk;
use Tk::TabbedForm;
use Tk::SplitFrame;
use Tk::Columns;
use Tk::Frame;
use Tk::Pane;

use base qw (Tk::Derived Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.01';

Tk::Widget->Construct ('TableEdit');

*separator = \&Tk::TableEdit::Separator;
*file = \&Tk::TableEdit::File;
*Save = \&Tk::TableEdit::Commit;
*Load = \&Tk::TableEdit::Fetch;

sub Populate
   {
    my ($this, $p_Parameters) = (shift, @_);

    my $l_SplitFrame = $this->{m_SplitWidget} = $this->Component
       (
        'SplitFrame' => 'SplitFrame',
        '-orientation' => 'vertical',
        '-sliderposition' => 120,
        '-padbefore' => 100,
        '-padafter' => 200,
       );

    my $l_ColumnWidget = $this->{m_ColumnWidget} = $l_SplitFrame->Component
       (
        'Columns' => 'Columns',
        '-command' => sub {$this->SelectRow (@_);},
       );

    my $l_Pane = $l_SplitFrame->Scrolled
       (
        'Pane',
        '-scrollbars' => 'osoe',
        '-relief' => 'flat',
        '-borderwidth' => 2,
        '-sticky' => 'nsew',
       );

    my $l_TabWidget = $this->{m_TabWidget} = $l_Pane->Component
       (
        'TabbedForm' => 'TabFrame',
       );

    my $l_ButtonFrame = $this->{m_ButtonFrame} = $this->Frame
       (
        '-borderwidth' => 0,
       );

    $this->ConfigSpecs
       (
        '-tabfont' => [$l_TabWidget],
        '-separator' => ['METHOD'],
        '-file' => ['METHOD'],
       );

    foreach my $l_Name (qw (Clear Insert Update Delete Reload Cancel OK Apply))
       {
        my $l_Button = $l_ButtonFrame->Button
           (
            '-command' => sub {$this->ButtonEvent ($l_Name, @_);},
            '-text' => $l_Name,
            '-borderwidth' => 1,
            '-relief' => 'raised',
           );

        $l_Button->pack
           (
            '-anchor' => 'nw',
            '-side' => 'left',
           );
       }

    $l_TabWidget->pack
       (
        '-fill' => 'both',
        '-expand' => 'true',
       );

    $l_SplitFrame->place
       (
        '-anchor' => 'nw',
        '-x' => 5,
        '-y' => 5,
        '-relwidth' => 1.0,
        '-relheight' => 1.0,
        '-height' => - (($l_ButtonFrame->children())[0]->reqheight() + 15),
        '-width' => - 10,
       );

    $l_ButtonFrame->place
       (
        '-x' => 5,
        '-y' => - 5,
        '-relwidth' => 1.0,
        '-rely' => 1.0,
        '-height' => ($l_ButtonFrame->children())[0]->reqheight(),
        '-width' => - 10,
        '-anchor' => 'sw',
       );

    $this->GeometryRequest
       (
        $l_SplitFrame->reqwidth(),
        $l_SplitFrame->reqheight() + $l_ButtonFrame->reqheight(),
       );

    $this->bind
       (
        '<Map>' => sub {$this->Fetch() if ($this->{m_Changes} == 2);}
       );

    $this->{m_SectionList} = [];
    $this->configure ('-separator' => '|');
    $this->SUPER::Populate (@_);
    $this->{m_Changes} = 2;
    return $this;
   }

sub Item
   {
    my $this = shift;

    my $l_Widget = $this->{m_TabWidget}->Item (@_);

    return unless (Exists ($l_Widget));

    if ($l_Widget->{m_SectionName} ne 'Global')
       {
        $this->{m_ColumnWidget}->configure
           (
            '-columnlabels' => [$this->{m_TabWidget}->GetItemNames ($this->GetSectionNameList())],
           );
       }

    return $l_Widget;
   }

sub SetItemValues
   {
    my ($this, @p_Values) = @_;

    my @l_ItemArray = $this->{m_TabWidget}->GetItemNames ($this->GetSectionNameList());

    for (my $l_Index = 0; $l_Index <= $#l_ItemArray; ++$l_Index)
       {
        $this->{m_TabWidget}->SetItemValue ($l_ItemArray [$l_Index], $p_Values [$l_Index]);
       }
   }

sub GetItemValues
   {
    my ($this) = @_;
    my @l_ItemArray = $this->{m_TabWidget}->GetItemNames ($this->GetSectionNameList());
    my @l_Array;

    for (my $l_Index = 0; $l_Index <= $#l_ItemArray; ++$l_Index)
       {
        push (@l_Array, $this->{m_TabWidget}->GetItemValue ($l_ItemArray [$l_Index]));
       }

    return @l_Array;
   }

sub GetSectionNameList()
   {
    return (grep (!/^Global/, $_[0]->{m_TabWidget}->GetSectionNames()));
   }

sub SelectRow
   {
    my $this = shift;

    my $l_CurrentIndex = $this->CurrentIndex ($this->{m_ColumnWidget}->curselection());

    $this->SetItemValues
       (
        $l_CurrentIndex > -1 ?
        $this->{m_ColumnWidget}->get ($l_CurrentIndex) :
        ()
       );
   }

sub CurrentIndex
   {
    my ($this, $p_Index) = (shift, @_);
    return $this->{m_ColumnWidget}->curselection() unless (defined ($p_Index));
    croak if ($p_Index < 0);
    $this->{m_ColumnWidget}->selectionClear (0, 'end');
    $this->{m_ColumnWidget}->selectionSet ($this->{m_Current} = $p_Index);
    return $p_Index;
   }

sub Fetch
   {
    my ($this) = (shift, @_);
    my $l_File = $this->cget (-file);
    my $l_Buffer;

    return unless (defined ($l_File));

    $this->{m_ColumnWidget}->delete (0, 'end');

    if (defined (open (FILE, '<'.$l_File)))
       {
        while (defined ($l_Buffer = <FILE>))
           {
            chomp $l_Buffer;

            $this->RecordIn (split ('\\'.$this->{m_Separator}, $l_Buffer));
           }

        $this->CurrentIndex (0);
        $this->{m_Changes} = 0;
        $this->SelectRow();
        close (FILE);
       }
   }

sub Commit
   {
    my ($this) = (shift, @_);
    my $l_File = $this->cget ('-file');
    my $l_Separator = $this->cget ('-separator');

    return unless ($this->{m_Changes} && defined ($l_File) && defined ($l_Separator));

    if (open (FILE, '>'.$l_File))
       {
        $this->Busy();

        printf FILE
           (
            "%s\n",
            join ($l_Separator, ('Global', $this->{m_TabWidget}->GetItemNames ('Global')))
           );

        printf FILE
           (
            "%s\n",
            join ($this->{m_Separator}, $this->RecordOut ('Global'))
           );

        printf FILE
           (
            "%s\n",
            join ($l_Separator, ('Normal', $this->{m_TabWidget}->GetItemNames ($this->GetSectionNameList())))
           );

        for (my $l_Index = 0; $l_Index < $this->{m_ColumnWidget}->size(); ++$l_Index)
           {
            printf FILE
               (
                "%s\n",
                join ($this->{m_Separator}, $this->RecordOut ($l_Index))
               );
           }

        $this->{m_Changes} = 0;
        $this->Unbusy();
        close (FILE);
       }
   }

sub RecordOut
   {
    my $this = shift;
    my $p_Index = shift;
    my @l_Array = ('');

    if ($p_Index eq 'Global')
       {
        foreach my $l_Key ($this->{m_TabWidget}->GetItemNames ('Global'))
           {
            push (@l_Array, $this->{m_TabWidget}->GetItemValue ($l_Key));
           }
       }
    elsif ($p_Index > -1)
       {
        push (@l_Array, $this->{m_ColumnWidget}->get ($p_Index));
       }

    return @l_Array;
   }

sub RecordIn
   {
    my $this = shift;
    my $l_Format = shift;

    if ($l_Format eq 'Global')
       {
        $this->{m_FormatType} = $l_Format;
        @{$this->{m_Format}} = @_;
       }
    elsif ($l_Format eq 'Normal')
       {
        my @l_ItemArray = $this->{m_TabWidget}->GetItemNames ($this->GetSectionNameList());
        $this->{m_FormatType} = $l_Format;
        @{$this->{m_Format}} = ();

        foreach my $l_Key (@_)
           {
            for (my $l_Index = 0; $l_Index <= $#l_ItemArray; ++$l_Index)
               {
                if ($l_Key eq $l_ItemArray [$l_Index])
                   {
                    push (@{$this->{m_Format}}, $l_Index);
                   }
               }
           }
       }
    elsif ($this->{m_FormatType} eq 'Global')
       {
        for (my $l_Index = 0; $l_Index <= $#{$this->{m_Format}}; ++$l_Index)
           {
            $this->{m_TabWidget}->SetItemValue (${$this->{m_Format}}[$l_Index], $_[$l_Index]);
           }
       }
    elsif ($this->{m_FormatType} eq 'Normal')
       {
        my @l_Array;

        foreach my $l_Index (@{$this->{m_Format}})
           {
            $l_Array [$l_Index] = shift;
           }

        $this->{m_ColumnWidget}->insert ('end', @l_Array);
       }
   }

sub Separator
   {
    return ($_[0]->{m_Separator} = (defined ($_[1]) ? $_[1] : $_[0]->{m_Separator}));
   }

sub File
   {
    return ($_[0]->{m_File} = (defined ($_[1]) ? $_[1] : $_[0]->{m_File}));
   }

sub ButtonEvent
   {
    my ($this, $p_Command) = (shift, @_);

    my $l_ColumnWidget = $this->{m_ColumnWidget};

    if ($p_Command eq 'Clear')
       {
        foreach my $l_Key ($this->{m_TabWidget}->GetItemNames ($this->GetSectionNameList()))
           {
            $this->{m_TabWidget}->SetItemValue ($l_Key);
           }
       }
    elsif ($p_Command eq 'Insert')
       {
        $l_ColumnWidget->insert ('end', $this->GetItemValues());
        $this->CurrentIndex ($l_ColumnWidget->size() - 1);
        $this->{m_Changes} = 1;
       }
    elsif ($p_Command eq 'Delete')
       {
        my $l_CurrentIndex = $this->CurrentIndex();
        $l_ColumnWidget->delete ($l_CurrentIndex);
        $this->CurrentIndex ($l_CurrentIndex - 1);
        $this->{m_Changes} = 1;
        $this->SelectRow();
       }
    elsif ($p_Command eq 'Reload')
       {
        $this->Fetch();
       }

    if ($p_Command eq 'Apply' || $p_Command eq 'OK' || $p_Command eq 'Update')
       {
        my $l_CurrentIndex = $this->CurrentIndex();
        $l_ColumnWidget->insert ($l_CurrentIndex, $this->GetItemValues());
        $l_ColumnWidget->delete ($l_CurrentIndex + 1);
        $this->CurrentIndex ($l_CurrentIndex);
        $this->{m_Changes} = 1;
       }

    if ($p_Command eq 'Apply' || $p_Command eq 'OK')
       {
        $this->Commit();
       }

    if ($p_Command eq 'OK' || $p_Command eq 'Cancel')
       {
        $this->toplevel()->destroy();
       }
   }

1;

__END__

=cut

=head1 NAME

Tk::TableEdit - A simple flat-file DBMS editor using Tk::SplitFrame, Tk::TabbedForm, and Tk::Columns

=head1 SYNOPSIS

    use Tk;

    my $MainWindow = MainWindow->new();

    Tk::MainLoop;

=head1 DESCRIPTION

A compound widget built from the TabbedForm, SplitFrame,
and Column widgets. It implements a simplified interface
to a flat file database. Try out the demo.

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

=head1 HISTORY 
 
=cut
