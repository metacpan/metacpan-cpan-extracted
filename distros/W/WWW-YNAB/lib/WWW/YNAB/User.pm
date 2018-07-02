package WWW::YNAB::User;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::User::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: User model object



has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YNAB::User - User model object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(...);
  my $user = $ynab->user;

=head1 OVERVIEW

See L<https://api.youneedabudget.com/v1#/User> for more information.

=head1 METHODS

=head2 id

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
