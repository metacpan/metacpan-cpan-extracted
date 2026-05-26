package WWW::MailboxOrg::API::Spamprotect;

# ABSTRACT: Spam protection API

use Moo;
with 'WWW::MailboxOrg::Role::API';
use Params::ValidationCompiler qw( validation_for );
use Types::Standard qw( Str Bool );

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

my %validators = (
    status => validation_for(
        params => {
            account => { type => Str, optional => 0 },
        },
    ),
    set => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            active  => { type => Bool, optional => 0 },
        },
    ),
);


sub status {
    my ( $self, %params ) = @_;
    my $v = $validators{'status'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'spamprotect.status', \%params );
}


sub set {
    my ( $self, %params ) = @_;
    my $v = $validators{'set'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'spamprotect.set', \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Spamprotect - Spam protection API

=head1 VERSION

version 0.100

=head2 status

    my $status = $api->spamprotect->status(account => 'admin@example.com');

Get spam protection status. Required: C<account>.

=head2 set

    $api->spamprotect->set(
        account => 'admin@example.com',
        active  => 1,
    );

Enable or disable spam protection. Required: C<account>, C<active>.

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
