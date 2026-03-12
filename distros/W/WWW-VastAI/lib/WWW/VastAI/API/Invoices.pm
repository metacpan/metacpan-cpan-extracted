package WWW::VastAI::API::Invoices;
our $VERSION = '0.001';
# ABSTRACT: Invoice listing for Vast.ai v1 billing endpoints

use Moo;
use WWW::VastAI::Invoice;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub list {
    my ($self, %query) = @_;
    my $result = $self->client->request_op('listInvoices', query => \%query);
    my $invoices = ref $result eq 'HASH' ? ($result->{invoices} || $result->{results} || []) : ($result || []);
    return [
        map {
            WWW::VastAI::Invoice->new(
                client => $self->client,
                data   => $_,
            )
        } @{$invoices}
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::Invoices - Invoice listing for Vast.ai v1 billing endpoints

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Lists billing invoices from the Vast.ai C</api/v1> endpoints and returns
L<WWW::VastAI::Invoice> objects.

=head1 METHODS

=head2 list

    my $invoices = $vast->invoices->list(limit => 10);

Lists invoice records.

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
