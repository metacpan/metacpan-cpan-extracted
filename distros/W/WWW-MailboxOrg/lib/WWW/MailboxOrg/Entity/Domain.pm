package WWW::MailboxOrg::Entity::Domain;

# ABSTRACT: Domain entity object

use Moo;

has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has domain => (
    is       => 'ro',
    required => 1,
);


has context_id => (
    is       => 'ro',
    predicate => 'has_context_id',
);


has is_active => (
    is       => 'ro',
    predicate => 'has_is_active',
);


has data => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_data',
);

sub _build_data {
    my ($self) = @_;
    return {
        domain     => $self->domain,
        context_id => $self->context_id,
        is_active  => $self->is_active,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::Entity::Domain - Domain entity object

=head1 VERSION

version 0.100

=head2 domain

Domain name.

=head2 context_id

Context ID.

=head2 is_active

Whether the domain is active.

=head2 data

Returns a hashref of the entity data.

=head1 SEE ALSO

L<WWW::MailboxOrg>

=cut

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-mailboxorg/issues>.

=head2 IRC

Join C<#perl-help> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
