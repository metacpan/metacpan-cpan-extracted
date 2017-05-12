package Wx::Perl::HtmlWizardPage;
use strict;
use warnings;
use Wx qw(wxALL wxGROW wxICON_INFORMATION wxOK);
use Wx::Html;
use Wx::Event qw(EVT_WIZARD_PAGE_CHANGING);
use base qw(Wx::WizardPage);

our $VERSION = 0.01;

sub new
# The constructor...
{
    my $class = shift;
    my $parent = shift;
    my $self = $class->SUPER::new($parent);
    $self->{_prev} = shift;
    $self->{_next} = shift;
    
    $self->{_tls} = Wx::FlexGridSizer->new(0,1); # only one column    
    $self->{_html} = Wx::HtmlWindow->new($self, -1);
    $self->{_tls}->Add($self->{_html}, 0, wxGROW|wxALL, 2);

    $self->{_tls}->AddGrowableRow(0);
    $self->{_tls}->AddGrowableCol(0);
    $self->SetAutoLayout(1);
    $self->SetSizer($self->{_tls});
    $self->{_tls}->SetSizeHints($self);

    return $self;
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

our $AUTOLOAD;

sub AUTOLOAD
{
    my $self = shift;
    my @params = @_;
    (my $auto = $AUTOLOAD) =~ s/.*:://;
    return $self->{_html}->$auto(@params) if $self->{_html}->can($auto);
}

1;
__END__

=head1 NAME

Wx::Perl::HtmlWizardPage - A simple Wx::WizardPage subclass for showing rendered HTML

=head1 SUPERCLASS

Wx::Perl::HtmlWizardPage is a subclass of Wx::WizardPage

=head1 SYNOPSIS

    use Wx;
    use Wx::Perl::HtmlWizardPage
    $self->{_wizard}        = Wx::Wizard->new($self,                     # parent
                                              -1,                        # id
                                              "This is a new Wizard",    # title
                                              Wx::Bitmap->new('logo.jpg', wxBITMAP_TYPE_JPEG)); # bitmap

    $self->{_startpage}     = Wx::WizardPageSimple->new($self->{_wizard});
    $self->{_lastpage}      = Wx::WizardPageSimple->new($self->{_wizard});

    $self->{_htmlpage}      = Wx::Perl::HtmlWizardPage->new(  $self->{_wizard},    # parent
                                                              $self->{_startpage}, # previous page
                                                              $self->{_lastpage}); # next page
            


=head1 DESCRIPTION

This class allows you to quickly create a wizard page with some rendered HTML

=head1 USAGE

In addition to the methods described below, you can call any Wx::HtmlWindow method
on objects of the Wx::Perl::HtmlWizardPage. See the wxWidgets reference for a complete
list of all methods.

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

=head2 GetNext

This method is needed for the wizard to work. It returns the next page
in the wizard, as defined in the constructor

=head2 GetPrev

This method is needed for the wizard to work. It returns the previous page
in the wizard, as defined in the constructor

=head2 SetNext(page)

This method will set the next page to the specified Wizard page.

=head2 SetPrev(page)

This method will set the previous page to the specified Wizard page.

=head1 AUTHOR

Jouke Visser, C<< <jouke@pvoice.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-wx-perl-htmlwizardpage@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx-Perl-HtmlWizardPage>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2005 Jouke Visser, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

