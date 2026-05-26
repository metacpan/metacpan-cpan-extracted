package WWW::MailboxOrg::API::Blacklist;

# ABSTRACT: Blacklist API

use Moo;
with 'WWW::MailboxOrg::Role::API';
use Params::ValidationCompiler qw( validation_for );
use Types::Standard qw( Str );

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

my %validators = (
    add => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            email   => { type => Str, optional => 0 },
        },
    ),
    del => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            email   => { type => Str, optional => 0 },
        },
    ),
    list => validation_for(
        params => {
            account => { type => Str, optional => 0 },
        },
    ),
);


sub add {
    my ( $self, %params ) = @_;
    my $v = $validators{'add'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'blacklist.add', \%params );
}


sub del {
    my ( $self, %params ) = @_;
    my $v = $validators{'del'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'blacklist.del', \%params );
}


sub list {
    my ( $self, %params ) = @_;
    my $v = $validators{'list'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'blacklist.list', \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Blacklist - Blacklist API

=head1 VERSION

version 0.100

=head2 add

    $api->blacklist->add(
        account => 'admin@example.com',
        email   => 'spam@example.com',
    );

Add an email to blacklist. Required: C<account>, C<email>.

=head2 del

    $api->blacklist->del(
        account => 'admin@example.com',
        email   => 'spam@example.com',
    );

Remove an email from blacklist.

=head2 list

    $api->blacklist->list(account => 'admin@example.com');

List blacklist entries. Required: C<account>.

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
