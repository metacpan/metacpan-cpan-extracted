package Tk::QuickForm::CColorItem;

=head1 NAME

Tk::QuickForm::CColorItem - ColorEntry widget for Tk::QuickForm.

=cut


use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.08';

use base qw(Tk::Derived Tk::QuickForm::CTextItem);
Construct Tk::Widget 'CColorItem';
require Tk::ColorEntry;

=head1 SYNOPSIS

 require Tk::QuickForm::CColorItem;
 my $bool = $window->CColorItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CTextItem>. Provides a ColorEntry field for L<Tk::QuickForm>

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 OPTIONS

All options, except I<-variable>, of L<Tk::Checkbutton> are available.

=cut

sub Populate {
	my ($self,$args) = @_;
	$args->{'-regex'} = '^#(?:[0-9a-fA-F]{3}){1,4}$';
	my $popcolor = delete $args->{'-popcolor'};
	$self->{POPCOLOR} = $popcolor;
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => [$self->Subwidget('Entry')],
	);
}

sub createHandler {
	my ($self, $var) = @_;
	my $popcolor = $self->{POPCOLOR};
	my $e = $self->ColorEntry(
		-popcolor => $popcolor,
		-variable => $var,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Entry => $e);
}

sub put {
	my ($self, $color) = @_;
	$self->SUPER::put($color);
	$self->Subwidget('Entry')->EntryUpdate;
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::ColorEntry>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CTextItem>

=back

=cut

1;

__END__
