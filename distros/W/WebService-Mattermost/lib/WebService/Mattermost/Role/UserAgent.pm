package WebService::Mattermost::Role::UserAgent;

use Moo::Role;
use Types::Standard 'InstanceOf';

use WebService::Mattermost::Util::UserAgent;
use WebService::Mattermost::Helper::Alias 'util';

################################################################################

has ua => (is => 'ro', isa => InstanceOf['Mojo::UserAgent'], lazy => 1, builder => 1);

################################################################################

sub mmauthtoken {
    my $self  = shift;
    my $token = shift;

    return sprintf('MMAUTHTOKEN=%s', $token);
}

sub bearer {
    my $self  = shift;
    my $token = shift;

    return sprintf('Bearer %s', $token);
}

################################################################################

sub _build_ua {
    return util('UserAgent')->new->ua;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::Role::UserAgent

=head1 DESCRIPTION

Bundles C<Mojo::UserAgent> and required parameters for HTTP headers.

=head2 USAGE

    use Moo;

    with 'WebService::Mattermost::Role::UserAgent';

    sub something {
        my $self = shift;

        my $bearer_header = $self->bearer;
        my $mmauthtoken   = $self->mmauthtoken;

        # Methods from Mojo::UserAgent
        $self->ua->post(
            # ...
        );
    }

=head2 ATTRIBUTES

=over 4

=item C<ua>

A C<Mojo::UserAgent> object.

=back

=head2 METHODS

=over 4

=item C<mmauthtoken()>

Formats the C<MMAUTHTOKEN> header.

=item C<bearer>

Formats the C<Bearer> header.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

