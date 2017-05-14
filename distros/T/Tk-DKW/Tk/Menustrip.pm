package Tk::Menustrip;

use Tk;
use Tk::Label;
use Tk::Button;
use Tk::Toplevel;

use base qw (Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.01';

Tk::Widget->Construct ('Menustrip');

sub Populate
   {
    my ($this, %p_Options) = (shift, @_);

    my $l_DefaultFont = delete $p_Options {'-font'} || '-*-Times-Medium-R-Normal--*-140-*-*-*-*-*-*';

    my $l_SubRef = sub
       {
        $this->configure ('-automenu' => 'false');
        $this->Hide();
       };

    $this->SUPER::Populate (@_);
    $this->toplevel()->bind ('<ButtonPress>' => $l_SubRef);
    $this->bind ('<ButtonPress-1>' => $l_SubRef);

    $this->ConfigSpecs
       (
        '-background' => [['SELF', 'CHILDREN', 'DESCENDANTS'], 'background', 'Background', $this->parent()->cget ('-background')],
        '-foreground' => [['SELF', 'PASSIVE', 'CHILDREN', 'DESCENDANTS'], 'foreground', 'Foreground', 'black'],
        '-borderwidth' => ['SELF', 'borderwidth', 'BorderWidth', 1],
        '-automenu' => ['METHOD', 'automenu', 'AutoMenu', 'false'],
        '-font' => ['PASSIVE', 'font', 'Font', $l_DefaultFont],
        '-relief' => ['SELF', 'relief', 'Relief', 'raised'],
       );

    $this->configure ('-font' => $l_DefaultFont);

    return $this;
   }

sub automenu
   {
    $_[0]->{'m_AutoMenu'} =
       (
        defined ($_[1]) ?
        ($_[1] eq 'true' || $_[1] > 0 || $_[1] eq 'on') :
        $_[0]->{'m_AutoMenu'}
       );
   }

sub MenuLabel
   {
    my ($this, $p_Caption, $p_Flag) = (shift, @_);

    my $l_Frame = $this->Component
       (
        'Frame' => $this->FixName ($p_Caption),
        '-borderwidth' => 2,
        '-relief' => 'flat',
       );

    my $l_Label = $l_Frame->Component
       (
        'Button' => 'Label',
        '-font' => $this->cget ('-font'),
        '-text' => $p_Caption,
        '-relief' => 'flat',
        '-borderwidth' => 0,
        '-padx' => 0,
        '-pady' => 0,
       );

    my $l_Popup = $l_Frame->Component
       (
        'Toplevel' => 'Popup',
        '-relief' => 'raised',
        '-borderwidth' => 1,
       );

    $l_Label->configure
       (
        '-activebackground' => $l_Label->cget ('-background'),
        '-highlightthickness' => 1,
       );

    $l_Label->pack
       (
        '-expand' => 'true',
        '-side' => 'left',
        '-ipadx' => 0,
        '-ipady' => 0,
        '-padx' => 0,
        '-pady' => 0,
       );

    $l_Frame->pack
       (
        '-side' => ($p_Flag eq '-right' ? 'right' : 'left'),
        '-anchor' => ($p_Flag eq '-right' ? 'ne' : 'nw'),
        '-fill' => 'y',
        '-padx' => 1,
        '-pady' => 1,
       );

    $l_Label->bind
       (
        '<ButtonPress-1>' => sub
           {
            $this->configure ('-automenu' => 'true');
            $this->Show ($l_Label);
            Tk->break;
           }
       );

    $l_Label->bind
       (
        '<Enter>' => sub
           {
            $this->Show ($l_Label) if ($this->cget ('-automenu'));
            Tk->break;
           }
       );

    $l_Label->bind
       (
        '<Return>' => sub
           {
            $this->configure ('-automenu' => 'true');
            $this->Show ($l_Label);
           }
       );

    $l_Label->bind
       (
        '<Down>' => sub
           {
            $this->configure ('-automenu' => 'true');
            $this->Show ($l_Label);
           }
       );

    $l_Label->bind
       (
        '<Right>' => sub
           {
            $l_Label->focusNext();
           }
       );

    $l_Label->bind
       (
        '<Left>' => sub
           {
            $l_Label->focusPrev();
           }
       );

    $l_Popup->bind
       (
        '<Escape>' => sub
           {
            $this->automenu ('false');
            $this->Hide();
           }
       );

    push (@{$this->{m_MenuList}}, $l_Label);
    $l_Popup->overrideredirect (1);
    $this->Hide ($l_Label);
   }

sub MenuEntry
   {
    my ($this, $p_Caption, $p_EntryCaption, $p_Action) = (shift, @_);

    unless (defined ($p_EntryCaption))
       {
        $this->MenuSeparator ($p_Caption);
        return;
       }

    unless (Exists ($this->Subwidget ($this->FixName ($p_Caption))))
       {
        $this->MenuLabel ($p_Caption);
        return unless Exists ($this->Subwidget ($this->FixName ($p_Caption)));
       }

    my $l_Popup = $this->Subwidget ($this->FixName ($p_Caption))->Subwidget ('Popup');

    my $l_Label = $l_Popup->Component
       (
        'Button' => $this->FixName ($p_EntryCaption),
        '-font' => $this->cget ('-font'),
        '-highlightthickness' => 1,
        '-text' => $p_EntryCaption,
        '-justify' => 'left',
        '-relief' => 'flat',
        '-borderwidth' => 1,
        '-anchor' => 'w',
        '-padx' => 5,
        '-pady' => 0,
       );

    $l_Popup->{'m_Focus'} = $l_Label unless (defined ($l_Popup->{'m_Focus'}));

    unless (ref ($p_Action) eq 'CODE')
       {
        $p_Action = sub {printf ("[%s]\n", $p_EntryCaption);};
       }

    $l_Label->configure
       (
        '-command' => sub
           {
            if ($l_Label->{m_Enabled} eq 'true')
               {
                $this->automenu ('false');
                $this->Hide();
                $this->afterIdle ($p_Action);
               }
           }
       );

    $l_Label->pack
       (
        '-expand' => 'true',
        '-anchor' => 'nw',
        '-side' => 'top',
        '-fill' => 'x',
        '-ipadx' => 0,
        '-ipady' => 0,
        '-padx' => 0,
        '-pady' => 0,
       );

    $l_Label->bind
       (
        '<Up>' => sub
           {
            $l_Label->focusPrev();
           }
       );

    $l_Label->bind
       (
        '<Down>' => sub
           {
            $l_Label->focusNext();
           }
       );

    $l_Label->bind
       (
        '<Left>' => sub
           {
            my $l_Header = $l_Popup->parent()->Subwidget ('Label');

            $this->Hide ($l_Header);
            $l_Header->focusPrev();

            my $l_Next = $this->toplevel()->focusCurrent();
            my $l_Found = 0;

            foreach my $l_Widget (@{$this->{m_MenuList}})
               {
                $l_Found = 1 if ($l_Next eq $l_Widget);
               }

            $this->Show ($l_Next) if ($l_Found);
           }
       );

    $l_Label->bind
       (
        '<Right>' => sub
           {
            my $l_Header = $l_Popup->parent()->Subwidget ('Label');
            $this->Hide ($l_Header);
            $l_Header->focusNext();

            my $l_Next = $this->toplevel()->focusCurrent();
            my $l_Found = 0;

            foreach my $l_Widget (@{$this->{m_MenuList}})
               {
                $l_Found = 1 if ($l_Next eq $l_Widget);
               }

            $this->Show ($l_Next) if ($l_Found);
           }
       );

    $l_Label->bind
       (
        '<Return>' => sub
           {
            $l_Label->invoke();
           }
       );

    $this->EnableEntry
       (
        $p_Caption,
        $p_EntryCaption
       );
   }

sub MenuSeparator
   {
    my ($this, $p_Caption) = (shift, @_);

    unless (Exists ($this->Subwidget ($this->FixName ($p_Caption))))
       {
        $this->MenuLabel ($p_Caption);
        return unless Exists ($this->Subwidget ($this->FixName ($p_Caption)));
       }

    my $l_Popup = $this->Subwidget ($this->FixName ($p_Caption))->Subwidget ('Popup');

    my $l_Frame = $l_Popup->Frame
       (
        '-borderwidth' => 1,
        '-relief' => 'flat',
       );

    my $l_Separator = $l_Frame->Frame
       (
        '-borderwidth' => 1,
        '-relief' => 'sunken',
        '-height' => 2,
       );

    $l_Separator->pack
       (
        '-anchor' => 'w',
        '-side' => 'left',
        '-fill' => 'x',
        '-expand' => 'true',
       );

    $l_Frame->pack
       (
        '-anchor' => 'nw',
        '-expand' => 'true',
        '-side' => 'top',
        '-fill' => 'x',
       );
   }

sub Show
   {
    my ($this, $p_Label) = (shift, @_);
    my $l_Popup = $p_Label->parent()->Subwidget ('Popup');
    my $l_Label = $p_Label;

    $this->Hide();

    $p_Label->parent()->configure
       (
        '-relief' => 'groove',
       );

    my $l_CodeRef = sub
       {
        $l_Popup->raise(); # Tk::
        $l_Popup->MapWindow();

        $l_Popup->geometry
           (
            '+'.
            ($l_Label->rootx() - 1).
            '+'.
            ($l_Label->parent()->rooty() + $l_Label->parent()->height() + $l_Label->cget ('-borderwidth'))
           );
       };

    $this->toplevel()->bind
       (
        '<Configure>' => $l_CodeRef
       );

    &{$l_CodeRef}();

    $l_Popup->{'m_FocusRestore'} = $this->toplevel()->focusSave();
    $l_Popup->transient();
    $l_Popup->deiconify();
#    $l_Popup->focus();
#    $l_Popup->{'m_Focus'}->focus() if (Exists ($l_Popup->{'m_Focus'}));
   }

sub Hide
   {
    my ($this, $p_Label) = (shift, @_);

    if (defined ($p_Label))
       {
        my $l_Popup = $p_Label->parent()->Subwidget ('Popup');

        $this->toplevel()->bind
           (
            '<Configure>' => ''
           );

        $p_Label->parent()->configure
           (
            '-relief' => 'flat',
           );

        &{$l_Popup->{'m_FocusRestore'}} if (ref ($l_Popup->{'m_FocusRestore'}) eq 'CODE');
        delete $l_Popup->{'m_FocusRestore'};
        $l_Popup->withdraw();
       }
    else
       {
        foreach my $l_Label (@{$this->{m_MenuList}})
           {
            $this->Hide ($l_Label);
           }
       }
   }

sub EnableEntry
   {
    my ($this, $p_MenuCaption, $p_EntryCaption) = (shift, @_);
    my $l_Popup = $this->Subwidget ($this->FixName ($p_MenuCaption))->Subwidget ('Popup');
    my $l_Label = $l_Popup->Subwidget ($this->FixName ($p_EntryCaption));

    $l_Label->{m_Enabled} = 'true';

    $l_Label->configure
       (
        '-activeforeground' => $this->cget ('-background'),
        '-activebackground' => $this->cget ('-foreground'),
        '-foreground' => $this->cget ('-foreground'),
        '-background' => $this->cget ('-background'),
        '-relief' => 'flat',
       );
   }

sub DisableEntry
   {
    my ($this, $p_MenuCaption, $p_EntryCaption) = (shift, @_);
    my $l_Popup = $this->Subwidget ($this->FixName ($p_MenuCaption))->Subwidget ('Popup');
    my $l_Label = $l_Popup->Subwidget ($this->FixName ($p_EntryCaption));

    $l_Label->{m_Enabled} = 'false';

    $l_Label->configure
       (
        '-activeforeground' => $l_Label->Darken ($this->cget ('-background'), 80),
        '-activebackground' => $this->cget ('-background'),
        '-foreground' => $l_Label->Darken ($this->cget ('-background'), 80),
        '-background' => $this->cget ('-background'),
        '-relief' => 'flat',
       );
   }

sub FixName
   {
    return (join ('_', split ('\.', $_[1])));
   }

1;

__END__

=cut

=head1 NAME

Tk::Menustrip - Another menubar with help menu support, etc

=head1 SYNOPSIS

    use Tk::Menustrip;
    use Tk;

    my $MainWindow = MainWindow->new();

    my $l_Menubar = $this->Menustrip();

    $l_Menubar->MenuLabel     ('File'),
    $l_Menubar->MenuEntry     ('File', 'Save', sub {Save();});
    $l_Menubar->MenuSeparator ('File');
    $l_Menubar->MenuEntry     ('File', 'Exit', sub {Exit();});

    $l_Menubar->MenuLabel     ('Help', '-right');
    $l_Menubar->MenuEntry     ('Help', 'About...');
    $l_Menubar->MenuSeparator ('Help');
    $l_Menubar->MenuEntry     ('Help', 'Help On...');

    $l_Menubar->pack(-fill => 'x');

    Tk::MainLoop;

=head1 DESCRIPTION

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

=head1 HISTORY 
 
=cut
