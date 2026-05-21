package WWW::MailboxOrg::Entity::Account;

# ABSTRACT: Account entity object

use Moo;

our $VERSION = '0.001';

has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has account => (
    is       => 'ro',
    required => 1,
);


has plan => (
    is       => 'ro',
    predicate => 'has_plan',
);


has confirmed => (
    is       => 'ro',
    predicate => 'has_confirmed',
);


has is_active => (
    is       => 'ro',
    predicate => 'has_is_active',
);


has is_locked => (
    is       => 'ro',
    predicate => 'has_is_locked',
);


has data => (
    is       => 'ro',
    builder  => '_build_data',
);

sub _build_data {
    my ($self) = @_;
    return {
        account   => $self->account,
        plan      => $self->plan,
        confirmed => $self->confirmed,
        is_active => $self->is_active,
        is_locked => $self->is_locked,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::Entity::Account - Account entity object

=head1 VERSION

version 0.001

=head2 account

Account email address.

=head2 plan

Account plan: basic, profi, profixl, reseller.

=head2 confirmed

Account confirmation status.

=head2 is_active

Whether the account is active.

=head2 is_locked

Whether the account is locked.

=head2 data

Returns a hashref of the entity data.

=head1 NAME

WWW::MailboxOrg::Entity::Account - Account entity object

=head1 SEE ALSO

L<WWW::MailboxOrg>

=cut

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/getty/p5-www-mailboxorg/issues>.

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
