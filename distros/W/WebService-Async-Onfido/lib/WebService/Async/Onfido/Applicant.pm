package WebService::Async::Onfido::Applicant;

use strict;
use warnings;

use parent qw(WebService::Async::Onfido::Base::Applicant);

our $VERSION = '0.006';    # VERSION

=head1 NAME

WebService::Async::Onfido::Applicant - represents data for Onfido

=head1 DESCRIPTION

=cut

sub as_string {
    my ($self) = @_;
    return sprintf '%s %s (ID %s)', $self->first_name, $self->last_name, $self->id;
}

sub onfido { return shift->{onfido} }

sub documents {
    my ($self, %args) = @_;
    return $self->onfido->document_list(
        applicant_id => $self->id,
        %args
    )->map(sub { $_->{applicant} = $self; $_ });
}

sub photos {
    my ($self, %args) = @_;
    return $self->onfido->photo_list(
        applicant_id => $self->id,
        %args
    )->map(sub { $_->{applicant} = $self; $_ });
}

sub checks {
    my ($self, %args) = @_;
    return $self->onfido->check_list(
        applicant_id => $self->id,
        %args
    )->map(sub { $_->{applicant} = $self; $_ });
}

## no critic (ProhibitBuiltinHomonyms)
sub delete : method {
    my ($self, %args) = @_;
    return $self->onfido->applicant_delete(
        applicant_id => $self->id,
        %args
    );
}

sub check {
    my ($self, %args) = @_;
    return $self->onfido->applicant_check(
        applicant_id => $self->id,
        %args,
    )->on_done(
        sub {
            shift->{applicant} = $self;
        });
}

sub get : method {
    my ($self) = @_;
    return $self->onfido->applicant_get(
        applicant_id => $self->id,
    );
}

1;

__END__

=head1 AUTHOR

deriv.com C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright deriv.com 2019. Licensed under the same terms as Perl itself.

