package WebService::Mattermost::Util::UserAgent;

use Moo;
use Mojo::UserAgent;
use Types::Standard qw(Bool InstanceOf Int);

################################################################################

has ua => (is => 'ro', isa => InstanceOf['Mojo::UserAgent'], lazy => 1, builder => 1);

has inactivity_timeout => (is => 'ro', isa => Int,  default => 15);
has max_redirects      => (is => 'ro', isa => Int,  default => 5);

################################################################################

sub _build_ua {
    my $self = shift;

    my $ua = Mojo::UserAgent->new();

    $ua->max_redirects($self->max_redirects);
    $ua->inactivity_timeout($self->inactivity_timeout);

    return $ua;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::Util::UserAgent

=head1 DESCRIPTION

Wraps C<Mojo::Log> with standard parameters for the project.

=head2 ATTRIBUTES

=over 4

=item C<ua>

A C<Mojo::Log> object.

=item C<inactivity_timeout()>

The default inactivity timeout (15 seconds).

=item C<max_redirects()>

The default maximum number of redirects (5).

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

