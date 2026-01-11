package WWW::Picnic::Result::Login;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Picnic login result with 2FA status

use Moo;

extends 'WWW::Picnic::Result';


has auth_key => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('auth_key') },
);


has user_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('user_id') },
);


has second_factor_authentication_required => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('second_factor_authentication_required') || 0 },
);


has show_second_factor_authentication_intro => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('show_second_factor_authentication_intro') || 0 },
);


sub requires_2fa {
  my ( $self ) = @_;
  return $self->second_factor_authentication_required ? 1 : 0;
}


sub is_authenticated {
  my ( $self ) = @_;
  return $self->auth_key && !$self->requires_2fa ? 1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::Login - Picnic login result with 2FA status

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    my $login = $picnic->login;

    if ($login->requires_2fa) {
        $picnic->generate_2fa_code;
        print "Enter SMS code: ";
        my $code = <STDIN>;
        chomp $code;
        $picnic->verify_2fa_code($code);
    }

=head1 DESCRIPTION

Represents the result of a login attempt. Contains information about
whether two-factor authentication is required.

=head2 auth_key

The authentication token if login was successful.

=head2 user_id

The user ID from the login response.

=head2 second_factor_authentication_required

Boolean indicating if 2FA verification is required to complete login.

=head2 show_second_factor_authentication_intro

Boolean indicating if the 2FA intro should be shown to the user.

=head2 requires_2fa

Convenience method returning true if 2FA is required.

=head2 is_authenticated

Returns true if fully authenticated (has auth key and no 2FA pending).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-picnic/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
