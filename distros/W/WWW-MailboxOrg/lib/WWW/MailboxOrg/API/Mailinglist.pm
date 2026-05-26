package WWW::MailboxOrg::API::Mailinglist;

# ABSTRACT: Mailing list API

use Moo;
with 'WWW::MailboxOrg::Role::API';
use Params::ValidationCompiler qw( validation_for );
use Types::Standard qw( Str ArrayRef HashRef Bool );

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

my %validators = (
    add => validation_for(
        params => {
            account  => { type => Str, optional => 0 },
            list     => { type => Str, optional => 0 },
            password => { type => Str, optional => 0 },
            memo     => { type => Str, optional => 1 },
        },
    ),
    del => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            list    => { type => Str, optional => 0 },
        },
    ),
    get => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            list    => { type => Str, optional => 0 },
        },
    ),
    list => validation_for( params => { account => { type => Str, optional => 1 } } ),
    set => validation_for(
        params => {
            account  => { type => Str, optional => 0 },
            list     => { type => Str, optional => 0 },
            password => { type => Str, optional => 1 },
            memo     => { type => Str, optional => 1 },
        },
    ),
    add_member => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            list    => { type => Str, optional => 0 },
            email   => { type => Str, optional => 0 },
        },
    ),
    del_member => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            list    => { type => Str, optional => 0 },
            email   => { type => Str, optional => 0 },
        },
    ),
    list_members => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            list    => { type => Str, optional => 0 },
        },
    ),
);


sub add {
    my ( $self, %params ) = @_;
    my $v = $validators{'add'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mailinglist.add', \%params );
}


sub del {
    my ( $self, %params ) = @_;
    my $v = $validators{'del'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mailinglist.del', \%params );
}


sub get {
    my ( $self, %params ) = @_;
    my $v = $validators{'get'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mailinglist.get', \%params );
}


sub list {
    my ( $self, %params ) = @_;
    my $v = $validators{'list'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mailinglist.list', \%params );
}


sub set {
    my ( $self, %params ) = @_;
    my $v = $validators{'set'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mailinglist.set', \%params );
}


sub add_member {
    my ( $self, %params ) = @_;
    my $v = $validators{'add_member'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mailinglist.add_member', \%params );
}


sub del_member {
    my ( $self, %params ) = @_;
    my $v = $validators{'del_member'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mailinglist.del_member', \%params );
}


sub list_members {
    my ( $self, %params ) = @_;
    my $v = $validators{'list_members'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mailinglist.list_members', \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Mailinglist - Mailing list API

=head1 VERSION

version 0.100

=head2 add

    $api->mailinglist->add(
        account  => 'admin@example.com',
        list     => 'list@example.com',
        password => 'secret',
        memo     => 'Optional note',
    );

Add a new mailing list. Required: C<account>, C<list>, C<password>.

=head2 del

    $api->mailinglist->del(
        account => 'admin@example.com',
        list    => 'list@example.com',
    );

Delete a mailing list.

=head2 get

    $api->mailinglist->get(
        account => 'admin@example.com',
        list    => 'list@example.com',
    );

Get mailing list details.

=head2 list

    $api->mailinglist->list;
    $api->mailinglist->list(account => 'admin@example.com');

List mailing lists. Optional C<account> filter.

=head2 set

    $api->mailinglist->set(
        account  => 'admin@example.com',
        list     => 'list@example.com',
        password => 'newsecret',
        memo     => 'Updated note',
    );

Update mailing list settings. At least C<account> and C<list> required.

=head2 add_member

    $api->mailinglist->add_member(
        account => 'admin@example.com',
        list    => 'list@example.com',
        email   => 'member@example.com',
    );

Add a member to a mailing list.

=head2 del_member

    $api->mailinglist->del_member(
        account => 'admin@example.com',
        list    => 'list@example.com',
        email   => 'member@example.com',
    );

Remove a member from a mailing list.

=head2 list_members

    $api->mailinglist->list_members(
        account => 'admin@example.com',
        list    => 'list@example.com',
    );

List all members of a mailing list.

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
