package Tk::QuickForm::CListItem;

=head1 NAME

Tk::QuickForm::CListItem - ListEntry widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::QuickForm::CTextItem);
Construct Tk::Widget 'CListItem';

require Tk::ListEntry;

=head1 SYNOPSIS

 require Tk::QuickForm::CListItem;
 my $bool = $window->CListItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CTextItem>. Provides a list entry for L<Tk::QuickForm>. 

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 CONFIG VARIABLES

All options, except I<-textvariable>, of L<Tk::Entry> are available.

=over 4

=item Switch: B<-values>

The list of possible values.

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	my $values = delete $args->{'-values'};
	warn "You need to set the -values option" unless defined $values;
	$self->{VALUES} = $values;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		DEFAULT => [$self->Subwidget('Entry')],
	);
}

sub createHandler {
	my ($self, $var) = @_;
	my $values = $self->{VALUES};
	my $e = $self->ListEntry(
		-textvariable => $var,
		-values => $values,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Entry => $e);
}

sub validate {
	my $self = shift;
	my $flag = $self->Subwidget('Entry')->validate;
	$self->validUpdate($flag);
	return $flag
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::ListEntry>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=item L<Tk::QuickForm::CTextItem>


=back

=cut



1;

__END__
