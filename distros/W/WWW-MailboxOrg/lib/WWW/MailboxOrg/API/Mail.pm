package WWW::MailboxOrg::API::Mail;

# ABSTRACT: Mail operations API

use Moo;
with 'WWW::MailboxOrg::Role::API';
use Params::ValidationCompiler qw( validation_for );
use Types::Standard qw( Str ArrayRef HashRef Bool Int );

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

my %validators = (
    find => validation_for( params => { query => { type => Str, optional => 0 } } ),
    list => validation_for(
        params => {
            account     => { type => Str,  optional => 1 },
            folder      => { type => Str,  optional => 1 },
            order_by    => { type => Str,  optional => 1 },
            page        => { type => Int,  optional => 1 },
            per_page    => { type => Int,  optional => 1 },
            result_mode => { type => Str,  optional => 1 },
            unseen_only => { type => Bool, optional => 1 },
        },
    ),
);


sub find {
    my ( $self, %params ) = @_;
    my $v = $validators{'find'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mail.find', \%params );
}


sub list {
    my ( $self, %params ) = @_;
    my $v = $validators{'list'};
    %params = $v->(%params) if $v;
    return $self->_rpc( 'mail.list', \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Mail - Mail operations API

=head1 VERSION

version 0.100

=head2 find

    my $results = $api->mail->find(query => 'from:user@example.com');
    my $results = $api->mail->find(query => 'subject:"hello world"');

Search emails. Required: C<query> string.

=head2 list

    $api->mail->list(folder => 'INBOX', unseen_only => 1);
    $api->mail->list(account => 'user@example.com', page => 1, per_page => 50);

List emails in a folder. Optional params:
- C<account> - Filter by account
- C<folder> - Folder name (default: INBOX)
- C<order_by> - Sort order
- C<page> - Page number
- C<per_page> - Results per page
- C<result_mode> - Result mode
- C<unseen_only> - Only unseen emails

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
