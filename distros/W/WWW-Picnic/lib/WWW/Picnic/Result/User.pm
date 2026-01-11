package WWW::Picnic::Result::User;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Picnic user account information

use Moo;

extends 'WWW::Picnic::Result';


has user_id => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('user_id') },
);


has firstname => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('firstname') },
);


has lastname => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('lastname') },
);


has contact_email => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('contact_email') },
);


has phone => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('phone') },
);


has customer_type => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('customer_type') },
);


has address => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('address') },
);


has household_details => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('household_details') },
);


has feature_toggles => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('feature_toggles') || [] },
);


has subscriptions => (
  is => 'ro',
  lazy => 1,
  default => sub { shift->_get('subscriptions') || [] },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic::Result::User - Picnic user account information

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    my $user = $picnic->get_user;
    say $user->firstname, ' ', $user->lastname;
    say $user->contact_email;

=head1 DESCRIPTION

Represents a Picnic user account with profile information, address,
and account settings.

=head2 user_id

Unique identifier for the user account.

=head2 firstname

User's first name.

=head2 lastname

User's last name.

=head2 contact_email

Email address associated with the account.

=head2 phone

Phone number associated with the account.

=head2 customer_type

Type of customer account.

=head2 address

Hashref containing delivery address information with keys: C<street>,
C<house_number>, C<house_number_ext>, C<postcode>, C<city>.

=head2 household_details

Hashref containing household information.

=head2 feature_toggles

Arrayref of enabled feature flags for this account.

=head2 subscriptions

Arrayref of active subscriptions (e.g., Picnic Plus).

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
