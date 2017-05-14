package Tk::TabbedForm;

use Tk;
use Tk::TabFrame;
use Tk::Frame;

use base qw (Tk::Derived Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.01';

Tk::Widget->Construct ('TabbedForm');

*tabfont = \&Tk::TabbedForm::TabFont;
*Field = \&Tk::TabbedForm::Item;
*field = \&Tk::TabbedForm::Item;
*item = \&Tk::TabbedForm::Item;
*file = \&Tk::TabbedForm::File;

sub Populate
   {
    my $this = shift;

    my $l_TabWidget = $this->{m_TabWidget} = $this->Component
       (
        'TabFrame' => 'TabFrame',
       );

    $this->ConfigSpecs
       (
        '-TabFont' => ['METHOD', 'tabfont', 'TabFont', '-adobe-times-medium-r-normal--16-*-*-*-*-*-*-*'],
       );

    $l_TabWidget->pack
       (
        '-fill' => 'both',
        '-expand' => 'true',
       );

    return $this->SUPER::Populate (@_);
   }

sub Item
   {
    my ($this, $p_WidgetClass, @p_Parameters) = @_;

    my %l_Hash = @p_Parameters;

    my $l_SectionName = delete $l_Hash {'-section'} || 'Undefined';
    my $l_SectionFrame = $this->SectionFrame ($l_SectionName);
    my $l_Expression = delete $l_Hash {'-rule'} || delete $l_Hash {'-expression'};
    my $l_ItemName = delete $l_Hash {'-name'} || 'Undefined_'.++$Tk::TabbedForm::g_Undefined;
    my $l_Set = delete $l_Hash {'-set'} || sub {$_[0]->delete ('0', 'end'); $_[0]->insert ('0', $_[1]);};
    my $l_Get = delete $l_Hash {'-get'} || sub {$_[0]->get();};
    my $l_Default = delete $l_Hash {'-default'};

    my $l_Label = $l_SectionFrame->Label
       (
        '-text' => $l_ItemName,
       );

    my $l_Widget = $l_SectionFrame->$p_WidgetClass
       (
        %l_Hash,
       );

    $l_Label->grid
       (
        '-row' => ++$l_SectionFrame->{m_Row},
        '-sticky' => 'nw',
        '-column' => 0,
        '-padx' => 2,
        '-pady' => 1,
       );

    $l_Widget->grid
       (
        '-row' => $l_SectionFrame->{m_Row},
        '-sticky' => 'nw',
        '-column' => 1,
        '-padx' => 2,
        '-pady' => 1,
       );

    # Add field to list of fields

    push (@{$this->{m_Fields}->{$l_SectionName}}, $l_ItemName);

    # Add widget to hash of field widgets

    $this->{'x_'.$l_ItemName} = $l_Widget;

    $l_Widget->{m_Section} = $l_SectionName;
    $l_Widget->{m_Default} = $l_Default;
    $l_Widget->{m_Name} = $l_ItemName;
    $l_Widget->{m_Get} = $l_Get;
    $l_Widget->{m_Set} = $l_Set;

    if (defined ($l_Expression))
       {
        my $l_FinalExpression = (ref ($l_Expression) eq 'ARRAY' ? ${$l_Expression}[-1] : $l_Expression);

        $l_Widget->bind
           (
            '<KeyRelease>' => sub {$this->TestExpression ($l_ItemName, $l_Expression);}
           );

        $l_Widget->bind
           (
            '<FocusOut>' => sub {$this->TestExpression ($l_ItemName, $l_FinalExpression, 1);}
           );
       }

    $this->SetItemValue ($l_ItemName);
    return $l_Widget;
   }

sub SectionFrame
   {
    my ($this, $p_SectionName) = @_;
    my $l_Frame = $this->{m_TabWidget}->{$p_SectionName};
    my $l_SectionLabel = $p_SectionName;

    return $l_Frame if (Exists ($l_Frame));

    $l_SectionLabel =~ s/^\_//;

    $this->{m_Fields}->{$p_SectionName} = [];

    $l_Frame = $this->{m_TabWidget}->{$p_SectionName} = $this->{m_TabWidget}->Frame
       (
        '-caption' => $l_SectionLabel,
       )->Frame
       (
       )->pack
       (
        '-anchor' => 'nw',
        '-padx' => 10,
        '-pady' => 10,
        '-expand' => 'true',
        '-fill' => 'x',
       );

    push (@{$this->{'m_TemporarySectionFrameList'}}, $l_Frame);

    $l_Frame->{m_Row} = 0;

    return $l_Frame;
   }

#----------------------------- Item Value Retrieval ----------------------------------#
sub GetItemDefault
   {
    my ($this, $p_ItemName) = (shift, @_);
    my $l_Widget = $this->{'x_'.$p_ItemName};

    return unless (Exists ($l_Widget));
    return $l_Widget->{m_Default} unless (ref ($l_Widget->{m_Default}) eq 'CODE');
    return &{$l_Widget->{m_Default}} ($l_Widget);
   }

sub GetItemValue
   {
    my ($this, $p_ItemName) = (shift, @_);
    my $l_Widget = $this->{'x_'.$p_ItemName};
    my $l_TextVariable;

    return unless (Exists ($l_Widget));

    eval {$l_TextVariable = $l_Widget->cget ('-textvariable');};

    my $l_Return =
       (
        ref ($l_TextVariable) eq 'SCALAR' ? ${$l_TextVariable} :
           (
            ref ($l_Widget->{m_Get}) eq 'CODE' ? &{$l_Widget->{m_Get}} ($l_Widget) :
               (
                ref ($l_Widget->{m_Get}) eq 'SCALAR' ? ${$l_Widget->{m_Get}} :
                   (
                    $l_Widget->{m_Get}
                   )
               )
           )
       );

    $l_Return =~ s/[\n\r]+//g;
    return $l_Return;
   }

sub GetItemValueHash
   {
    my $this = shift;
    my @l_Array = ();

    foreach my $l_Section ($#_ > -1 ? @_ : $this->GetSectionNames())
       {
        foreach my $l_ItemName (@{$this->{m_Fields}->{$l_Section}})
           {
            push (@l_Array, $l_ItemName, $this->GetItemValue ($l_ItemName));
           }
       }

    return @l_Array;
   }

sub GetSectionNames
   {
    return (sort (keys %{$_[0]->{m_Fields}}));
   }

sub GetItemNames
   {
    my $this = shift;
    my %l_Hash = $this->GetItemValueHash (@_);
    return (sort (keys %l_Hash));
   }

#--------------------------------- Item Value Setting ----------------------------------#
sub SetItemValue
   {
    my ($this, $p_ItemName, $p_Value) = (shift, @_);
    my $l_Widget = $this->{'x_'.$p_ItemName};
    my $l_TextVariable;

    return unless (Exists ($l_Widget));

    $p_Value = $this->GetItemDefault ($p_ItemName) unless defined ($p_Value);
    eval {$l_TextVariable = $l_Widget->cget ('-textvariable');};

    if (ref ($l_TextVariable) eq 'SCALAR')
       {
        return ${$l_TextVariable} = $p_Value;
       }
    elsif (ref ($l_Widget->{m_Set}) eq 'CODE')
       {
        return &{$l_Widget->{m_Set}} ($l_Widget, $p_Value);
       }
    elsif (ref ($l_Widget->{m_Get}) eq 'SCALAR')
       {
        return ${$l_Widget->{m_Get}} = $p_Value;
       }
   }

sub SetItemValueHash
   {
    my $this = shift; $this->SetItemValue (shift, shift) while ($#_ > 0);
   }

#----------------------------- Field Value Qualification ----------------------------------#
sub TestExpression
   {
    my ($this, $p_ItemName, $p_Expression, $p_DontCorrect) = (shift, @_);
    my $l_Value = $this->GetItemValue ($p_ItemName);
    my $l_Widget = $this->{'x_'.$p_ItemName};

    return unless (Exists ($l_Widget) && defined ($l_Value));
    return if ($this->MatchExpression ($l_Value, $p_Expression));

    chop $l_Value until ($this->MatchExpression ($l_Value, $p_Expression));
    $this->SetItemValue ($p_ItemName, $l_Value) unless ($p_DontCorrect);
    $l_Widget->focus();
    $l_Widget->bell();
   }

sub MatchExpression
   {
    my ($l_Return, $this, $p_Value, $p_Expression) = (0, shift, @_);

    return 1 if ($p_Value eq '');

    foreach my $l_Expression (ref ($p_Expression) eq 'ARRAY' ? @{$p_Expression} : ($p_Expression))
       {
        $l_Return = 1 if ($p_Value =~ $l_Expression);
       }

    return $l_Return;
   }

sub TabFont
   {
    return $_[0]->{m_TabWidget}->cget ('-font') unless (defined ($_[1]));
    $_[0]->{m_TabWidget}->configure ('-font' => $_[1]);
    return $_[1];
   }

1;

__END__

=cut

=head1 NAME

Tk::TabbedForm - a form management arrangement using Tk::TabFrame

=head1 SYNOPSIS

    use Tk;

    my $MainWindow = MainWindow->new();

    Tk::MainLoop;

=head1 DESCRIPTION

An extended TabFrame, allowing managed subwidgets used
as entry fields. Each field widget is given a 'set'
and a 'get' method to provide widget independent
methods of maintaining and querying data. The form
will pass back a hash of all field values on request.

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

=head1 HISTORY 
 
=cut
