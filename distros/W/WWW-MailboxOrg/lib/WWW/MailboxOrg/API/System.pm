package WWW::MailboxOrg::API::System;

# ABSTRACT: System API (hello, test, capabilities)

use Moo;
with 'WWW::MailboxOrg::Role::API';

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);


sub hello       { shift->_rpc('hello') }


sub test        { shift->_rpc('test') }


sub capabilities { shift->_rpc('capabilities') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::System - System API (hello, test, capabilities)

=head1 VERSION

version 0.100

=head2 hello

    my $result = $api->system->hello;

Get API hello response. No parameters required.

=head2 test

    my $result = $api->system->test;

Test API connection. Returns test result.

=head2 capabilities

    my $caps = $api->system->capabilities;

Get API capabilities. Returns capability list.

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
