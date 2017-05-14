package Tk::Signals;

use Tk::Widget;
use Tk;

use vars qw ($VERSION %SLOTS);
use strict;
use Carp;

$VERSION = '0.03';

sub GLOBALSLOT
   {
    Tk::Signals::__insertslothandler ($_[0], $_[1], \%Tk::Signals::SLOTS);
   }

sub SLOT
   {
    my $l_Toplevel = $_[0]->__findtoplevel();
    $l_Toplevel->{'Tk::Signals::SLOTS'} = {} unless (defined ($l_Toplevel->{'Tk::Signals::SLOTS'}));
    Tk::Signals::__insertslothandler ($_[0], $_[1], $l_Toplevel->{'Tk::Signals::SLOTS'});
   }

sub SIGNAL
   {
    my ($p_Self, $p_Signal, @p_Arguments) = (shift, @_);

    return unless (defined ($p_Signal) && defined ($p_Self));

    my @l_WidgetList;
    my %l_Hash;

    foreach my $l_Reference ($p_Self->__findtoplevel()->{'Tk::Signals::SLOTS'}->{$p_Signal}, $Tk::Signals::SLOTS {$p_Signal})
       {
        foreach my $l_Widget (@{$l_Reference})
           {
            unless ($l_Hash {$l_Widget})
               {
                push (@l_WidgetList, $l_Widget);
                $l_Hash {$l_Widget} = 1;
               }
           }
       }

    foreach my $l_Widget (@l_WidgetList)
       {
        no strict 'refs';
        next unless (Exists ($l_Widget));
        my $l_Callback = $l_Widget->{'__Tk::Signal::ClassName'}.'::'.$p_Signal;
        next unless $l_Widget->can ($l_Callback);
        &{$l_Callback} ($l_Widget, @p_Arguments);
        use strict 'refs';
       }
   }

sub __findtoplevel
   {
    my $l_Toplevel = $_[0]->toplevel();

    while (ref ($l_Toplevel) ne 'Tk::Toplevel' && ref ($l_Toplevel) ne 'Tk::MainWindow' && defined ($l_Toplevel->parent()))
       {
        $l_Toplevel = $l_Toplevel->parent()->toplevel();
       }

    return $l_Toplevel;
   }

sub __insertslothandler
   {
    my ($l_Found, $p_Self, $p_Signal, $p_Reference) = (0, shift, @_);

    return unless (defined ($p_Signal) && defined ($p_Self) && defined ($p_Reference));

    foreach my $l_Search (@{$p_Reference->{$p_Signal}})
       {
        $l_Found = 1 if ($l_Search eq $p_Self);
       }

    unless ($l_Found)
       {
        $p_Self->{'__Tk::Signal::ClassName'} = ref ($p_Self);
        push (@{$p_Reference->{$p_Signal}}, $p_Self);
       }
   }

1;
