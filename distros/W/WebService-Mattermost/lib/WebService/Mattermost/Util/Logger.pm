package WebService::Mattermost::Util::Logger;

use Moo;
use Mojo::Util 'monkey_patch';
use Mojo::Log;
use Types::Standard 'InstanceOf';

################################################################################

has logger => (is => 'ro', isa => InstanceOf['Mojo::Log'], lazy => 1, builder => 1);

has logger_store => (is => 'rw', isa => InstanceOf['Mojo::Log']);

################################################################################

monkey_patch 'Mojo::Log',
    debugf => sub { shift->debug(sprintf(shift, @_)) },
    infof  => sub { shift->info(sprintf(shift, @_))  },
    fatalf => sub { shift->fatal(sprintf(shift, @_)) },
    warnf  => sub { shift->warn(sprintf(shift, @_))  };

################################################################################

sub _build_logger {
    my $self = shift;

    unless ($self->logger_store) {
        $self->logger_store(Mojo::Log->new());
    }

    return $self->logger_store;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::Util::Logger

=head1 DESCRIPTION

Patched instance of C<Mojo::Log> with some wrapping methods.

=head2 ATTRIBUTES

=over 4

=item C<logger>

A C<Mojo::Log> object with additional methods:

=over 8

=item C<debugf()>

    $self->logger->debugf('sprintf for %s', 'debug'); # sprintf for debug

=item C<infof()>

    $self->logger->infof('sprintf for %s', 'info'); # sprintf for info

=item C<fatalf()>

    $self->logger->fatalf('sprintf for %s', 'fatal'); # sprintf for fatal

=item C<warnf()>

    $self->logger->warnf('sprintf for %s', 'warn'); # sprintf for warn

=back

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

