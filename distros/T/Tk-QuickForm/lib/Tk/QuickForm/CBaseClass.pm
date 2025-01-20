package Tk::QuickForm::CBaseClass;

=head1 NAME

Tk::QuickForm::CBaseClass - Base class for items in Tk::QuickForm.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.07';

use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'CBaseClass';

use Tie::Watch;
use Carp;

=head1 SYNOPSIS

 package MyFormItem;
 
 use base qw(Tk::TabedForm::CBaseClass);
 Construct Tk::Widget 'MyFormItem';

=head1 DESCRIPTION

Inherits L<Tk::Frame>

Provides a base class for you to inherit. Helps making items for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 OPTIONS

=over 4

=item Switch: B<-regex>

By default '.*'. Set a regular expression used for validation.

=item Switch: B<-validatecall>

Callback, called after validation with the result as parameter.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	my $quickform = delete $args->{'-quickform'};
	croak "Option '-quickform' not specified" unless defined $quickform;
	
	$self->SUPER::Populate($args);
	my $var = '';
	Tie::Watch->new(
		-variable => \$var,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			$self->Callback('-validatecall');
		},
	);
	$self->createHandler(\$var);
	$self->{VARIABLE} = \$var;
	$self->{QUICKFORM} = $quickform;

	$self->ConfigSpecs(
		-regex => ['PASSIVE', undef, undef, '.*'],
		-validatecall => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => ['SELF'],
	);
	$self->after(1, ['validate', $self]);
}

sub createHandler {
}

=item B<get>

Returns the value.

=cut

sub get {
	my $self = shift;
	my $var = $self->variable;
	return $$var;
}

=item B<put>I<($value)>

Sets the value.

=cut

sub put {
	my ($self, $value) = @_;
	my $var = $self->variable;
	$$var = $value;
}

=item B<quickform>

Returns a reference to the Tk::QuickForm mother widget.

=cut

sub quickform { return $_[0]->{QUICKFORM} }

=item B<validate>I<(?$value?)>

Validates the value against the regex in the B<-regex> option.

=cut

sub validate {
	my ($self, $val) = @_;
	my $var = $self->variable;
	return 1 unless defined $var;
	$val = $$var unless defined $val;
	my $reg = $self->cget('-regex');
	my $flag = $val =~ /$reg/;
	$self->validUpdate($flag, $val);
	return $flag;
}

=item B<validUpdate>I<($flag, $value)>

For you to overwrite. Does nothing. Is called to update the 
widget to reflect the outcome of validate.

=cut

sub validUpdate {
}

=item B<variable>

Returns a reference to the internal variable.

=cut

sub variable {
	return $_[0]->{VARIABLE};
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

=back

=cut

1;

__END__
