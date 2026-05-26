package WWW::MailboxOrg::API::Invoice;

# ABSTRACT: Invoice API

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
    list     => validation_for( params => { account => { type => Str, optional => 1 } } ),
    get      => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            invoice => { type => Str, optional => 0 },
        },
    ),
    download => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            invoice => { type => Str, optional => 0 },
        },
    ),
);


sub list {
    my ( $self, %params ) = @_;
    my $v = $validators{'list'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'invoice.list', \%params );
}


sub get {
    my ( $self, %params ) = @_;
    my $v = $validators{'get'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'invoice.get', \%params );
}


sub download {
    my ( $self, %params ) = @_;
    my $v = $validators{'download'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'invoice.download', \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Invoice - Invoice API

=head1 VERSION

version 0.100

=head2 list

    my $invoices = $api->invoice->list;
    $api->invoice->list(account => 'admin@example.com');

List invoices. Optional C<account> filter.

=head2 get

    $api->invoice->get(
        account => 'admin@example.com',
        invoice => 'INV-2024-001',
    );

Get invoice details. Required: C<account>, C<invoice>.

=head2 download

    $api->invoice->download(
        account => 'admin@example.com',
        invoice => 'INV-2024-001',
    );

Download an invoice. Required: C<account>, C<invoice>.

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
