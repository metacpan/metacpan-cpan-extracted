use strict;
use warnings;
use utf8;

package Ukigumo::Client::Notify::Callback;
use Mouse;

has send_cb => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

sub send {
    my $self = shift;
    $self->send_cb->(@_);
}

1;
__END__

=head1 NAME

Ukigumo::Client::Notify::Callback - send notification by callback

=head1 DESCRIPTION

This is a notifier class for Ukigumo, send notification by callback

=head1 SYNOPSIS

    use Ukigumo::Client::Notify::Callback;

    my $app = Ukigumo::Client->new(...);
    $app->push_notifier(
        Ukigumo::Client::Notify::Callback->new(
            send_cb => sub {
                my ($c, $status, $last_status, $report_url) = @_;
                ...
            },
        )
    );

=head1 ATTRIBUTES

=over

=item send_cb

=back
