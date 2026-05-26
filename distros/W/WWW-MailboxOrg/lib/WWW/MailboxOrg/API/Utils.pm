package WWW::MailboxOrg::API::Utils;

# ABSTRACT: Utility API (parse_headers, parse_date, generate_message_id)

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
    parse_headers      => validation_for( params => { headers => { type => Str, optional => 0 } } ),
    parse_date         => validation_for( params => { date    => { type => Str, optional => 0 } } ),
    generate_message_id => validation_for( params => { account => { type => Str, optional => 1 } } ),
);


sub parse_headers {
    my ( $self, %params ) = @_;
    my $v = $validators{'parse_headers'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'utils.parse_headers', \%params );
}


sub parse_date {
    my ( $self, %params ) = @_;
    my $v = $validators{'parse_date'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'utils.parse_date', \%params );
}


sub generate_message_id {
    my ( $self, %params ) = @_;
    my $v = $validators{'generate_message_id'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'utils.generate_message_id', \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Utils - Utility API (parse_headers, parse_date, generate_message_id)

=head1 VERSION

version 0.100

=head2 parse_headers

    my $parsed = $api->utils->parse_headers(
        headers => "From: user@example.com\r\nSubject: Hello",
    );

Parse email headers. Required: C<headers>.

=head2 parse_date

    my $parsed = $api->utils->parse_date(date => 'Mon, 01 Jan 2024 12:00:00 +0000');

Parse an email date. Required: C<date>.

=head2 generate_message_id

    my $msg_id = $api->utils->generate_message_id;
    my $msg_id = $api->utils->generate_message_id(account => 'user@example.com');

Generate a message ID. Optional: C<account>.

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
