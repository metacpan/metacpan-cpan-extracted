package Tk::QuickForm::CFloatItem;

=head1 NAME

Tk::QuickForm::CFloatItem - Floating numbers entry widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.07';

use Tk;
use base qw(Tk::Derived Tk::QuickForm::CTextItem);
Construct Tk::Widget 'CFloatItem';

use Scalar::Util::Numeric qw(isfloat isint);

=head1 SYNOPSIS

 require Tk::QuickForm::CFloatItem;
 my $bool = $window->CFloatItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CTextItem>. Provides an entry for floating point numbers to L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 OPTIONS

All options, except I<-textvariable>, of L<Tk::Entry> are available.

=cut

sub validate {
	my $self = shift;
	my $var = $self->variable;
	my $flag = 0;
	$flag = 1 if $$var eq '';
	$flag = 1 if isint $$var;
	$flag = 1 if isfloat $$var;
	$self->validUpdate($flag);
	return $flag
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=item L<Tk::QuickForm::CTextItem>

=back

=cut


1;

__END__
