package WWW::MailboxOrg::Types;

# ABSTRACT: Custom types for Mailbox.org API

use Type::Library -base, -declare => qw( EmailAddress DomainName );
use Type::Utils -all;
use Types::Standard -types;

my $meta = __PACKAGE__->meta;

declare EmailAddress,
    as Str,
    where { /^[^\s@]+@[^\s@]+\.[^\s@]+$/ },
    message { "$_ is not a valid email address" };

declare DomainName,
    as Str,
    where { /^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$/ },
    message { "$_ is not a valid domain name" };

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::Types - Custom types for Mailbox.org API

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    use WWW::MailboxOrg::Types qw( EmailAddress DomainName );

    has email => ( is => 'ro', isa => EmailAddress );
    has domain => ( is => 'ro', isa => DomainName );

=head1 TYPES

=head2 EmailAddress

Valid email address format.

=head2 DomainName

Valid domain name format.

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
