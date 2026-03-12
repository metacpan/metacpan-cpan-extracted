package WWW::VastAI::API::User;
our $VERSION = '0.001';
# ABSTRACT: Current-user access for Vast.ai

use Moo;
use WWW::VastAI::User;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub current {
    my ($self) = @_;
    my $result = $self->client->request_op('getCurrentUser');
    my $user = ref $result eq 'HASH' ? ($result->{user} || $result) : $result;
    return WWW::VastAI::User->new(
        client => $self->client,
        data   => $user,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::User - Current-user access for Vast.ai

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Fetches the current authenticated Vast.ai user as a L<WWW::VastAI::User>
object.

=head1 METHODS

=head2 current

Returns the currently authenticated user profile.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-vastai/issues>.

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
