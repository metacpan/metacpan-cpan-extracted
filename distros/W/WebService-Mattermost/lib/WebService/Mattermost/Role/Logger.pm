package WebService::Mattermost::Role::Logger;

use Moo::Role;
use Types::Standard 'InstanceOf';

use WebService::Mattermost::Util::Logger;
use WebService::Mattermost::Helper::Alias 'util';

################################################################################

has logger => (is => 'ro', isa => InstanceOf['Mojo::Log'], lazy => 1, builder => 1);

################################################################################

sub _build_logger {
    return util('Logger')->new->logger;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::Role::Logger

=head1 DESCRIPTION

Bundle a C<Mojo::Log> object into a Moo class.

=head2 SYNOPSIS

    use Moo;

    with 'WebService::Mattermost::Role::Logger';

    sub something {
        my $self = shift;

        $self->logger->warn('Foo');
    }

=head2 ATTRIBUTES

=over 4

=item C<logger>

A C<Mojo::Log> object.

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::Util::Logger>

=item C<Log::Log4perl>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

