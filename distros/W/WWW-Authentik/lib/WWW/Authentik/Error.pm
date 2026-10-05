package WWW::Authentik::Error;

# ABSTRACT: Exception base class for WWW::Authentik

use Moo;

# No namespace::autoclean here: it would remove the overload stub.
use overload '""' => sub { $_[0]->message }, fallback => 1;

our $VERSION = '0.001';


has message => (
  is       => 'ro',
  required => 1
);


sub throw {
  my ( $class, %arg ) = @_;
  die $class->new(%arg);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Authentik::Error - Exception base class for WWW::Authentik

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Scalar::Util qw( blessed );

    my $user = eval { $api->get_user($pk) };
    if ( blessed $@ && $@->isa('WWW::Authentik::Error::API') && $@->is_not_found ) { ... }

=head1 DESCRIPTION

Every error WWW::Authentik raises is an object of one of three subclasses:
L<WWW::Authentik::Error::Validation> for wrong arguments,
L<WWW::Authentik::Error::Network> when no HTTP answer arrived, and
L<WWW::Authentik::Error::API> when authentik answered with an error. All of
them stringify to their message, so plain C<$@> matching keeps working.

=head2 message

The human-readable description. The object stringifies to it. It never
carries the API token, a client secret or a password.

=head2 throw

    WWW::Authentik::Error::Validation->throw( message => 'base_url is required' );

Builds the exception and dies with it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-authentik/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
