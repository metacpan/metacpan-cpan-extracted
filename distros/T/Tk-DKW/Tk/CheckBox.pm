package Tk::CheckBox;

use Tk;
use Tk::Canvas;
use Tk::Frame;

use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.01';

use base qw (Tk::Derived Tk::Frame);

Tk::Widget->Construct ('CheckBox');

*textvariable = \&Tk::CheckBox::TextVariable;
*get = \&Tk::CheckBox::CurrentState;
*disable = \&Tk::CheckBox::Disable;
*enable = \&Tk::CheckBox::Enable;
*state = \&Tk::CheckBox::State;
*set = \&Tk::CheckBox::State;

sub ClassInit
   {
    my ($p_Class, $p_Window) = (@_);
    $p_Window->bind ($p_Class, '<ButtonPress-1>', 'State');
    $p_Window->bind ($p_Class, '<space>', 'State');
    $p_Window->bind ($p_Class, '<Control-Tab>','focusNext');
    $p_Window->bind ($p_Class, '<Control-Shift-Tab>','focusPrev');
    $p_Window->bind ($p_Class, '<Tab>', 'focus');
    return $p_Class;
   }

sub new
   {
    my $p_Class = shift;
    my $this = $p_Class->SUPER::new (@_);
    $this->MapWindow();

    my $l_Canvas = $this->Component
       (
        'Canvas' => 'Canvas',
        '-background' => $this->cget ('-background'),
        '-height' => 15,
        '-width' => 15,
       );

    $l_Canvas->pack
       (
        '-fill' => 'both',
        '-expand' => 'true',
       );

    $this->{m_CheckMark} = $l_Canvas->create
       (
        'polygon',
        0, 8,
        3, 12,
        4, 14,
        4, 15,
        11, 4,
        15, 0,
        4, 11,
        0, 8,
       );

    $l_Canvas->Tk::bind ('<ButtonPress-1>' => sub {$this->State();});
    $this->bind ('<Tab>' => sub {$this->focus();});
    $this->Enable();
    $this->State ('off');
    return $this;
   }

sub Populate
   {
    my ($this) = (shift, @_);

    $this->SUPER::Populate (@_);

    $this->configure ('-background' => 'white');

    $this->ConfigSpecs
       (
        '-foreground' => [['SELF', 'PASSIVE'], 'foreground', 'Foreground', 'red'],
        '-textvariable' => ['METHOD', 'textvariable', 'TextVariable', \$this->{m_Value}],
        '-borderwidth' => [['SELF', 'PASSIVE'], 'borderwidth', 'BorderWidth', 2],
        '-relief' => [['SELF', 'PASSIVE'], 'relief', 'Relief', 'sunken'],
        '-enable' => ['METHOD', 'Enable', 'Enable', 'true'],
        '-state' => ['METHOD', 'State', 'State', 'on'],
       );

    return $this;
   }

sub Disable
   {
    $_[0]->Enable ('false');
   }

sub Enable
   {
    $_[0]->{m_Enabled} = ($_[1] eq 'true' || ! defined ($_[1]));
   }

sub State
   {
    my ($this, $p_State) = (shift, @_);
    my $l_Canvas = $this->Subwidget ('Canvas');

    $this->{m_State} =
       (
        $this->{m_Enabled} ?
           (
            defined ($p_State) ?
            ($p_State eq 'on' || $p_State eq 'true' || $p_State > 0 || $p_State < 0) :
            (! $this->{m_State})
           ) :
        $this->{m_State}
       );

    my $l_Color =
       (
        $this->{m_State} ? 
        $this->cget ('-foreground') :
        $this->cget ('-background')
       );

    if (Exists ($l_Canvas))
       {
        $l_Canvas->itemconfigure
           (
            $this->{m_CheckMark},
            '-outline' => $l_Color,
            '-fill' => $l_Color,
           );
       }

    if (defined ($this->{m_TextVariable} = $this->{Configure}{-textvariable}))
       {
        ${$this->{m_TextVariable}} = $this->{m_State};
       }
   }

sub TextVariable
   {
    my ($this, $p_Reference) = (shift, @_);

    return $this->{m_TextVariable} unless (defined ($p_Reference));

    $this->afterCancel ($this->{m_AfterID}) if (defined ($this->{m_AfterID}));

    $this->{m_AfterID} = $this->repeat
       (
        1000,
        sub {$this->State (${$p_Reference});}
       );

    return ($this->{m_TextVariable} = $p_Reference);
   }

sub CurrentState
   {
    return $_[0]->{m_State};
   }
 
1;
__END__

=cut

=head1 NAME

Tk::CheckBox - Another radio button style widget (with a check mark)

=head1 SYNOPSIS

    use Tk;

    my $MainWindow = MainWindow->new();

    Tk::MainLoop;

=head1 DESCRIPTION

A radio button style widget that uses a check mark in a box.
Useful as a boolean field.

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

=head1 HISTORY 
 
=cut
