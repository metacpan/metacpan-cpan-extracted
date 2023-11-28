package WebService::Async::Onfido::Check;

use strict;
use warnings;

use parent qw(WebService::Async::Onfido::Base::Check);

our $VERSION = '0.007';    # VERSION

=head1 NAME

WebService::Async::Onfido::Check - represents data for Onfido

=head1 DESCRIPTION

=cut

use Log::Any qw($log);

sub as_string {
    my ($self) = @_;

    return sprintf 'Check %s, result was %s (created %s as ID %s)', $self->status, $self->result, $self->created_at, $self->id;
}

sub applicant { return shift->{applicant} // die 'no applicant defined' }

sub onfido { return shift->{onfido} }

sub reports {
    my ($self, %args) = @_;

    # return Ryu::Source->from($self->{reports}) if $self->{reports};
    return $self->onfido->report_list(
        check_id => $self->id,
        %args
    )->map(sub { $log->debugf('Have report %s', $_->as_string); $_->{check} = $self; $_ });
}

sub download {
    my ($self) = @_;

    return $self->onfido->download_check(
        check_id => $self->id,
    );
}

1;

__END__

=head1 AUTHOR

deriv.com C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright deriv.com 2019. Licensed under the same terms as Perl itself.

