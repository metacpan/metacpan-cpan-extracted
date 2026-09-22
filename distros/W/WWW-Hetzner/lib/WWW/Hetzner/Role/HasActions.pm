package WWW::Hetzner::Role::HasActions;
# ABSTRACT: Controller role wrapping raw hashes as Action objects

our $VERSION = '0.101';

use Moo::Role;
use WWW::Hetzner::Action;
use namespace::clean;


requires 'client';

has action_poll_path => (
    is      => 'ro',
    default => sub { '/actions' },
);


sub _wrap_action {
    my ($self, $data) = @_;
    return defined $data
        ? WWW::Hetzner::Action->new(
            client    => $self->client,
            %$data,
            poll_path => $self->action_poll_path,
        )
        : undef;
}


sub _wrap_actions {
    my ($self, $list) = @_;
    return [ map { $self->_wrap_action($_) } @{ $list // [] } ];
}


sub _wrap_action_result {
    my ($self, $result) = @_;
    my %sidecar = %$result;
    my $action = delete $sidecar{action};
    return undef unless defined $action;
    WWW::Hetzner::Action->new(
        client    => $self->client,
        %$action,
        result    => \%sidecar,
        poll_path => $self->action_poll_path,
    );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Role::HasActions - Controller role wrapping raw hashes as Action objects

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    package WWW::Hetzner::Cloud::API::Servers;
    use Moo;
    with 'WWW::Hetzner::Role::HasActions';

    # inside a method that returns an action
    return $self->_wrap_action($result->{action});

=head1 DESCRIPTION

Shared helper for API controllers whose endpoints return an action or a list
of actions alongside (or instead of) the primary resource. Wraps raw
decoded-JSON hashes as L<WWW::Hetzner::Action> objects.

Requires the consumer to provide a C<client> attribute or method.

=head2 action_poll_path

Base path used when wrapped Actions are refreshed. Defaults to the Cloud
C</actions> endpoint; controllers for another API host may override it.

=head2 _wrap_action

    my $action = $self->_wrap_action($hash);

Wraps a decoded action hashref as a L<WWW::Hetzner::Action>. Returns
undef when C<$hash> is undef.

=head2 _wrap_actions

    my $actions = $self->_wrap_actions($arrayref);

Wraps each element of C<$arrayref> via L</_wrap_action>. Returns an empty
arrayref when C<$arrayref> is undef.

=head2 _wrap_action_result

    my $action = $self->_wrap_action_result($result);

Wraps a full decoded-JSON response hashref as a L<WWW::Hetzner::Action>,
same as L</_wrap_action>, but keeps whatever the endpoint returned alongside
C<action> (e.g. C<root_password>) as the Action's L<WWW::Hetzner::Action/result>.
Returns undef when C<$result> carries no C<action> key.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Action> - Action entity class

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
