package Wx::Perl::CheckBoxWizardPage;
#----------------------------------------------------------------------
# The Wx::Perl::CheckBoxWizardPage is a subclass of Wx::WizardPage.
#
# Author: Jouke Visser
#
#----------------------------------------------------------------------

use strict;
use warnings;
use Wx qw(wxALL wxGROW wxICON_INFORMATION wxOK);
use Wx::Event qw(EVT_WIZARD_PAGE_CHANGING);
use base qw(Wx::WizardPage);

our $VERSION = 0.03;

sub new
# The constructor...
{
    my $class = shift;
    my $parent = shift;
    my $self = $class->SUPER::new($parent);
    $self->{_prev} = shift;
    $self->{_next} = shift;
    
    $self->{_selectionisoptional} = 0;
    $self->{_tls} = Wx::FlexGridSizer->new(0,1); # only one column    

    $self->{_tls}->AddGrowableRow(0);
    $self->{_tls}->AddGrowableCol(0);
    $self->SetAutoLayout(1);
    $self->SetSizer($self->{_tls});
    $self->{_tls}->SetSizeHints($self);
    
    EVT_WIZARD_PAGE_CHANGING($self, -1, \&_OnWizardPageChanging);
    return $self;
}

sub SelectionIsOptional
{
    my $self = shift;
    my $bool = shift;
    $self->{_selectionisoptional} = $bool if defined $bool;
    return $self->{_selectionisoptional};
    
}

sub _OnWizardPageChanging
{
    my ($self, $event) = @_;

    unless ($self->SelectionIsOptional)
    {
        unless ($self->IsAnythingSelected)
        {
            # We notify the user to select something first
            Wx::MessageBox("Please select one or more option before proceeding", "Attention",
                         wxICON_INFORMATION | wxOK);
            # And we call a Veto
            $event->Veto 
        }
    }
}

sub GetNext
{
    my $self = shift;
    return $self->{_next};
}

sub GetPrev
{
    my $self = shift;
    return $self->{_prev};
}

sub SetNext
{
    my $self = shift;
    $self->{_next} = shift;
}

sub SetPrev
{
    my $self = shift;
    $self->{_prev} = shift;
}

sub AddItems
{
    my $self  = shift;
    my $items = shift;
    foreach my $item (@$items)
    {
        my $check = Wx::CheckBox->new($self, -1, $item);
        push @{$self->{_items}}, $check;
        $self->{_tls}->Add($check, 0, wxGROW|wxALL, 2);
    }
}

sub GetSelectionLabel
{
    my $self = shift;
    my @selection;
    push @selection, $_->GetLabel foreach grep {$_->IsChecked} @{$self->{_items}};
    return @selection
}

sub GetSelectionIndex
{
    my $self = shift;
    my @selection;
    for (my $i = 0; $i < @{$self->{_items}}; $i++)
    {
        push @selection, $i if $self->{_items}->[$i]->IsChecked;
    }
    return @selection
}

sub IsAnythingSelected
{
    my $self = shift;
    return 1 if grep{$_->IsChecked} @{$self->{_items}};
}

sub AddText
{
    my $self = shift;
    my $text = Wx::StaticText->new($self, -1, shift);
    push @{$self->{_text}}, $text;
    $self->{_tls}->Add($text, 0, wxGROW|wxALL, 2);
}

1;
__END__

=pod

=head1 NAME

Wx::Perl::CheckBoxWizardPage - A simple Wx::WizardPage subclass for making a selection from checkboxes

=head1 SUPERCLASS

Wx::Perl::CheckBoxWizardPage is a subclass of Wx::WizardPage

=head1 SYNOPSIS

    use Wx;
    $self->{_wizard}        = Wx::Wizard->new($self,                     # parent
                                              -1,                        # id
                                              "This is a new Wizard",    # title
                                              Wx::Bitmap->new('logo.jpg', wxBITMAP_TYPE_JPEG)); # bitmap

    $self->{_startpage}     = Wx::WizardPageSimple->new($self->{_wizard});
    $self->{_lastpage}      = Wx::WizardPageSimple->new($self->{_wizard});

    $self->{_selectionpage} = CheckBoxWizardPage->new($self->{_wizard},    # parent
                                                      $self->{_startpage}, # previous page
                                                      $self->{_lastpage}); # next page
    
    $self->{_selectionpage}->AddText("Select one or more options");
    
    $self->{_selectionpage}->AddItems([ "Option 1", 
                                        "Option 2", 
                                        "Option 3",
                                        "Option 4"  ]);



=head1 DESCRIPTION

This class allows you to quickly create a wizard page with some text and
one or more checkboxes to choose.

=head1 USAGE

=head2 new(wizard, previous, next)

This is the constructor. It takes three arguments:

=over 4

=item wizard

This is the (parent) wizard that this page will be part of

=item previous

This is the previous page in the wizard

=item next

This is the next page in the wizard

=back

=head2 AddText(text)

This method will add some (static) text to the page. Keep in mind that
the text will appear above the checkboxes ONLY if you call AddText before
you call AddItems. In other words, the controls are added to the page sequentially.

This of course also means you can call AddText multiple times and have multiple
static text controls on your page...

=head2 AddItems(items)

This method takes a listref of strings that will become the labels of the
checkboxes. For example:

    $wizardpage->AddItems(['option 1','option 2']);

=head2 GetNext

This method is needed for the wizard to work. It returns the next page
in the wizard, as defined in the constructor

=head2 GetPrev

This method is needed for the wizard to work. It returns the previous page
in the wizard, as defined in the constructor

=head2 GetSelectionIndex

This method will return a list of index numbers of the selected items (0 is the first
item). 

=head2 GetSelectionLabel

This method will return a list of labels of the selected items

=head2 IsAnythingSelected

This method will return 1 if any of the checkboxes have been selected, undef otherwise

=head2 SelectionIsOptional(bool)

This method defines wether or not the user is allowed to press 'next' without selecting
anything. Default, the user is not allowed to go to the next page without making a selection,
which results in a MessageBox with a gentle reminder to select something.

If you call SelectionIsOptional(1), the user is allowed to continue without making a selection.

=head2 SetNext(page)

This method will set the next page to the specified Wizard page.

=head2 SetPrev(page)

This method will set the previous page to the specified Wizard page.

=head1 AUTHOR

	Jouke Visser
	jouke@pvoice.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), Wx, Wx::WizardPage

=cut